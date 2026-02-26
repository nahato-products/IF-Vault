# share-minutes Reference

## 依存ツール・環境変数

| ツール | 用途 | 必須 |
|--------|------|------|
| Notion MCP | 議事録ページ取得（`notion_get_page_content`, `notion_search`） | Yes |
| `notion-pdf` スキル | Notion ページ → PDF 変換 | Yes |
| `gog gmail` | メール下書き作成・送信 | Yes |
| `gog drive` | 20MB超ファイルの共有リンク生成 | Optional |

| 環境変数 | 用途 |
|----------|------|
| `NOTION_TOKEN_V2` | PDF変換用（`notion-pdf` スキル経由で参照） |

### パイプライン全体図

```
[Notion議事録] → notion_get_page_content → notion-pdf (PDF変換)
  → /tmp/claude/<date>-<title>.pdf → 要約生成 (決定事項・TODO・次回MTG抽出)
  → gog gmail drafts create (下書き + PDF添付) → [ユーザープレビュー]
  → gog gmail drafts send (送信)
```

---

## コマンドリファレンス

### gog gmail drafts create

```bash
gog gmail drafts create [flags]
  --to=STRING          宛先（カンマ区切り）
  --cc=STRING          CC（カンマ区切り）
  --bcc=STRING         BCC（カンマ区切り）
  --subject=STRING     件名
  --body=STRING        本文（短い場合）
  --body-file=STRING   本文ファイルパス
  --body-html=STRING   HTML本文
  --attach=PATH        添付ファイル（複数指定可）
  --from=STRING        送信元（verified alias）
  --reply-to-message-id=STRING  返信先
```

### gog gmail drafts send

```bash
gog gmail drafts send <draftId>
```

### gog drive（20MB超のフォールバック用）

```bash
# アップロード
gog drive upload "/tmp/claude/minutes.pdf" --parent <folderId>

# 共有設定
gog drive share <fileId> --email "recipient@example.com" --role reader

# URL取得
gog drive url <fileId>
```

### Notion MCP ツール

```python
# ページ内容取得
notion_get_page_content(page_id)

# ページ検索
notion_search(query: "議事録 プロジェクトAlpha")
```

---

## パターン辞書

### 要約抽出パターン（正規表現）

```regex
# 決定事項セクション
^#{2,3}\s*(決定事項|決定事項まとめ)

# TODO / チェックボックス
^-\s*\[\s*\]\s*(.+)
^#{2,3}\s*(TODO|Next\s*Steps|アクション)

# 次回MTG
^#{2,3}\s*次回(MTG|ミーティング|打ち合わせ)
次回[:：]\s*(.+)
次回MTG[:：]\s*(.+)
```

### 件名テンプレート

| パターン | フォーマット | 備考 |
|---------|-------------|------|
| 通常 | `【議事録】{M}/{D} {MTG名}` | M/D はゼロパディングなし（例: `2/5`） |
| 修正版 | `【議事録・修正版】{M}/{D} {MTG名}` | 再送時 |
| 返信 | `Re: {元件名}` | スレッド返信時 |

### 内部向けメールテンプレート

```
お疲れ様です。
{date} {mtg_name}の議事録をお送りします。

【主な決定事項】
{decisions}

【Next Steps】
{todos}

{next_meeting}

詳細は添付PDFをご確認ください。
```

### 外部向けメールテンプレート

```
いつもお世話になっております。
{date}の{mtg_name}について、議事録を共有させていただきます。

【決定事項】
{decisions}

【今後のアクション】
{todos}

{next_meeting}

詳細は添付PDFをご確認ください。
何かご不明点がございましたらお気軽にご連絡ください。
```

---

## トラブルシューティング

| エラー | 原因 | 対処 |
|--------|------|------|
| notion-pdf 変換失敗 | `token_v2` 失効 or pandoc 未インストール | `notion-pdf` スキルの Fallback セクション確認 |
| PDF 20MB超 | ページ内の画像が多い | Drive 共有リンクに自動切替（Step 2.5） |
| gog gmail 認証エラー | OAuth 失効 | `gog auth login` で再認証 |
| 下書き作成失敗 | 宛先メールアドレス不正 | メールアドレス形式を確認（`@` 含む） |
| 添付ファイルが見つからない | PDF生成パスが不正 | `/tmp/claude/` に PDF が存在するか確認 |
| 件名が文字化け | 非ASCII文字のエンコード問題 | gog CLI が自動処理（通常は問題なし） |

### ファイルサイズ制限

| サービス | 添付上限 |
|---------|---------|
| Gmail | 25MB |
| Drive共有 | 制限なし |
