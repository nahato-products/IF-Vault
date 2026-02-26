---
name: context-economy
description: "Token-efficient codebase exploration via TokenGuardian MCP: read_smart, grep_surgical, map_dir_cost"
user-invocable: true
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

**実行テンプレート:**
```
Step 1: map_dir_cost → プロジェクト全体像
Step 2: read_smart → 主要ファイルのskeleton
Step 3: grep_surgical → 特定パターン検索
Step 4: read_fragment → 必要箇所のみ精読
```

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

**status.md テンプレート:**
```markdown
# Session Status — [日付]

## 完了タスク
- [x] タスク名: 結果の要約

## 進行中タスク
- [ ] タスク名: 現在の状態、次のステップ

## 重要な発見事項
- ファイルパス: 発見内容（行番号があれば記載）

## 未着手・次にやること
- タスク名: コンテキスト情報

## キーファイル（再開時に最初に読むもの）
- /path/to/important/file.ts — 理由
```

**Knowledge Externalization パターン:**
- 繰り返し参照する情報 → ファイルに書き出し
- 調査結果のサマリ → status.md に記録
- アーキテクチャ理解 → architecture-notes.md に記録

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

### Pattern 1: Scout & Sniper（偵察→狙撃）

大規模コードベースを効率的に探索するパターン。

```
1. map_dir_cost(path) → 全体像把握、コスト高いファイル特定
2. grep_surgical(query, path) → ターゲットの場所を特定
3. read_fragment(path, start, end) → ピンポイントで必要箇所だけ読む
```

**効果:** 従来の「Readで丸ごと読む」と比較してトークン消費を大幅削減（例: 500行ファイルの関数定義調査で、全文Read ~2000tok → grep_surgical+read_fragment ~300tok）。

### Pattern 2: Knowledge Externalization（知識の外部化）

繰り返し参照する情報をコンテキストから外部ファイルに移す。

```
1. 調査中に繰り返し参照する情報を特定
2. その情報をMarkdownファイルに書き出す
3. 以降はread_fragmentで必要な部分だけ参照
```

**適用場面:**
- API仕様の調査結果
- アーキテクチャの理解メモ
- 依存関係の整理

### Pattern 3: Session Limit Protocol（セッション限界プロトコル）

長いセッションでコンテキスト消費を抑えるための対処法。正確なコンテキスト使用量は取得できないため、多くのファイルを読んだ・大量の出力が発生した場合に積極的に適用する。

```
1. Conserve: offset/limit指定のRead、head_limitつきGrepを積極的に使う
2. Stop: 大量のコンテキスト消費が発生したら現在の作業を一旦停止
3. Save: status.md に現在の状態を書き出す
   - 完了したタスク
   - 進行中のタスク
   - 次にやるべきこと
   - 重要な発見事項
4. Reset: セッションをリセット
5. Resume: status.md を読んで作業再開
```

### Pattern 4: Pre-computation（事前計算）

セッション開始時にコスト情報を先に取得する。

```
1. map_dir_cost でプロジェクト全体のトークンコストを把握
2. 高コストファイルにマークを付ける
3. 以降の読み込みではskeleton優先で進める
```

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

ファイル全体（デフォルト2000行）を読む代わりに、必要な範囲だけ指定する。

```
# NG: 500行ファイルを丸ごと読む（全行分のトークン消費）
Read ツール: パラメータ指定なし → デフォルト2000行まで全部読み込み

# OK: 必要な50行だけ読む
Read ツール: offset=120, limit=50 で必要な50行だけ読む
```

**活用パターン:**
- まず `limit=30` で先頭のimport/型定義だけ確認
- Grepで行番号を特定 → その前後だけ `offset`/`limit` で読む

### Grep: head_limit で結果制限

大規模プロジェクトでは検索結果が大量に返る。`head_limit` で上限を設定する。

```
# NG: 全マッチ返却（数百件になることも）
Grep ツール: pattern="useState", path="src/" → 全件返却

# OK: 最初の10件だけ返す
Grep ツール: pattern="useState", path="src/", head_limit=10 で上限設定
```

**活用パターン:**
- `output_mode="files_with_matches"` でまずファイル一覧を取得
- `output_mode="count"` でヒット数を事前確認してから `content` で取得

### Glob: 読む前にファイルを発見する

ファイルを闇雲にReadする前に、Globで存在確認・対象絞り込みを行う。

```
# まず構造を把握
Glob ツール: pattern="src/**/*.tsx" でファイル一覧取得

# 特定パターンのファイルだけ発見
Glob ツール: pattern="**/use*.ts" でカスタムHooksだけ探す
```

### SKILL.md / reference.md の効率的な読み方

他のスキルのSKILL.mdを参照する時も、全文読みを避ける。

```
# NG: SKILL.md を丸ごと読む
Read ツール: パラメータ指定なし → 全文読み込み

# OK: 先頭のfrontmatter + 概要だけ読む
Read ツール: limit=30 で先頭30行だけ読む
```

### 広範囲の調査には Task + Explore Agent

複数ファイルにまたがる調査は、自分で1つずつ読むよりTaskツールでExploreエージェントに委譲する方がコンテキスト効率が良い。Task ツールで起動したエージェントの内部コンテキスト消費は、呼び出し元のコンテキストには返り値のみが反映される（エージェント内部の全読み取り内容は含まれない）。ただしこの挙動は将来のバージョンで変更される可能性がある。

### Fallback Decision Tree

```
ファイルを読みたい
├─ ファイルの場所がわからない
│  └─ Glob → ファイル発見 → Read(offset, limit)
├─ 特定のパターンを探したい
│  └─ Grep(head_limit=10) → 行番号特定 → Read(offset, limit)
├─ ファイル全体の構造を知りたい
│  └─ Read(limit=30) で先頭のimport/export確認
├─ 複数ファイルを横断調査したい
│  └─ Task + Explore Agent に委譲
└─ 確実に全文が必要
   └─ 通常の Read（これは仕方ない）
```

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

**推定方法:** 500行TypeScriptファイル（平均40文字/行、英数字中心）を基準。full read のトークン数 ≈ 全行 x 平均文字数 / 4（英語は約4文字≈1トークン）。skeleton mode ≈ 関数シグネチャ + import行のみ（全体の約20%）。日本語コメントが多い場合は 1.5文字 ≈ 1トークン で換算するためトークン数は増加する。実際の削減量はファイルサイズ・構造・言語に依存。
