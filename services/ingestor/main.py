import json
import os
import time
import uuid
from datetime import datetime, timezone

import requests
from fastapi import FastAPI, Response
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Gauge, Histogram, generate_latest

from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient

from schema import validate_payload


APP_NAME = "nfl-data-ingestor"

SPORTS_API_URL = os.getenv(
    "SPORTS_API_URL",
    "https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard",
).strip()

INGEST_INTERVAL_SECONDS = int(os.getenv("INGEST_INTERVAL_SECONDS", "300"))
REQUEST_TIMEOUT_SECONDS = int(os.getenv("REQUEST_TIMEOUT_SECONDS", "20"))

BLOB_CONTAINER_RAW = os.getenv("BLOB_CONTAINER_RAW", "raw").strip()
BLOB_CONTAINER_PROCESSED = os.getenv("BLOB_CONTAINER_PROCESSED", "processed").strip()
BLOB_CONTAINER_QUARANTINE = os.getenv("BLOB_CONTAINER_QUARANTINE", "quarantine").strip()

AZURE_STORAGE_ACCOUNT_NAME = os.getenv("AZURE_STORAGE_ACCOUNT_NAME", "").strip()
AZURE_STORAGE_ACCOUNT_URL = os.getenv("AZURE_STORAGE_ACCOUNT_URL", "").strip()
AZURE_STORAGE_CONNECTION_STRING = os.getenv("AZURE_STORAGE_CONNECTION_STRING", "").strip()


ingestion_runs_total = Counter("ingestion_runs_total", "Total ingestion runs", ["result"])
schema_validity_total = Counter("schema_validity_total", "Total schema validation results", ["valid"])
api_request_latency_seconds = Histogram("api_request_latency_seconds", "API request latency in seconds")
payload_bytes = Histogram("payload_bytes", "Payload size in bytes")
data_freshness_seconds = Gauge("data_freshness_seconds", "Seconds since newest data timestamp found in payload")
ingestion_last_success_timestamp_seconds = Gauge(
    "ingestion_last_success_timestamp_seconds",
    "Unix timestamp of last successful ingestion run",
)


def now_utc() -> datetime:
    return datetime.now(timezone.utc)


def log(msg: str, **fields):
    base = {"ts": now_utc().isoformat(), "app": APP_NAME, "msg": msg}
    base.update(fields)
    print(json.dumps(base, separators=(",", ":"), ensure_ascii=False))


def compute_freshness_seconds(payload: dict) -> float | None:
    candidates = []

    def add(v):
        if isinstance(v, str) and v:
            candidates.append(v)

    add(payload.get("timestamp"))
    add(payload.get("lastUpdated"))

    events = payload.get("events") or []
    if isinstance(events, list) and events and isinstance(events[0], dict):
        add(events[0].get("date"))
        add(events[0].get("lastUpdated"))

    for ts in candidates:
        try:
            dt = datetime.fromisoformat(ts.replace("Z", "+00:00"))
            return max(0.0, (now_utc() - dt).total_seconds())
        except Exception:
            continue
    return None


def make_blob_service() -> BlobServiceClient:
    if AZURE_STORAGE_CONNECTION_STRING:
        return BlobServiceClient.from_connection_string(AZURE_STORAGE_CONNECTION_STRING)

    account_url = AZURE_STORAGE_ACCOUNT_URL
    if not account_url and AZURE_STORAGE_ACCOUNT_NAME:
        account_url = f"https://{AZURE_STORAGE_ACCOUNT_NAME}.blob.core.windows.net"

    if not account_url:
        raise RuntimeError(
            "Set AZURE_STORAGE_ACCOUNT_NAME or AZURE_STORAGE_ACCOUNT_URL for managed identity auth, "
            "or AZURE_STORAGE_CONNECTION_STRING for local dev."
        )

    cred = DefaultAzureCredential()
    return BlobServiceClient(account_url=account_url, credential=cred)


def upload_json(blob_service: BlobServiceClient, container: str, blob_name: str, payload: dict) -> int:
    data = json.dumps(payload, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    client = blob_service.get_blob_client(container=container, blob=blob_name)
    client.upload_blob(data, overwrite=True)
    return len(data)


def fetch_payload() -> dict:
    with api_request_latency_seconds.time():
        r = requests.get(SPORTS_API_URL, timeout=REQUEST_TIMEOUT_SECONDS)
        r.raise_for_status()
        return r.json()


def build_blob_path(kind: str, run_id: str) -> str:
    dt = now_utc()
    return (
        f"source=nfl/kind={kind}/y={dt:%Y}/m={dt:%m}/d={dt:%d}/h={dt:%H}/run_id={run_id}.json"
    )


def run_once(blob_service: BlobServiceClient) -> None:
    run_id = str(uuid.uuid4())
    started = time.time()

    try:
        payload = fetch_payload()

        freshness = compute_freshness_seconds(payload)
        if freshness is not None:
            data_freshness_seconds.set(freshness)

        valid, reason = validate_payload(payload)

        if valid:
            schema_validity_total.labels(valid="true").inc()
            blob_name = build_blob_path(kind="processed", run_id=run_id)
            size = upload_json(blob_service, BLOB_CONTAINER_PROCESSED, blob_name, payload)
            payload_bytes.observe(size)
            ingestion_runs_total.labels(result="success").inc()
            ingestion_last_success_timestamp_seconds.set(time.time())
            log("ingestion_success", run_id=run_id, seconds=round(time.time() - started, 3), bytes=size)
            return

        schema_validity_total.labels(valid="false").inc()

        raw_blob_name = build_blob_path(kind="raw", run_id=run_id)
        raw_size = upload_json(blob_service, BLOB_CONTAINER_RAW, raw_blob_name, payload)

        quarantine_payload = {
            "run_id": run_id,
            "schema_valid": False,
            "schema_error": reason,
            "original": payload,
            "ingested_at": now_utc().isoformat(),
        }
        q_blob_name = build_blob_path(kind="quarantine", run_id=run_id)
        q_size = upload_json(blob_service, BLOB_CONTAINER_QUARANTINE, q_blob_name, quarantine_payload)

        payload_bytes.observe(raw_size)
        payload_bytes.observe(q_size)

        ingestion_runs_total.labels(result="failure").inc()
        log(
            "ingestion_schema_invalid",
            run_id=run_id,
            seconds=round(time.time() - started, 3),
            raw_bytes=raw_size,
            quarantine_bytes=q_size,
            error=reason,
        )

    except Exception as e:
        ingestion_runs_total.labels(result="failure").inc()
        log("ingestion_exception", run_id=run_id, error=str(e))
        raise


app = FastAPI()


@app.get("/healthz")
def healthz():
    return {"ok": True, "app": APP_NAME}


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.on_event("startup")
def startup():
    blob_service = make_blob_service()

    def loop():
        while True:
            try:
                run_once(blob_service)
            except Exception:
                pass
            time.sleep(INGEST_INTERVAL_SECONDS)

    import threading
    threading.Thread(target=loop, daemon=True).start()
