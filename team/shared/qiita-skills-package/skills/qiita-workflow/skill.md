---
name: qiita-workflow
description: Qiita記事執筆ワークフローを管理。ユーザーが忘れても、自動的に次のステップを案内します
args:
  - name: action
    description: アクション（start/continue/status/省略可）
    required: false
---

# Qiita記事執筆ワークフロー管理

記事執筆のステップを自動管理し、ユーザーが忘れても次にやるべきことを案内します。

## ワークフローのステップ

```
1. idea        → アイディア創出
2. draft       → 下書き執筆
3. review      → 文体チェック・推敲
4. publish     → 出稿
5. completed   → 完了
```

## 実行手順

### 引数なしで実行された場合

現在進行中の記事の状況を確認し、次にやるべきステップを提案します。

**処理:**
1. `11_Qiita/drafts/` 内のすべての記事を読み込み
2. 各記事のフロントマター `workflow_step` を確認
3. 進行中の記事を一覧表示
4. 次のステップを提案

**出力例:**
```markdown
# 📊 Qiita記事ワークフロー状況

## 🚧 進行中の記事

### 1. Next.jsのサーバーコンポーネントでハマった話
- **ステータス:** draft（下書き完了）
- **作成日:** 2026-02-17
- **次のステップ:** `/qiita-review` で文体チェック

### 2. tmuxの使い方とセットアップ
- **ステータス:** idea（アイディアのみ）
- **作成日:** 2026-02-16
- **次のステップ:** `/qiita-draft [ファイル名]` で下書き作成

---

## 🎯 推奨アクション

最も進んでいる記事を続けますか？

1. `/qiita-review` - Next.jsの記事を推敲する
2. `/qiita-draft` - tmuxの記事を書く
3. `/qiita-workflow start` - 新しい記事を始める
```

AskUserQuestionで次のアクションを確認し、自動的に該当Skillを実行します。

### `action: start` の場合

新しい記事を開始します。

**処理:**
1. `/qiita-topics-from-slack` または `/qiita-draft` のどちらで始めるか確認
2. AskUserQuestionで選択
3. 選択されたSkillを自動実行

**選択肢:**
```
新しい記事を始めます。どこからスタートしますか？

1. Slackから記事ネタを探す（推奨）
2. Daily Notesから記事候補を探す
3. トピックを直接指定して書く
```

### `action: continue` の場合

中断した記事を再開します。

**処理:**
1. `drafts/` 内で `workflow_step` が `completed` でない記事を探す
2. 最も最近更新された記事を優先的に提示
3. 次のステップを自動実行

**例:**
```
中断していた記事を再開します。

📝 Next.jsのサーバーコンポーネントでハマった話
   ステータス: draft
   次のステップ: 文体チェック

→ `/qiita-review` を自動実行します
```

### `action: status` の場合

全記事の進捗状況を表示します。

**処理:**
1. `drafts/` と `published/` のすべての記事を読み込み
2. ステータス別に分類して表示
3. 統計情報を出力

**出力例:**
```markdown
# 📊 Qiita記事統計

## ステータス別

- 🆕 アイディアのみ: 3件
- ✍️  下書き完了: 2件
- ✅ 推敲完了: 1件
- 🚀 公開済み: 5件

## 今週の進捗

- 新規作成: 2件
- 公開: 1件

## 次にやるべきこと

推敲完了している記事があります！
→ `/qiita-publish` で出稿しましょう
```

## ワークフロー自動進行

各Skillの実行後、自動的に次のステップを提案します。

### ステップ1完了後（アイディア創出）

`/qiita-topics-from-slack` または `/qiita-draft`（候補選択のみ）が完了したら：

```
✅ 記事ネタが決まりました！

📝 次のステップ: 下書き執筆
→ `/qiita-draft [トピック名]` を実行しますか？

[はい] [後で]
```

「はい」を選択すると、自動的に `/qiita-draft [トピック名]` を実行します。

### ステップ2完了後（下書き執筆）

`/qiita-draft` が完了したら：

1. フロントマターの `workflow_step` を `draft` に更新
2. 次のステップを提案

```
✅ 下書きが完成しました！
📁 保存先: 11_Qiita/drafts/2026-02-17_Next.jsの話.md

📝 次のステップ: 文体チェック
→ `/qiita-review` を実行しますか？

[はい] [後で]
```

### ステップ3完了後（推敲）

`/qiita-review` が完了したら：

1. フロントマターの `workflow_step` を `review` に更新
2. 次のステップを提案

```
✅ 文体チェックが完了しました！

📝 次のステップ: 出稿
→ `/qiita-publish` を実行しますか？

[今すぐ投稿] [下書き保存] [後で]
```

### ステップ4完了後（出稿）

`/qiita-publish` が完了したら：

1. フロントマターの `workflow_step` を `completed` に更新
2. 記事を `published/` に移動
3. 次の記事を提案

```
✅ 記事を投稿しました！ 🎉
🔗 URL: https://qiita.com/your-username/items/xxxxx

📊 今週の進捗:
- 公開: 2件
- 下書き中: 1件

📝 次にやること:
1. 新しい記事を書く → `/qiita-workflow start`
2. 下書き中の記事を続ける → `/qiita-workflow continue`
3. 休憩する 😊
```

## フロントマターの自動管理

各Skillは、記事のフロントマターを自動的に更新します。

### フロントマター構造

```yaml
---
title: "記事タイトル"
tags: [タグ1, タグ2]
status: draft  # draft / published
workflow_step: draft  # idea / draft / review / publish / completed
created: 2026-02-17
updated: 2026-02-17
qiita_url: ""
---
```

### 自動更新のタイミング

| Skill | workflow_step | updated |
|-------|---------------|---------|
| `/qiita-topics-from-slack` | `idea` | ✅ |
| `/qiita-draft` (候補選択) | `idea` | ✅ |
| `/qiita-draft` (執筆完了) | `draft` | ✅ |
| `/qiita-review` | `review` | ✅ |
| `/qiita-publish` | `completed` | ✅ |

## 通知・リマインダー機能

ユーザーが一定期間操作していない場合、自動的にリマインドします。

**例:**
- 下書きを作成してから24時間経過 → 「推敲を忘れていませんか？」
- 推敲完了から3日経過 → 「出稿を忘れていませんか？」

## エラーハンドリング

### 記事が見つからない場合

```
❌ 進行中の記事が見つかりません。

新しい記事を始めますか？
→ `/qiita-workflow start`
```

### ステップが不正な場合

フロントマターの `workflow_step` が不正な値の場合、自動的に修正を提案します。

## 注意事項

- **自動保存:** 各ステップの完了時、フロントマターを自動更新
- **ファイル移動:** 公開後、自動的に `published/` に移動
- **バックアップ:** 元のファイルは保持（上書きしない）

## 完了メッセージ

```
✅ ワークフロー管理システムが稼働しています！

📊 現在の状況を確認するには:
   `/qiita-workflow`

🆕 新しい記事を始めるには:
   `/qiita-workflow start`

▶️  中断した記事を再開するには:
   `/qiita-workflow continue`

記事執筆、頑張ってください！ 🚀
```
