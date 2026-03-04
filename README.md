# NFL Data Reliability Platform (Azure)

Treats a public NFL sports API as a production data source and wraps ingestion with SRE style observability, reliability signals, and Infrastructure as Code.

## What this platform does
- Ingests data from a public NFL endpoint on a schedule using a Python service
- Stores raw and processed payloads in Azure Blob Storage with a quarantine path for schema issues
- Exposes custom Prometheus metrics for SLIs and SLO oriented monitoring
- Runs on Azure Container Apps, built and deployed with Terraform modules
- Uses a Prometheus scraper container app for PromQL queries and basic burn rate analysis
- Includes runbooks and SLO documentation for reliability operations

## Core components
- Azure Container Apps
  - Ingestor service container app exposing /healthz and /metrics
  - Prometheus scraper container app scraping the ingestor metrics endpoint
- Azure Storage
  - Storage account with blob containers: raw, processed, quarantine
  - RBAC storage permissions granted to the ingestor managed identity
- Azure Container Registry
  - Stores the ingestor image tagged for deployment
- Azure Key Vault
  - Holds secrets for future integrations
- Azure Managed Grafana
  - Managed dashboard surface for Prometheus metrics

## Observability and reliability signals
Custom Prometheus metrics exposed by the ingestor include:
- ingestion_runs_total{result="success|failure"}
- schema_validity_total{valid="true|false"}
- data_freshness_seconds
- ingestion_last_success_timestamp_seconds

PromQL examples and burn rate guidance are documented under ops/slo, and a runbook is provided under ops/runbooks.

## Repository structure
- infra/bootstrap
  - Creates the remote backend resources for Terraform state
- infra/environments/dev
  - Dev environment root, wires modules together
- infra/modules
  - Reusable Terraform modules for platform resources
- services/ingestor
  - Python ingestion service and Dockerfile
- ops/slo
  - SLO and burn rate PromQL references
- ops/runbooks
  - Operational runbooks for incident response

## Deploy and destroy
This project is designed to be deployed for testing and then destroyed.
- Deploy: terraform apply from infra/environments/dev
- Destroy: terraform destroy from infra/environments/dev, then terraform destroy from infra/bootstrap if you want to remove the state backend too

## Notes
The ingestion service image must be built and pushed as linux amd64 for Azure Container Apps compatibility on Apple Silicon development machines.
