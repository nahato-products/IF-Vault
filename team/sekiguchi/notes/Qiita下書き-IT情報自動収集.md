---
date: 2026-02-12
tags: [Qiita, Claude Code, 自動化, Slack, Obsidian]
status: draft
---

# Qiita記事用資料: Claude Codeで作るIT情報自動収集システム

## 記事タイトル案

- 「Claude Code + シェルスクリプトで、IT情報の自動収集→Slack投稿→Obsidian保存を全自動化した」
- 「週3回、朝7時にSlackにIT最新ニュースが届く仕組みをClaude Codeだけで作った話」
- 「Claude Codeの--printモードとMCPで、IT情報収集パイプラインを30分で構築した」

## 想定読者

- Claude Codeを使い始めたエンジニア
- 情報収集を自動化したい人
- Slack/Obsidian連携に興味がある人

---

## 1. 全体像

### やっていること

```
cron (月水金 7:00)
  ↓
weekly-it-news.sh
  ↓
Claude Code (--print + WebSearch)
  → 6系統のメディアから最新記事を検索
  → 品質フィルターで注目度が高い記事を厳選
  → Slack形式 / Obsidian形式 / URL一覧 の3セクションに整形して出力
  ↓
awk で3セクションに分割
  ↓
├── Slack投稿 (Claude Code + MCP経由)
├── Obsidian保存 (日付ファイルに書き出し)
└── URLログ更新 (重複防止用、最新100件保持)
```

### 技術スタック

| 技術 | 役割 |
|------|------|
| Claude Code CLI | 情報収集エンジン + Slack投稿 |
| `--print` モード | CLIの出力をパイプラインで扱えるようにする |
| `--allowedTools` | 使えるツールをWebSearchやSlack MCPに限定 |
| WebSearch | Web検索（Claude Code組み込み） |
| Slack MCP | `mcp__claude_ai_Slack__slack_send_message` でSlack投稿 |
| bash + awk | 出力のパース・分割 |
| cron | 定期実行 |
| Obsidian | Markdownナレッジベースへの蓄積 |

---

## 2. Claude Codeの2つのモード使い分け

この仕組みの肝は、Claude Codeを2回呼び出していること。

### 1回目: `--print` モード（情報収集）

```bash
claude --print --allowedTools 'WebSearch' << EOF > output.txt
検索して、整形して出力して
EOF
```

- `--print`: 結果をstdoutに出力するモード。パイプラインで扱える
- `--allowedTools 'WebSearch'`: WebSearchだけ許可。余計なツールを使わせない
- ヒアドキュメントでプロンプトを流し込む

`--print` モードはMCPツール（Slack投稿など）を実行できない。あくまで「テキスト生成」専用。

### 2回目: 通常モード（Slack投稿）

```bash
claude --allowedTools 'mcp__claude_ai_Slack__slack_send_message' --max-turns 3 << EOF
チャンネルID C0AEDCZAECB に投稿して
${SLACK_MESSAGE}
EOF
```

- `--print` なし: MCPツールを実行できるモード
- `--max-turns 3`: 無限ループ防止。投稿→確認で十分なので3ターン
- チャンネル名ではなくチャンネルIDを直接指定（名前解決の不安定さを回避）

### なぜ2回に分けるのか

| | --print | 通常モード |
|---|---|---|
| stdout出力 | できる | できない（対話的） |
| MCP実行 | できない | できる |
| 用途 | テキスト生成 | ツール実行 |

1回の呼び出しでは「検索→整形→出力→Slack投稿」を全部やれない。だから収集と投稿を分離した。

---

## 3. プロンプト設計のポイント

### 3-1. 「パイプラインの一部」と宣言する

```
【重要：出力ルール】
あなたはデータ収集パイプラインの一部です。人間と会話しているのではありません。
出力は必ず「---SLACK-FORMAT---」から開始してください。
挨拶、感想、まとめ、コメント等の余計なテキストは一切出力しないでください。
```

CLAUDE.mdで性格設定をしていると、サブプロセスのClaude Codeにもその設定が効く。自分の場合はギャル口調の設定が入っていたので、収集結果の前に「よっしゃ〜！めっちゃいい記事集まった！」みたいなおしゃべりが出力された。

