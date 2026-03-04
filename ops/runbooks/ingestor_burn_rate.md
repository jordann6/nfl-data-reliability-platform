# Runbook: Ingestor error budget burn

## Signals
Burn rate indicates the ingestion success SLO is being violated and consuming error budget.

## Triage
1. Confirm impact in Prometheus
   Query ingestion_runs_total and error rate over 5m
2. Check ingestor health
   curl /healthz and /metrics
3. Inspect Container App logs for ca-nfldrp-dev-ingestor
4. Validate upstream API reachability
5. Validate Blob permissions and storage availability

## Mitigation
1. Roll back to last known good image tag
2. Reduce ingestion frequency temporarily
3. Disable ingestion app if upstream is hard down and you want to preserve budget

## Post incident
1. Capture root cause
2. Add guardrail or retry backoff
3. Update alerts and thresholds if needed
