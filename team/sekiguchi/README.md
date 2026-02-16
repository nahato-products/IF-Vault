# guchiの作業スペース

最終更新: 2026-02-14

---

## フォルダ構成

- **daily/** - デイリーノート（日々の作業記録）
- **projects/** - プロジェクト管理
  - **If-DB/** - ANSEM IF-DB設計プロジェクト
- **notes/** - 技術メモ・学習ノート
- **code-snippets/** - コードスニペット集

---

## クイックリンク

### デイリーノート
```dataview
table file.mtime as 更新日時
from "team/guchi/daily"
sort file.mtime desc
limit 5
```

### 進行中のプロジェクト

| プロジェクト | ステータス | 概要 |
|---|---|---|
| [[ANSEM-プロジェクト全体サマリー\|ANSEM IF-DB]] | DB設計完了（v5.4.0）→ Phase 1実装待ち | インフルエンサー管理DB（32テーブル） |

### 最近のノート
```dataview
table file.mtime as 更新日時
from "team/guchi/notes"
sort file.mtime desc
limit 5
```

### コードスニペット
```dataview
table language as 言語, file.mtime as 更新日
from "team/guchi/code-snippets"
sort file.mtime desc
limit 5
```

---

## 主要ドキュメント

### ANSEM プロジェクト
- [[ANSEM-プロジェクト全体サマリー]] - 全体概要
- [[ANSEM-ER図]] - DB設計書本体（DDL v5.4.0）
- [[ANSEM-セキュリティ監査レポート]] - セキュリティ監査結果
- [[ANSEM-追加機能ロードマップ]] - Phase 1〜4の機能計画

### Claude Code Skills
- [[Claude-Code-Skills一覧]] - 55個の全Skills管理
- [[自作Skills一覧]] - 自作4スキルの詳細
- [[Skills-49個スキャンレポート]] - 品質スキャン結果

### 技術メモ
- [[2026-テック動向リサーチ]] - 2026年の技術トレンド
- [[認証認可-SSO-OAuth-OIDC-SAMLの地図]] - 認証・認可の概念整理
- [[Moltbot-ANSEM連携設計メモ]] - LINE Bot × DB連携設計
- [[VRoid-Remotion-Presenter実装ガイド]] - VRoidプレゼンター

### 下書き
- [[Qiita下書き-Skills54個運用]] - Qiita記事下書き

---

## 便利なコマンド

- **Cmd + P** → "Open today's daily note" - 今日のノート作成
- **Cmd + P** → "Templater: Insert template" - テンプレート挿入
- **Cmd + P** → "Git: Commit all changes" - Git保存

---

_guchiのダッシュボード_
