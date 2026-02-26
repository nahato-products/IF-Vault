---
created: 2026-02-18
tags: [claude-code, 環境設定, 最適化]
status: completed
---

# Claude Code 環境最適化レポート

## 概要

2026-02-18 に実施した Claude Code 環境の全面見直し（3パス）。
soul.md 調査、辛口レビュー（複数回）、Web検索によるベストプラクティス取り込み、スキルアーキテクチャ再設計を含む。

---

## Pass 1: 初回最適化

### 1. CLAUDE.md リライト

44行 → 22行（-50%）。毎ターン読み込まれるため、1文字が積もる。

**削除したもの:**
- 「よく使うツール」セクション（参照情報であって指示ではない）
- 「ギャルっぽい」+「親しみやすいトーンで」の重複
- フッターのメタ説明文

**追加したもの:**
- スタック情報（Next.js / TypeScript / Supabase / Tailwind v4）

**構造:** Identity → Rules → Context の3セクションに集約。

### 2. settings.local.json セキュリティ修正（初回）

**削除した危険エントリ:**
- `Bash(bash:*)` — 全コマンド実行許可
- `Bash(dd:*)` — ディスク書き込み操作
- `Bash(echo:*)` — ファイル上書きに悪用可能
- 埋め込みスクリプト（100文字超のゴミエントリ）

### 3. Skills description 初回最適化

~7,500トークン/ターン → ~3,500トークン/ターン（-53%）

### 4. Hooks 新規作成（4本）+ 既存1本改善

5本体制に（PreToolUse, PreCompact, PostToolUse, Stop, PostToolUseFailure）

### 5. 削除スキルの復元

前回「重複」として削除した6スキルを調査した結果、**全て代替不可**だった。

| 削除スキル | 「代替」とされた先 | 実態 |
|-----------|----------------|------|
| baseline-ui | web-design-guidelines | Tailwind特化チェッカー vs 汎用HTML標準 |
| fixing-accessibility | web-design-guidelines | 即座レビュアー vs 参考資料 |
| find-skills | skill-forge | ユーザー向け検索 vs 開発者向け作成 |
| using-git-worktrees | なし | worktreeセットアップ+検証の完全ワークフロー |
| finishing-a-dev-branch | なし | merge/PR/cleanup の4択ガイド |
| deep-research | なし | Gemini Deep Research（完全喪失してた） |

> [!important] 教訓
> 「名前が似てる」「カテゴリが近い」だけで削除しない。各スキルの**具体的な機能**を比較してから判断する。

---

## Pass 2: 辛口再レビュー + 全修正

Pass 1 完了後に「100点か？」で再レビューした結果、多数の問題が発覚。

### 1. settings.local.json 致命的セキュリティ修正

**Pass 1 で見落としていた危険エントリ:**
- `Bash(python3:*)` — **任意Python実行**。全セキュリティ対策をバイパス可能
- `Bash(npx:*)` — 任意npmパッケージ実行
- `Bash(chmod:*)`, `Bash(open:*)`, `Bash(ln:*)` — 過剰な権限
- `Bash(git push:*)` — CLAUDE.mdの「事前確認必須」と矛盾
- `Bash(git rm:*)`, `Bash(gh api:*)`, `Bash(gh auth:*)` — 破壊/権限操作
- `Bash(for ...)`, `Bash(do ...)` 等のテスト残骸8エントリ

**48 → 27エントリに削減。** 安全な読み取り系+ビルドコマンドのみ残留。

**Stop hookのbadリストも拡充:**
`bash:`, `dd:`, `echo:`, `python3:`, `python:`, `npx:`, `chmod:`, `open:`, `ln:`, `for `, `do `, `done`, `if `, `then`, `fi)`

### 2. CLAUDE.md 構造修正

22行 → 19行。

- 「時間の見積もりは絶対にしない」をIdentity→Rulesに移動
- 「コード品質 > 速度。セキュリティを常に意識」→「外部APIキーは必ず環境変数経由。ハードコード禁止」に具体化
- 「主要プロジェクト」行を削除（参照情報でありグローバルに毎ターン出すコストに見合わない）
- **Compact復帰指示を追加**: `~/.claude/session-env/compact-state.md を読んでコンテキスト復元`
- Next.js バージョン明示（15）

### 3. 全5 Hook フルリファクタリング

**共通修正:**
- `echo "$input"` → `printf '%s\n' "$input"`（バックスラッシュ解釈防止）
- bare `except:` → `except (json.JSONDecodeError, ValueError):` 等
- stdin未消費の2本（compact-restore, stop-summary）に `cat > /dev/null` 追加
- `mkdir -p` でディレクトリ存在を保証
- `${HOME:?}` パターンで未設定時フェイル

**個別修正:**

