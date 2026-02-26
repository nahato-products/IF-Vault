---
tags: [ANSEM, database, design, documentation, postgresql]
created: 2026-02-06
updated: 2026-02-12
status: completed
version: 5.4.0
related: "[[ANSEM-ER図（ビジュアル版）]], [[ANSEM-ER図レビュー]], [[ANSEM-要件変更ログ]], [[ANSEM-データ投入運用方針]]"
---

# ANSEMプロジェクト データベース設計書

## 目次

1. [プロジェクト概要](#プロジェクト概要)
2. [設計方針・原則](#設計方針原則)
3. [テーブル構成](#テーブル構成)
4. [ER図](#er図)
5. [テーブル詳細定義](#テーブル詳細定義)
6. [共通トリガー・ファンクション](#共通トリガーファンクション)
7. [使用例](#使用例)
8. [運用ガイドライン](#運用ガイドライン)
9. [参考情報](#参考情報)
10. [チェックリスト](#チェックリスト)
11. [変更履歴](#変更履歴)

---

## プロジェクト概要

### プロジェクト名
**ANSEM（インフルエンサーマーケティング管理システム）**

### 目的
インフルエンサー、パートナー、クライアント、キャンペーンを一元管理し、広告配信・成果測定・請求業務を効率化するシステムのデータベース設計

### スコープ
- インフルエンサープロファイル管理
- SNSアカウント・カテゴリ管理
- パートナー・サイト管理
- クライアント・広告コンテンツ管理
- キャンペーン管理
- 単価設定・期間管理
- 日次パフォーマンス集計
- 監査ログ・履歴管理
- セキュリティ・認証管理

### 技術スタック
- **DB**: PostgreSQL 14以降
- **言語**: SQL
- **ORM**: 未定（将来的にPrisma/TypeORMを検討）

---

## 設計方針・原則

### 1. 命名規則

#### テーブル名
- **マスタテーブル**: `m_` プレフィックス
  - コード値、固定データ、あまり変更されないデータ
  - 例: `m_countries`, `m_categories`, `m_agents`
- **トランザクションテーブル**: `t_` プレフィックス
  - 可変データ、業務データ、状態が変化するデータ
  - 例: `t_partner_sites`, `t_addresses`, `t_unit_prices`

#### カラム名
- **主キー**: `{table}_id` 形式
  - 例: `influencer_id`, `campaign_id`
- **外部キー**: 参照先のテーブル名_id 形式
  - 例: `parent_category_id`, `department_id`
- **複合語**: スネークケース
  - 例: `created_at`, `email_address`, `follower_count`

### 2. データ型統一

#### 文字列型
- **統一ルール**: `TEXT` 型を使用
- **禁止**: `VARCHAR(n)` は使用しない
- **理由**:
  - パフォーマンス差がほぼない
  - 長さ制限の変更時にALTER不要
  - シンプルで管理しやすい

#### 日時型
- **統一ルール**: `TIMESTAMPTZ` 型を使用
- **禁止**: `TIMESTAMP` (タイムゾーンなし) は使用しない
- **理由**:
  - グローバル展開を見据えた設計
  - タイムゾーン変換が自動
  - 国際化対応
- **例外（DATE型を使用する場合）**: 時刻情報が不要で日単位の精度で十分なカラム
  - 有効期間: `valid_from` / `valid_to`（t_addresses, t_bank_accounts, t_billing_info）
  - 単価期間: `start_at` / `end_at`（t_unit_prices）
  - 入社日: `join_date`（m_agents）
  - 集計日: `action_date`（t_daily_performance_details, t_daily_click_details）

#### 数値型
- **金額**: `DECIMAL(12, 0)` （整数円）
- **カウント**: `INTEGER` または `BIGINT`
- **ID**: `BIGINT GENERATED ALWAYS AS IDENTITY`
  - **例外①**: マスタ系で件数が少なく値が固定的なもの（`m_countries`, `m_agent_role_types`）は `SMALLINT` 手動採番
  - **例外②**: 1対1リレーションのセキュリティテーブル（`m_agent_security`, `m_influencer_security`）は親テーブルのIDをPK/FKとして使用
  - **例外③**: 外部システムID一致テーブル（`m_partners_division`）はBQ/ASPのIDと一致させるため `partner_id BIGINT PRIMARY KEY`（手動指定、IDENTITY不使用）
- **小さな種類**: `SMALLINT` (ステータスコード等)

#### 真偽値型
- **統一ルール**: `BOOLEAN` 型を使用
- **デフォルト値**: 明示的に設定
- **例**: `is_active BOOLEAN NOT NULL DEFAULT TRUE`

### 3. 監査カラム（全テーブル必須）

> [!NOTE]
> **例外:**
> - **`t_audit_logs`** — 監査ログ自体が監査の記録であるため、`operator_id` / `operated_at` で代替。4カラムは冗長のため不要。
> - **`ingestion_logs`** — システムジョブの実行ログであるため、`started_at` / `finished_at` で代替。ジョブは自動実行のため `created_by` / `updated_by` は不要。
> - **`m_partners_division`** — BQ/ASPの外部システムID一致用テーブル。データ投入は一括インポートのみで、個人の操作記録が不要なため `created_by` / `updated_by` は持たない。`created_at` / `updated_at` のみ保持。

> [!NOTE]
> 監査カラム（created_by, updated_by, created_at, updated_at）のCOMMENT ON COLUMNは全テーブル共通のため省略しています。意味は本セクションの定義を参照してください。ただし、日次集計テーブル（t_daily_performance_details, t_daily_click_details）は `DEFAULT 1`（システム管理者）という特殊なデフォルト値を持つため、例外的に個別COMMENTを付与しています。

```sql
-- 作成者・更新者
created_by BIGINT NOT NULL,
updated_by BIGINT NOT NULL,

-- 作成日時・更新日時
created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
```

### 4. 外部キー制約

#### 基本方針
- **必須**: すべての外部キーに制約を設定
- **削除制約**: 原則 `ON DELETE RESTRICT` （削除禁止）
- **更新制約**: デフォルト（NO ACTION）

#### ON DELETE 使い分けルール

| ON DELETE | 用途 | 対象例 |
|-----------|------|--------|
| **RESTRICT**（原則） | 参照データの保全。削除前に依存データの整理が必要 | 集計テーブル、`t_unit_prices`、`t_influencer_sns_accounts`、`t_influencer_agent_assignments` |
| **CASCADE** | 親子関係が強い1対多。親削除時に子も連動削除 | IF→住所・口座・請求先、1対1セキュリティテーブル、パートナー→区分、SNSアカウント→カテゴリ紐付け |
| **SET NULL** | 任意の参照。親削除時にNULL化して関連を切る | パートナー→IF兼業、IF→国、広告→クライアント/担当者 |

> [!NOTE]
> **SNSアカウント・担当割当が RESTRICT の理由**: SNSアカウントはキャンペーン実績や集計データと紐付く可能性があり、安易な連動削除はデータ損失リスクがある。担当割当も履歴として保持すべきため、IF削除前に明示的な解除が必要。

#### 集計テーブルの方針
- **集計テーブル**: 外部キー制約あり + スナップショット方式
  - `t_daily_performance_details` → `m_partners`, `t_partner_sites`, `m_clients`, `m_ad_contents`
  - `t_daily_click_details` → `t_partner_sites`
  - **FK制約**: データ整合性を担保（ON DELETE RESTRICT）
  - **スナップショット**: 名前カラム（partner_name等）を非正規化して保持し、集計時点の名称を記録

#### 命名規則
```sql
CONSTRAINT fk_{table}_{column}
  FOREIGN KEY (column)
  REFERENCES parent_table(parent_column)
  ON DELETE RESTRICT
```

### 5. インデックス設計

#### 作成基準
1. **外部キー**: 必ず作成
2. **検索条件**: 頻繁に使用するカラム
3. **ソート条件**: ORDER BY に使用するカラム
4. **結合条件**: JOIN に使用するカラム
5. **複合インデックス**: 複数カラムで頻繁に検索する場合

#### 命名規則
```sql
-- 単一カラム
CREATE INDEX idx_{table}_{column} ON table(column);

-- 複合インデックス
CREATE INDEX idx_{table}_{col1}_{col2} ON table(col1, col2);

-- 部分インデックス（WHERE条件付き）
CREATE INDEX idx_{table}_{column} ON table(column)
  WHERE is_active = TRUE;
```

### 6. 正規化レベル

- **第3正規形（3NF）完全準拠**
- **非正規化の禁止**: 集計テーブル以外
- **冗長性の排除**: すべての推移的関数従属性を除去

### 7. 辞書テーブル（コード値マスタ）の判断基準

#### 作成する場合
- 階層構造を持つ
- 頻繁に追加・変更される
- 関連属性が多い（名前だけでない）
- 例: `m_categories`, `m_departments`, `m_countries`

#### 作成しない場合（コメント管理）
- 種類が少ない（10個未満）
- ほぼ固定
- 名前以外の属性がない
- 例: `address_type_id` (1:自宅, 2:お届け先), `billing_type_id` (1:個人, 2:法人)
```sql
-- コメントでの管理例
COMMENT ON COLUMN t_addresses.address_type_id IS
  '住所タイプID（1: 自宅, 2: お届け先）';
```

### 8. NULL許容の原則

#### NULL を許容する場合
- 任意項目（業務上必須でない）
- 期間の終了日（無期限を表現）
- 親子関係のルートノード（parent_id）
- オプション機能の設定値

#### NULL を許容しない場合
- 主キー
- 外部キー（リレーションが必須の場合）
- 監査カラム
- 業務上必須の項目

---

## テーブル構成

### 全体像（32テーブル）

#### マスタテーブル（15テーブル）

| #   | テーブル名                 | 日本語名         | 主な用途               |
| --- | --------------------- | ------------ | ------------------ |
| 1   | m_countries           | 国マスタ         | 国際化対応・ISO準拠        |
| 2   | m_departments         | 部署マスタ（階層）    | 組織階層管理             |
| 3   | m_categories          | カテゴリマスタ（2階層） | IFのジャンル分類          |
| 4   | m_agents              | エージェント       | 社内担当者管理            |
| 5   | m_agent_role_types    | エージェント役割     | 役割・権限定義            |
| 6   | m_agent_security      | エージェント認証     | パスワード・セッション管理      |
| 7   | m_influencers         | インフルエンサー     | IFプロファイル管理         |
| 8   | m_influencer_security | IF認証         | パスワード・セッション管理      |
| 9   | m_ad_groups           | 広告グループ       | 広告の大分類             |
| 10  | m_clients             | クライアント       | 広告主企業              |
| 11  | m_ad_contents         | 広告コンテンツ      | 具体的な広告素材           |
| 12  | m_partners            | パートナー        | ASP・広告配信パートナー      |
| 13  | m_partners_division   | パートナー区分      | IF卸/トータルマーケ        |
| 14  | m_sns_platforms       | SNSプラットフォーム  | YouTube/Instagram等 |
| 15  | m_campaigns           | キャンペーン（加工用）  | 案件管理               |

#### トランザクションテーブル（16テーブル）

| # | テーブル名 | 日本語名 | 主な用途 |
|---|-----------|---------|---------|
| 1 | t_partner_sites | パートナーサイト | パートナーが運営するサイト |
| 2 | t_influencer_sns_accounts | SNSアカウント | SNS別アカウント管理 |
| 3 | t_account_categories | アカウント×カテゴリ | 多対多中間テーブル |
| 4 | t_addresses | 住所 | 請求先・送付先住所 |
| 5 | t_bank_accounts | 銀行口座（国内・海外） | 振込先口座情報 |
| 6 | t_billing_info | 請求先（インボイス対応） | 請求書発行情報 |
| 7 | t_unit_prices | 単価設定 | サイト・コンテンツ別単価 |
| 8 | t_influencer_agent_assignments | 担当割当 | 担当者アサイン管理 |
| 9 | t_notifications | 通知 | 各種通知管理 |
| 10 | t_translations | 翻訳 | 多言語対応（汎用） |
| 11 | t_files | ファイル管理 | 画像・PDF等のメタデータ |
| 12 | t_audit_logs | 監査ログ（JSONB） | 全テーブル横断的な履歴 |
| 13 | t_daily_performance_details | 日次CV集計（パーティション） | パフォーマンスデータ |
| 14 | t_daily_click_details | 日次クリック集計（パーティション） | クリックデータ |
| 15 | t_billing_runs | 請求確定バッチ | 請求確定スナップショット |
| 16 | t_billing_line_items | 請求明細 | 確定済み請求明細 |

#### システムテーブル（1テーブル）

| # | テーブル名 | 日本語名 | 主な用途 |
|---|-----------|---------|---------|
| 1 | ingestion_logs | BQ取り込みログ | BigQuery連携ジョブ管理 |

### テーブル間リレーション概要

#### 中心的なエンティティ
1. **m_influencers（インフルエンサー）**
   - 住所、口座、請求先、認証、SNSアカウント、担当者割当と紐付く

2. **m_partners（パートナー）**
   - サイト、日次集計と紐付く
   - インフルエンサーとの兼業管理（influencer_id）

3. **m_campaigns（キャンペーン・加工用）**
   - サイト、インフルエンサー、プラットフォームと紐付く

#### リレーション概要図（テキスト版）
```
m_countries
  └─ m_influencers, t_addresses, t_bank_accounts

m_categories（階層）
  └─ t_account_categories
       └─ t_influencer_sns_accounts
            └─ m_influencers

m_departments（階層）
  └─ m_agents
       ├─ m_agent_security
       ├─ t_influencer_agent_assignments
       └─ t_audit_logs（operator_type=1）

m_influencers
  ├─ t_addresses
  ├─ t_bank_accounts
  ├─ t_billing_info
  ├─ m_influencer_security
  ├─ t_influencer_sns_accounts
  ├─ t_influencer_agent_assignments
  ├─ t_audit_logs（operator_type=2）
  ├─ m_campaigns
  └─ m_partners（兼業管理 influencer_id）

m_partners
  ├─ t_partner_sites
  │    ├─ t_unit_prices
  │    └─ m_campaigns
  └─ t_daily_performance_details

m_partners ─── m_partners_division（1:1・BQ/ASP ID一致）

m_campaigns
  ├─ t_partner_sites（site_id）
  ├─ m_influencers（influencer_id）
  └─ m_sns_platforms（platform_id）

t_unit_prices
  ├─ t_partner_sites
  ├─ m_ad_contents
  └─ m_clients

t_daily_performance_details（スナップショット方式・FK制約あり）
  ├─ m_partners（partner_id）
  ├─ t_partner_sites（site_id）
  ├─ m_clients（client_id）
  └─ m_ad_contents（content_id）

t_daily_click_details（スナップショット方式・FK制約あり）
  └─ t_partner_sites（site_id）

t_billing_runs（請求確定バッチ・論理削除方式）
  └─ m_agents（confirmed_by / cancelled_by）

t_billing_line_items（請求確定明細・スナップショット方式）
  ├─ t_billing_runs（billing_run_id）
  ├─ m_partners（partner_id）
  ├─ t_partner_sites（site_id）
  ├─ m_clients（client_id）
  └─ m_ad_contents（content_id）

m_ad_groups
  └─ m_ad_contents

m_clients
  ├─ m_ad_contents
  ├─ t_unit_prices
  └─ t_daily_performance_details

m_sns_platforms
  ├─ t_influencer_sns_accounts
  └─ m_campaigns

m_agent_role_types
  └─ t_influencer_agent_assignments

t_notifications（汎用・FKなし）
  └─ user_type + user_id でエージェント/IF/パートナーへの通知を管理

t_translations（汎用・FKなし）
  └─ table_name + record_id + column_name + language_code で任意テーブルの翻訳を管理

t_files（汎用・FKなし）
  └─ entity_type + entity_id で任意エンティティのファイルメタデータを管理

ingestion_logs（システム）
  └─ BQ取り込みジョブの実行履歴
```

> [!NOTE]
> **ポリモーフィックテーブルの番号体系**: 1=Agent, 2=Influencer は全テーブル共通。3番以降は用途に応じて拡張:
> - `t_audit_logs.operator_type`: 1: Agent, 2: Influencer（パートナーの直接操作は現時点で想定しないため2種のみ）
> - `t_notifications.user_type`: 1: Agent, 2: Influencer, 3: Partner
> - `t_files.entity_type`: 1: Agent, 2: Influencer, 3: Partner, 4: AdContent, 5: Campaign

---

## ER図

### 全体ER図（Mermaid）
```mermaid
erDiagram
    %% ============================================================
    %% 🌏 国・カテゴリ系マスタ
    %% ============================================================

    m_countries ||--o{ t_addresses : "country_id"
    m_countries ||--o{ t_bank_accounts : "country_id"
    m_countries ||--o{ m_influencers : "country_id"

    m_categories ||--o{ m_categories : "parent_category_id (階層)"
    m_categories ||--o{ t_account_categories : "category_id"

    %% ============================================================
    %% 🏢 組織・エージェント系マスタ
    %% ============================================================

    m_departments ||--o{ m_departments : "parent_department_id (階層)"
    m_departments ||--o{ m_agents : "department_id"

    m_agents ||--o| m_agent_security : "agent_id (1対1)"
    m_agents ||--o{ t_influencer_agent_assignments : "agent_id"
    m_agents ||--o{ t_audit_logs : "operator_type=1, operator_id"
    m_influencers ||--o{ t_audit_logs : "operator_type=2, operator_id"

    m_agent_role_types ||--o{ t_influencer_agent_assignments : "role_type_id"

    %% ============================================================
    %% 📱 SNS・カテゴリ系
    %% ============================================================

    m_sns_platforms ||--o{ t_influencer_sns_accounts : "platform_id"

    t_influencer_sns_accounts ||--o{ t_account_categories : "account_id"

    %% ============================================================
    %% 📢 広告・クライアント系
    %% ============================================================

    m_ad_groups ||--o{ m_ad_contents : "ad_group_id"
    m_agents ||--o{ m_ad_contents : "person_id"
    m_clients ||--o{ m_ad_contents : "client_id"

    m_ad_contents ||--o{ t_unit_prices : "content_id"
    m_ad_contents ||--o{ t_daily_performance_details : "content_id"

    m_clients ||--o{ t_unit_prices : "client_id"
    m_clients ||--o{ t_daily_performance_details : "client_id"

    %% ============================================================
    %% 👤 インフルエンサー系
    %% ============================================================

    m_influencers ||--o| m_influencer_security : "influencer_id (1対1)"
    m_influencers ||--o{ t_addresses : "influencer_id"
    m_influencers ||--o{ t_bank_accounts : "influencer_id"
    m_influencers ||--o{ t_billing_info : "influencer_id"
    m_influencers ||--o{ t_influencer_sns_accounts : "influencer_id"
    m_influencers ||--o{ t_influencer_agent_assignments : "influencer_id"
    m_influencers ||--o{ m_campaigns : "influencer_id"

    %% ============================================================
    %% 🤝 パートナー系
    %% ============================================================

    m_influencers ||--o{ m_partners : "influencer_id (兼業)"

    m_partners ||--o{ t_partner_sites : "partner_id"
    m_partners ||--o{ t_daily_performance_details : "partner_id"
    m_partners ||--|| m_partners_division : "partner_id"

    t_partner_sites ||--o{ t_unit_prices : "site_id"
    t_partner_sites ||--o{ m_campaigns : "site_id"
    t_partner_sites ||--o{ t_daily_performance_details : "site_id"
    t_partner_sites ||--o{ t_daily_click_details : "site_id"

    %% ============================================================
    %% 🔔 通知
    %% ============================================================

    t_notifications {
        BIGINT notification_id PK
        BIGINT user_id
        SMALLINT user_type
        TEXT notification_type
        TEXT title
        BOOLEAN is_read
    }

    t_translations {
        BIGINT translation_id PK
        TEXT table_name
        BIGINT record_id
        TEXT column_name
        TEXT language_code
        TEXT translated_value
    }

    t_files {
        BIGINT file_id PK
        SMALLINT entity_type
        BIGINT entity_id
        TEXT file_category
        TEXT file_name
        TEXT storage_path
    }

    %% ============================================================
    %% 💰 請求確定系
    %% ============================================================

    m_agents ||--o{ t_billing_runs : "confirmed_by"
    t_billing_runs ||--o{ t_billing_line_items : "billing_run_id"
    m_partners ||--o{ t_billing_line_items : "partner_id"
    t_partner_sites ||--o{ t_billing_line_items : "site_id"
    m_clients ||--o{ t_billing_line_items : "client_id"
    m_ad_contents ||--o{ t_billing_line_items : "content_id"

    %% ============================================================
    %% 📊 キャンペーン（加工用）
    %% ============================================================

    m_sns_platforms ||--o{ m_campaigns : "platform_id"

    %% ============================================================
    %% テーブル定義（主要カラムのみ）
    %% ============================================================

    m_agent_role_types {
        SMALLINT role_type_id PK
        TEXT role_name
        TEXT role_code
    }

    t_addresses {
        BIGINT address_id PK
        BIGINT influencer_id FK
        SMALLINT country_id FK
    }

    t_bank_accounts {
        BIGINT bank_account_id PK
        BIGINT influencer_id FK
        SMALLINT country_id FK
    }

    t_billing_info {
        BIGINT billing_info_id PK
        BIGINT influencer_id FK
    }

    t_influencer_agent_assignments {
        BIGINT assignment_id PK
        BIGINT influencer_id FK
        BIGINT agent_id FK
        SMALLINT role_type_id FK
    }

    t_audit_logs {
        TIMESTAMPTZ operated_at PK
        BIGINT log_id PK
        TEXT table_name
        BIGINT record_id
        SMALLINT operator_type
        BIGINT operator_id
    }

    m_countries {
        SMALLINT country_id PK
        TEXT country_name
        TEXT country_code
        TEXT currency_code
    }

    m_categories {
        BIGINT category_id PK
        BIGINT parent_category_id FK
        TEXT category_name
    }

    m_departments {
        BIGINT department_id PK
        BIGINT parent_department_id FK
        TEXT department_name
    }

    m_agents {
        BIGINT agent_id PK
        TEXT login_id UK
        BIGINT department_id FK
        TEXT agent_name
    }

    m_agent_security {
        BIGINT agent_id PK_FK
        TEXT password_hash
    }

    m_influencers {
        BIGINT influencer_id PK
        TEXT login_id UK
        TEXT influencer_name
        SMALLINT country_id FK
    }

    m_influencer_security {
        BIGINT influencer_id PK_FK
        TEXT password_hash
    }

    m_sns_platforms {
        BIGINT platform_id PK
        TEXT platform_name
    }

    m_ad_groups {
        BIGINT ad_group_id PK
        TEXT ad_group_name
    }

    m_ad_contents {
        BIGINT content_id PK
        BIGINT ad_group_id FK
        BIGINT client_id FK
        TEXT ad_name
    }

    m_clients {
        BIGINT client_id PK
        TEXT client_name
        TEXT industry
    }

    m_partners {
        BIGINT partner_id PK
        TEXT partner_name
        BIGINT influencer_id FK
    }

    m_partners_division {
        BIGINT partner_id PK
        TEXT partner_name
        SMALLINT division_type
        BOOLEAN is_comprehensive
        BOOLEAN is_excluded
    }

    m_campaigns {
        BIGINT campaign_id PK
        BIGINT site_id FK
        BIGINT influencer_id FK
        BIGINT platform_id FK
    }

    t_partner_sites {
        BIGINT site_id PK
        BIGINT partner_id FK
        TEXT site_name
    }

    t_unit_prices {
        BIGINT unit_price_id PK
        BIGINT site_id FK
        BIGINT content_id FK
        BIGINT client_id FK
        DECIMAL unit_price
    }

    t_daily_performance_details {
        DATE action_date PK
        BIGINT partner_id PK_FK
        BIGINT site_id PK_FK
        BIGINT client_id PK_FK
        BIGINT content_id PK_FK
        SMALLINT status_id PK
        INTEGER cv_count
        DECIMAL client_action_cost
    }

    t_daily_click_details {
        DATE action_date PK
        BIGINT site_id PK_FK
        INTEGER click_count
    }

    t_billing_runs {
        BIGINT billing_run_id PK
        DATE billing_period_from
        DATE billing_period_to
        JSONB filter_conditions
        BIGINT confirmed_by FK
        BOOLEAN is_cancelled
    }

    t_billing_line_items {
        BIGINT line_item_id PK
        BIGINT billing_run_id FK
        DATE action_date
        BIGINT partner_id FK
        BIGINT site_id FK
        BIGINT client_id FK
        BIGINT content_id FK
        INTEGER cv_count
        DECIMAL amount
    }

    ingestion_logs {
        BIGINT ingestion_id PK
        TEXT job_type
        TEXT status
        INTEGER records_count
    }
```

---

## テーブル詳細定義

> [!NOTE]
> **掲載順序について**: 本セクションのテーブル掲載順はカテゴリ別の論理的なグルーピングであり、DDL実行順ではありません。実際のDDL実行時は、FK参照先テーブルを先に作成するか、`ALTER TABLE ... ADD CONSTRAINT` で後からFK制約を追加してください。

### 1. m_countries（国マスタ）

#### 概要
ISO 3166-1準拠の国マスタ。国際化対応の基盤テーブル。

#### CREATE文
```sql
CREATE TABLE m_countries (
  country_id SMALLINT PRIMARY KEY,
  country_name TEXT NOT NULL UNIQUE,
  country_code TEXT NOT NULL UNIQUE,
  country_code_3 TEXT NOT NULL UNIQUE,
  currency_code TEXT NOT NULL,
  phone_prefix TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  display_order INTEGER NOT NULL DEFAULT 0,
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_countries_active ON m_countries(is_active, display_order);

COMMENT ON TABLE m_countries IS '国マスタ（ISO 3166-1準拠）';
COMMENT ON COLUMN m_countries.country_id IS '主キー（PK）';
COMMENT ON COLUMN m_countries.country_name IS '国名（例: 日本）';
COMMENT ON COLUMN m_countries.country_code IS '国コード2文字（ISO 3166-1 alpha-2 / 例: JP）';
COMMENT ON COLUMN m_countries.country_code_3 IS '国コード3文字（ISO 3166-1 alpha-3 / 例: JPN）';
COMMENT ON COLUMN m_countries.currency_code IS '通貨コード（ISO 4217 / 例: JPY）';
COMMENT ON COLUMN m_countries.phone_prefix IS '電話番号プレフィックス（例: +81）';
COMMENT ON COLUMN m_countries.is_active IS '有効フラグ（TRUE: 有効, FALSE: 無効）';
COMMENT ON COLUMN m_countries.display_order IS '表示順（昇順ソート用）';
```

---

### 2. m_categories（カテゴリマスタ・2階層）

#### 概要
インフルエンサーのジャンル分類。親子2階層構造。

#### CREATE文
```sql
CREATE TABLE m_categories (
  category_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  parent_category_id BIGINT,
  category_name TEXT NOT NULL,
  category_code TEXT NOT NULL,
  category_description TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  display_order INTEGER NOT NULL DEFAULT 0,
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_category_parent
    FOREIGN KEY (parent_category_id)
    REFERENCES m_categories(category_id)
    ON DELETE RESTRICT,

  CONSTRAINT uq_category_code UNIQUE (category_code)
);

CREATE INDEX idx_categories_parent ON m_categories(parent_category_id);
CREATE INDEX idx_categories_active ON m_categories(is_active, display_order);

COMMENT ON TABLE m_categories IS 'カテゴリマスタ（2階層: 大カテゴリ・小カテゴリ）';
COMMENT ON COLUMN m_categories.parent_category_id IS '親カテゴリID（NULL=大カテゴリ）';
COMMENT ON COLUMN m_categories.category_id IS '主キー（PK）。自動採番';
COMMENT ON COLUMN m_categories.category_name IS 'カテゴリ名（例: 美容, ファッション）';
COMMENT ON COLUMN m_categories.category_code IS 'カテゴリコード（ユニーク）';
COMMENT ON COLUMN m_categories.category_description IS 'カテゴリ説明';
COMMENT ON COLUMN m_categories.is_active IS '有効フラグ（TRUE: 有効, FALSE: 無効）';
COMMENT ON COLUMN m_categories.display_order IS '表示順（昇順ソート用）';
```

---

### 3. m_departments（部署マスタ・階層）

#### 概要
組織階層管理。親子構造で事業部→部門を表現。

#### CREATE文
```sql
CREATE TABLE m_departments (
  department_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  parent_department_id BIGINT,
  department_name TEXT NOT NULL,
  department_code TEXT NOT NULL UNIQUE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  display_order INTEGER NOT NULL DEFAULT 0,
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_department_parent
    FOREIGN KEY (parent_department_id)
    REFERENCES m_departments(department_id)
    ON DELETE RESTRICT
);

CREATE INDEX idx_departments_parent ON m_departments(parent_department_id);
CREATE INDEX idx_departments_active ON m_departments(is_active, display_order);

COMMENT ON TABLE m_departments IS '部署マスタ（階層構造対応）';
COMMENT ON COLUMN m_departments.parent_department_id IS '親部署ID（NULL=トップレベル）';
COMMENT ON COLUMN m_departments.department_id IS '主キー（PK）。自動採番';
COMMENT ON COLUMN m_departments.department_name IS '部署名';
COMMENT ON COLUMN m_departments.department_code IS '部署コード（ユニーク）';
COMMENT ON COLUMN m_departments.is_active IS '有効フラグ（TRUE: 有効, FALSE: 無効）';
COMMENT ON COLUMN m_departments.display_order IS '表示順（昇順ソート用）';
```

---

### 4. m_agents（エージェントマスタ）

#### 概要
社内担当者（営業・マーケ・企画）のマスタ。

#### CREATE文
```sql
CREATE TABLE m_agents (
  agent_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  -- 基本情報
  agent_name TEXT NOT NULL,
  email_address TEXT NOT NULL UNIQUE,
  login_id TEXT NOT NULL UNIQUE,
  -- 組織情報
  department_id BIGINT NOT NULL,
  job_title TEXT,
  join_date DATE,
  -- ステータス
  status_id SMALLINT NOT NULL DEFAULT 1,
  -- 監査
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_agent_department
    FOREIGN KEY (department_id)
    REFERENCES m_departments(department_id)
    ON DELETE RESTRICT,

  CONSTRAINT chk_agent_status CHECK (status_id IN (1, 2, 3))
);

CREATE INDEX idx_agents_department_status ON m_agents(department_id, status_id);
CREATE INDEX idx_agents_status ON m_agents(status_id)
  WHERE status_id = 1;
CREATE INDEX idx_agents_name ON m_agents(agent_name);

COMMENT ON TABLE m_agents IS 'エージェント（社内担当者）マスタ';
COMMENT ON COLUMN m_agents.agent_id IS '主キー（PK）。自動採番';
COMMENT ON COLUMN m_agents.agent_name IS '氏名（フルネーム）';
COMMENT ON COLUMN m_agents.email_address IS '連絡用メールアドレス（ユニーク）';
COMMENT ON COLUMN m_agents.login_id IS '管理画面ログイン用ID（ユニーク）';
COMMENT ON COLUMN m_agents.department_id IS '所属部署（FK → m_departments）';
COMMENT ON COLUMN m_agents.job_title IS '役職（例: マネージャー, リーダー）';
COMMENT ON COLUMN m_agents.join_date IS '入社年月日';
COMMENT ON COLUMN m_agents.status_id IS 'ステータス（1: 現役, 2: 退任, 3: 休職）';
```

---

### 5. m_agent_role_types（エージェント役割マスタ）

#### 概要
担当者の役割定義（メイン・サブ・スカウト）。

#### CREATE文
```sql
CREATE TABLE m_agent_role_types (
  role_type_id SMALLINT PRIMARY KEY,
  -- 基本情報
  role_name TEXT NOT NULL UNIQUE,
  role_code TEXT NOT NULL UNIQUE,
  description TEXT,
  -- 権限設定
  can_edit_profile BOOLEAN NOT NULL DEFAULT FALSE,
  can_approve_content BOOLEAN NOT NULL DEFAULT FALSE,
  -- 表示制御
  display_order INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  -- 監査
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_agent_role_types_active ON m_agent_role_types(is_active, display_order);

COMMENT ON TABLE m_agent_role_types IS '役割マスタテーブル';
COMMENT ON COLUMN m_agent_role_types.role_type_id IS '主キー（PK）';
COMMENT ON COLUMN m_agent_role_types.role_name IS '役割名';
COMMENT ON COLUMN m_agent_role_types.role_code IS '役割コード';
COMMENT ON COLUMN m_agent_role_types.description IS '説明';
COMMENT ON COLUMN m_agent_role_types.can_edit_profile IS 'プロフィール編集権限';
COMMENT ON COLUMN m_agent_role_types.can_approve_content IS 'コンテンツ承認権限';
COMMENT ON COLUMN m_agent_role_types.display_order IS '表示順（昇順ソート用）';
COMMENT ON COLUMN m_agent_role_types.is_active IS '有効フラグ（TRUE: 有効, FALSE: 無効）';
```

---

### 6. m_agent_security（エージェント認証）

#### 概要
エージェント用の認証情報（1対1）。

#### CREATE文
```sql
CREATE TABLE m_agent_security (
  agent_id BIGINT PRIMARY KEY,
  -- 認証情報
  password_hash TEXT NOT NULL,
  -- セッション管理
  session_token TEXT,
  session_expires_at TIMESTAMPTZ,
  -- パスワード管理
  password_changed_at TIMESTAMPTZ,
  password_reset_token TEXT,
  reset_token_expires_at TIMESTAMPTZ,
  -- セキュリティ
  failed_login_attempts SMALLINT NOT NULL DEFAULT 0,
  locked_until TIMESTAMPTZ,
  -- 監査
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_security_agent
    FOREIGN KEY (agent_id)
    REFERENCES m_agents(agent_id)
    ON DELETE CASCADE
);

CREATE INDEX idx_agent_security_session ON m_agent_security(session_token)
  WHERE session_token IS NOT NULL;
CREATE INDEX idx_agent_security_locked ON m_agent_security(agent_id, locked_until)
  WHERE locked_until IS NOT NULL;
CREATE INDEX idx_agent_security_password_changed ON m_agent_security(password_changed_at);
CREATE INDEX idx_agent_security_reset_token ON m_agent_security(password_reset_token)
  WHERE password_reset_token IS NOT NULL;

COMMENT ON TABLE m_agent_security IS 'エージェント認証・セキュリティ情報（1対1）';
COMMENT ON COLUMN m_agent_security.agent_id IS 'エージェントID（PK・FK）';
COMMENT ON COLUMN m_agent_security.password_hash IS 'パスワードハッシュ（bcrypt等）';
COMMENT ON COLUMN m_agent_security.session_token IS 'セッショントークン';
COMMENT ON COLUMN m_agent_security.session_expires_at IS 'セッション有効期限';
COMMENT ON COLUMN m_agent_security.password_changed_at IS 'パスワード変更日時';
COMMENT ON COLUMN m_agent_security.password_reset_token IS 'パスワードリセットトークン';
COMMENT ON COLUMN m_agent_security.reset_token_expires_at IS 'リセットトークン有効期限';
COMMENT ON COLUMN m_agent_security.failed_login_attempts IS 'ログイン失敗回数';
COMMENT ON COLUMN m_agent_security.locked_until IS 'アカウントロック解除日時';
```

---

### 7. t_addresses（住所情報）

#### 概要
インフルエンサーの住所管理。自宅・お届け先を区別。

#### CREATE文
```sql
CREATE TABLE t_addresses (
  address_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  -- 紐付け
  influencer_id BIGINT NOT NULL,
  address_type_id SMALLINT NOT NULL,
  -- 基本情報
  recipient_name TEXT,
  country_id SMALLINT NOT NULL DEFAULT 1,
  zip_code TEXT,
  state_province TEXT,
  city TEXT,
  address_line1 TEXT,
  address_line2 TEXT,
  phone_number TEXT,
  -- フラグ
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  -- 有効期間
  valid_from DATE,
  valid_to DATE,
  -- 監査
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_address_influencer
    FOREIGN KEY (influencer_id)
    REFERENCES m_influencers(influencer_id)
    ON DELETE CASCADE,

  CONSTRAINT fk_address_country
    FOREIGN KEY (country_id)
    REFERENCES m_countries(country_id)
    ON DELETE RESTRICT
);

CREATE INDEX idx_addresses_influencer ON t_addresses(influencer_id, is_active);
CREATE INDEX idx_addresses_primary ON t_addresses(influencer_id, is_primary)
  WHERE is_primary = TRUE;
CREATE UNIQUE INDEX uq_addresses_primary
  ON t_addresses(influencer_id) WHERE is_primary = TRUE;
CREATE INDEX idx_addresses_type ON t_addresses(address_type_id);
CREATE INDEX idx_addresses_country ON t_addresses(country_id);
CREATE INDEX idx_addresses_valid ON t_addresses(influencer_id, valid_from, valid_to)
  WHERE is_active = TRUE;

COMMENT ON TABLE t_addresses IS '住所情報テーブル';
COMMENT ON COLUMN t_addresses.address_type_id IS '住所タイプID（1: 自宅, 2: お届け先）';
COMMENT ON COLUMN t_addresses.recipient_name IS '受取人名';
COMMENT ON COLUMN t_addresses.influencer_id IS 'インフルエンサーID（FK → m_influencers）';
COMMENT ON COLUMN t_addresses.country_id IS '国ID（FK → m_countries）';
COMMENT ON COLUMN t_addresses.valid_from IS '有効期間開始日';
COMMENT ON COLUMN t_addresses.valid_to IS '有効期間終了日';
COMMENT ON COLUMN t_addresses.address_id IS '主キー（PK）。自動採番';
COMMENT ON COLUMN t_addresses.zip_code IS '郵便番号';
COMMENT ON COLUMN t_addresses.state_province IS '都道府県・州';
COMMENT ON COLUMN t_addresses.city IS '市区町村';
COMMENT ON COLUMN t_addresses.address_line1 IS '住所1（番地まで）';
COMMENT ON COLUMN t_addresses.address_line2 IS '住所2（建物名等）';
COMMENT ON COLUMN t_addresses.phone_number IS '電話番号';
COMMENT ON COLUMN t_addresses.is_primary IS 'メイン住所フラグ';
COMMENT ON COLUMN t_addresses.is_active IS '有効フラグ（TRUE: 有効, FALSE: 無効）';
```

---

### 8. t_bank_accounts（銀行口座）

#### 概要
インフルエンサーの振込先口座情報。国内・海外口座対応。

#### CREATE文
```sql
CREATE TABLE t_bank_accounts (
  bank_account_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  -- 紐付け
  influencer_id BIGINT NOT NULL,
  -- 通貨・国
  currency_code TEXT NOT NULL,
  country_id SMALLINT NOT NULL,
  -- 国内口座（日本）
  bank_name TEXT,
  branch_name TEXT,
  branch_code TEXT,
  account_type SMALLINT,
  account_number TEXT,
  account_holder_name TEXT,
  -- 海外口座
  swift_bic_code TEXT,
  iban TEXT,
  overseas_account_number TEXT,
  routing_number TEXT,
  bank_address TEXT,
  -- フラグ
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  -- 有効期間
  valid_from DATE,
  valid_to DATE,
  -- 監査
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_bank_account_influencer
    FOREIGN KEY (influencer_id)
    REFERENCES m_influencers(influencer_id)
    ON DELETE CASCADE,

  CONSTRAINT fk_bank_account_country
    FOREIGN KEY (country_id)
    REFERENCES m_countries(country_id)
    ON DELETE RESTRICT
);

CREATE INDEX idx_bank_accounts_influencer ON t_bank_accounts(influencer_id, is_active);
CREATE INDEX idx_bank_accounts_primary ON t_bank_accounts(influencer_id, is_primary)
  WHERE is_primary = TRUE;
CREATE UNIQUE INDEX uq_bank_accounts_primary
  ON t_bank_accounts(influencer_id) WHERE is_primary = TRUE;
CREATE INDEX idx_bank_accounts_country ON t_bank_accounts(country_id);
CREATE INDEX idx_bank_accounts_currency ON t_bank_accounts(currency_code);
CREATE INDEX idx_bank_accounts_valid ON t_bank_accounts(influencer_id, valid_from, valid_to)
  WHERE is_active = TRUE;

COMMENT ON TABLE t_bank_accounts IS '銀行口座情報テーブル（国内・海外対応）';
COMMENT ON COLUMN t_bank_accounts.influencer_id IS 'インフルエンサーID（FK → m_influencers）';
COMMENT ON COLUMN t_bank_accounts.currency_code IS '通貨コード（ISO 4217）';
COMMENT ON COLUMN t_bank_accounts.country_id IS '国ID（FK → m_countries）';
COMMENT ON COLUMN t_bank_accounts.account_type IS '口座種別（1: 普通, 2: 当座）';
COMMENT ON COLUMN t_bank_accounts.swift_bic_code IS 'SWIFTコード/BICコード';
COMMENT ON COLUMN t_bank_accounts.iban IS 'IBAN（国際銀行口座番号）';
COMMENT ON COLUMN t_bank_accounts.overseas_account_number IS '海外口座番号';
COMMENT ON COLUMN t_bank_accounts.routing_number IS 'ルーティング番号（米国）';
COMMENT ON COLUMN t_bank_accounts.bank_address IS '銀行住所';
COMMENT ON COLUMN t_bank_accounts.valid_from IS '有効期間開始日';
COMMENT ON COLUMN t_bank_accounts.valid_to IS '有効期間終了日';
COMMENT ON COLUMN t_bank_accounts.bank_account_id IS '主キー（PK）。自動採番';
COMMENT ON COLUMN t_bank_accounts.bank_name IS '銀行名';
COMMENT ON COLUMN t_bank_accounts.branch_name IS '支店名';
COMMENT ON COLUMN t_bank_accounts.branch_code IS '支店コード';
COMMENT ON COLUMN t_bank_accounts.account_number IS '口座番号（国内）';
COMMENT ON COLUMN t_bank_accounts.account_holder_name IS '口座名義';
COMMENT ON COLUMN t_bank_accounts.is_primary IS 'メイン口座フラグ';
COMMENT ON COLUMN t_bank_accounts.is_active IS '有効フラグ（TRUE: 有効, FALSE: 無効）';
```

---

### 9. t_billing_info（請求先情報）

#### 概要
請求書発行用の情報（インボイス対応）。

#### CREATE文
```sql
CREATE TABLE t_billing_info (
  billing_info_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  -- 紐付け
  influencer_id BIGINT NOT NULL,
  -- 基本情報
  billing_name TEXT NOT NULL,
  billing_department TEXT,
  billing_contact_person TEXT,
  -- 請求情報
  billing_type_id SMALLINT,
  invoice_tax_id TEXT,
  purchase_order_status_id SMALLINT CHECK (purchase_order_status_id IN (1, 2, 3, 9)),
  evidence_url TEXT,
  -- フラグ
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  -- 有効期間
  valid_from DATE,
  valid_to DATE,
  -- 監査
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_billing_influencer
    FOREIGN KEY (influencer_id)
    REFERENCES m_influencers(influencer_id)
    ON DELETE CASCADE
);

CREATE INDEX idx_billing_info_influencer ON t_billing_info(influencer_id, is_active);
CREATE INDEX idx_billing_info_primary ON t_billing_info(influencer_id, is_primary)
  WHERE is_primary = TRUE;
CREATE UNIQUE INDEX uq_billing_info_primary
  ON t_billing_info(influencer_id) WHERE is_primary = TRUE;
CREATE INDEX idx_billing_info_type ON t_billing_info(billing_type_id);
CREATE INDEX idx_billing_info_invoice ON t_billing_info(invoice_tax_id)
  WHERE invoice_tax_id IS NOT NULL;
CREATE INDEX idx_billing_info_valid ON t_billing_info(influencer_id, valid_from, valid_to)
  WHERE is_active = TRUE;

COMMENT ON TABLE t_billing_info IS '請求先情報テーブル（インボイス対応）';
COMMENT ON COLUMN t_billing_info.influencer_id IS 'インフルエンサーID（FK → m_influencers）';
COMMENT ON COLUMN t_billing_info.billing_name IS '請求先名（会社名・屋号）';
COMMENT ON COLUMN t_billing_info.billing_department IS '部署名';
COMMENT ON COLUMN t_billing_info.billing_contact_person IS '担当者名';
COMMENT ON COLUMN t_billing_info.billing_type_id IS '報酬体系ID（1: 固定報酬, 2: 成果報酬, 3: 予算型）';
COMMENT ON COLUMN t_billing_info.invoice_tax_id IS 'インボイス番号';
COMMENT ON COLUMN t_billing_info.purchase_order_status_id IS '発注書ステータスID（1: 未発行, 2: 発行済, 3: 承認済, 9: 取消）';
COMMENT ON COLUMN t_billing_info.evidence_url IS '証明書URL';
COMMENT ON COLUMN t_billing_info.valid_from IS '有効期間開始日';
COMMENT ON COLUMN t_billing_info.valid_to IS '有効期間終了日';
COMMENT ON COLUMN t_billing_info.billing_info_id IS '主キー（PK）。自動採番';
COMMENT ON COLUMN t_billing_info.is_primary IS 'メイン請求先フラグ';
COMMENT ON COLUMN t_billing_info.is_active IS '有効フラグ（TRUE: 有効, FALSE: 無効）';
```

---

### 10. m_ad_groups（広告グループ）

#### 概要
広告の大分類（プロジェクト単位）。

#### CREATE文
```sql
CREATE TABLE m_ad_groups (
  ad_group_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  -- 基本情報
  ad_group_name TEXT NOT NULL,
  -- 監査
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ad_groups_name ON m_ad_groups(ad_group_name);

COMMENT ON TABLE m_ad_groups IS '広告グループ（案件・キャンペーン）マスタ';
COMMENT ON COLUMN m_ad_groups.ad_group_id IS '主キー（PK）。groupIdに相当';
COMMENT ON COLUMN m_ad_groups.ad_group_name IS '広告グループ名';
```

---

### 11. m_ad_contents（広告コンテンツ）

#### 概要
具体的な広告素材・訴求内容。PKは `content_id`（FK参照との一致のため）。

#### CREATE文
```sql
CREATE TABLE m_ad_contents (
  content_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  -- 紐付け
  ad_group_id BIGINT NOT NULL,
  client_id BIGINT,
  person_id BIGINT,
  -- 広告情報
  ad_name TEXT NOT NULL,
  -- 配信設定
  delivery_status_id SMALLINT NOT NULL DEFAULT 1,
  delivery_start_at TIMESTAMPTZ,
  delivery_end_at TIMESTAMPTZ,
  -- ITPパラメータ
  is_itp_param_status_id SMALLINT NOT NULL DEFAULT 0,
  -- 監査
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_content_ad_group
    FOREIGN KEY (ad_group_id)
    REFERENCES m_ad_groups(ad_group_id)
    ON DELETE RESTRICT,

  CONSTRAINT fk_content_client
    FOREIGN KEY (client_id)
    REFERENCES m_clients(client_id)
    ON DELETE SET NULL,

  CONSTRAINT fk_content_person
    FOREIGN KEY (person_id)
    REFERENCES m_agents(agent_id)
    ON DELETE SET NULL,

  CONSTRAINT chk_content_delivery_status CHECK (delivery_status_id IN (1, 2, 3)),
  CONSTRAINT chk_content_itp_status CHECK (is_itp_param_status_id IN (0, 1))
);

CREATE INDEX idx_ad_contents_ad_group ON m_ad_contents(ad_group_id, delivery_status_id);
CREATE INDEX idx_ad_contents_client ON m_ad_contents(client_id)
  WHERE client_id IS NOT NULL;
CREATE INDEX idx_ad_contents_person ON m_ad_contents(person_id)
  WHERE person_id IS NOT NULL;
CREATE INDEX idx_ad_contents_delivery_status ON m_ad_contents(delivery_status_id, delivery_start_at, delivery_end_at);
CREATE INDEX idx_ad_contents_delivery_period ON m_ad_contents(delivery_start_at, delivery_end_at)
  WHERE delivery_status_id = 1;

COMMENT ON TABLE m_ad_contents IS '広告コンテンツマスタ';
COMMENT ON COLUMN m_ad_contents.content_id IS '主キー（PK）。contentIdに相当';
COMMENT ON COLUMN m_ad_contents.ad_group_id IS '広告グループID（FK → m_ad_groups）';
COMMENT ON COLUMN m_ad_contents.client_id IS 'クライアントID（FK → m_clients）';
COMMENT ON COLUMN m_ad_contents.person_id IS '担当者ID（FK → m_agents）';
COMMENT ON COLUMN m_ad_contents.ad_name IS '広告コンテンツ名';
COMMENT ON COLUMN m_ad_contents.delivery_status_id IS '配信ステータス（1: 承認待ち, 2: 配信中, 3: 停止）';
COMMENT ON COLUMN m_ad_contents.delivery_start_at IS '配信開始日時';
COMMENT ON COLUMN m_ad_contents.delivery_end_at IS '配信終了日時';
COMMENT ON COLUMN m_ad_contents.is_itp_param_status_id IS 'ITPパラメータステータス（0: 未設定, 1: 設定済）';
```

---

### 12. m_clients（クライアント）

#### 概要
広告主企業のマスタ。

#### CREATE文
```sql
CREATE TABLE m_clients (
  client_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  -- 基本情報
  client_name TEXT NOT NULL,
  industry TEXT,
  -- ステータス
  status_id SMALLINT NOT NULL DEFAULT 1,
  -- 監査
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT chk_client_status CHECK (status_id IN (1, 2))
);

CREATE INDEX idx_clients_status ON m_clients(status_id);
CREATE INDEX idx_clients_industry ON m_clients(industry)
  WHERE industry IS NOT NULL;
CREATE INDEX idx_clients_name ON m_clients(client_name);

COMMENT ON TABLE m_clients IS 'クライアント（広告主）マスタ';
COMMENT ON COLUMN m_clients.client_id IS '主キー（PK）。自動採番';
COMMENT ON COLUMN m_clients.client_name IS '正式名称（例: 株式会社ナハト）';
COMMENT ON COLUMN m_clients.industry IS '業種（例: 美容、ゲーム、金融）';
COMMENT ON COLUMN m_clients.status_id IS 'ステータス（1: 取引中, 2: 取引停止）';
```

---

### 13. m_sns_platforms（SNSプラットフォームマスタ）

#### 概要
YouTube、Instagram等のSNSプラットフォーム定義。

#### CREATE文
```sql
CREATE TABLE m_sns_platforms (
  platform_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  platform_name TEXT NOT NULL UNIQUE,
  platform_code TEXT NOT NULL UNIQUE,
  url_pattern TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  display_order INTEGER NOT NULL DEFAULT 0,
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sns_platforms_active ON m_sns_platforms(is_active, display_order);

COMMENT ON TABLE m_sns_platforms IS 'SNSプラットフォームマスタ';
COMMENT ON COLUMN m_sns_platforms.url_pattern IS 'URL形式（例: https://youtube.com/@{handle}）';
COMMENT ON COLUMN m_sns_platforms.platform_id IS '主キー（PK）。自動採番';
COMMENT ON COLUMN m_sns_platforms.platform_name IS 'プラットフォーム名（例: YouTube, Instagram）';
COMMENT ON COLUMN m_sns_platforms.platform_code IS 'プラットフォームコード（例: youtube, instagram）';
COMMENT ON COLUMN m_sns_platforms.is_active IS '有効フラグ（TRUE: 有効, FALSE: 無効）';
COMMENT ON COLUMN m_sns_platforms.display_order IS '表示順（昇順ソート用）';
```

---

### 14. t_influencer_sns_accounts（IFのSNSアカウント）

#### 概要
インフルエンサーが運営するSNSアカウント情報。

#### CREATE文
```sql
CREATE TABLE t_influencer_sns_accounts (
  account_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  influencer_id BIGINT NOT NULL,
  platform_id BIGINT NOT NULL,
  account_url TEXT NOT NULL,
  account_handle TEXT,
  follower_count BIGINT,
  engagement_rate DECIMAL(5, 2),
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  is_verified BOOLEAN NOT NULL DEFAULT FALSE,
  status_id SMALLINT NOT NULL DEFAULT 1,
  last_updated_at TIMESTAMPTZ,
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_sns_account_influencer
    FOREIGN KEY (influencer_id)
    REFERENCES m_influencers(influencer_id)
    ON DELETE RESTRICT,

  CONSTRAINT fk_sns_account_platform
    FOREIGN KEY (platform_id)
    REFERENCES m_sns_platforms(platform_id)
    ON DELETE RESTRICT,

  CONSTRAINT chk_sns_account_status CHECK (status_id IN (1, 2, 3))
);

CREATE INDEX idx_sns_accounts_influencer ON t_influencer_sns_accounts(influencer_id, status_id);
CREATE INDEX idx_sns_accounts_platform ON t_influencer_sns_accounts(platform_id);
CREATE INDEX idx_sns_accounts_follower ON t_influencer_sns_accounts(follower_count DESC)
  WHERE status_id = 1;
CREATE UNIQUE INDEX uq_sns_accounts_primary
  ON t_influencer_sns_accounts(influencer_id) WHERE is_primary = TRUE;

COMMENT ON TABLE t_influencer_sns_accounts IS 'インフルエンサーのSNSアカウント';
COMMENT ON COLUMN t_influencer_sns_accounts.influencer_id IS 'インフルエンサーID（FK → m_influencers）';
COMMENT ON COLUMN t_influencer_sns_accounts.platform_id IS 'プラットフォームID（FK → m_sns_platforms）';
COMMENT ON COLUMN t_influencer_sns_accounts.status_id IS 'ステータス（1: 有効, 2: 停止中, 3: 削除済）';
COMMENT ON COLUMN t_influencer_sns_accounts.account_id IS '主キー（PK）。自動採番';
COMMENT ON COLUMN t_influencer_sns_accounts.account_url IS 'アカウントURL';
COMMENT ON COLUMN t_influencer_sns_accounts.account_handle IS 'アカウントハンドル名（@なし）';
COMMENT ON COLUMN t_influencer_sns_accounts.follower_count IS 'フォロワー数';
COMMENT ON COLUMN t_influencer_sns_accounts.engagement_rate IS 'エンゲージメント率（%）';
COMMENT ON COLUMN t_influencer_sns_accounts.is_primary IS 'メインアカウントフラグ';
COMMENT ON COLUMN t_influencer_sns_accounts.is_verified IS '認証済みフラグ';
COMMENT ON COLUMN t_influencer_sns_accounts.last_updated_at IS 'SNS情報最終更新日時';
```

---

### 15. t_account_categories（アカウント×カテゴリ紐付け）

#### 概要
SNSアカウントとカテゴリの多対多中間テーブル。

#### CREATE文
```sql
CREATE TABLE t_account_categories (
  account_category_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  account_id BIGINT NOT NULL,
  category_id BIGINT NOT NULL,
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_account_category_account
    FOREIGN KEY (account_id)
    REFERENCES t_influencer_sns_accounts(account_id)
    ON DELETE CASCADE,

  CONSTRAINT fk_account_category_category
    FOREIGN KEY (category_id)
    REFERENCES m_categories(category_id)
    ON DELETE RESTRICT,

  CONSTRAINT uq_account_category UNIQUE (account_id, category_id)
);

-- UNIQUE制約 uq_account_category(account_id, category_id) が account_id の検索にも利用可能
CREATE INDEX idx_account_categories_category ON t_account_categories(category_id);

COMMENT ON TABLE t_account_categories IS 'アカウント×カテゴリ紐付け（多対多）';
COMMENT ON COLUMN t_account_categories.account_id IS 'SNSアカウントID（FK → t_influencer_sns_accounts）';
COMMENT ON COLUMN t_account_categories.category_id IS 'カテゴリID（FK → m_categories）';
COMMENT ON COLUMN t_account_categories.is_primary IS 'メインカテゴリフラグ';
COMMENT ON COLUMN t_account_categories.account_category_id IS '主キー（PK）。自動採番';
```

---

### 16. m_influencer_security（IF認証）

#### 概要
インフルエンサー用の認証情報（1対1）。

#### CREATE文
```sql
CREATE TABLE m_influencer_security (
  influencer_id BIGINT PRIMARY KEY,
  -- 認証情報
  password_hash TEXT NOT NULL,
  -- セッション管理
  session_token TEXT,
  session_expires_at TIMESTAMPTZ,
  -- パスワード管理
  password_changed_at TIMESTAMPTZ,
  password_reset_token TEXT,
  reset_token_expires_at TIMESTAMPTZ,
  -- セキュリティ
  failed_login_attempts SMALLINT NOT NULL DEFAULT 0,
  locked_until TIMESTAMPTZ,
  -- 監査
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_security_influencer
    FOREIGN KEY (influencer_id)
    REFERENCES m_influencers(influencer_id)
    ON DELETE CASCADE
);

CREATE INDEX idx_influencer_security_session ON m_influencer_security(session_token)
  WHERE session_token IS NOT NULL;
CREATE INDEX idx_influencer_security_password_changed ON m_influencer_security(password_changed_at);
CREATE INDEX idx_influencer_security_reset_token ON m_influencer_security(password_reset_token)
  WHERE password_reset_token IS NOT NULL;
CREATE INDEX idx_influencer_security_locked ON m_influencer_security(influencer_id, locked_until)
  WHERE locked_until IS NOT NULL;

COMMENT ON TABLE m_influencer_security IS 'インフルエンサー認証・セキュリティ情報（1対1）';
COMMENT ON COLUMN m_influencer_security.influencer_id IS 'インフルエンサーID（PK・FK）';
COMMENT ON COLUMN m_influencer_security.password_hash IS 'パスワードハッシュ（bcrypt等）';
COMMENT ON COLUMN m_influencer_security.session_token IS 'セッショントークン';
COMMENT ON COLUMN m_influencer_security.session_expires_at IS 'セッション有効期限';
COMMENT ON COLUMN m_influencer_security.password_changed_at IS 'パスワード変更日時';
COMMENT ON COLUMN m_influencer_security.password_reset_token IS 'パスワードリセットトークン';
COMMENT ON COLUMN m_influencer_security.reset_token_expires_at IS 'リセットトークン有効期限';
COMMENT ON COLUMN m_influencer_security.failed_login_attempts IS 'ログイン失敗回数';
COMMENT ON COLUMN m_influencer_security.locked_until IS 'アカウントロック解除日時';
```

---

### 17. t_influencer_agent_assignments（IF×エージェント担当割当）

#### 概要
インフルエンサーへの担当者アサイン管理。履歴対応。

#### CREATE文
```sql
CREATE TABLE t_influencer_agent_assignments (
  assignment_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  influencer_id BIGINT NOT NULL,
  agent_id BIGINT NOT NULL,
  role_type_id SMALLINT NOT NULL,
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  unassigned_at TIMESTAMPTZ,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_assignment_influencer
    FOREIGN KEY (influencer_id)
    REFERENCES m_influencers(influencer_id)
    ON DELETE RESTRICT,

  CONSTRAINT fk_assignment_agent
    FOREIGN KEY (agent_id)
    REFERENCES m_agents(agent_id)
    ON DELETE RESTRICT,

  CONSTRAINT fk_assignment_role
    FOREIGN KEY (role_type_id)
    REFERENCES m_agent_role_types(role_type_id)
    ON DELETE RESTRICT
);

CREATE INDEX idx_assignments_influencer ON t_influencer_agent_assignments(influencer_id, is_active);
CREATE INDEX idx_assignments_agent ON t_influencer_agent_assignments(agent_id, is_active);
CREATE INDEX idx_assignments_role ON t_influencer_agent_assignments(role_type_id);

COMMENT ON TABLE t_influencer_agent_assignments IS 'インフルエンサー×エージェント担当割当';
COMMENT ON COLUMN t_influencer_agent_assignments.influencer_id IS 'インフルエンサーID（FK → m_influencers）';
COMMENT ON COLUMN t_influencer_agent_assignments.agent_id IS 'エージェントID（FK → m_agents）';
COMMENT ON COLUMN t_influencer_agent_assignments.role_type_id IS '役割タイプID（FK → m_agent_role_types）';
COMMENT ON COLUMN t_influencer_agent_assignments.assignment_id IS '主キー（PK）。自動採番';
COMMENT ON COLUMN t_influencer_agent_assignments.assigned_at IS '担当開始日時';
COMMENT ON COLUMN t_influencer_agent_assignments.unassigned_at IS '担当終了日時（NULL=現在担当中）';
COMMENT ON COLUMN t_influencer_agent_assignments.is_active IS '有効フラグ（TRUE: 担当中, FALSE: 解除済）';
```

---

### 18. t_audit_logs（共通監査ログ）

#### 概要
全テーブル横断的な変更履歴管理（ハイブリッド設計）。ポリモーフィック方式でAgent/Influencer両方の操作を記録可能。

#### CREATE文
```sql
CREATE TABLE t_audit_logs (
  log_id BIGINT GENERATED ALWAYS AS IDENTITY,
  table_name TEXT NOT NULL,
  record_id BIGINT NOT NULL,
  action_type TEXT NOT NULL,
  old_value JSONB,
  new_value JSONB,
  operator_type SMALLINT NOT NULL,
  operator_id BIGINT NOT NULL,
  operator_ip TEXT,
  operated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  -- パーティションキーをPKに含める（PostgreSQL要件）
  PRIMARY KEY (operated_at, log_id),

  CONSTRAINT chk_action_type
    CHECK (action_type IN ('INSERT', 'UPDATE', 'DELETE')),
  CONSTRAINT chk_operator_type
    CHECK (operator_type IN (1, 2))
) PARTITION BY RANGE (operated_at);

CREATE INDEX idx_audit_logs_table_record ON t_audit_logs(table_name, record_id);
CREATE INDEX idx_audit_logs_operator ON t_audit_logs(operator_type, operator_id, operated_at);
CREATE INDEX idx_audit_logs_operated ON t_audit_logs(operated_at);
CREATE INDEX idx_audit_logs_old_value ON t_audit_logs USING GIN (old_value);
CREATE INDEX idx_audit_logs_new_value ON t_audit_logs USING GIN (new_value);

COMMENT ON TABLE t_audit_logs IS '共通監査ログ（全テーブル横断的な履歴管理）';
COMMENT ON COLUMN t_audit_logs.action_type IS '操作種別（INSERT/UPDATE/DELETE）';
COMMENT ON COLUMN t_audit_logs.operator_type IS '操作者種別（1: Agent, 2: Influencer）';
COMMENT ON COLUMN t_audit_logs.operator_id IS '操作者ID（operator_typeに応じてm_agents.agent_idまたはm_influencers.influencer_idを参照）';
COMMENT ON COLUMN t_audit_logs.log_id IS '複合主キー（PK: operated_at, log_id）。自動採番';
COMMENT ON COLUMN t_audit_logs.table_name IS '対象テーブル名';
COMMENT ON COLUMN t_audit_logs.record_id IS '対象レコードのPK値';
COMMENT ON COLUMN t_audit_logs.old_value IS '変更前の値（JSONB）';
COMMENT ON COLUMN t_audit_logs.new_value IS '変更後の値（JSONB）';
COMMENT ON COLUMN t_audit_logs.operator_ip IS '操作者IPアドレス';
COMMENT ON COLUMN t_audit_logs.operated_at IS '操作日時';
```

---

### 19. m_influencers（インフルエンサー）

#### 概要
インフルエンサーのプロファイル情報。中心的エンティティ。

#### CREATE文
```sql
CREATE TABLE m_influencers (
  influencer_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  -- 基本情報
  login_id TEXT NOT NULL UNIQUE,
  influencer_name TEXT,
  influencer_alias TEXT,
  email_address TEXT,
  phone_number TEXT,
  honorific TEXT,
  -- 所属情報
  affiliation_name TEXT,
  affiliation_type_id SMALLINT,
  -- 基本属性（インフルエンサー自身の国籍・拠点）
  country_id SMALLINT,
  -- ステータス・フラグ
  status_id SMALLINT NOT NULL DEFAULT 1,
  compliance_check BOOLEAN NOT NULL DEFAULT FALSE,
  start_transaction_consent BOOLEAN NOT NULL DEFAULT FALSE,
  privacy_consent BOOLEAN NOT NULL DEFAULT FALSE,
  -- 申請情報（初回登録時の記録）
  submitted_at TIMESTAMPTZ,
  submission_form_source TEXT,
  submission_ip_address TEXT,
  user_agent TEXT,
  -- 楽観ロック
  version INTEGER NOT NULL DEFAULT 1,
  -- 監査
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_influencer_country
    FOREIGN KEY (country_id)
    REFERENCES m_countries(country_id)
    ON DELETE SET NULL,

  CONSTRAINT chk_influencer_status CHECK (status_id IN (1, 2, 3))
);

CREATE INDEX idx_influencers_status ON m_influencers(status_id);
CREATE INDEX idx_influencers_country ON m_influencers(country_id);
CREATE INDEX idx_influencers_affiliation ON m_influencers(affiliation_type_id);
CREATE INDEX idx_influencers_submitted ON m_influencers(submitted_at)
  WHERE submitted_at IS NOT NULL;

COMMENT ON TABLE m_influencers IS 'インフルエンサー基本情報テーブル（正規化版）';
COMMENT ON COLUMN m_influencers.influencer_id IS '主キー（PK）';
COMMENT ON COLUMN m_influencers.login_id IS 'ログインID（ユニーク）';
COMMENT ON COLUMN m_influencers.influencer_name IS 'インフルエンサー名（本名）';
COMMENT ON COLUMN m_influencers.influencer_alias IS '活動名・ニックネーム';
COMMENT ON COLUMN m_influencers.email_address IS 'メールアドレス';
COMMENT ON COLUMN m_influencers.phone_number IS '電話番号';
COMMENT ON COLUMN m_influencers.honorific IS '敬称（様、さん等）';
COMMENT ON COLUMN m_influencers.affiliation_name IS '所属組織名';
COMMENT ON COLUMN m_influencers.affiliation_type_id IS '所属タイプID（1: 事務所所属, 2: フリーランス, 3: 企業専属）';
COMMENT ON COLUMN m_influencers.country_id IS 'インフルエンサー自身の拠点国・国籍（FK → m_countries）';
COMMENT ON COLUMN m_influencers.status_id IS 'ステータス（1: 契約中, 2: 休止中, 3: 契約終了）';
COMMENT ON COLUMN m_influencers.compliance_check IS 'コンプライアンスチェック完了フラグ';
COMMENT ON COLUMN m_influencers.start_transaction_consent IS '取引開始同意フラグ';
COMMENT ON COLUMN m_influencers.privacy_consent IS 'プライバシーポリシー同意フラグ';
COMMENT ON COLUMN m_influencers.submitted_at IS '初回申請送信日時';
COMMENT ON COLUMN m_influencers.submission_form_source IS 'どのフォーム経由で申請されたか';
COMMENT ON COLUMN m_influencers.submission_ip_address IS '申請時のIPアドレス';
COMMENT ON COLUMN m_influencers.user_agent IS '申請時のユーザーエージェント';
COMMENT ON COLUMN m_influencers.version IS '楽観ロック用バージョン番号';
```

---

### 20. m_partners（パートナー）

#### 概要
ASP・広告配信パートナー（企業・個人）。

#### CREATE文
```sql
CREATE TABLE m_partners (
  partner_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  -- 基本情報
  partner_name TEXT NOT NULL,
  email_address TEXT,
  -- 紐付け（兼業管理）
  influencer_id BIGINT,
  -- ステータス
  status_id SMALLINT NOT NULL DEFAULT 1,
  -- 監査
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_partner_influencer
    FOREIGN KEY (influencer_id)
    REFERENCES m_influencers(influencer_id)
    ON DELETE SET NULL,

  CONSTRAINT chk_partner_status CHECK (status_id IN (1, 2))
);

CREATE INDEX idx_partners_influencer ON m_partners(influencer_id);
CREATE INDEX idx_partners_status ON m_partners(status_id);

COMMENT ON TABLE m_partners IS 'パートナー（ASP・広告配信パートナー）マスタ（企業・個人）';
COMMENT ON COLUMN m_partners.partner_id IS '主キー（PK）。自動採番';
COMMENT ON COLUMN m_partners.partner_name IS '氏名または企業名';
COMMENT ON COLUMN m_partners.email_address IS 'メールアドレス';
COMMENT ON COLUMN m_partners.influencer_id IS 'IF兼業管理用（FK → m_influencers）';
COMMENT ON COLUMN m_partners.status_id IS 'ステータス（1: 有効, 2: 無効）';
```

---

### 21. t_partner_sites（パートナーサイト）

#### 概要
パートナーが運営する広告配信サイト。

#### CREATE文
```sql
CREATE TABLE t_partner_sites (
  site_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  partner_id BIGINT NOT NULL,
  site_name TEXT NOT NULL,
  site_url TEXT,
  status_id SMALLINT NOT NULL DEFAULT 1,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_partner_site_partner
    FOREIGN KEY (partner_id)
    REFERENCES m_partners(partner_id)
    ON DELETE RESTRICT,

  CONSTRAINT chk_partner_site_status CHECK (status_id IN (1, 2, 3, 9))
);

CREATE INDEX idx_partner_sites_partner ON t_partner_sites(partner_id, is_active);
CREATE INDEX idx_partner_sites_status ON t_partner_sites(status_id);

COMMENT ON TABLE t_partner_sites IS 'パートナーサイト（媒体・枠）';
COMMENT ON COLUMN t_partner_sites.site_id IS '主キー（PK）。siteIdに相当';
COMMENT ON COLUMN t_partner_sites.partner_id IS 'パートナーID（FK → m_partners）';
COMMENT ON COLUMN t_partner_sites.site_name IS 'サイト名';
COMMENT ON COLUMN t_partner_sites.site_url IS 'URLやアプリBundle ID';
COMMENT ON COLUMN t_partner_sites.status_id IS 'ステータス（1: 稼働中, 2: 審査中, 3: 一時停止, 9: 停止）';
COMMENT ON COLUMN t_partner_sites.is_active IS '有効フラグ（TRUE: 有効, FALSE: 無効）';
```

---

### 22. m_campaigns（キャンペーン・加工用）

#### 概要
案件管理テーブル。パートナーサイト×インフルエンサー×プラットフォームの組み合わせで案件を管理。

#### CREATE文
```sql
CREATE TABLE m_campaigns (
  campaign_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  site_id BIGINT NOT NULL,
  influencer_id BIGINT,
  platform_id BIGINT NOT NULL,
  reward_type SMALLINT NOT NULL DEFAULT 1 CHECK (reward_type IN (1, 2, 3)),
  price_type SMALLINT NOT NULL DEFAULT 1 CHECK (price_type IN (1, 2)),
  status_id SMALLINT NOT NULL DEFAULT 1,
  -- 楽観ロック
  version INTEGER NOT NULL DEFAULT 1,
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_campaign_site
    FOREIGN KEY (site_id)
    REFERENCES t_partner_sites(site_id)
    ON DELETE RESTRICT,

  CONSTRAINT fk_campaign_influencer
    FOREIGN KEY (influencer_id)
    REFERENCES m_influencers(influencer_id)
    ON DELETE SET NULL,

  CONSTRAINT fk_campaign_platform
    FOREIGN KEY (platform_id)
    REFERENCES m_sns_platforms(platform_id)
    ON DELETE RESTRICT,

  CONSTRAINT chk_campaign_status CHECK (status_id IN (1, 2, 3))
);

CREATE INDEX idx_campaigns_site ON m_campaigns(site_id, status_id);
CREATE INDEX idx_campaigns_influencer ON m_campaigns(influencer_id, status_id);
CREATE INDEX idx_campaigns_platform ON m_campaigns(platform_id, status_id);
CREATE INDEX idx_campaigns_status ON m_campaigns(status_id, created_at);

COMMENT ON TABLE m_campaigns IS 'キャンペーン（案件）管理テーブル';
COMMENT ON COLUMN m_campaigns.site_id IS 'パートナーサイトID（FK → t_partner_sites）';
COMMENT ON COLUMN m_campaigns.influencer_id IS '担当インフルエンサーID（FK → m_influencers）';
COMMENT ON COLUMN m_campaigns.platform_id IS 'SNSプラットフォームID（FK → m_sns_platforms）';
COMMENT ON COLUMN m_campaigns.reward_type IS '報酬体系（1:固定, 2:予算, 3:成果）';
COMMENT ON COLUMN m_campaigns.price_type IS '価格体系（1:Gross, 2:Net）';
COMMENT ON COLUMN m_campaigns.status_id IS 'ステータス（1: 進行中, 2: 完了, 3: 中止）';
COMMENT ON COLUMN m_campaigns.version IS '楽観ロック用バージョン番号';
COMMENT ON COLUMN m_campaigns.campaign_id IS '主キー（PK）。自動採番';
```

---

### 23. m_partners_division（パートナー区分）

#### 概要
パートナーの事業区分を管理（IF卸/トータルマーケティング）。BigQuery/ASP側のIDと一致させるため手動PKを採用。

#### CREATE文
```sql
CREATE TABLE m_partners_division (
  partner_id BIGINT PRIMARY KEY,
  partner_name TEXT,
  -- 管理用属性
  division_type SMALLINT NOT NULL DEFAULT 1,
  is_comprehensive BOOLEAN NOT NULL DEFAULT FALSE,
  is_excluded BOOLEAN NOT NULL DEFAULT FALSE,
  -- 監査
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_division_partner
    FOREIGN KEY (partner_id)
    REFERENCES m_partners(partner_id)
    ON DELETE CASCADE
);

CREATE INDEX idx_partners_division ON m_partners_division(division_type);

COMMENT ON TABLE m_partners_division IS 'パートナー区分（IF卸/トータルマーケティング）';
COMMENT ON COLUMN m_partners_division.partner_id IS '主キー（PK・FK → m_partners）。BigQuery/ASP側のIDと一致';
COMMENT ON COLUMN m_partners_division.partner_name IS 'パートナー名';
COMMENT ON COLUMN m_partners_division.division_type IS '区分タイプ（1: IF卸, 2: トータルマーケ）';
COMMENT ON COLUMN m_partners_division.is_comprehensive IS 'IF総合追加フラグ';
COMMENT ON COLUMN m_partners_division.is_excluded IS 'フィルタ除外フラグ';
```

---

### 24. ingestion_logs（BQ取り込みログ）

#### 概要
BigQueryからのデータ取り込みジョブ実行履歴（システムテーブル）。

#### CREATE文
```sql
CREATE TABLE ingestion_logs (
  ingestion_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  job_type TEXT NOT NULL,
  target_from TIMESTAMPTZ NOT NULL,
  target_to TIMESTAMPTZ NOT NULL,
  parameters JSONB,
  status TEXT NOT NULL CHECK (status IN ('RUNNING', 'SUCCESS', 'FAILED')),
  records_count INTEGER NOT NULL DEFAULT 0,
  error_message TEXT,
  started_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  finished_at TIMESTAMPTZ
);

CREATE INDEX idx_ingestion_logs_started_at ON ingestion_logs(started_at DESC);
CREATE INDEX idx_ingestion_logs_status_started ON ingestion_logs(status, started_at DESC);
CREATE INDEX idx_ingestion_logs_job_type ON ingestion_logs(job_type, started_at DESC);
CREATE INDEX idx_ingestion_logs_target_period ON ingestion_logs(target_from, target_to);

COMMENT ON TABLE ingestion_logs IS 'BQデータ取り込み実行履歴（システムログ）';
COMMENT ON COLUMN ingestion_logs.ingestion_id IS '取り込みID（PK）';
COMMENT ON COLUMN ingestion_logs.job_type IS 'ジョブ種別（DAILY/HOURLY/RETRY）';
COMMENT ON COLUMN ingestion_logs.target_from IS 'データ取得対象期間（開始）';
COMMENT ON COLUMN ingestion_logs.target_to IS 'データ取得対象期間（終了）';
COMMENT ON COLUMN ingestion_logs.parameters IS 'ジョブパラメータ（JSONB）';
COMMENT ON COLUMN ingestion_logs.status IS '実行ステータス（RUNNING/SUCCESS/FAILED）';
COMMENT ON COLUMN ingestion_logs.records_count IS '取り込みレコード数';
COMMENT ON COLUMN ingestion_logs.error_message IS 'エラーメッセージ';
COMMENT ON COLUMN ingestion_logs.started_at IS '実行開始日時';
COMMENT ON COLUMN ingestion_logs.finished_at IS '実行終了日時';
```

---

### 25. t_unit_prices（単価設定）

#### 概要
サイト・コンテンツ・クライアント別の単価管理。期間対応。

#### CREATE文
```sql
CREATE TABLE t_unit_prices (
  unit_price_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  site_id BIGINT NOT NULL,
  content_id BIGINT,
  client_id BIGINT,
  unit_price DECIMAL(12, 0) NOT NULL,
  semi_unit_price DECIMAL(12, 0),
  limit_cap INTEGER,
  start_at DATE NOT NULL,
  end_at DATE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  -- 楽観ロック
  version INTEGER NOT NULL DEFAULT 1,
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_unit_price_site
    FOREIGN KEY (site_id)
    REFERENCES t_partner_sites(site_id)
    ON DELETE RESTRICT,

  CONSTRAINT fk_unit_price_content
    FOREIGN KEY (content_id)
    REFERENCES m_ad_contents(content_id)
    ON DELETE RESTRICT,

  CONSTRAINT fk_unit_price_client
    FOREIGN KEY (client_id)
    REFERENCES m_clients(client_id)
    ON DELETE RESTRICT
);

CREATE INDEX idx_unit_prices_site ON t_unit_prices(site_id, is_active);
CREATE INDEX idx_unit_prices_content ON t_unit_prices(content_id, is_active);
CREATE INDEX idx_unit_prices_client ON t_unit_prices(client_id, is_active);
CREATE INDEX idx_unit_prices_period ON t_unit_prices(start_at, end_at)
  WHERE is_active = TRUE;

COMMENT ON TABLE t_unit_prices IS '単価設定';
COMMENT ON COLUMN t_unit_prices.site_id IS 'サイトID（FK → t_partner_sites）';
COMMENT ON COLUMN t_unit_prices.content_id IS 'コンテンツID（FK → m_ad_contents）';
COMMENT ON COLUMN t_unit_prices.client_id IS 'クライアントID（FK → m_clients）';
COMMENT ON COLUMN t_unit_prices.semi_unit_price IS '準単価（用途要確認）';
COMMENT ON COLUMN t_unit_prices.limit_cap IS '上限キャップ（件数）';
COMMENT ON COLUMN t_unit_prices.end_at IS '有効期間終了日（NULL=無期限）';
COMMENT ON COLUMN t_unit_prices.version IS '楽観ロック用バージョン番号';
COMMENT ON COLUMN t_unit_prices.unit_price_id IS '主キー（PK）。自動採番';
COMMENT ON COLUMN t_unit_prices.unit_price IS '単価（円）';
COMMENT ON COLUMN t_unit_prices.start_at IS '有効期間開始日';
COMMENT ON COLUMN t_unit_prices.is_active IS '有効フラグ（TRUE: 有効, FALSE: 無効）';
```

---

### 26. t_daily_performance_details（日次CV集計）

#### 概要
日次コンバージョン集計データ。パーティション対応。FK制約あり（partner_id, site_id, client_id, content_id）。

#### CREATE文
```sql
-- ============================================================
-- 📊 日次パフォーマンス詳細（CV版・パーティション対応）
-- ============================================================

CREATE TABLE t_daily_performance_details (
  -- 集計軸（Dimensions）
  action_date DATE NOT NULL,
  partner_id BIGINT NOT NULL,
  site_id BIGINT NOT NULL,
  client_id BIGINT NOT NULL,
  content_id BIGINT NOT NULL,
  status_id SMALLINT NOT NULL,

  -- 表示用名称（Snapshots）
  partner_name TEXT,
  site_name TEXT,
  client_name TEXT,
  content_name TEXT,

  -- 集計値（Metrics）
  cv_count INTEGER NOT NULL DEFAULT 0,
  client_action_cost DECIMAL(12, 0) NOT NULL DEFAULT 0,
  unit_price DECIMAL(12, 0) NOT NULL DEFAULT 0,

  -- 監査（集計テーブルはシステム投入のため DEFAULT 1 = システム管理者）
  created_by BIGINT NOT NULL DEFAULT 1,
  updated_by BIGINT NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  -- 複合主キー
  PRIMARY KEY (action_date, partner_id, site_id, client_id, content_id, status_id),

  -- 外部キー制約
  CONSTRAINT fk_daily_perf_partner
    FOREIGN KEY (partner_id)
    REFERENCES m_partners(partner_id)
    ON DELETE RESTRICT,

  CONSTRAINT fk_daily_perf_site
    FOREIGN KEY (site_id)
    REFERENCES t_partner_sites(site_id)
    ON DELETE RESTRICT,

  CONSTRAINT fk_daily_perf_client
    FOREIGN KEY (client_id)
    REFERENCES m_clients(client_id)
    ON DELETE RESTRICT,

  CONSTRAINT fk_daily_perf_content
    FOREIGN KEY (content_id)
    REFERENCES m_ad_contents(content_id)
    ON DELETE RESTRICT,

  CONSTRAINT chk_daily_perf_status CHECK (status_id IN (1, 2, 9))
) PARTITION BY RANGE (action_date);

-- パーティション作成（直近3年分）
CREATE TABLE t_daily_perf_2024 PARTITION OF t_daily_performance_details
  FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

CREATE TABLE t_daily_perf_2025 PARTITION OF t_daily_performance_details
  FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

CREATE TABLE t_daily_perf_2026 PARTITION OF t_daily_performance_details
  FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');

-- インデックス（検索高速化）
CREATE INDEX idx_perf_detail_date
  ON t_daily_performance_details(action_date);

CREATE INDEX idx_perf_detail_partner
  ON t_daily_performance_details(partner_id, action_date);

CREATE INDEX idx_perf_detail_site
  ON t_daily_performance_details(site_id, action_date);

CREATE INDEX idx_perf_detail_client
  ON t_daily_performance_details(client_id, action_date);

CREATE INDEX idx_perf_detail_content
  ON t_daily_performance_details(content_id, action_date);

CREATE INDEX idx_perf_detail_status
  ON t_daily_performance_details(status_id, action_date);

-- テーブルコメント
COMMENT ON TABLE t_daily_performance_details IS '日次パフォーマンス詳細（CV版・トランザクション）。レンジパーティション対応で大量データを効率的に管理。';

-- カラムコメント
COMMENT ON COLUMN t_daily_performance_details.action_date IS '集計日（パーティションキー）';
COMMENT ON COLUMN t_daily_performance_details.partner_id IS 'パートナーID（FK → m_partners）';
COMMENT ON COLUMN t_daily_performance_details.site_id IS 'サイトID（FK → t_partner_sites）';
COMMENT ON COLUMN t_daily_performance_details.client_id IS 'クライアントID（FK → m_clients）';
COMMENT ON COLUMN t_daily_performance_details.content_id IS 'コンテンツID（FK → m_ad_contents）';
COMMENT ON COLUMN t_daily_performance_details.status_id IS 'ステータスID（1:承認済み, 2:未承認, 9:キャンセル等）';
COMMENT ON COLUMN t_daily_performance_details.partner_name IS 'パートナー名（スナップショット・集計時点の名称）';
COMMENT ON COLUMN t_daily_performance_details.site_name IS 'サイト名（スナップショット・集計時点の名称）';
COMMENT ON COLUMN t_daily_performance_details.client_name IS 'クライアント名（スナップショット・集計時点の名称）';
COMMENT ON COLUMN t_daily_performance_details.content_name IS 'コンテンツ名（スナップショット・集計時点の名称）';
COMMENT ON COLUMN t_daily_performance_details.cv_count IS 'CV件数（コンバージョン数）';
COMMENT ON COLUMN t_daily_performance_details.client_action_cost IS '報酬総額（売上）。クライアントから支払われる金額。';
COMMENT ON COLUMN t_daily_performance_details.unit_price IS '平均単価（総額÷件数）。表示用。';
COMMENT ON COLUMN t_daily_performance_details.created_by IS '作成者（システムユーザーID=1）';
COMMENT ON COLUMN t_daily_performance_details.updated_by IS '最終更新者（システムユーザーID=1）';
COMMENT ON COLUMN t_daily_performance_details.created_at IS '作成日時';
COMMENT ON COLUMN t_daily_performance_details.updated_at IS '最終更新日時';
```

> [!NOTE]
> `site_id` と `content_id` は NOT NULL。必ず実際の値が入る前提。
> FK制約でデータ整合性を担保（参照先のレコードが存在しないとINSERT不可）。

---

### 27. t_daily_click_details（日次クリック集計）

#### 概要
日次クリック集計データ。パーティション対応。FK制約あり（site_id）。

#### CREATE文
```sql
-- ============================================================
-- 📊 日次クリック詳細（パーティション対応）
-- ============================================================

CREATE TABLE t_daily_click_details (
  -- 集計軸（Dimensions）
  action_date DATE NOT NULL,
  site_id BIGINT NOT NULL,

  -- 表示用名称（Snapshots）
  site_name TEXT,

  -- 集計値（Metrics）
  click_count INTEGER NOT NULL DEFAULT 0,

  -- 監査（集計テーブルはシステム投入のため DEFAULT 1 = システム管理者）
  created_by BIGINT NOT NULL DEFAULT 1,
  updated_by BIGINT NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  -- 複合主キー
  PRIMARY KEY (action_date, site_id),

  -- 外部キー制約
  CONSTRAINT fk_daily_click_site
    FOREIGN KEY (site_id)
    REFERENCES t_partner_sites(site_id)
    ON DELETE RESTRICT
) PARTITION BY RANGE (action_date);

-- パーティション作成（直近3年分）
CREATE TABLE t_daily_click_2024 PARTITION OF t_daily_click_details
  FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

CREATE TABLE t_daily_click_2025 PARTITION OF t_daily_click_details
  FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

CREATE TABLE t_daily_click_2026 PARTITION OF t_daily_click_details
  FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');

-- インデックス（検索高速化）
CREATE INDEX idx_click_detail_date
  ON t_daily_click_details(action_date);

CREATE INDEX idx_click_detail_site
  ON t_daily_click_details(site_id, action_date);

CREATE INDEX idx_click_detail_count
  ON t_daily_click_details(click_count DESC)
  WHERE click_count > 0;

-- テーブルコメント
COMMENT ON TABLE t_daily_click_details IS '日次クリック詳細（トランザクション）。レンジパーティション対応で大量データを効率的に管理。';

-- カラムコメント
COMMENT ON COLUMN t_daily_click_details.action_date IS '集計日（パーティションキー）';
COMMENT ON COLUMN t_daily_click_details.site_id IS 'サイトID（FK → t_partner_sites）';
COMMENT ON COLUMN t_daily_click_details.site_name IS 'サイト名（スナップショット・集計時点の名称）';
COMMENT ON COLUMN t_daily_click_details.click_count IS 'クリック件数（広告リンクのクリック数）';
COMMENT ON COLUMN t_daily_click_details.created_by IS '作成者（システムユーザーID=1）';
COMMENT ON COLUMN t_daily_click_details.updated_by IS '最終更新者（システムユーザーID=1）';
COMMENT ON COLUMN t_daily_click_details.created_at IS '作成日時';
COMMENT ON COLUMN t_daily_click_details.updated_at IS '最終更新日時';
```

> [!NOTE]
> `site_id` は NOT NULL。必ず実際の値が入る前提。
> FK制約でデータ整合性を担保（参照先のレコードが存在しないとINSERT不可）。

---

### 28. t_notifications（通知）

#### 概要
エージェント・インフルエンサー・パートナーへの通知管理。担当割当、承認依頼、支払い通知等。

#### CREATE文
```sql
CREATE TABLE t_notifications (
  notification_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  -- 通知先
  user_id BIGINT NOT NULL,
  user_type SMALLINT NOT NULL,
  -- 通知内容
  notification_type TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT,
  link_url TEXT,
  -- 既読管理
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  read_at TIMESTAMPTZ,
  -- 監査
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT chk_user_type CHECK (user_type IN (1, 2, 3))
);

CREATE INDEX idx_notifications_user ON t_notifications(user_id, user_type, is_read, created_at DESC);
CREATE INDEX idx_notifications_type ON t_notifications(notification_type, created_at DESC);
CREATE INDEX idx_notifications_unread ON t_notifications(user_id, user_type, created_at DESC)
  WHERE is_read = FALSE;

COMMENT ON TABLE t_notifications IS '通知テーブル';
COMMENT ON COLUMN t_notifications.notification_id IS '主キー（PK）。自動採番';
COMMENT ON COLUMN t_notifications.user_id IS '通知先ユーザーID（user_typeに応じてagent_id/influencer_id/partner_idのいずれか）';
COMMENT ON COLUMN t_notifications.user_type IS '通知先ユーザー種別（1: Agent, 2: Influencer, 3: Partner）';
COMMENT ON COLUMN t_notifications.notification_type IS '通知タイプ（assignment: 担当割当, approval: 承認依頼, payment: 支払い通知, campaign: キャンペーン関連, system: システム通知）';
COMMENT ON COLUMN t_notifications.title IS '通知タイトル';
COMMENT ON COLUMN t_notifications.message IS '通知本文';
COMMENT ON COLUMN t_notifications.link_url IS '遷移先URL';
COMMENT ON COLUMN t_notifications.is_read IS '既読フラグ';
COMMENT ON COLUMN t_notifications.read_at IS '既読日時';
```

---

### 29. t_translations（翻訳）

#### 概要
テーブル横断で名称カラムの多言語翻訳を管理する汎用テーブル。既存カラムを変更せず、後付けで多言語対応できる。

#### CREATE文
```sql
CREATE TABLE t_translations (
  translation_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  -- 対象レコード特定
  table_name TEXT NOT NULL,
  record_id BIGINT NOT NULL,
  column_name TEXT NOT NULL,
  language_code TEXT NOT NULL,
  -- 翻訳内容
  translated_value TEXT NOT NULL,
  -- 監査
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  -- ユニーク制約（同一レコード×カラム×言語で1件）
  CONSTRAINT uq_translation UNIQUE (table_name, record_id, column_name, language_code)
);

CREATE INDEX idx_translations_lookup ON t_translations(table_name, record_id, language_code);
CREATE INDEX idx_translations_lang ON t_translations(language_code);

COMMENT ON TABLE t_translations IS '翻訳テーブル（汎用多言語対応）';
COMMENT ON COLUMN t_translations.translation_id IS '主キー（PK）。自動採番';
COMMENT ON COLUMN t_translations.table_name IS '対象テーブル名（例: m_categories, m_sns_platforms）';
COMMENT ON COLUMN t_translations.record_id IS '対象レコードのPK値';
COMMENT ON COLUMN t_translations.column_name IS '対象カラム名（例: category_name, platform_name）';
COMMENT ON COLUMN t_translations.language_code IS '言語コード（ISO 639-1: en, ko, zh, th 等）';
COMMENT ON COLUMN t_translations.translated_value IS '翻訳後の値';
```

#### 使用例
```sql
-- カテゴリ名の英語翻訳を登録
INSERT INTO t_translations (table_name, record_id, column_name, language_code, translated_value, created_by, updated_by)
VALUES ('m_categories', 1, 'category_name', 'en', 'Beauty', 1, 1);

-- 多言語対応のカテゴリ一覧取得
SELECT
  c.category_id,
  c.category_name AS name_ja,
  t.translated_value AS name_en
FROM m_categories c
LEFT JOIN t_translations t
  ON t.table_name = 'm_categories'
  AND t.record_id = c.category_id
  AND t.column_name = 'category_name'
  AND t.language_code = 'en';
```

> [!NOTE]
> 翻訳が必要な主な対象カラム:
> - `m_categories.category_name` — カテゴリ名
> - `m_sns_platforms.platform_name` — プラットフォーム名
> - `m_countries.country_name` — 国名
> - `m_ad_groups.ad_group_name` — 広告グループ名
> FK制約は設けない（汎用テーブルのため）。データ整合性はアプリケーション層で担保する。

---

### 30. t_files（ファイル管理）

#### 概要
プロフィール画像、広告素材、契約書PDF等のファイルメタデータを管理。実ファイルはオブジェクトストレージ（S3/GCS）に保存し、本テーブルにはパスとメタ情報のみ格納。

#### CREATE文
```sql
CREATE TABLE t_files (
  file_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  -- 紐付け先（ポリモーフィック）
  entity_type SMALLINT NOT NULL,
  entity_id BIGINT NOT NULL,
  -- ファイル情報
  file_category TEXT NOT NULL,
  file_name TEXT NOT NULL,
  storage_path TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  file_size_bytes BIGINT NOT NULL,
  -- メタ情報
  sort_order SMALLINT NOT NULL DEFAULT 0,
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  -- 監査
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT chk_entity_type CHECK (entity_type IN (1, 2, 3, 4, 5))
);

CREATE INDEX idx_files_entity ON t_files(entity_type, entity_id, file_category);
CREATE INDEX idx_files_primary ON t_files(entity_type, entity_id)
  WHERE is_primary = TRUE;

COMMENT ON TABLE t_files IS 'ファイル管理テーブル';
COMMENT ON COLUMN t_files.file_id IS '主キー（PK）。自動採番';
COMMENT ON COLUMN t_files.entity_type IS '紐付け先エンティティ種別（1: Agent, 2: Influencer, 3: Partner, 4: AdContent, 5: Campaign）';
COMMENT ON COLUMN t_files.entity_id IS '紐付け先エンティティのPK値';
COMMENT ON COLUMN t_files.file_category IS 'ファイル種別（profile_image: プロフィール画像, contract_pdf: 契約書, ad_material: 広告素材, invoice: 請求書, other: その他）';
COMMENT ON COLUMN t_files.file_name IS '元ファイル名（アップロード時の名前）';
COMMENT ON COLUMN t_files.storage_path IS 'オブジェクトストレージ上のパス（例: uploads/influencers/123/profile.jpg）';
COMMENT ON COLUMN t_files.mime_type IS 'MIMEタイプ（例: image/jpeg, application/pdf）';
COMMENT ON COLUMN t_files.file_size_bytes IS 'ファイルサイズ（バイト）';
COMMENT ON COLUMN t_files.sort_order IS '表示順';
COMMENT ON COLUMN t_files.is_primary IS 'メインファイルフラグ（プロフィール画像のデフォルト等）';
```

> [!NOTE]
> t_notifications と同様のポリモーフィックパターン（entity_type + entity_id）を採用。
> FK制約は設けず、アプリケーション層で整合性を担保する。
> 実ファイルの保存先はオブジェクトストレージを前提とし、DBにはメタデータのみ格納。

---

### 31. t_billing_runs（請求確定バッチ）

#### 概要
請求確定のスナップショットを管理するテーブル。確定時の抽出条件（フィルタ条件）をJSONBで保存し、再現性・監査対応を実現する。論理削除（`is_cancelled`）方式で物理削除は行わない。

#### CREATE文
```sql
CREATE TABLE t_billing_runs (
  billing_run_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  -- 対象期間
  billing_period_from DATE NOT NULL,
  billing_period_to DATE NOT NULL,
  -- フィルタ条件（確定時の抽出条件を保存・再現性のため）
  filter_conditions JSONB NOT NULL DEFAULT '{}',
  -- 確定情報
  confirmed_by BIGINT NOT NULL,
  confirmed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  -- 論理削除（取消）
  is_cancelled BOOLEAN NOT NULL DEFAULT FALSE,
  cancelled_by BIGINT,
  cancelled_at TIMESTAMPTZ,
  -- メモ
  notes TEXT,
  -- 監査
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_billing_run_confirmed_by
    FOREIGN KEY (confirmed_by)
    REFERENCES m_agents(agent_id)
    ON DELETE RESTRICT,

  CONSTRAINT fk_billing_run_cancelled_by
    FOREIGN KEY (cancelled_by)
    REFERENCES m_agents(agent_id)
    ON DELETE RESTRICT,

  -- 取消の整合性: is_cancelled=TRUEなら cancelled_by/cancelled_at 必須
  CONSTRAINT chk_billing_run_cancel
    CHECK (
      (is_cancelled = FALSE AND cancelled_by IS NULL AND cancelled_at IS NULL)
      OR (is_cancelled = TRUE AND cancelled_by IS NOT NULL AND cancelled_at IS NOT NULL)
    )
);

CREATE INDEX idx_billing_runs_period ON t_billing_runs(billing_period_from, billing_period_to);
CREATE INDEX idx_billing_runs_confirmed_by ON t_billing_runs(confirmed_by);
CREATE INDEX idx_billing_runs_active ON t_billing_runs(is_cancelled, confirmed_at DESC)
  WHERE is_cancelled = FALSE;

COMMENT ON TABLE t_billing_runs IS '請求確定バッチ（スナップショット方式）';
COMMENT ON COLUMN t_billing_runs.billing_run_id IS '主キー（PK）。自動採番';
COMMENT ON COLUMN t_billing_runs.billing_period_from IS '請求対象期間（開始日）';
COMMENT ON COLUMN t_billing_runs.billing_period_to IS '請求対象期間（終了日）';
COMMENT ON COLUMN t_billing_runs.filter_conditions IS '確定時のフィルタ条件（JSONB）。例: {"partner_ids":[1,2],"site_ids":[10],"status_ids":[1]}';
COMMENT ON COLUMN t_billing_runs.confirmed_by IS '確定者（FK → m_agents.agent_id）';
COMMENT ON COLUMN t_billing_runs.confirmed_at IS '確定日時';
COMMENT ON COLUMN t_billing_runs.is_cancelled IS '取消フラグ（TRUE: 取消済, FALSE: 有効）。論理削除用';
COMMENT ON COLUMN t_billing_runs.cancelled_by IS '取消者（FK → m_agents.agent_id）。is_cancelled=TRUE時に必須';
COMMENT ON COLUMN t_billing_runs.cancelled_at IS '取消日時。is_cancelled=TRUE時に必須';
COMMENT ON COLUMN t_billing_runs.notes IS 'メモ・備考';
```

#### filter_conditions の構造例
```json
{
  "partner_ids": [1, 2, 3],
  "site_ids": [10, 20],
  "client_ids": [100],
  "content_ids": null,
  "status_ids": [1]
}
```

> [!NOTE]
> - `filter_conditions` にはnullや空配列も許容。nullは「全件」を意味する
> - 論理削除パターンを採用しているため、`DELETE`文は原則使用しない
> - CHECK制約 `chk_billing_run_cancel` により、`is_cancelled = TRUE` 時に `cancelled_by` / `cancelled_at` の両方がセットされていることを保証

---

### 32. t_billing_line_items（請求明細）

#### 概要
請求確定バッチに紐づく明細行。t_daily_performance_details の確定時スナップショットとして、パートナー×サイト×クライアント×コンテンツ×日付の粒度で金額を保持する。

#### CREATE文
```sql
CREATE TABLE t_billing_line_items (
  line_item_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  billing_run_id BIGINT NOT NULL,
  -- 次元カラム（FK付き）
  action_date DATE NOT NULL,
  partner_id BIGINT NOT NULL,
  site_id BIGINT NOT NULL,
  client_id BIGINT NOT NULL,
  content_id BIGINT NOT NULL,
  -- スナップショット名称（確定時点の名称を保持）
  partner_name TEXT,
  site_name TEXT,
  client_name TEXT,
  content_name TEXT,
  -- 集計値
  cv_count INTEGER NOT NULL DEFAULT 0,
  unit_price DECIMAL(12, 0) NOT NULL DEFAULT 0,
  amount DECIMAL(12, 0) NOT NULL DEFAULT 0,
  -- 監査
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_line_item_run
    FOREIGN KEY (billing_run_id)
    REFERENCES t_billing_runs(billing_run_id)
    ON DELETE RESTRICT,

  CONSTRAINT fk_line_item_partner
    FOREIGN KEY (partner_id)
    REFERENCES m_partners(partner_id)
    ON DELETE RESTRICT,

  CONSTRAINT fk_line_item_site
    FOREIGN KEY (site_id)
    REFERENCES t_partner_sites(site_id)
    ON DELETE RESTRICT,

  CONSTRAINT fk_line_item_client
    FOREIGN KEY (client_id)
    REFERENCES m_clients(client_id)
    ON DELETE RESTRICT,

  CONSTRAINT fk_line_item_content
    FOREIGN KEY (content_id)
    REFERENCES m_ad_contents(content_id)
    ON DELETE RESTRICT
);

CREATE INDEX idx_line_items_run ON t_billing_line_items(billing_run_id);
CREATE INDEX idx_line_items_partner ON t_billing_line_items(partner_id, action_date);
CREATE INDEX idx_line_items_site ON t_billing_line_items(site_id, action_date);
CREATE INDEX idx_line_items_client ON t_billing_line_items(client_id, action_date);
CREATE INDEX idx_line_items_content ON t_billing_line_items(content_id, action_date);
CREATE INDEX idx_line_items_date ON t_billing_line_items(action_date);

COMMENT ON TABLE t_billing_line_items IS '請求明細（確定済みスナップショット）';
COMMENT ON COLUMN t_billing_line_items.line_item_id IS '主キー（PK）。自動採番';
COMMENT ON COLUMN t_billing_line_items.billing_run_id IS '請求確定バッチID（FK → t_billing_runs）';
COMMENT ON COLUMN t_billing_line_items.action_date IS '集計日';
COMMENT ON COLUMN t_billing_line_items.partner_id IS 'パートナーID（FK → m_partners）';
COMMENT ON COLUMN t_billing_line_items.site_id IS 'サイトID（FK → t_partner_sites）';
COMMENT ON COLUMN t_billing_line_items.client_id IS 'クライアントID（FK → m_clients）';
COMMENT ON COLUMN t_billing_line_items.content_id IS 'コンテンツID（FK → m_ad_contents）';
COMMENT ON COLUMN t_billing_line_items.partner_name IS 'パートナー名（スナップショット・確定時点の名称）';
COMMENT ON COLUMN t_billing_line_items.site_name IS 'サイト名（スナップショット・確定時点の名称）';
COMMENT ON COLUMN t_billing_line_items.client_name IS 'クライアント名（スナップショット・確定時点の名称）';
COMMENT ON COLUMN t_billing_line_items.content_name IS 'コンテンツ名（スナップショット・確定時点の名称）';
COMMENT ON COLUMN t_billing_line_items.cv_count IS 'CV件数（コンバージョン数）';
COMMENT ON COLUMN t_billing_line_items.unit_price IS '単価';
COMMENT ON COLUMN t_billing_line_items.amount IS '金額（cv_count × unit_price）';
```

> [!NOTE]
> - `t_daily_performance_details` の確定版スナップショットとして機能する
> - スナップショット名称カラム（partner_name等）は集計テーブルと同じパターンで、確定時点の名称を保持
> - 全FKが `ON DELETE RESTRICT` — 請求確定済みデータの参照先は削除不可
> - 親テーブル `t_billing_runs` への FK も `ON DELETE RESTRICT` — 論理削除方式のため物理削除は不可

---

## 共通トリガー・ファンクション

### updated_at 自動更新トリガー

全テーブルの `updated_at` カラムをUPDATE時に自動更新するためのトリガー。

```sql
-- 共通関数（1回だけ作成）
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- マスタテーブル
CREATE TRIGGER trg_countries_updated_at BEFORE UPDATE ON m_countries FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_departments_updated_at BEFORE UPDATE ON m_departments FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_categories_updated_at BEFORE UPDATE ON m_categories FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_agents_updated_at BEFORE UPDATE ON m_agents FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_agent_role_types_updated_at BEFORE UPDATE ON m_agent_role_types FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_agent_security_updated_at BEFORE UPDATE ON m_agent_security FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_influencers_updated_at BEFORE UPDATE ON m_influencers FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_influencer_security_updated_at BEFORE UPDATE ON m_influencer_security FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_ad_groups_updated_at BEFORE UPDATE ON m_ad_groups FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_clients_updated_at BEFORE UPDATE ON m_clients FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_ad_contents_updated_at BEFORE UPDATE ON m_ad_contents FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_partners_updated_at BEFORE UPDATE ON m_partners FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_partners_division_updated_at BEFORE UPDATE ON m_partners_division FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_sns_platforms_updated_at BEFORE UPDATE ON m_sns_platforms FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_campaigns_updated_at BEFORE UPDATE ON m_campaigns FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- トランザクションテーブル
CREATE TRIGGER trg_partner_sites_updated_at BEFORE UPDATE ON t_partner_sites FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_sns_accounts_updated_at BEFORE UPDATE ON t_influencer_sns_accounts FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_account_categories_updated_at BEFORE UPDATE ON t_account_categories FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_addresses_updated_at BEFORE UPDATE ON t_addresses FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_bank_accounts_updated_at BEFORE UPDATE ON t_bank_accounts FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_billing_info_updated_at BEFORE UPDATE ON t_billing_info FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_unit_prices_updated_at BEFORE UPDATE ON t_unit_prices FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_assignments_updated_at BEFORE UPDATE ON t_influencer_agent_assignments FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_notifications_updated_at BEFORE UPDATE ON t_notifications FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_translations_updated_at BEFORE UPDATE ON t_translations FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_files_updated_at BEFORE UPDATE ON t_files FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 請求確定テーブル
CREATE TRIGGER trg_billing_runs_updated_at BEFORE UPDATE ON t_billing_runs FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_billing_line_items_updated_at BEFORE UPDATE ON t_billing_line_items FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 集計テーブル
CREATE TRIGGER trg_daily_performance_updated_at BEFORE UPDATE ON t_daily_performance_details FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_daily_click_updated_at BEFORE UPDATE ON t_daily_click_details FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

> [!NOTE]
> **除外テーブル:**
> - `t_audit_logs` — `operated_at` で管理。UPDATEされない前提（追記のみ）。
> - `ingestion_logs` — `finished_at` で管理。ジョブ専用テーブル。

---

## 使用例

### カテゴリ階層表示
```sql
WITH RECURSIVE category_tree AS (
  SELECT
    category_id,
    parent_category_id,
    category_name,
    category_code,
    0 AS level,
    category_name AS path
  FROM m_categories
  WHERE parent_category_id IS NULL

  UNION ALL

  SELECT
    c.category_id,
    c.parent_category_id,
    c.category_name,
    c.category_code,
    ct.level + 1,
    ct.path || ' > ' || c.category_name
  FROM m_categories c
  INNER JOIN category_tree ct ON c.parent_category_id = ct.category_id
)
SELECT
  REPEAT('  ', level) || category_name AS カテゴリ階層,
  category_code,
  path
FROM category_tree
ORDER BY path;
```

### 部署階層表示
```sql
WITH RECURSIVE dept_tree AS (
  SELECT
    department_id,
    parent_department_id,
    department_name,
    department_code,
    0 AS level
  FROM m_departments
  WHERE parent_department_id IS NULL

  UNION ALL

  SELECT
    d.department_id,
    d.parent_department_id,
    d.department_name,
    d.department_code,
    dt.level + 1
  FROM m_departments d
  INNER JOIN dept_tree dt ON d.parent_department_id = dt.department_id
)
SELECT
  REPEAT('  ', level) || department_name AS 部署階層,
  department_code
FROM dept_tree
ORDER BY department_code;
```

### インフルエンサー一覧（担当者・SNS情報付き）
```sql
SELECT
  i.influencer_name,
  i.email_address,
  STRING_AGG(DISTINCT a.agent_name || '(' || art.role_name || ')', ', ') AS 担当者,
  STRING_AGG(
    DISTINCT sp.platform_name || ': @' || COALESCE(isa.account_handle, 'N/A') ||
    ' (' || COALESCE(isa.follower_count::TEXT, '0') || ')',
    ', '
  ) AS SNS情報
FROM m_influencers i
LEFT JOIN t_influencer_agent_assignments iaa
  ON i.influencer_id = iaa.influencer_id AND iaa.is_active = TRUE
LEFT JOIN m_agents a ON iaa.agent_id = a.agent_id
LEFT JOIN m_agent_role_types art ON iaa.role_type_id = art.role_type_id
LEFT JOIN t_influencer_sns_accounts isa
  ON i.influencer_id = isa.influencer_id AND isa.status_id = 1
LEFT JOIN m_sns_platforms sp ON isa.platform_id = sp.platform_id
WHERE i.status_id = 1
GROUP BY i.influencer_id, i.influencer_name, i.email_address
ORDER BY i.influencer_name;
```

### キャンペーン一覧（サイト・IF・プラットフォーム付き）
```sql
SELECT
  c.campaign_id,
  ps.site_name,
  i.influencer_name,
  sp.platform_name,
  c.reward_type,
  c.price_type,
  c.status_id
FROM m_campaigns c
INNER JOIN t_partner_sites ps ON c.site_id = ps.site_id
LEFT JOIN m_influencers i ON c.influencer_id = i.influencer_id
INNER JOIN m_sns_platforms sp ON c.platform_id = sp.platform_id
WHERE c.status_id = 1
ORDER BY c.created_at DESC;
```

### 月次パフォーマンスサマリー
```sql
SELECT
  TO_CHAR(action_date, 'YYYY-MM') AS 年月,
  partner_name,
  SUM(cv_count) AS CV総数,
  SUM(client_action_cost) AS 売上
FROM t_daily_performance_details
WHERE action_date >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '3 months')
  AND status_id = 1  -- 承認済のみ
GROUP BY TO_CHAR(action_date, 'YYYY-MM'), partner_id, partner_name
ORDER BY 年月 DESC, 売上 DESC;
```

---

## 運用ガイドライン

### パーティション管理

#### 新年度のパーティション作成
```sql
-- 2027年用パーティション作成（2026年12月に実施）
CREATE TABLE t_daily_perf_2027 PARTITION OF t_daily_performance_details
  FOR VALUES FROM ('2027-01-01') TO ('2028-01-01');

CREATE TABLE t_daily_click_2027 PARTITION OF t_daily_click_details
  FOR VALUES FROM ('2027-01-01') TO ('2028-01-01');
```

#### 古いパーティションの削除
```sql
-- 3年以上前のデータは削除（要アーカイブ後）
DROP TABLE t_daily_perf_2024;
DROP TABLE t_daily_click_2024;
```

### 監査ログの検索
```sql
-- 特定レコードの変更履歴（Agent/IF両対応）
SELECT
  al.operated_at,
  CASE al.operator_type
    WHEN 1 THEN a.agent_name
    WHEN 2 THEN i.influencer_name
  END AS 操作者,
  CASE al.operator_type WHEN 1 THEN 'Agent' WHEN 2 THEN 'IF' END AS 操作者種別,
  al.action_type AS 操作,
  al.old_value,
  al.new_value
FROM t_audit_logs al
LEFT JOIN m_agents a ON al.operator_type = 1 AND al.operator_id = a.agent_id
LEFT JOIN m_influencers i ON al.operator_type = 2 AND al.operator_id = i.influencer_id
WHERE al.table_name = 'm_influencers'
  AND al.record_id = 123
ORDER BY al.operated_at DESC;
```

### 単価変更の手順
```sql
-- トランザクション内で実施
BEGIN;

-- 1. 既存単価を終了
UPDATE t_unit_prices
SET
  end_at = CURRENT_DATE - INTERVAL '1 day',
  updated_by = :agent_id,
  updated_at = CURRENT_TIMESTAMP
WHERE site_id = :site_id
  AND content_id = :content_id
  AND client_id = :client_id
  AND is_active = TRUE
  AND (end_at IS NULL OR end_at >= CURRENT_DATE);

-- 2. 新単価を登録
INSERT INTO t_unit_prices (
  site_id, content_id, client_id,
  unit_price, start_at,
  created_by, updated_by
) VALUES (
  :site_id, :content_id, :client_id,
  :new_price, CURRENT_DATE,
  :agent_id, :agent_id
);

COMMIT;
```

### 既存テーブルへの監査カラム追加
```sql
-- 1. 一時的にNULL許容で追加
ALTER TABLE テーブル名
ADD COLUMN created_by BIGINT,
ADD COLUMN updated_by BIGINT;

-- 2. 既存データに初期値設定（システム管理者 ID=1）
UPDATE テーブル名
SET created_by = 1, updated_by = 1
WHERE created_by IS NULL;

-- 3. NOT NULL制約追加
ALTER TABLE テーブル名
ALTER COLUMN created_by SET NOT NULL,
ALTER COLUMN updated_by SET NOT NULL;
```

### インデックスのメンテナンス
```sql
-- 定期的なREINDEX（週次・夜間バッチ）
REINDEX TABLE t_daily_performance_details;
REINDEX TABLE t_daily_click_details;

-- VACUUM ANALYZE（日次・深夜実施）
VACUUM ANALYZE t_influencer_sns_accounts;
VACUUM ANALYZE t_influencer_agent_assignments;
```

### バックアップ戦略
```sql
-- フルバックアップ（日次）
pg_dump -Fc ansem_db > ansem_db_$(date +%Y%m%d).dump

-- テーブル単位バックアップ（重要マスタのみ）
pg_dump -Fc -t m_countries -t m_categories ansem_db > masters_$(date +%Y%m%d).dump

-- パーティション単位バックアップ（月次）
pg_dump -Fc -t t_daily_perf_2026 ansem_db > perf_2026_$(date +%Y%m%d).dump
```

### スケーリング方針

#### コネクションプーリング

本番環境では **PgBouncer** を導入し、DBコネクションを効率管理する。

```
[推奨設定]
- プーリングモード: transaction
- デフォルト接続上限: 100（PostgreSQL側 max_connections）
- PgBouncer側: default_pool_size = 25
- アプリケーション側: コネクションプールサイズ = 10〜20
```

> [!NOTE]
> ORM（Prisma/TypeORM等）のコネクションプール設定と PgBouncer の二重管理に注意。
> transaction モードの場合、PREPARE文やSET文はセッション単位で使えないため、ORM側で `pgbouncer=true` 相当の設定を入れること。

#### リードレプリカ

参照系クエリの負荷分散のため、ストリーミングレプリケーションでリードレプリカを構成する。

| 用途 | 接続先 | 対象テーブル |
|------|--------|-------------|
| 書き込み（INSERT/UPDATE/DELETE） | プライマリ | 全テーブル |
| レポート・集計クエリ | リードレプリカ | t_daily_performance_details, t_daily_click_details |
| 管理画面の一覧表示 | リードレプリカ | m_influencers, t_influencer_sns_accounts 等 |
| 監査ログ検索 | リードレプリカ | t_audit_logs |

> [!TIP]
> 初期はリードレプリカなしの単一構成で運用開始し、クエリ負荷が上がってきた段階で導入する。

#### t_audit_logs の肥大化対策（実装済み）

全テーブルの変更履歴が集中するため、最も早く肥大化するテーブル。月単位パーティション化で対策済み（セクション18のCREATE文に反映済み）。

```sql
-- パーティション化（実装済み — セクション18のCREATE文を参照）
-- PK: (operated_at, log_id) の複合キーで PARTITION BY RANGE (operated_at)

-- 月単位パーティション作成（005_create_partitions.sql で直近3年=36パーティション作成済み）
CREATE TABLE t_audit_logs_2024_01 PARTITION OF t_audit_logs
  FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
-- ...（以降、月次で2026年12月まで計36パーティション）

-- 13ヶ月以上前のパーティションはアーカイブ後に切り離し
ALTER TABLE t_audit_logs DETACH PARTITION t_audit_logs_2024_12;
-- アーカイブ（S3/GCS等へエクスポート後にDROP）
```

#### データアーカイブ戦略

| テーブル | 保持期間 | アーカイブ先 | 方法 |
|---------|---------|-------------|------|
| t_daily_performance_details | 3年 | S3/GCS（Parquet形式） | パーティションDETACH → COPY → DROP |
| t_daily_click_details | 3年 | S3/GCS（Parquet形式） | 同上 |
| t_audit_logs | 1年 | S3/GCS（JSONL形式） | パーティションDETACH → COPY → DROP |
| t_notifications | 6ヶ月（既読のみ） | 削除 | DELETE WHERE is_read = TRUE AND created_at < now() - interval '6 months' |

> [!WARNING]
> アーカイブ前に必ずバックアップを取得すること。DETACH PARTITION は CONCURRENTLY オプションでロックを最小化。

#### パーティション自動管理（将来検討）

現在は手動でパーティションを作成しているが、運用負荷軽減のため `pg_partman` 拡張の導入を検討する。

```sql
-- pg_partman 導入時の設定例（参考）
CREATE EXTENSION pg_partman;

-- t_audit_logs（月次パーティション）
SELECT partman.create_parent(
  p_parent_table := 'public.t_audit_logs',
  p_control := 'operated_at',
  p_type := 'native',
  p_interval := '1 month',
  p_premake := 3  -- 3ヶ月先まで自動作成
);

-- t_daily_performance_details（年次パーティション）
SELECT partman.create_parent(
  p_parent_table := 'public.t_daily_performance_details',
  p_control := 'action_date',
  p_type := 'native',
  p_interval := '1 year',
  p_premake := 1  -- 1年先まで自動作成
);

-- t_daily_click_details（年次パーティション）
SELECT partman.create_parent(
  p_parent_table := 'public.t_daily_click_details',
  p_control := 'action_date',
  p_type := 'native',
  p_interval := '1 year',
  p_premake := 1  -- 1年先まで自動作成
);
```

> [!TIP]
> `pg_partman` を導入すると、パーティションの自動作成・自動削除・デフォルトパーティションの管理が自動化され、月次パーティションの作成漏れを防止できる。

#### アクセス制御（将来検討）

本番運用時は以下のロールを定義し、最小権限の原則を適用する。

| ロール | 用途 | 権限 |
|-------|------|------|
| `ansem_app` | アプリケーション | SELECT / INSERT / UPDATE / DELETE |
| `ansem_readonly` | レポート・分析 | SELECT のみ |
| `ansem_admin` | 管理・DDL操作 | ALL PRIVILEGES |

> [!NOTE]
> ROLE/GRANT文は `006_create_roles.sql` として別途作成予定。本番デプロイ前に定義する。

---

## 参考情報

### 設計判断の記録

| 項目 | 判断 | 理由 |
|-----|------|------|
| 国マスタ | 作成 | 国際化対応・ISO準拠・外部キー制約 |
| 部署マスタ | 作成 | 階層構造・将来の組織変更対応 |
| 辞書テーブル | コメント管理 | 種類が少ないものはDDL不要（address_type_id等） |
| 集計テーブルの外部キー | あり（NOT NULL + FK） | データ整合性を担保。スナップショット名称カラムは別途保持 |
| t_partner_sitesの命名 | t_プレフィックス | 可変データ・状態変化あり |
| m_campaigns | 加工用テーブル | site_id×influencer_id×platform_idで案件管理 |
| m_partners_division | 新設 | IF卸/トータルマーケの区分管理 |
| m_partners_division.partner_name | 冗長カラム（許容） | BQ/ASP連携でJOIN不要にするため意図的に保持。m_partners.partner_nameと同値 |
| ingestion_logs | 新設 | BQデータ取り込みジョブ管理 |
| ingestion_logs命名 | プレフィックスなし | システムテーブルとして区別。将来sys_プレフィックスも検討 |
| t_billing_runs | 新設 | 請求確定スナップショット。論理削除（is_cancelled）方式。filter_conditions（JSONB）で抽出条件を保存 |
| t_billing_line_items | 新設 | 請求確定明細。t_daily_performance_detailsの確定版スナップショット。全FK ON DELETE RESTRICT |

### トラブルシューティング

#### 外部キー制約エラー
```sql
-- 参照先レコードの存在確認
SELECT * FROM parent_table WHERE parent_id = 123;

-- 制約の一時無効化（開発環境のみ）
ALTER TABLE child_table DISABLE TRIGGER ALL;
-- データ修正後
ALTER TABLE child_table ENABLE TRIGGER ALL;
```

#### パーティション作成漏れ
```sql
-- デフォルトパーティション作成（一時対応）
CREATE TABLE t_daily_performance_details_default
  PARTITION OF t_daily_performance_details DEFAULT;

-- 正しいパーティション作成後、データを移動
```

#### インデックス肥大化
```sql
-- インデックスサイズ確認
SELECT
  schemaname,
  tablename,
  indexname,
  pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
ORDER BY pg_relation_size(indexrelid) DESC;

-- 不要インデックスの削除検討
SELECT * FROM pg_stat_user_indexes WHERE idx_scan = 0;
```

---

## チェックリスト

### テーブル作成時
- [ ] 命名規則（m_/t_プレフィックス）に従っているか
- [ ] TEXT型・TIMESTAMPTZ型を使用しているか
- [ ] 監査カラム（4つ）をすべて含んでいるか
- [ ] 主キーはGENERATED ALWAYS AS IDENTITYか（例外①: SMALLINT手動採番、例外②: 1対1 FK主キー、例外③: 外部システムID一致）
- [ ] 外部キー制約は適切か（ON DELETE RESTRICT/CASCADE/SET NULL の使い分けルール参照）
- [ ] 楽観ロック（version）が必要なテーブルか
- [ ] インデックスは必要十分か
- [ ] コメントは充実しているか

### データ投入時
- [ ] トランザクション内で実施しているか
- [ ] created_by/updated_byを設定しているか
- [ ] タイポ（t→m等）がないか確認したか
- [ ] 外部キー制約違反がないか

### 本番リリース前
- [ ] 全テーブルのCREATE文が実行可能か
- [ ] パーティションが作成されているか
- [ ] バックアップ体制は整っているか
- [ ] 監視・アラート設定は完了しているか

---

## 変更履歴

| バージョン | 日付 | 変更内容 |
|---|---|---|
| 1.0.0 | 2026-02-06 | 初版（27テーブル） |
| 2.0.0 | 2026-02-09 | 全面改訂: プレフィックス整理、新規テーブル追加（m_partners_division, ingestion_logs）、日次集計テーブルにFK制約追加（NOT NULL + FK）、旧テーブル削除（t_campaign_influencers, t_partner_influencers）、m_campaigns構造変更、affiliation_type_id→m_departments紐付け |
| 3.0.0 | 2026-02-10 | スプシDDLアライメント: m_influencers/m_partners/m_clients等の構造変更、country_type_id→country_id、is_active→status_id統一、password_salt削除、設計方針例外追加（③外部システムID一致） |
| 4.0.0 | 2026-02-10 | レビュー指摘対応: t_billing_info billing_address_id削除、m_partners login_id削除、assigned_at TIMESTAMPTZ化、楽観ロック（version）追加、ON DELETEルール明文化、COMMENT値定義充実、updated_atトリガー追加、t_notifications新設（28テーブル化） |
| 5.0.0 | 2026-02-10 | 保留指摘対応: スケーリング方針追加（コネクションプーリング・リードレプリカ・audit_logsパーティション・アーカイブ戦略）、t_translations新設（多言語対応）、t_files新設（ファイル管理）→30テーブル化 |
| 5.1.0 | 2026-02-10 | コンテンツレビュー対応: 初期データ投入順序修正（C-23）、fk_campaign_site CASCADE→RESTRICT（C-1）、idx_assignments_role追加（C-4）、m_campaigns.status_id COMMENT値追加（C-9）、冗長インデックス5件削除（C-5/6/7）、entity_type番号統一（C-17）、display_order型統一（C-10）、CLAUDE.md記述修正（C-12）、m_partners_division FK追加（C-19）、t_audit_logs ポリモーフィック化（C-20: operator_type追加、Agent/IF両対応）、セキュリティテーブル差異統一 |
| 5.2.0 | 2026-02-10 | ドキュメント整理: 目次拡充（11項目化）、DDL実行順注記追加、COMMENT ON COLUMN全カラム網羅、ON UPDATE記述修正、構成整理（まとめ→変更履歴統合、タイポパターン削除、監査カラム追加手順を運用ガイドラインに移動） |
| 5.3.0 | 2026-02-12 | DDL整合性強化: t_audit_logsパーティション化実装（PK複合キー化+PARTITION BY RANGE）、CHECK制約追加（m_clients/m_agents/m_influencers/m_partners/t_partner_sites/t_influencer_sns_accounts/m_campaigns/m_ad_contents/t_billing_info/t_daily_performance_details）、is_primary部分UNIQUEインデックス追加（t_addresses/t_bank_accounts/t_billing_info/t_influencer_sns_accounts） |
| 5.4.0 | 2026-02-12 | 請求確定テーブル追加: t_billing_runs（請求確定バッチ・論理削除方式・filter_conditions JSONB）、t_billing_line_items（請求明細・スナップショット方式）を新設→32テーブル化。要件定義書とのギャップ分析に基づく追加 |

**作成日**: 2026-02-06
**バージョン**: 5.4.0
**ステータス**: 完成
**最終更新**: 2026-02-12
