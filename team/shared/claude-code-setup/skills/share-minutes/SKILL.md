---
name: share-minutes
description: "Share meeting minutes as PDF via email by converting Notion minutes pages to PDF, generating a concise summary, and creating an email draft with the PDF attachment. Use when sending minutes by email, sharing PDF-attached minutes with external parties, distributing meeting summaries after meetings, or preparing post-meeting email communications with attachments. Do not trigger for creating minutes (use create-minutes), Notion-to-PDF conversion only (use notion-pdf), or composing general emails (use gog-gmail). Invoke with /share-minutes."
user-invocable: true
---

# share-minutes

Notion議事録をPDF化し、要約付きメールで共有する複合スキル。

## パイプライン

```
Notion議事録 → notion-pdf(PDF変換) → 要約生成 → gog-gmail(下書き作成) → [ユーザー確認] → 送信
```

## 実行フロー

### Step 1: 議事録の取得

Notion MCP で対象ページの内容を取得:

```
notion_get_page_content(page_id: "<議事録ページID>")
→ ページタイトル、内容をMarkdownで取得
```

### Step 2: PDF変換

`notion-pdf` スキルを使ってPDF化:

```
notion-pdf
  page_id: <議事録ページID>
  output: /tmp/claude/<date>-<title>.pdf
  format: A4
```

→ `/tmp/claude/2025-01-20-プロジェクトAlpha-議事録.pdf`

### Step 2.5: ファイルサイズチェック

PDF生成後、ファイルサイズをチェック:

- **20MB以下**: 通常添付
- **20MB超**: `gog-drive` でアップロード → 共有リンクをメール本文に記載

```bash
# 20MB超の場合
gog drive upload "/tmp/claude/<file>.pdf" --parent <folderId>
gog drive share <fileId> --email "recipient@example.com" --role reader
DRIVE_URL=$(gog drive url <fileId>)
# メール本文にリンクを挿入（添付なし）
```

### Step 3: 要約生成

Notionページから以下のパターンで情報を抽出する:

| 抽出対象 | Notion上のパターン | マッピング先 |
|----------|-------------------|-------------|
| 決定事項 | `### 決定事項` or `## 決定事項まとめ` 配下の箇条書き | `{decisions}` |
| TODO | `- [ ]` 行（チェックボックス） | `{todos}` |
| 次回MTG | `### 次回MTG` or `次回:` or `次回MTG:` | `{next_meeting}` |

**内部向けテンプレート**:

```
お疲れ様です。
{date} {mtg_name}の議事録をお送りします。

【主な決定事項】
{decisions}

【Next Steps】
{todos}

【次回MTG】
{next_meeting}

詳細は添付PDFをご確認ください。
```

**外部向けテンプレート**:

```
いつもお世話になっております。
{date}の{mtg_name}について、議事録を共有させていただきます。

【決定事項】
{decisions}

【今後のアクション】
{todos}

【次回MTG】
{next_meeting}

詳細は添付PDFをご確認ください。
何かご不明点がございましたらお気軽にご連絡ください。
```

内部 / 外部の判定は宛先ドメインまたはユーザー指定で切り替える。

### Step 4: メール下書き作成

`gog-gmail` で下書きを作成:

```bash
gog gmail drafts create \
  --to "yamada@client.com,suzuki@client.com" \
  --cc "tanaka@mycompany.com" \
  --subject "【議事録】1/20 プロジェクトAlpha 定例MTG" \
  --body-file /tmp/claude/email-body.txt \
  --attach "/tmp/claude/2025-01-20-プロジェクトAlpha-議事録.pdf"
```

### Step 5: ユーザー確認

下書き作成後、以下を表示:
- 宛先一覧
- 件名
- 本文プレビュー
- 添付ファイル名

→ ユーザーが確認して問題なければ送信:

```bash
gog gmail drafts send <draftId>
```

## 使い方

```
/share-minutes

必要な情報:
1. Notion議事録のページID or URL
2. 宛先メールアドレス（TO/CC）
3. （任意）件名カスタマイズ
4. （任意）本文に追加するメッセージ
```

## 件名の自動生成ルール

**フォーマット**: `【議事録】M/D MTG名`

- M/D は月/日の省略形（ゼロパディングなし）
- 例: `【議事録】1/20 プロジェクトAlpha 定例MTG`
- 例: `【議事録】2/3 要件定義ヒアリング（第2回）`

## メール本文のカスタマイズ

ユーザーが追加メッセージを指定した場合、要約の前に挿入:

```
{ユーザーの追加メッセージ}

---

{自動生成の要約}

詳細は添付PDFをご確認ください。
```

## 依存スキル

| スキル | 役割 |
|--------|------|
| `notion-pdf` | Notion → PDF変換 |
| `gog-gmail` | メール下書き作成・送信 |

## 安全設計

- **デフォルトは下書き作成**。直接送信しない
- 宛先・件名・本文は必ずプレビュー表示
- PDF添付の確認（ファイルサイズ、ページ数）
- 送信は `gog gmail drafts send` で明示的に実行

## エラーハンドリング

| エラー | 対処 |
|--------|------|
| PDF変換失敗 | notion-pdf のフォールバック確認 |
| PDF 20MB超 | Step 2.5 に従いDrive共有リンクに切替 |
| 宛先不正 | メールアドレス形式チェック |

## Cross-references

- **create-minutes**: 共有元となる議事録ページの作成
- **fill-external-minutes**: 外部向けに整形した議事録の作成
- **notion-pdf**: Notion ページから PDF への変換処理
- **gog-gmail**: メール下書き作成・送信の実行

