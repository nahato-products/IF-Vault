# チーム共有 Skills ガイド

guchiが作成・最適化した Claude Code Skills のセットアップと使い方。Claude Codeを使うメンバー全員が対象。

全24スキルは skill-forge の10項目100点レビューで品質担保済み。全スキル最終レビュー＆最適化完了。

---

## 自動セットアップ（推奨）

**install.sh で全スキルが自動インストール済み。** 以下のコマンドで24スキル + メタスキル3個がシンボリックリンクでセットアップされる。

```bash
bash team/shared/claude-code-setup/install.sh
```

個別にスキルを追加/削除したい場合は、下記の手動セットアップを参照。

---

## スキル一覧

### Tier 1: 全員必須（6個）

日常で最も発火する基盤系。全メンバー必須。

| Skill | 説明 | 発火タイミング | スコア |
|-------|------|--------------|--------|
| ux-psychology | UI/UXの認知心理学ベース設計 | UI設計・レビュー・バリデーション最適化時 | 最適化済 |
| natural-japanese-writing | AI臭を排除した自然な日本語 | Markdown日本語文の執筆・編集時 | 最適化済 |
| ansem-db-patterns | PostgreSQL本番スキーマ設計 | テーブル設計・DDL作成・FK削除ポリシー決定時 | 最適化済 |
| typescript-best-practices | 型安全パターンと実装ルール | TypeScript型設計・コードレビュー時 | 最適化済 |
| systematic-debugging | 根本原因調査の4段階プロセス | バグ診断・原因追跡・テスト失敗解析時 | 最適化済 |
| error-handling-logging | エラー分類とログ構造化設計 | エラー境界・ロギング・Sentry連携時 | 最適化済 |

### Tier 2: 開発者推奨（10個）

プロジェクト開発で頻繁に使う。担当領域に合わせて選択。

| Skill | 説明 | 発火タイミング | スコア |
|-------|------|--------------|--------|
| nextjs-app-router-patterns | App Router 15ルーティング・キャッシュ | ルート設計・キャッシュ戦略決定時 | 最適化済 |
| react-component-patterns | React合成・CVA・SC/CC設計 | コンポーネント設計・リファクタリング時 | 最適化済 |
| tailwind-design-system | Tailwind v4 CSS-first設定・CVA | Tailwindユーティリティ・バリアント構築時 | 最適化済 |
| testing-strategy | TDD・テスト品質分析フロー | テスト設計・バグ修正時テスト作成時 | 最適化済 |
| supabase-auth-patterns | Auth・RLS・セッション管理 | 認証フロー・RLSポリシー実装時 | 最適化済 |
| supabase-postgres-best-practices | クエリ最適化・接続プール・RLS性能 | SQL最適化・遅いクエリ診断時 | 最適化済 |
| vercel-react-best-practices | ランタイムパフォーマンス最適化 | バンドル削減・再レンダリング抑制時 | 最適化済 |
| security-review | 脆弱性検出・セキュリティ監査 | `/security-review` で手動起動 | 最適化済 |
| ci-cd-deployment | GitHub Actions・Vercel自動化 | パイプライン構築・デプロイ設定時 | 最適化済 |
| docker-expert | Docker最適化・Compose・セキュア化 | Dockerfile作成・イメージサイズ削減時 | 最適化済 |

### Tier 3: 専門特化（6個）

特定ドメインで発火。担当プロジェクトに応じて導入。

| Skill | 説明 | 発火タイミング | スコア |
|-------|------|--------------|--------|
| dashboard-data-viz | ダッシュボード・KPI・データテーブル | ダッシュボード構築・データ表示設計時 | 最適化済 |
| design-token-system | トークン階層・OKLCH色・ダークモード | カラーパレット設計・トークン定義時 | 最適化済 |
| micro-interaction-patterns | ローディング・トースト・フォームUX | UI状態フィードバック・アニメーション実装時 | 最適化済 |
| mobile-first-responsive | LIFF/PWA・モバイルファースト | モバイルレスポンシブ・LIFF実装時 | 最適化済 |
| web-design-guidelines | WCAG・セマンティックHTML・フォーム・SEO | アクセシビリティ監査・HTML設計時 | 最適化済 |
| line-bot-dev | LINE Bot・Messaging API・LIFF | LINE Bot開発・Webhook署名検証時 | 最適化済 |

