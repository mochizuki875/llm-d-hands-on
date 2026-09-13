# llm-d hands-on(CPU-only on kind)
## 概要
[llm-d](https://llm-d.ai/)の機能を[kind](https://kind.sigs.k8s.io/)でCPU環境に構築したKubernetesクラスタ上で検証するためのプロジェクトです。
llm-dの機能検証を目的としているためGPUを必要とする実際の推論ワークロードは起動せず、[llm-d-inference-sim](https://github.com/llm-d/llm-d-inference-sim)を使用してGPU環境でのvLLM実行をシミュレートします。

> [!NOTE]
> このコンテンツは一部AIを使って作成しています。

## ソフトウェアスタック
| ソフトウェア | バージョン | 備考 |
| --- | --- | --- |
| [kind](https://kind.sigs.k8s.io/) | v0.33.0|  |
| Kubernetes | v1.37.0|  |
| [Envoy Gateway](https://github.com/envoyproxy/gateway) | v1.9.1 |  |
| [Envoy AI Gateway]() | v1.1.0 | |
| [Gateway API](https://github.com/kubernetes-sigs/gateway-api) | v1.6.1 |  |
| [Gateway API Inference Extension](https://github.com/kubernetes-sigs/gateway-api-inference-extension) | v1.6.0 ||
| [llm-d-router](https://github.com/llm-d/llm-d-router) | v0.10.0 ||
| [llm-d-inference-sim](https://github.com/llm-d/llm-d-inference-sim) | v0.10.2 | GPU環境でのvLLM実行をシミュレートするためのMock Image|

## Prerequisites
- [Create Kubernetes Cluster with kind](./setup/kind/README.md)
- [Install Grafana Monitoring Stack](./setup/monitoring/README.md)
- [Install Envoy Gateway and Gateway API Inference Extension](./setup/gateway-api)

## llm-d機能検証シナリオ
- [Optimized Baseline](./optimized-baseline/README.md)
- [P/D Disaggregation](./pd-disaggregation/README.md)