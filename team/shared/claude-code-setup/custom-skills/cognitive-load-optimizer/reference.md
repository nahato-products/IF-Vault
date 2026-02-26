# cognitive-load-optimizer Reference

## リスク判定パターン辞書

### 🔴 Destructive（不可逆・影響大）

| パターン | マッチ条件 | 理由 |
|---------|----------|------|
| `rm -rf`, `rm -fr`, `rm -r -f` | `rm` + recursive + force フラグ | 再帰的ファイル削除 |
| `sudo rm` | `sudo` + `rm` | 特権でのファイル削除 |
| `git push --force`, `git push -f` | `git push` + force フラグ | リモート履歴上書き |
| `git reset --hard` | `git reset` + `--hard` | 未コミット変更全消去 |
| `git clean -f` | `git clean` + `-f` フラグ | 未追跡ファイル削除 |
| `git checkout .` | `git checkout` + `.` (末尾) | 作業ツリー全復元 |
| `git restore .` | `git restore` + `.` (末尾) | 作業ツリー全復元 |
| `DROP TABLE`, `DROP DATABASE` | SQL の DROP 文 | データベース破壊操作 |
| `TRUNCATE TABLE` | SQL の TRUNCATE 文 | テーブルデータ全削除 |
| `dd if=`, `mkfs.`, `> /dev/sd` | ディスク直接書き込みパターン | ディスク破壊の可能性 |

### 🟡 Review（変更あり・可逆）

| パターン | マッチ条件 | 理由 |
|---------|----------|------|
| `git add` | `git add` コマンド | ステージング変更 |
| `git commit` | `git commit` コマンド | コミット作成 |
| `git push` (force なし) | `git push` (force フラグなし) | リモートへプッシュ |
| `git merge` | `git merge` コマンド | ブランチマージ |
| `git rebase` | `git rebase` コマンド | 履歴書き換え |
| `git stash drop` | `git stash drop` コマンド | stash 削除 |
| `npm/pnpm/yarn install` | パッケージインストール | node_modules 変更 |
| `pnpm/npm add` | パッケージ追加 | 依存追加 |
| `npm/pnpm/yarn uninstall` | パッケージ削除 | 依存削除 |
| `brew install` | Homebrew インストール | システムパッケージ |
| `mkdir` | ディレクトリ作成 | ファイルシステム変更 |
| `chmod`, `chown` | 権限変更 | ファイル権限変更 |
| `mv` | ファイル移動 | ファイルシステム変更 |
| `cp` | ファイルコピー | ファイルシステム変更 |
| `docker run/build/compose` | Docker コマンド | コンテナ操作 |

### 🟢 Safe（読み取り専用・副作用なし）

| パターン | マッチ条件 | 理由 |
|---------|----------|------|
| `ls`, `cat`, `head`, `tail` | ファイル表示コマンド | 読み取り専用 |
| `echo`, `printf`, `which`, `type` | 出力専用コマンド | 副作用なし |
| `pwd`, `whoami`, `date`, `uname` | システム情報コマンド | 読み取り専用 |
| `wc`, `sort`, `uniq`, `diff` | テキスト処理コマンド | 読み取り専用 |
| `find`, `grep`, `rg`, `fd` | 検索コマンド | 読み取り専用 |
| `tree`, `file`, `stat`, `du` | ファイル情報コマンド | 読み取り専用 |
| `git status/log/diff/show/branch` | Git 読み取りコマンド | 読み取り専用 |
| `git remote/tag/stash list/blame` | Git 読み取りコマンド | 読み取り専用 |
| `node`, `python3`, `python` | スクリプト実行 | 通常は安全 |
| `vitest`, `jest`, `pytest` | テストランナー | テスト実行 |
| `eslint`, `prettier`, `biome`, `tsc` | Linter/Formatter | 静的解析 |
| `jq`, `sed`, `awk` | テキスト処理 | パイプ使用想定 |
| `curl`, `wget` | HTTP クライアント | GET 想定 |
| その他（未マッチ） | 既知の危険パターンに該当なし | デフォルト safe |

---

## フェーズ推定ルール（詳細）

### 判定優先順位

ステータスラインとセッション復帰サマリーで使用されるフェーズ推定ロジック:

```
1. ブランチが main/master → 🏠 メインブランチ
2. 未追跡ファイルあり + コミット数 ≤ 1 → 🔰 初期実装中
3. ステージ済み変更あり → 📦 コミット準備中
4. 直近コミットメッセージが fix/WIP/bugfix → 🔧 修正・デバッグ中
5. ブランチが feature/* → 🚀 機能開発進行中
6. それ以外 → 🏠 メインブランチ
```

### フェーズ別の推奨アクション

| フェーズ | 推奨アクション |
|---------|-------------|
| 🔰 初期実装中 | 変更を確認して最初のコミットを作成 |
| 📦 コミット準備中 | `git diff --cached` でステージ内容を確認してコミット |
| 🔧 修正・デバッグ中 | 修正が完了しているか確認、テスト実行を提案 |
| 🚀 機能開発進行中 | 未コミット変更をレビューして続きを進める |
| 🏠 メインブランチ | 次のタスクを選択、ブランチを切って作業開始 |

---

## flow テンプレート集

### 選択肢提示テンプレート

```
[推奨] Option A: 〜〜〜（理由: 最もシンプル）
[代替] Option B: 〜〜〜（理由: 拡張性重視）
→ 特に希望なければ A で進めるよ？
```

