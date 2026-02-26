---
name: context-economy
description: "Optimize token consumption in codebase exploration via TokenGuardian MCP: read_smart, read_fragment, grep_surgical, map_dir_cost. Includes fallback patterns for standard Read/Grep/Glob. Use when exploring large codebases, reducing context window usage, managing long sessions, or diagnosing token exhaustion. Do not trigger for developer cognitive load management (use cognitive-load-optimizer) or general session compaction (/compact). Invoke with /context-economy."
user-invocable: true
triggers:
  - トークンを節約したい
  - コンテキストを最適化
  - 大きなコードベースを探索
  - コンテキスト窓が枯渇しそう
  - /context-economy
---

# context-economy

> **前提:** TokenGuardian MCP サーバーが必要。未導入時は [Fallback セクション](#fallback-tokenguardian-なしのトークン節約) の Read/Grep 直接パターンを使用。

TokenGuardianツールを活用して、Claude Codeのコンテキストウィンドウ消費を最適化するスキル。
標準ツール（Read/Grep/Glob）だけでも実践できるFallbackパターンも提供。

## Modes

ユーザーが `/context-economy` を起動した時、以下の3モードから選択させる:

### 1. Scout Mode（偵察モード）

新しいプロジェクトやディレクトリを探索する時のフロー。

**手順:**
1. `map_dir_cost` でディレクトリ全体像を把握
2. トークンコストの高いファイルを特定
3. `read_smart` で主要ファイルの構造を確認（skeleton mode）
4. `grep_surgical` で特定のパターンを検索
5. `read_fragment` で必要な箇所だけピンポイント読み

**フロー**: map_dir_cost(全体像) -> read_smart(skeleton) -> grep_surgical(検索) -> read_fragment(精読)

### 2. Session Mode（セッション管理モード）

長時間セッションでコンテキスト消費を管理する時のフロー。

**Session Limit Protocol:**

> 注意: Claude Code はコンテキスト使用量をスキルに公開していないため、正確な閾値判定はできない。長いセッションでは積極的に offset/limit 指定の Read と head_limit つき Grep を使い、以下の外部化パターンを早めに適用する。

**外部化開始トリガー（目安・経験則ベースの指標）:**
- 10ファイル以上を Read した
- 長いコマンド出力（テスト結果、ビルドログ等）を3回以上受け取った
- 同じ情報を2回以上思い出そうとした（＝再Readが発生）
- セッション中の会話ターンが20回を超えた

**手順:**
1. 長時間セッション（上記トリガーに該当）では早めに外部化を開始
2. 現在の作業状態を `status.md` に書き出す
3. 重要な発見事項をファイルに外部化（Knowledge Externalization）
4. 必要に応じてセッションリセット＆レジューム

**status.md**: 完了タスク / 進行中タスク / 重要な発見事項(パス+行番号) / 未着手 / キーファイル(再開時に最初に読むもの) の5セクション構成。-> テンプレート: reference.md

**Knowledge Externalization**: 繰り返し参照する情報 -> ファイルに外部化、調査結果 -> status.md、アーキテクチャ -> architecture-notes.md

### 3. Audit Mode（診断モード）

現在のセッションのトークン効率を診断する。

**チェック項目（計測可能な基準付き）:**

| チェック | 基準 | 確認方法 |
|---------|------|---------|
| 大きなファイルを丸ごとReadしていないか | 500行以上のファイルを全文Read | Grep ツールで `wc -l` 相当の行数確認、または map_dir_cost でトークン数確認 |
| 同じファイルを複数回読んでいないか | 同一ファイルへの Read が2回以上 | セッション中の Read 履歴を振り返り、重複がないか確認 |
| grep結果が大量に返ってきていないか | head_limit なしで50件超のマッチ | Grep の output_mode="count" で事前にヒット数を確認してから content 取得 |
| skeleton で十分な箇所に full read していないか | 構造把握だけが目的なのに全文読み | read_smart の自動判定か、Read の limit=30 で先頭だけ読んでいるか確認 |

## Decision Tree

ファイルを読む必要がある時の判断フロー:

```
ファイルを読みたい
├─ ファイルの場所がわからない
│  └─ map_dir_cost → ディレクトリ構造を確認
├─ 特定のパターンを探したい
│  └─ grep_surgical → 前後3行コンテキスト付き検索
├─ ファイル全体の構造を知りたい
│  └─ read_smart → 自動でskeleton/full切り替え
├─ 特定の行範囲だけ読みたい
│  └─ read_fragment → ピンポイント読み
└─ 確実に全文が必要
   └─ read_smart(force_full=true) or 通常のRead
```

## Operational Patterns

### Pattern 1: Scout & Sniper（偵察->狙撃）

map_dir_cost(全体像) -> grep_surgical(場所特定) -> read_fragment(ピンポイント読み)。500行ファイルの関数調査: 全文Read ~2000tok -> grep+fragment ~300tok。

### Pattern 2: Knowledge Externalization（知識の外部化）

繰り返し参照する情報をファイルに書き出し、以降は read_fragment で部分参照。適用: API仕様、アーキテクチャ理解、依存関係整理。

### Pattern 3: Session Limit Protocol

Conserve(offset/limit/head_limit積極使用) -> Stop(消費が多いと感じたら停止) -> Save(status.mdに状態書き出し) -> Reset -> Resume(status.md読んで再開)

### Pattern 4: Pre-computation

セッション開始時に map_dir_cost で全体コスト把握 -> 高コストファイルにマーク -> skeleton優先で進行

## Checklists

### ファイル読み込み前チェック

- [ ] そのファイルは本当に読む必要があるか？
- [ ] skeleton modeで十分ではないか？
- [ ] 特定の行範囲だけで済まないか？
- [ ] grepで必要な情報だけ取得できないか？

### セッション中チェック

- [ ] 同じファイルを2回以上読んでいないか？
- [ ] 大きなファイルの全文読みをしていないか？
- [ ] 調査結果を外部ファイルに書き出しているか？
- [ ] map_dir_costでコスト確認してから作業しているか？

## Tool Reference

| ツール | 用途 | トークン効率 |
|--------|------|-------------|
| `read_smart` | ファイル読み（自動最適化） | ⭐⭐⭐⭐ |
| `read_fragment` | 行範囲指定読み | ⭐⭐⭐⭐⭐ |
| `map_dir_cost` | ディレクトリコスト表示 | ⭐⭐⭐⭐⭐ |
| `grep_surgical` | 限定コンテキスト検索 | ⭐⭐⭐⭐ |
| 通常の `Read` | ファイル丸読み | ⭐⭐ |
| 通常の `Grep` | 全マッチ返却 | ⭐⭐ |

## Fallback: TokenGuardian なしのトークン節約

TokenGuardian MCP が未導入でも、標準の Claude Code ツールでトークン消費を大幅に削減できる。

### Read: offset + limit で部分読み

`Read(offset=120, limit=50)` で必要な50行だけ読む。先に `limit=30` で先頭のimport/型確認、Grepで行番号特定してから `offset`/`limit` で精読。

### Grep: head_limit で結果制限

`Grep(head_limit=10)` で上限設定。`output_mode="count"` でヒット数を事前確認してから `content` 取得。`files_with_matches` でまずファイル一覧を取得。

### Glob: 読む前にファイル発見

`Glob("src/**/*.tsx")` で一覧取得 -> 対象を絞ってから Read。

### SKILL.md は先頭30行だけ読む

`Read(limit=30)` で frontmatter + 概要だけ確認。全文読み不要。

### Task + Explore Agent

複数ファイル横断調査は Task で委譲。エージェント内部消費は返り値のみ反映される（将来変更の可能性あり）。

### Fallback Decision Tree

場所不明 -> Glob -> Read(offset,limit) / パターン検索 -> Grep(head_limit) -> Read(offset,limit) / 構造把握 -> Read(limit=30) / 横断調査 -> Task+Explore / 全文必要 -> 通常Read

## Cross-references

- **claude-env-optimizer**: 環境全体のメンテナンス・診断（hooks/skills/health/session）
- **skill-forge**: スキルの品質評価・最適化に活用
- **typescript-best-practices**: TypeScriptコードの効率的な読み方
- **obsidian-power-user**: Knowledge Externalizationの保存先としてObsidianを活用

## Token Savings Examples

以下は代表的なシナリオでの概算比較。実際の削減量はファイルサイズや構造に依存する。

| シナリオ | 従来方式（全文Read） | 最適化後 | 手法 |
|---------|---------------------|---------|------|
| 500行TSファイルの構造把握 | ~2000 tok | ~400 tok | skeleton mode / Read(limit=30) |
| 関数定義の場所を特定 | 全ファイル読み | マッチ行+前後3行のみ | grep_surgical / Grep(head_limit) |
| プロジェクト構造把握 | 複数ファイルRead | ツリー+コスト概算のみ | map_dir_cost / Glob |
| 特定関数の修正 | ~2000 tok | 対象行範囲のみ | read_fragment / Read(offset, limit) |

概算基準: 500行TSファイル(40文字/行)。full≈全行x文字数/4tok、skeleton≈20%。日本語は1.5文字≈1tok。
