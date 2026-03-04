# Burn rate PromQL

SLO target: 99.5 percent
Budget: 1 - 0.995 = 0.005

## 5m error rate
err_5m = 1 - (sum(rate(ingestion_runs_total{result="success"}[5m])) / sum(rate(ingestion_runs_total[5m])))

## Fast burn condition
err_5m > 0.005 * 14

## Slow burn condition
err_5m > 0.005 * 2
