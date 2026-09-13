#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="llm-d-monitoring"

kubectl delete -k "${SCRIPT_DIR}/otel-collector" --ignore-not-found || true
kubectl delete -k "${SCRIPT_DIR}/podmonitors" --ignore-not-found || true
kubectl delete -k "${SCRIPT_DIR}/dashboards" --ignore-not-found || true

helm uninstall monitoring-tempo -n "${NAMESPACE}" || true
helm uninstall monitoring-prometheus -n "${NAMESPACE}" || true

kubectl delete -f "${SCRIPT_DIR}/namespace.yaml" --ignore-not-found