# Playwright CLI — Reference

SKILL.md 補足: コマンド詳細、セレクタ戦略、よくあるトラブルシュート。

---

## コマンドリファレンス

### 基本操作

```bash
PW="$HOME/.codex/skills/playwright/scripts/playwright_cli.sh"

# ページ操作
"$PW" open <url> [--headed]        # URL を開く（--headed でブラウザ表示）
"$PW" snapshot                      # DOM スナップショット取得（ref 番号付き）
"$PW" screenshot                    # スクリーンショット取得
"$PW" screenshot --full             # フルページスクリーンショット

# インタラクション
"$PW" click <ref>                   # 要素クリック（snapshot の ref 番号）
"$PW" fill <ref> "text"             # フォーム入力
"$PW" type "text"                   # キーボード入力（アクティブ要素に）
"$PW" press Enter                   # キー押下
"$PW" select <ref> "value"          # セレクトボックス選択
"$PW" hover <ref>                   # ホバー

# タブ管理
"$PW" tab-new <url>                 # 新しいタブで開く
"$PW" tab-list                      # タブ一覧
"$PW" tab-select <idx>              # タブ切り替え

# デバッグ
"$PW" tracing-start                 # トレース開始
"$PW" tracing-stop                  # トレース終了（trace.zip 生成）
"$PW" console                       # コンソールログ取得
```

### MCP ツール版

```
mcp__playwright__browser_navigate   # URL 遷移
mcp__playwright__browser_snapshot   # DOM スナップショット
mcp__playwright__browser_click      # クリック
mcp__playwright__browser_fill_form  # フォーム入力
mcp__playwright__browser_take_screenshot  # スクリーンショット
mcp__playwright__browser_evaluate   # JS 実行
mcp__playwright__browser_wait_for   # 要素待機
```

---

## セレクタ戦略

### 優先順位

| 優先度 | セレクタ | 例 | 理由 |
|:------:|---------|-----|------|
| 1 | snapshot ref | `click ref=42` | 最も確実、DOM 状態に基づく |
| 2 | role + name | `getByRole('button', { name: '送信' })` | a11y ベースで安定 |
| 3 | text | `getByText('ログイン')` | 視覚的に明確 |
| 4 | test-id | `getByTestId('submit-btn')` | DOM 変更に強い |
| 5 | CSS | `.btn-primary` | 最後の手段、脆い |

### snapshot → click ワークフロー

```
1. snapshot          # DOM の ref 番号を取得
2. click ref=<N>     # ref 番号で操作
3. snapshot          # 変更後の状態を再取得（必須！）
```

**鉄則**: DOM 変更後は必ず再 snapshot。古い ref 番号は無効になる。

---

## よくあるパターン

### フォーム入力→送信

```bash
"$PW" open "https://example.com/login"
"$PW" snapshot
"$PW" fill ref=12 "user@example.com"   # メールアドレス
"$PW" fill ref=15 "password123"         # パスワード
"$PW" click ref=18                      # ログインボタン
"$PW" snapshot                          # 結果確認
```

### スクリーンショットでの UX レビュー

```bash
"$PW" open "https://example.com" --headed
"$PW" screenshot --full
# → lazy-user-ux-review スキルで画像を分析
```

### データ抽出

```bash
"$PW" open "https://example.com/dashboard"
"$PW" snapshot
# snapshot の JSON から必要なデータを jq で抽出
```

---

## トラブルシューティング

| 症状 | 原因 | 対策 |
|------|------|------|
| `ref not found` | 古い snapshot を参照 | 再 snapshot してから操作 |
| ページ遷移後に操作失敗 | DOM が変わった | `wait_for` で要素出現を待つ |
| `timeout exceeded` | 要素が非表示 or ローディング中 | timeout を延長 or `wait_for` |
| スクリーンショットが白い | SPA の初期ロード未完了 | `wait_for` で main content を待つ |
| フォームに入力できない | readonly or disabled | snapshot で属性確認 |
| ポップアップがブロック | ブラウザのポップアップブロッカー | `--headed` モードで手動許可 |

---

## E2E テスト連携

### testing-strategy スキルとの併用

```bash
# 1. Playwright でユーザーフロー記録
"$PW" open "https://localhost:3000"
"$PW" tracing-start
# ... 操作を実行 ...
"$PW" tracing-stop
# → trace.zip を分析して Playwright Test に変換

# 2. テストコード化
npx playwright test --trace on
npx playwright show-report
```

### CI 環境での注意

- `--headed` は CI で使えない（headless がデフォルト）
- Docker 内では `--no-sandbox` フラグが必要な場合あり
- GitHub Actions: `npx playwright install --with-deps` で依存解決