awkでセクション区切りを探すパイプラインなので、余計なテキストがあるとパースが壊れる。「パイプラインの一部である」と明示することで、構造化されたデータだけを出力させる。

### 3-2. セクション区切りで出力を構造化する

```
---SLACK-FORMAT---
(Slack用のmrkdwn)

---OBSIDIAN-FORMAT---
(Obsidian用のMarkdown)

---NEW-URLS---
(URL一覧)
```

1回のClaude呼び出しで3種類のフォーマットを同時生成し、awkで分割する。

```bash
# Slack形式を抽出
awk '/---SLACK-FORMAT---/{flag=1;next}/---OBSIDIAN-FORMAT---/{flag=0}flag' output.txt

# Obsidian形式を抽出
awk '/---OBSIDIAN-FORMAT---/{flag=1;next}/---NEW-URLS---/{flag=0}flag' output.txt

# URL一覧を抽出
awk '/---NEW-URLS---/{flag=1;next}flag' output.txt | grep -E '^https?://'
```

APIを3回叩くより、1回で3フォーマット出す方がコスト効率がいい。

### 3-3. 年フィルターで古い記事を排除する

```
- 投稿日: ${DATE} を基準に過去48時間以内のみ。${DATE}の年は2026年である。
- 検索クエリに必ず「2026」を含めて、今年の記事に絞ること

【重要な注意】
- 2026年の記事だけを収集すること。2025年以前の古い記事は絶対に含めない。
```

初期バージョンでは「過去48時間以内」とだけ指示していたが、WebSearchが古い記事も拾ってしまった。年号を明示的にプロンプトと検索クエリの両方に入れることで解決。

スクリプト内では `$(date +%Y)` で動的に年を生成しているので、年が変わっても修正不要。

### 3-4. 品質フィルターで記事の質を担保する

```
【品質フィルター】
- はてブ: 50ブクマ以上を優先
- Qiita: いいね10以上 or ストック10以上を優先
- Zenn: いいね10以上を優先
- X: いいね50以上 or RT20以上を優先
- 上記に満たなくても、内容が特に有益・速報性が高い場合は含めてよい
```

品質フィルターなしだと、Qiitaのニッチな記事ばかり拾ってきてしまった。閾値を設けつつ「速報性が高ければOK」という逃げ道も残しておく。

### 3-5. 重複防止はURLログで

```bash
LOG_FILE="$HOME/.claude-automation/processed-urls.log"

# 既存URLをプロンプトに含めて除外
EXISTING_URLS=$(cat "$LOG_FILE")

# 新規URLをログに追記（最新100件のみ保持）
cat "$TEMP_URLS" "$LOG_FILE" | head -100 > "$LOG_FILE.tmp"
mv "$LOG_FILE.tmp" "$LOG_FILE"
```

プロンプトに既出URLを渡して「これは除外して」と指示する。100件保持で十分。

---

## 4. Slack mrkdwn のハマりポイント

SlackのメッセージフォーマットはMarkdownではなくmrkdwn（Slack独自）。

| 書きたいこと | Markdown | Slack mrkdwn |
|---|---|---|
| 太字 | `**text**` | `*text*` |
| イタリック | `*text*` | `_text_` |
| コード | `` `code` `` | `` `code` `` |
| リンク | `[text](url)` | `<url|text>` |

実際にハマったポイント:

- URLは独立した行に書かないと、前後のテキストがリンクに巻き込まれる
- 絵文字とURLを同じ行に書くと、Slackがリンク認識を壊すことがある
- `<URL📁>` みたいな意図しない結合が起きた
- 解決策: URLは常に単独行に配置する

---

## 5. 安全設計

### エラーハンドリング

```bash
set -euo pipefail  # エラーで即停止、未定義変数でエラー
trap cleanup EXIT   # 終了時に一時ファイルを必ず削除
```

### Claude呼び出しの失敗対応

```bash
# 収集失敗 → スクリプト全体を停止
if [ $CLAUDE_EXIT -ne 0 ]; then
    log "❌ Claude実行エラー"
    exit 1
fi

# Slack投稿失敗 → ログに記録してObsidian保存は続行
$CLAUDE_PATH ... && SLACK_SUCCESS=true || true
```