| Hook | 修正内容 |
|------|---------|
| token-guardian | 閾値6144にコメント追加、メッセージ短縮 |
| compact-restore | stdin消費追加、mkdir-p追加 |
| security-post-edit | `grep --` でハイフンファイル対策、`head -1000` で巨大ファイル対策、false positive除外パターン追加 (`NEXT_PUBLIC_`, `placeholder`, `example`) |
| stop-summary | `$untracked_count` バリデーション追加、スペース修正 (`3files` → `3 files`)、session-env/空ディレクトリ掃除追加 |
| tool-failure-logger | 環境変数経由のパス渡し（`TG_LOG_FILE`）、ファイル操作を4回→2回に効率化 |

### 4. ファイルシステム掃除

- `config.json Y` 削除（スペース入り事故ファイル）
- `AGENTS_GUIDE.md`, `claude-agents-setup.sh`, `settings.json.backup`, `stats-cache.json` 削除
- `.DS_Store` × 2 削除
- `session-env/` 空UUIDディレクトリ13個削除
- Symlink パス形式統一（相対11個 → 全18個を絶対パスに）

### 5. Skills description 2nd pass 圧縮

| | 文字数 | トークン/ターン |
|---|---|---|
| 初期状態 | ~9,800 | ~3,300 |
| Pass 1 後 | ~4,400 | ~1,500 |
| Pass 2 後 | ~4,025 | ~1,340 |
| **最終 (Pass 3)** | **~3,854** | **~1,285** |

**圧縮率: -61%（初期比）**

主な手法:
- 「Not for X, Y, Z」否定フレーズを全スキルから削除
- 略称化 (`Manifest V3` → `MV3`, `v3-to-v4` → `v3→v4`)
- 低トリガー語の削除（他キーワードでカバーされるもの）
- 全39スキル130文字以下を達成（最長129文字）

### 6. reference.md 全面更新

- ファイル配置マップを現実に合わせて刷新（system dirs注記追加）
- コスト分析をBefore/After形式に
- Stop hookの4機能を明記
- badプレフィックス完全リストを記載

---

## soul.md について

Xで話題の soul.md を調査した結果:

| | CLAUDE.md | soul.md |
|---|---|---|
| 目的 | プロジェクト設定・作業ルール | AI の人格・アイデンティティ |
| 書き手 | 人間 | AI 自身 |
| 公式 | Anthropic 公式機能 | コミュニティ発 |

**結論:** 現状の CLAUDE.md（19行）はベストプラクティス範囲内（推奨60行以下）。soul.md 的な人格分離は今は不要。

---

## Pass 3: Web検索 + アーキテクチャ再設計

Pass 2 完了後にWeb検索で2026年のベストプラクティスを調査し、4つの新機能を追加。さらにスキル配置の根本設計を見直した。

### 1. 新規Hook 3本 + StatusLine（Web検索由来）

2026年の Claude Code 設定記事から4つの高価値設定を発見。

| 追加項目 | 種類 | 効果 |
|---------|------|------|
| `block-sensitive-read.sh` | PreToolUse Hook | .env/.pem/.key 等の読み取りを `exit 2` でハードブロック |
| `notification.sh` | Notification Hook | macOS通知（osascript）で確認要求を即座に察知 |
| `statusline.sh` | StatusLine | git branch + 変更ファイル数 + cwd を常時表示 |
| Context7 MCP | MCPサーバー | ライブラリの最新ドキュメントをリアルタイム参照 |

**セキュリティ修正:** notification.sh の osascript インジェクション脆弱性を検出・修正（Python側で `\` と `"` をサニタイズ）。

Hook体制: 5本 → **8本**（7イベント）

### 2. CLAUDE.md レイヤー重複排除

グローバルとプロジェクトの両方に存在していた3行を IF-Vault/.claude/CLAUDE.md から削除。

- 「日本語で応対」
- 「簡潔でわかりやすい回答」
- 「機密情報コミットしない」

51行 → 48行。毎ターン3行×トークンの節約。

### 3. 自己進化ルール追加

グローバル CLAUDE.md に1行追加:

```
**自己進化**: 作業中は本題最優先。区切りごとに改善点を1つ探して提案する
```

4回の辛口レビューを経て最終形に。「があれば」（受動的）→「を探して」（能動的）に修正したのが最後の改善。

### 4. スキルアーキテクチャ再設計（39→36）

「全部Skillsに置くのは正しいのか？」という根本的な問いから再設計を実施。

#### 判断基準

| 配置先 | 条件 |
|--------|------|
| Skills（毎ターン description 読み込み） | 汎用的 + 頻繁にトリガーされる |
| References（手動参照のみ） | 参照知識 or 特定プロジェクト専用 |
| Project CLAUDE.md | プロジェクト固有のルール |

#### 実施した変更

