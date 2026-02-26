# transcribe-to-minutes Reference

## 依存ツール・環境変数

| 名前 | パス / キー | 用途 | 必須 |
|------|------------|------|------|
| `ptrans.sh` | `~/.claude/scripts/ptrans.sh` | 音声 → テキスト変換 | Yes |
| `OPENAI_API_KEY` | 環境変数 | Whisper API 認証 | Yes |
| Notion MCP | Claude Code MCP 設定 | ページ作成・更新 | Yes |
| `ffmpeg` | システム PATH | 25MB 超音声ファイル分割 | Optional |

## コマンドリファレンス

### ptrans オプション

```bash
~/.claude/scripts/ptrans.sh <audio-file> [options]
  --language ja     # 言語（default: ja）
  --json            # verbose_json形式で出力
  --out <path>      # 出力先ファイル
  --model whisper-1 # モデル指定
  --prompt <text>   # 認識ヒント（固有名詞等）
```

### Whisper verbose_json 出力形式

```json
{
  "task": "transcribe",
  "language": "japanese",
  "duration": 3600.0,
  "text": "全文テキスト...",
  "segments": [
    { "id": 0, "start": 0.0, "end": 5.2, "text": "それでは始めましょう", "tokens": [...] }
  ]
}
```

### 音声ファイル分割（25MB超の場合）

```bash
# ffmpegで30分ごとに分割
ffmpeg -i meeting.m4a -f segment -segment_time 1800 \
  -c copy /tmp/claude/part_%03d.m4a

# 各パートを個別に文字起こし
for f in /tmp/claude/part_*.m4a; do
  ~/.claude/scripts/ptrans.sh "$f" --json --out "${f%.m4a}.json"
done
```

### Notion MCP ツール

```
notion_create_page(parent_id, title, content)   # ページ作成
notion_update_page(page_id, content)             # ページ更新（内容追記）
notion_search(query)                             # ページ検索
```

## パターン辞書

### 誤変換修正パターン

#### 人名

| 誤認識 | 正しい | パターン |
|--------|--------|---------|
| たなかたろう | 田中太郎 | 参加者リスト照合 |
| さとうさん | 佐藤さん | 参加者リスト照合 |

#### 技術用語

| 誤認識 | 正しい |
|--------|--------|
| えーぴーあい | API |
| データベース / でーたべーす | DB |
| ギットハブ | GitHub |
| スラック | Slack |
| ジラ | Jira |
| リアクト | React |
| タイプスクリプト | TypeScript |
| ネクスト | Next.js |
| スーパーベース | Supabase |
| テイルウインド | Tailwind |
| ウェブフック | Webhook |
| マイグレーション | migration |
| デプロイ | deploy |
| リポジトリ | repository |

### フィラー除去リスト

| フィラー | 除去ルール |
|----------|-----------|
| えーと / えー | 常に除去 |
| あの / あのー | 常に除去 |
| まあ / まぁ | 常に除去 |
| なんか | 文頭のみ除去 |
| ちょっと | 文頭のみ除去（本来の意味で使われている場合は残す） |
| そうですね | 相槌の場合のみ除去（回答の場合は残す） |

### 決定事項の抽出パターン

```regex
〜(に決まり|で決定|でいき|にしましょう|で進め)
〜(ということで|ってことで)
結論(として|は)〜
```

### TODO の抽出パターン

```regex
〜(お願い|やって|確認して|共有して|送って|まとめて)
〜(やっておき|対応しておき|準備しておき)ます
〜(までに|を期限に)
```

### 議題開始パターン

```regex
〜(について|に関して|の件)
(次の議題は|それでは|では次)
(議題[0-9]+|[0-9]+番目)
```

### 句読点正規化ルール

- `。` → 全角統一
- `、` → 全角統一
- 文末にピリオドがない場合は `。` を補完

## トラブルシューティング

| エラー | 原因 | 対処 |
|--------|------|------|
| `ptrans.sh: command not found` | スクリプト未配置 | `~/.claude/scripts/` に ptrans.sh を配置 |
| `OPENAI_API_KEY not set` | 環境変数未設定 | `.env` や `.zshrc` に `OPENAI_API_KEY` を設定 |
| 音声ファイルが 25MB 超 | Whisper API の上限 | ffmpeg で分割（音声ファイル分割セクション参照） |
| 文字起こし精度が低い | 固有名詞が多い | `--prompt` に固有名詞リストを追加 |
| Notion MCP 接続エラー | MCP 未設定 | Claude Code の MCP 設定を確認 |
| 日本語認識で英語が混じる | language 未指定 | `--language ja` を明示指定 |