### Tier 4: ツール系（2個）

特定ツール操作に特化。使うツールに合わせて導入。

| Skill | 説明 | 発火タイミング | スコア |
|-------|------|--------------|--------|
| obsidian-power-user | Obsidian Markdown・Bases・Dataview | Obsidian本格運用・クエリ作成時 | 最適化済 |
| chrome-extension-dev | Chrome拡張MV3・DOM操作・SNS対応 | 拡張機能開発・manifest設定時 | 最適化済 |

---

## 手動セットアップ（個別追加/削除したい場合）

install.sh を使わず個別にスキルを管理したい場合。IF-Vaultのルートディレクトリで実行する。`git pull` で最新化してから行うこと。

### Tier 1: 全員必須

```bash
ln -s "$(pwd)/team/shared/skills/ux-psychology" ~/.claude/skills/ux-psychology
ln -s "$(pwd)/team/shared/skills/natural-japanese-writing" ~/.claude/skills/natural-japanese-writing
ln -s "$(pwd)/team/shared/skills/ansem-db-patterns" ~/.claude/skills/ansem-db-patterns
ln -s "$(pwd)/team/shared/skills/typescript-best-practices" ~/.claude/skills/typescript-best-practices
ln -s "$(pwd)/team/shared/skills/systematic-debugging" ~/.claude/skills/systematic-debugging
ln -s "$(pwd)/team/shared/skills/error-handling-logging" ~/.claude/skills/error-handling-logging
```

### Tier 2: 開発者推奨（必要なものだけ選択）

```bash
ln -s "$(pwd)/team/shared/skills/nextjs-app-router-patterns" ~/.claude/skills/nextjs-app-router-patterns
ln -s "$(pwd)/team/shared/skills/react-component-patterns" ~/.claude/skills/react-component-patterns
ln -s "$(pwd)/team/shared/skills/tailwind-design-system" ~/.claude/skills/tailwind-design-system
ln -s "$(pwd)/team/shared/skills/testing-strategy" ~/.claude/skills/testing-strategy
ln -s "$(pwd)/team/shared/skills/supabase-auth-patterns" ~/.claude/skills/supabase-auth-patterns
ln -s "$(pwd)/team/shared/skills/supabase-postgres-best-practices" ~/.claude/skills/supabase-postgres-best-practices
ln -s "$(pwd)/team/shared/skills/vercel-react-best-practices" ~/.claude/skills/vercel-react-best-practices
ln -s "$(pwd)/team/shared/skills/security-review" ~/.claude/skills/security-review
ln -s "$(pwd)/team/shared/skills/ci-cd-deployment" ~/.claude/skills/ci-cd-deployment
ln -s "$(pwd)/team/shared/skills/docker-expert" ~/.claude/skills/docker-expert
```

### Tier 3: 専門特化（担当プロジェクトに応じて選択）

```bash
ln -s "$(pwd)/team/shared/skills/dashboard-data-viz" ~/.claude/skills/dashboard-data-viz
ln -s "$(pwd)/team/shared/skills/design-token-system" ~/.claude/skills/design-token-system
ln -s "$(pwd)/team/shared/skills/micro-interaction-patterns" ~/.claude/skills/micro-interaction-patterns
ln -s "$(pwd)/team/shared/skills/mobile-first-responsive" ~/.claude/skills/mobile-first-responsive
ln -s "$(pwd)/team/shared/skills/web-design-guidelines" ~/.claude/skills/web-design-guidelines
ln -s "$(pwd)/team/shared/skills/line-bot-dev" ~/.claude/skills/line-bot-dev
```

