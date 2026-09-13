# Setup
## 目的
[kind](https://kind.sigs.k8s.io/)を用いてKubernetesクラスタを構築する。

### Kubernetesクラスタの作成
```bash
kind create cluster --config kind-config.yaml
```

## クリーンアップ
```bash
kind delete cluster --name kind-v1.36.1
```