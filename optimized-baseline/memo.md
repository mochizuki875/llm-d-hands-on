共通prefixを持つリクエストを順番に送信する。
ほぼ同じpromptを連続で送るため、`prefix-cache-affinity-filter`により2つの推論PodのうちKV Cacheがヒットしやすい一方のみにリクエストが集中することを確認する。

```bash
for i in $(seq 1 30); do
  curl -s http://127.0.0.1:8080/v1/chat/completions \
    -H 'Content-Type: application/json' \
    -d '{
      "model": "Qwen/Qwen2.5-0.5B-Instruct",
      "messages": [
        {
          "role": "user",
          "content": "llm-d optimizes request routing for repeated prefixes by keeping related requests close to warm KV cache state on the same backend. Summarize how prefix locality, inflight load, and backend selection interact in this simulator-based optimized baseline example, and mention why repeated prefixes should improve cache reuse. request-'"${i}"'"
        }
      ],
      "max_tokens": 128,
      "temperature": 0
    }' > /dev/null
done
```


これだと分散する。

------
ChatGPT

**原因**
分散の主因は Envoy AI Gateway ではなく、同時に更新された **llm-d Router/EPP v0.9.0 の prefix 判定粒度の変更**です。

現在のクラスタでは、EPP の起動ログに次の内容が出ています。

```text
GIE build ... build-ref="v0.9.0"

Prefix DataProducer initialized
autoTune=true blockSizeTokens=16

WARNING: configured blockSizeTokens is below the recommended minimum,
overriding it.
blockSizeTokens=16 minimum=64
```

v0.9.0では、EPPの近似prefix indexが過大になるのを防ぐため、`blockSizeTokens`が最小64 tokenに強制されます。  
これは [llm-d-router PR #1160](https://github.com/llm-d/llm-d-router/pull/1160) で追加された変更です。

今回のpromptは、EPPログ上では約84から85 tokenです。  
そのため、64 token単位では次の2 blockになります。

```text
Block 1: 共通部分
Block 2: 共通部分の末尾 + request-N
```

`request-N`によって2番目のblock hashが毎回変わると、再利用できるのは1 blockだけです。

$$
\text{prefix score}
=
\frac{\text{一致 block 数}}{\text{全 block 数}}
=
\frac{1}{2}
=
0.5
$$

一方、`prefix-cache-affinity-filter`のデフォルト閾値は `0.80` です。  
したがって、どちらのPodもsticky endpointとして認定されず、filterは候補を絞らずに2 Podをそのまま後段へ渡します。

**なぜ前回は集中したのか**
以前のEPPが16 token単位で判定していたなら、約84 tokenは6 blockになります。

末尾の1 blockだけが変化する場合は、概算で次のscoreになります。

$$
\frac{5}{6} \approx 0.833
$$

これは閾値 `0.80` を超えるため、前回は最初に選ばれたPodへ集中しやすかったと説明できます。

現在のログでも、同じリクエストについて2 Podの両方が `TokenLoadScorer`まで到達しています。

```text
endpoint=...-2lmqf-rank-0 tokenLoad=84 score=0.9999799728393555
endpoint=...-54pbw-rank-0 tokenLoad=84 score=0.9999799728393555
```

これは、先に実行される `prefix-cache-affinity-filter`が候補を1 Podへ絞れなかった証拠です。  
逐次送信なので両Podの負荷も同点になり、暗黙に追加される `max-score-picker`が同点候補をランダムに選びます。その結果、2 Podへ分散します。

**Gateway更新との関係**
Envoy AI GatewayやGateway API Inference Extensionが直接負荷分散しているわけではありません。

今回、EPPは次を正常に実行できています。

- リクエスト本文を受信
- モデル名を解析
- promptをtokenize
- 2つのendpointをscore
- 選択結果をGatewayへ返却

したがって、Gatewayとの連携不具合を示す証拠はありません。  
「Gateway周辺を更新したタイミング」と「Router/EPP v0.9.0へ更新したタイミング」が重なっており、実際にルーティング結果を変えたのは後者と考えられます。

**再現テストの直し方**
デフォルトの `affinityThreshold: 0.80` を維持するなら、共通prefixを十分長くしてください。

64 token blockで末尾1 blockだけが変わる場合、最低でも次を満たす必要があります。

$$
\frac{N-1}{N} \ge 0.8
$$

したがって $N \ge 5$、つまり共通部分だけで少なくとも約256 token必要です。  
tokenizationの揺れを考慮すると、**320 token以上の固定prefixを置き、`request-N`を最後に付ける**方が安定します。

別案として、検証用途に限って gateway-api.values.yaml のfilterへ `affinityThreshold: 0.5` を指定できます。ただし、Optimized Baselineのデフォルト挙動を確認する試験では、閾値を下げるよりpromptを長くする方が適切です。

また、添付の `Per-Pod Request Distribution` は llm-d-performance-kv-cache.json の `irate` による完了リクエスト率です。2 Podへ届いたことは示しますが、prefix scoreや選択理由、累積リクエスト数は示しません。