### 段階的開示テンプレート

```
## 概要（30秒で把握）
[1-2行の要約]

## 詳細
<details>
[展開すると詳細が見える]
</details>
```

### スマートデフォルト一覧

| 場面 | デフォルト | 根拠 |
|------|----------|------|
| ブランチ名 | `feature/[タスク要約の kebab-case]` | CLAUDE.md Git 規約 |
| コミットメッセージ | 変更内容の日本語要約 | CLAUDE.md Git 規約 |
| テスト実行 | `vitest run [変更ファイルの隣の .test ファイル]` | CLAUDE.md テスト戦略 |
| エラーハンドリング | Result パターン `{ success, data, error }` | CLAUDE.md エラー方針 |
| コンポーネント配置 | `features/[機能名]/components/` | CLAUDE.md ディレクトリ構成 |
| 型定義 | Zod スキーマから導出 (`z.infer`) | CLAUDE.md TypeScript 規約 |

### セッション復帰サマリーテンプレート

```
📍 セッション復帰サマリー
━━━━━━━━━━━━━━━━━━━━━
フェーズ: [推定フェーズアイコン] [フェーズ名]
ブランチ: [ブランチ名]
未コミット: [数]ファイル変更
最後のスキル: [スキル名 or なし]

直近の作業:
- [ハッシュ] [メッセージ]
- [ハッシュ] [メッセージ]

💡 推奨アクション: [フェーズ別の推奨アクション]
```

---

## 認知密度マネジメント

### METR研究の知見

2025年のMETR研究によると、経験豊富なオープンソース開発者がAIツールを使用した場合、複雑で新規のタスクで19%遅くなった。原因は「認知密度の増加」— AIがルーチンワーク（ボイラープレート、検索、単純な実装）を消すことで、残る作業が全て高認知負荷のタスク（設計判断、アーキテクチャ選択、エッジケース対応）になる。

### 対策パターン

| パターン | 説明 | 適用タイミング |
|---------|------|-------------|
| **思考の外在化** | 判断ポイントを明示的にテンプレートに書き出す | 設計判断に直面したとき |
| **段階的複雑性** | 大きな判断を小さな判断に分割 | 影響範囲が3ファイル以上のとき |
| **強制的な休止** | Plan Mode で一度立ち止まって設計 | 実装に飛びつきそうなとき |
| **コンテキストリセット** | /compact + 要約で頭をリフレッシュ | 90分以上の連続作業後 |
| **専門スキル委譲** | 適切なスキルに判断を委ねる | 自分の専門外の判断が必要なとき |

### 判断足場テンプレート（詳細版）

```
🧠 判断ポイント検知

━━━━━━━━━━━━━━━━━━━━━
【何を決めるか】: [判断の要約を1行で]

【背景】: [なぜこの判断が必要になったか]

【選択肢】:
  A: [選択肢A]
     ✅ メリット: [具体的に]
     ❌ デメリット: [具体的に]
     📊 影響範囲: [ファイル数・コンポーネント数]

  B: [選択肢B]
     ✅ メリット: [具体的に]
     ❌ デメリット: [具体的に]
     📊 影響範囲: [ファイル数・コンポーネント数]

【判断基準】（優先順）:
  1. [最重要基準]
  2. [次の基準]
  3. [その次]

【可逆性】: 🟢 簡単に戻せる / 🟡 コストかかる / 🔴 不可逆

【推奨】: [Option X]
【理由】: [1-2行で理由]
━━━━━━━━━━━━━━━━━━━━━
```

### セッション疲労チェックリスト

| チェック | 対応 |
|---------|------|
| 同じエラーを3回以上修正している | → systematic-debugging に切り替え |
| 「とりあえず」「一旦」が増えている | → Plan Mode で設計を整理 |
| ファイル間を行き来して迷っている | → brainstorming で要件を再整理 |
| コンテキストウィンドウが80%以上 | → /compact で圧縮 |
| 90分以上連続作業 | → 5分休憩 + /compact |

---

## トラブルシューティング

### shield が動かない

1. `~/.claude/settings.json` の PreToolUse に Bash matcher が登録されているか確認
2. `~/.claude/hooks/command-shield.sh` に実行権限があるか確認: `ls -la ~/.claude/hooks/command-shield.sh`
3. `jq` がインストールされているか確認: `which jq`
4. hook のテスト実行:
   ```bash
   echo '{"tool_name":"Bash","tool_input":{"command":"ls -la"}}' | ~/.claude/hooks/command-shield.sh
   # 期待: {"additionalContext":"🟢 safe | ls — 読み取り専用コマンド"}
   ```

### resume で情報が不足する

- `~/.claude/session-env/` ディレクトリが存在するか確認
- `session-compact-restore.sh` hook (PreCompact) が正常に動作しているか確認
- Git リポジトリ外のディレクトリでは Git 情報が取得できない

### statusline にフェーズアイコンが出ない

- Git リポジトリ内にいることを確認
- `~/.claude/hooks/statusline.sh` を直接実行してデバッグ:
  ```bash
  echo '{"workspace":{"current_dir":"'$(pwd)'"}}' | ~/.claude/hooks/statusline.sh
  ```

### 既存 hook との干渉

- command-shield は `additionalContext` のみ返すため、他の hook の `decision` と干渉しない
- `block-sensitive-read.sh` (Read matcher) とは matcher が異なるため競合しない
- `security-post-edit.sh` は PostToolUse なのでタイミングが異なり競合しない
