# email-search Reference

## Gmail検索演算子 完全リスト

### 基本

| 演算子 | 説明 | 例 |
|--------|------|-----|
| `from:` | 送信者 | `from:tanaka@example.com` |
| `to:` | 宛先 | `to:me` |
| `cc:` | CC | `cc:team@example.com` |
| `bcc:` | BCC | `bcc:manager` |
| `subject:` | 件名 | `subject:議事録` |
| `label:` | ラベル | `label:project-alpha` |
| `in:` | フォルダ | `in:inbox` / `in:sent` / `in:trash` |
| `category:` | カテゴリ | `category:primary` / `category:promotions` |

### 日付

| 演算子 | 説明 | 例 |
|--------|------|-----|
| `after:` | 以降 | `after:2025/01/01` |
| `before:` | 以前 | `before:2025/02/01` |
| `older_than:` | より古い | `older_than:30d` |
| `newer_than:` | より新しい | `newer_than:7d` |

日付単位: `d`(日), `m`(月), `y`(年)

### 状態

| 演算子 | 説明 |
|--------|------|
| `is:unread` | 未読 |
| `is:read` | 既読 |
| `is:starred` | スター付き |
| `is:important` | 重要 |
| `is:snoozed` | スヌーズ中 |

### 添付

| 演算子 | 説明 | 例 |
|--------|------|-----|
| `has:attachment` | 添付あり | - |
| `filename:` | ファイル名/拡張子 | `filename:pdf` / `filename:report.xlsx` |
| `has:drive` | Drive添付 | - |
| `has:document` | Docs添付 | - |
| `has:spreadsheet` | Sheets添付 | - |
| `has:presentation` | Slides添付 | - |

### サイズ

| 演算子 | 説明 | 例 |
|--------|------|-----|
| `size:` | バイト数 | `size:1000000` |
| `larger:` | 以上 | `larger:5M` |
| `smaller:` | 以下 | `smaller:1M` |

### 論理演算

| 演算子 | 説明 | 例 |
|--------|------|-----|
| スペース | AND | `from:a subject:b` |
| `{ }` | OR | `{from:a from:b}` |
| `-` | NOT | `-from:noreply` |
| `"..."` | フレーズ一致 | `"exact phrase"` |

### 特殊

| 演算子 | 説明 |
|--------|------|
| `has:userlabels` | ユーザーラベルあり |
| `has:nouserlabels` | ユーザーラベルなし |
| `deliveredto:` | 配信先 |
| `list:` | メーリングリスト |
| `rfc822msgid:` | Message-ID |

## 日付変換ヘルパー（bash）

```bash
# 昨日
date -v-1d +%Y/%m/%d

# 先週月曜
date -v-1w -v-mon +%Y/%m/%d

# 先月1日
date -v-1m -v1d +%Y/%m/%d

# X日前
date -v-${X}d +%Y/%m/%d
```