Slack投稿は失敗してもObsidianには保存する。データ収集が本体で、Slackは通知手段にすぎない。

### ツール制限

`--allowedTools` で使えるツールを最小限に絞る。情報収集時は `WebSearch` のみ、Slack投稿時は `slack_send_message` のみ。意図しないファイル操作やコマンド実行を防ぐ。

---

## 6. cron設定

```bash
# 月水金 7:00 に実行
0 7 * * 1,3,5 /bin/bash /Users/sekiguchiyuki/scripts/weekly-it-news.sh
```

```bash
# cron登録コマンド
(crontab -l 2>/dev/null; echo "0 7 * * 1,3,5 /bin/bash $HOME/scripts/weekly-it-news.sh") | crontab -
```

---

## 7. 出力サンプル

### Slack投稿の実際の出力

```
📰 IT情報収集 - 2026/02/12
新着記事 10件

━━━━━━━━━━━━━━━━━━━━

1. Google DeepMind「Aletheia」、AIによる自律的な数学研究に成功
AI | GIGAZINE | 2026-02-12
• Gemini 3 Deep Thinkベースのエージェントが人間の介入なしに数学研究論文を生成
• エルデシュ予想データベースの未解決問題4つを自律的に解決
• AIが「ツール」から「研究パートナー」へ進化する象徴的な成果

2. 中国製AI「GLM-5」登場 — モデル無料公開
AI | GIGAZINE | 2026-02-12
• 744億パラメータのAIモデル、MITライセンスで無料ダウンロード可能
• 推論・コーディング・エージェントタスクで既存モデルを上回る
• オープンソースAIの競争が激化

...（以下10件まで続く）

━━━━━━━━━━━━━━━━━━━━
🤖 自動収集 by weekly-it-news.sh
```

### Obsidianに保存されるMarkdown

日付ファイル（例: `2026-02-12.md`）として保存される。frontmatter付きで、タグ検索やDataviewクエリに対応。

同日に複数回実行した場合は「追加収集 HH:MM」として追記される。

---

## 8. 開発中にぶつかった問題と解決策

| 問題 | 原因 | 解決策 |
|------|------|--------|
| 去年の記事が混ざる | プロンプトに年の指定がなかった | `$(date +%Y)` で年を明示 + 「去年以前は絶対除外」と強調 |
| Slack投稿が実行されない | `--print` モードではMCPツールが実行されない | 収集（--print）と投稿（通常モード）を2回に分離 |
| Slackの表示が崩れる | mrkdwnとMarkdownの違い、URLと絵文字の混在 | URLを単独行に配置、Slack専用フォーマットを設計 |
| 余計なおしゃべりが出力される | CLAUDE.mdの性格設定がサブプロセスにも適用される | 「パイプラインの一部」と宣言、構造化出力を強制 |
| 記事の質が低い | 品質フィルターなし、ソースがQiita+Xだけ | 6系統に拡大 + いいね/ブクマ数の閾値を設定 |
| 出力が空になることがある | Claudeの出力が確率的にフォーマットから逸脱 | セクション区切りの出力を強く指示、エラーハンドリング追加 |

---

## 9. コスト

- Claude Code CLIの利用料金のみ（Claude Pro/Max契約内）
- WebSearchは組み込み機能なので追加料金なし
- Slack MCPも追加料金なし
- cron実行なのでサーバー代もなし

---

## 10. ソースコード全文

記事にはスクリプト全文を掲載する。ファイルパス: `~/scripts/weekly-it-news.sh`

---

## 記事構成案

1. 完成形のデモ（Slackスクショ + Obsidianスクショ）
2. なぜ作ったか（手動で情報収集するのがだるい）
3. 全体アーキテクチャ
4. Claude Codeの2モード使い分け
5. プロンプト設計（ここが本記事の肝）
6. Slack mrkdwnのハマりポイント
7. cron設定
8. 開発中にぶつかった問題と解決策
9. ソースコード全文
10. まとめ

## タグ案

`Claude Code`, `AI`, `自動化`, `Slack`, `Obsidian`, `シェルスクリプト`, `MCP`