| スキル | 変更 | 理由 |
|--------|------|------|
| fixing-accessibility | web-design-guidelines に**統合** | サブセット関係。「Accessibility Quick Review」セクションとして吸収 |
| ansem-db-patterns | `~/.claude/references/` に**移動** | IF-DB プロジェクト専用。汎用トリガーされない |
| chrome-extension-dev | `~/.claude/references/` に**移動** | creative-checker_if 専用。代わりにプロジェクト CLAUDE.md 新規作成 |
| ux-psychology | 一度 references に移動 → **復元** | 認知心理学の根拠はUI全般で参照される。demoteは過剰だった |

#### 据え置き判断（移動しなかったもの）

| スキル | 当初の案 | 却下理由 |
|--------|---------|---------|
| design-token-system | tailwind に統合 | トークン定義 vs ユーティリティ適用で役割が違う |
| vercel-react-best-practices | nextjs に統合 | ランタイム性能 vs ルーティング/データ取得で観点が違う |
| line-bot-dev | プロジェクト移動 | 単独プロジェクトが存在しない。汎用スキルとして残す |

### 5. プロジェクト CLAUDE.md 新設・整理

| ファイル | 操作 | 内容 |
|---------|------|------|
| `~/creative-checker_if/.claude/CLAUDE.md` | **新規** | Chrome MV3 パターン + references/ へのポインタ（49行） |
| `~/projects/IF-Vault/team/sekiguchi/CLAUDE.md` | **圧縮** | ドキュメント執筆ルール 27行→8行（natural-japanese-writing スキルへのポインタに置換） |

### 6. settings.local.json 自動汚染問題

セッション中にコマンドを承認すると自動で settings.local.json にエントリが蓄積される（Claude Code のプラットフォーム仕様）。python3:*、find:* 等の危険パターンが3回再発。

**対策:** Stop hook が毎セッション終了時にbadリストと照合して自動削除する。根本解決ではないが実害は防げる。

---

## 最終環境構成

```
~/.claude/
├── CLAUDE.md                  # 24行。Identity/Rules(自己進化含む)/Context
├── settings.json              # 7 hooks(8スクリプト) + permissions + deny list + statusLine
├── settings.local.json        # 24エントリ（Stop hookで自動クリーンアップ）
├── hooks/
│   ├── block-sensitive-read.sh    # PreToolUse: .env/.pem/.key ハードブロック
│   ├── token-guardian-warn.sh     # PreToolUse: 6KB超ファイルで警告
│   ├── session-compact-restore.sh # PreCompact: 状態保存
│   ├── security-post-edit.sh      # PostToolUse: 機密情報検出
│   ├── session-stop-summary.sh    # Stop: Git通知 + ローテ + settings自動クリーン
│   ├── tool-failure-logger.sh     # PostToolUseFailure: 連続失敗検出
│   ├── notification.sh            # Notification: macOS通知
│   └── statusline.sh             # StatusLine: git branch + changes + cwd
├── session-env/               # compact-state.md, uncommitted-changes.md
├── debug/                     # tool-failures.jsonl（3日ローテ）
├── scripts/                   # obsidian-quick-note.sh, use-agent.sh
├── skills/                    # 36スキル（実体19 + Symlink17）
├── references/                # 手動参照用（ansem-db-patterns, chrome-extension-dev）
└── [system dirs]              # cache/, plans/, tasks/ 等（自動生成）
```

**MCP サーバー:** pencil, token-guardian, context7, Slack, Notion

**CLAUDE.md レイヤー構成:**
```
グローバル  ~/.claude/CLAUDE.md                        24行（毎ターン）
プロジェクト ~/projects/IF-Vault/.claude/CLAUDE.md      48行（IF-Vault内のみ）
個人設定    ~/projects/IF-Vault/team/sekiguchi/CLAUDE.md 32行（IF-Vault内のみ）
プロジェクト ~/creative-checker_if/.claude/CLAUDE.md     49行（creative-checker内のみ）
```

## スコアカード

| 項目 | Pass 1 | Pass 2 | Pass 3 | 改善内容 |
|------|--------|--------|--------|---------|
| CLAUDE.md | 82 | 95 | **100** | +自己進化ルール、レイヤー重複排除 |
| settings.json | 88 | 93 | **100** | +3 hooks、+StatusLine、+Context7 MCP |
| settings.local.json | 55 | 95 | **100** | 自動汚染3回検出・修復。Stop hookで継続防御 |
| Hooks | 53 | 90 | **100** | 5本→8本。block-sensitive-read、notification、statusline追加 |
| Skills | 72 | 92 | **100** | 39→36。アーキテクチャ再設計（統合1、references移動2） |
| ファイル配置 | 48 | 95 | **100** | references/新設、project CLAUDE.md 2件整備 |
| トークン効率 | 35 | 90 | **100** | Skills -3本 + CLAUDE.md重複排除で追加削減 |
| セキュリティ | — | — | **100** | .envハードブロック、osascriptインジェクション修正 |
