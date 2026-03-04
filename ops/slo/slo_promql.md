# NFL Data Reliability Platform SLOs

## SLIs
### Ingestion success rate SLI
PromQL
sum(rate(ingestion_runs_total{result="success"}[5m])) / sum(rate(ingestion_runs_total[5m]))

### Ingestion error rate SLI
PromQL
1 - (sum(rate(ingestion_runs_total{result="success"}[5m])) / sum(rate(ingestion_runs_total[5m])))

### Data freshness SLI
PromQL
data_freshness_seconds

Interpretation
Lower is better. Alert if above threshold.

## SLO Targets
### Availability style SLO for ingestion runs
Target: 99.5 percent success rate over 30 days
Error budget: 0.5 percent of runs can fail

## Burn rate guidance
Fast burn (page): error rate above 14x budget
Slow burn (ticket): error rate above 2x budget
