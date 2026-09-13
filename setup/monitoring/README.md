# Monitoring
## 目的
kindで構築したKubernetes上にGrafanを中心とした以下のモニタリングスタックを導入し、llm-dの機能検証に必要なメトリクスを収集する。


| コンポーネント | バージョン |
| --- | --- |
| `prometheus-community/kube-prometheus-stack` | `88.6.2` |
| Grafana | `13.2.0` |
| Prometheus | `v3.14.0` |
| Tempo | `2.10.8` |
| OpenTelemetry Collector | `0.159.0` |

## 1. モニタリングスタックのインストール

```bash
bash install.sh
```

このスクリプトでは以下の処理を実施している。

3. `llm-d-monitoring` namespaceの作成
4. `prometheus-community/kube-prometheus-stack`(PrometheusとGrafana)のインストール
5. `Tempo`のインストール
6. OpenTelemetry Collectorのインストール
7. PrometheusのScprape設定(`PodMonitor`)
8. Grafanaダッシュボードの作成()

## 動作確認
### Grafanaへのアクセス

ポートフォワードを行う。
```bash
kubectl port-forward -n llm-d-monitoring svc/monitoring-prometheus-grafana 3000:80
```

ブラウザで`http://127.0.0.1:3000`にアクセスする。
- user: `admin`
- password: `admin`


## クリーンアップ

```bash
bash uninstall.sh
```