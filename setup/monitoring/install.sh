#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="llm-d-monitoring"
KUBE_PROMETHEUS_STACK_VERSION="88.6.2"
TEMPO_CHART_VERSION="2.3.0"

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts --force-update
helm repo add grafana-community https://grafana-community.github.io/helm-charts --force-update
helm repo update

kubectl apply -f "${SCRIPT_DIR}/namespace.yaml"

helm upgrade --install monitoring-prometheus prometheus-community/kube-prometheus-stack \
  --namespace "${NAMESPACE}" \
  --version "${KUBE_PROMETHEUS_STACK_VERSION}" \
  -f "${SCRIPT_DIR}/prometheus.values.yaml"

helm upgrade --install monitoring-tempo grafana-community/tempo \
  --namespace "${NAMESPACE}" \
  --version "${TEMPO_CHART_VERSION}" \
  -f "${SCRIPT_DIR}/tempo.values.yaml"

kubectl apply -k "${SCRIPT_DIR}/otel-collector"
kubectl apply -k "${SCRIPT_DIR}/podmonitors"
kubectl apply -k "${SCRIPT_DIR}/dashboards"