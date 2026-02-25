# Systematic Debugging — Reference

## Root Cause Tracing

バグは call stack の深い場所で発生。症状ではなく原因で修正。

### ステップ

1. **症状を観察**: エラーメッセージ、誤った出力、クラッシュ
2. **直接原因を発見**: どの行でスロー？ どの値が誤り？
3. **1レベル上へトレース**: 何がこの関数を誤った値で呼んだ？
4. **繰り返し** 元のトリガーに到達するまで
5. **原因で修正**、その後 defense-in-depth 検証を追加

### スタックトレース追加

```typescript
// 問題操作の前に追加（失敗後でなく）
async function riskyOperation(input: string) {
  console.error('DEBUG riskyOperation:', {
    input,
    cwd: process.cwd(),
    stack: new Error().stack,
  });
  // ... operation
}
```

テストでは `console.error()` 使用（logger 出力は抑制される可能性）。

### Git Bisect でリグレッション調査

```bash
git bisect start
git bisect bad
git bisect good <known-good-sha>
# 中間点をテストしてマーク:
git bisect good  # or  git bisect bad
# 繰り返し
git bisect reset
```

テストスクリプトで自動化: `git bisect run npm test -- --testPathPattern=failing.test`

### テスト汚染の発見

```bash
./find-polluter.sh '.git' 'src/**/*.test.ts'
```

---

## Defense-in-Depth Validation

根本原因発見後、すべてのレイヤーで検証追加してバグを構造的に不可能に。

### 4レイヤー

| レイヤー | 目的 | 例 |
|---------|-----|---|
| エントリーポイント | API 境界で無効入力を拒否 | 非空、存在、正しい型を検証 |
| ビジネスロジック | 操作に意味のあるデータを保証 | コンテキストに必要なフィールドを検証 |
| 環境ガード | 特定コンテキストでの危険な操作を防止 | テスト内で tmpdir 外での破壊操作を拒否 |
| デバッグ計装 | フォレンジック用コンテキストをキャプチャ | 危険操作前に入力、cwd、stack をログ |

### なぜ4つ全部必要？

- 異なるコードパスがエントリ検証をバイパス
- モックがビジネスロジックをバイパス
- プラットフォーム別エッジケースに環境ガード必要
- デバッグログが構造的誤用パターンを特定

---

## Condition-Based Waiting

任意の `setTimeout`/`sleep` を実際の条件のポーリングに置き換え。

### コアパターン

```typescript
// BAD: タイミングを推測
await new Promise(r => setTimeout(r, 50));
expect(getResult()).toBeDefined();

// GOOD: 条件を待つ
await waitFor(() => getResult() !== undefined, 'result available');
expect(getResult()).toBeDefined();
```

### 汎用実装

```typescript
async function waitFor<T>(
  condition: () => T | undefined | null | false,
  description: string,
  timeoutMs = 5000
): Promise<T> {
  const startTime = Date.now();
  while (true) {
    const result = condition();
    if (result) return result;
    if (Date.now() - startTime > timeoutMs) {
      throw new Error(`Timeout waiting for ${description} after ${timeoutMs}ms`);
    }
    await new Promise(r => setTimeout(r, 10));
  }
}
```

### クイックリファレンス

| シナリオ | パターン |
|---------|---------|
| イベント待ち | `waitFor(() => events.find(e => e.type === 'DONE'))` |
| 状態待ち | `waitFor(() => machine.state === 'ready')` |
| カウント待ち | `waitFor(() => items.length >= 5)` |
| ファイル待ち | `waitFor(() => fs.existsSync(path))` |

### 任意のタイムアウトが正しい場合

実際のタイミング動作テスト時のみ（debounce、throttle）。要件:
1. トリガー条件を最初に待つ
2. 推測でなく既知のタイミングに基づくタイムアウト
3. 理由を説明するコメント

---

## デバッグ判断フローチャート

```
バグ報告
  |
  v
エラーメッセージを完全に読む
  |
  v
再現可能? --NO--> データ収集、ログ追加、再発を待つ
  |YES
  v
git diff / 最近の変更を確認
  |
  v
複数コンポーネント? --YES--> 境界ログ追加、1回実行、分析
  |NO                       |
  v                         v
データフローを逆向きにトレース  失敗コンポーネント特定
  |                         |
  v                         v
根本原因特定? --NO--> 仮説形成、最小限テスト
  |YES                      |
  v                         v (確認まで繰り返し)
動作例を見つけて差異比較
  |
  v
失敗するテスト作成
  |
  v
単一の修正を実装
  |
  v
テストパス? --NO--> 修正回数 < 3? --YES--> 調査に戻る
  |YES                          |NO
  v                             v
完了。defense-in-depth 追加     停止: アーキテクチャをユーザーと議論
```

---

## 関連スキルとの境界

| デバッグシナリオ | このスキルでやること | 引き継ぎ先 |
|----------------|---------------------|----------|
| バグ発見、リグレッションテスト必要 | 根本原因特定 | `testing-strategy`: 失敗テスト書いて修正 |
| エラー分類不明 | データフローをトレースして起源を発見 | `error-handling-logging`: operational vs programmer error 分類 |
| セキュリティ脆弱性の可能性 | 再現と根本原因調査 | `security-review`: 悪用可能性と深刻度評価 |
| 3回目の修正試行失敗 | アーキテクチャ議論にエスカレート | `testing-strategy`: テストファースト再設計 |
| CI パイプライン破損 | 失敗ステージ分離の境界ログ追加 | `ci-cd-deployment`: パイプライン設定修正 |
