# Slack通知の実装手順

日報が作成されたら #it-if チャンネルに通知する設定です。

## 📋 必要なもの

- Slackワークスペースの管理者権限（またはアプリ追加権限）
- 通知先チャンネル：#it-if
- 作業時間：約5分

---

## 🔧 Step 1: Slack Webhook URLの作成

### 1. Slackアプリの作成

https://api.slack.com/apps にアクセス

1. 「Create New App」をクリック
2. 「From scratch」を選択
3. 入力:
   - App Name: `日報通知` (任意の名前)
   - Workspace: あなたのワークスペースを選択
4. 「Create App」をクリック

### 2. Incoming Webhookの有効化

1. 左メニューから「Incoming Webhooks」をクリック
2. 右上の「Activate Incoming Webhooks」をオンに切り替え
3. ページ下部の「Add New Webhook to Workspace」をクリック
4. チャンネル選択：`#it-if` を選択
5. 「Allow」をクリック

### 3. Webhook URLをコピー

以下のような形式のURLが表示されます：

```
https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX
```

この**Webhook URL全体をコピー**してください。

---

## 🔐 Step 2: GitHub Secretsに保存

### 方法A: コマンドで設定（推奨）

ターミナルで以下を実行：

```bash
gh secret set SLACK_WEBHOOK_URL --repo nahato-products/IF-Vault
```

プロンプトが表示されたら、コピーしたWebhook URLをペーストしてEnter

### 方法B: Web UIで設定

1. 以下のURLを開く：
   ```
   https://github.com/nahato-products/IF-Vault/settings/secrets/actions
   ```

2. 「New repository secret」をクリック

3. 入力：
   - Name: `SLACK_WEBHOOK_URL`
   - Value: コピーしたWebhook URLをペースト

4. 「Add secret」をクリック

---

## 📝 Step 3: ワークフローファイルの修正

Claude Codeに以下のように依頼してください：

```
日報ワークフローにSlack通知を追加して。
Secretsに SLACK_WEBHOOK_URL を保存済みです。
#it-if チャンネルに「日報が作成されました」と通知してください。
```

または、手動で修正する場合：

`.github/workflows/daily-report.yml` の最後に以下を追加：

```yaml
      - name: Notify Slack
        if: success()
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
        run: |
          curl -X POST "$SLACK_WEBHOOK_URL" \
            -H 'Content-Type: application/json' \
            -d '{
              "text": "📝 日報が作成されました！",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "*📝 日報が作成されました！*\n\n今日の振り返りを記録しましょう 💪"
                  }
                },
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "<https://github.com/nahato-products/IF-Vault/issues?q=is:issue+label:daily-report+is:open+sort:created-desc|📋 日報を開く>"
                  }
                }
              ]
            }'
```

---

## 🧪 Step 4: テスト実行

1. ワークフローを手動実行：
   ```bash
   gh workflow run daily-report.yml --repo nahato-products/IF-Vault
   ```

2. 実行状況を確認：
   ```bash
   gh run list --repo nahato-products/IF-Vault --limit 1
   ```

3. Slackの #it-if チャンネルを確認
   - 「📝 日報が作成されました！」のメッセージが届いていればOK

---

## ❌ トラブルシューティング

### 通知が届かない場合

1. **Secretsが正しく保存されているか確認**
   ```bash
   gh secret list --repo nahato-products/IF-Vault
   ```
   → SLACK_WEBHOOK_URL が表示されればOK

2. **ワークフローのログを確認**
   ```bash
   gh run view --repo nahato-products/IF-Vault --log
   ```
   → エラーメッセージを確認

3. **Webhook URLが正しいか確認**
   - `https://hooks.slack.com/services/` で始まっているか
   - コピー時に改行や余分な文字が入っていないか

### Webhook URLを再取得する場合

1. https://api.slack.com/apps
2. 作成したアプリを選択
3. 「Incoming Webhooks」
4. 既存のWebhook URLをコピー（または新規作成）

---

## 🎯 完了確認

- [ ] Slack Webhook URLを取得
- [ ] GitHub Secretsに保存
- [ ] ワークフローファイルを修正
- [ ] テスト実行で通知を確認

---

**作成日**: 2026-02-27
**対象リポジトリ**: nahato-products/IF-Vault
**通知先**: #it-if チャンネル