### Tier 4: ツール系（必要に応じて選択）

```bash
ln -s "$(pwd)/team/shared/skills/obsidian-power-user" ~/.claude/skills/obsidian-power-user
ln -s "$(pwd)/team/shared/skills/chrome-extension-dev" ~/.claude/skills/chrome-extension-dev
```

セットアップ後、Claude Codeを再起動すれば使える。

---

## 更新・無効化

### 更新

```bash
git pull
```

シンボリックリンク経由なので `git pull` だけで全メンバーに反映される。再リンク不要。

### 無効化

使いたくないスキルはリンクを削除する。

```bash
rm ~/.claude/skills/スキル名
```

### 全スキル一括削除

```bash
ls -la ~/.claude/skills/ | grep "IF-Vault" | awk '{print $NF}' | xargs -I{} rm ~/.claude/skills/{}
```

---

## Skillsの作り方

`/skill-forge` コマンドで起動するメタスキルを使う。8フェーズのCreate Modeで要件定義から品質レビューまで一気通貫で作成できる。10項目100点満点の品質スコアリングで品質を担保する。

新しいSkillを作りたくなったらguchiに相談。

---

## ファイル構成

```
team/shared/skills/
├── README.md
├── ux-psychology/
│   ├── SKILL.md              (399行)
│   └── reference.md          (534行)
├── natural-japanese-writing/
│   ├── SKILL.md              (186行)
│   └── reference.md          (463行)
├── ansem-db-patterns/
│   ├── SKILL.md              (334行)
│   └── reference.md          (394行)
├── typescript-best-practices/
│   ├── SKILL.md              (306行)
│   └── reference.md          (198行)
├── systematic-debugging/
│   ├── SKILL.md              (189行)
│   └── reference.md          (184行)
├── error-handling-logging/
│   ├── SKILL.md              (328行)
│   └── reference.md          (548行)
├── nextjs-app-router-patterns/
│   ├── SKILL.md              (494行)
│   └── reference.md          (472行)
├── react-component-patterns/
│   ├── SKILL.md              (470行)
│   └── reference.md          (458行)
├── tailwind-design-system/
│   ├── SKILL.md              (189行)
│   └── reference.md          (649行)
├── testing-strategy/
│   ├── SKILL.md              (300行)
│   └── reference.md          (417行)
├── supabase-auth-patterns/
│   ├── SKILL.md              (356行)
│   └── reference.md          (369行)
├── supabase-postgres-best-practices/
│   ├── SKILL.md              (337行)
│   └── reference.md          (673行)
├── vercel-react-best-practices/
│   ├── SKILL.md              (301行)
│   └── reference.md          (358行)
├── security-review/
│   ├── SKILL.md              (277行)
│   └── reference.md          (143行)
├── ci-cd-deployment/
│   ├── SKILL.md              (295行)
│   └── reference.md          (379行)
├── docker-expert/
│   ├── SKILL.md              (313行)
│   └── reference.md          (259行)
├── dashboard-data-viz/
│   ├── SKILL.md              (349行)
│   └── reference.md          (663行)
├── design-token-system/
│   ├── SKILL.md              (384行)
│   └── reference.md          (578行)
├── micro-interaction-patterns/
│   ├── SKILL.md              (369行)
│   └── reference.md          (842行)
├── mobile-first-responsive/
│   ├── SKILL.md              (359行)
│   └── reference.md          (569行)
├── web-design-guidelines/
│   ├── SKILL.md              (342行)
│   └── reference.md          (969行)
├── line-bot-dev/
│   ├── SKILL.md              (327行)
│   └── reference.md          (339行)
├── obsidian-power-user/
│   ├── SKILL.md              (491行)
│   └── reference.md          (360行)
└── chrome-extension-dev/
    ├── SKILL.md              (415行)
    └── reference.md          (259行)
```
