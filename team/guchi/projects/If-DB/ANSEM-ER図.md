---
tags: [ANSEM, database, design, documentation, postgresql]
created: 2026-02-06
updated: 2026-02-06
status: completed
version: 1.0.0
---

# ANSEMプロジェクト データベース設計書

## 📋 目次

1. [プロジェクト概要](#プロジェクト概要)
2. [設計方針・原則](#設計方針原則)
3. [テーブル構成](#テーブル構成)
4. [ER図](#er図)
5. [テーブル詳細定義](#テーブル詳細定義)
6. [初期データ](#初期データ)
7. [使用例](#使用例)
8. [運用ガイドライン](#運用ガイドライン)

---

## 🎯 プロジェクト概要

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

## 📐 設計方針・原則

### 1. 命名規則

#### テーブル名
- **マスタテーブル**: `m_` プレフィックス
  - コード値、固定データ、あまり変更されないデータ
  - 例: `m_countries`, `m_categories`, `m_agents`
- **トランザクションテーブル**: `t_` プレフィックス
  - 可変データ、業務データ、状態が変化するデータ
  - 例: `t_influencers`, `t_campaigns`, `t_partners`

#### カラム名
- **主キー**: `{table}_id` 形式
  - 例: `influencer_id`, `campaign_id`
- **外部キー**: 参照先のテーブル名_id 形式
  - 例: `parent_category_id`, `department_id`
- **複合語**: スネークケース
  - 例: `created_at`, `email_address`, `follower_count`

#### 頻出タイポパターン（注意）
スプシからの転記時に発生しやすいタイポ:
- `t` → `m` パターン
  - `contenm` → `content`
  - `clienm` → `client`
  - `starm` → `start`
  - `CURRENm` → `CURRENT`
  - `agenm` → `agent`
  - `departmenm` → `department`
  - `parenm` → `parent`

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

#### 数値型
- **金額**: `DECIMAL(12, 0)` （整数円）
- **カウント**: `INTEGER` または `BIGINT`
- **ID**: `BIGINT GENERATED ALWAYS AS IDENTITY`
- **小さな種類**: `SMALLINT` (ステータスコード等)

#### 真偽値型
- **統一ルール**: `BOOLEAN` 型を使用
- **デフォルト値**: 明示的に設定
- **例**: `is_active BOOLEAN NOT NULL DEFAULT TRUE`

### 3. 監査カラム（全テーブル必須）
```sql
-- 作成者・更新者
created_by BIGINT NOT NULL,
updated_by BIGINT NOT NULL,

-- 作成日時・更新日時
created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
```

#### 追加手順（既存テーブル修正時）
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

### 4. 外部キー制約

#### 基本方針
- **必須**: すべての外部キーに制約を設定
- **削除制約**: 原則 `ON DELETE RESTRICT` （削除禁止）
- **更新制約**: デフォルト（CASCADE）

#### 集計テーブルの方針
- **集計テーブル**: 外部キー制約あり + スナップショット方式
  - `t_daily_performance_details` → `t_partners`, `t_partner_sites`, `m_clients`, `m_ad_contents`
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
- 例: `address_type_id` (1:請求先, 2:送付先), `billing_type_id` (1:個人, 2:法人)
```sql
-- コメントでの管理例
COMMENT ON COLUMN m_addresses.address_type_id IS
  '住所タイプID（1: 請求先住所, 2: 送付先住所）';
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

## 🗂️ テーブル構成

### 全体像（27テーブル）

#### マスタテーブル（18テーブル）

| # | テーブル名 | 日本語名 | 主な用途 |
|---|-----------|---------|---------|
| 1 | m_countries | 国マスタ | 国際化対応・ISO準拠 |
| 2 | m_categories | カテゴリマスタ | IFのジャンル分類（2階層） |
| 3 | m_departments | 部署マスタ | 組織階層管理 |
| 4 | m_agents | エージェントマスタ | 社内担当者管理 |
| 5 | m_agent_role_types | エージェント役割マスタ | 役割・権限定義 |
| 6 | m_agent_security | エージェント認証 | パスワード・セッション管理 |
| 7 | m_addresses | 住所情報 | 請求先・送付先住所 |
| 8 | m_bank_accounts | 銀行口座 | 振込先口座情報 |
| 9 | m_billing_info | 請求先情報 | 請求書発行情報 |
| 10 | m_ad_groups | 広告グループ | 広告の大分類 |
| 11 | m_ad_contents | 広告コンテンツ | 具体的な広告素材 |
| 12 | m_clients | クライアント | 広告主企業 |
| 13 | m_sns_platforms | SNSプラットフォーム | YouTube/Instagram等 |
| 14 | m_influencer_sns_accounts | IFのSNSアカウント | SNS別アカウント管理 |
| 15 | m_account_categories | アカウント×カテゴリ紐付け | 多対多中間テーブル |
| 16 | m_influencer_security | IF認証 | パスワード・セッション管理 |
| 17 | m_influencer_agent_assignments | IF×エージェント担当割当 | 担当者アサイン管理 |
| 18 | m_audit_logs | 共通監査ログ | 全テーブル横断的な履歴 |

#### トランザクションテーブル（9テーブル）

| # | テーブル名 | 日本語名 | 主な用途 |
|---|-----------|---------|---------|
| 1 | t_influencers | インフルエンサー | IFプロファイル管理 |
| 2 | t_partners | パートナー | ASP・広告配信パートナー |
| 3 | t_partner_sites | パートナーサイト | パートナーが運営するサイト |
| 4 | t_campaigns | キャンペーン | 広告キャンペーン管理 |
| 5 | t_campaign_influencers | キャンペーン×IF紐付け | 多対多中間テーブル |
| 6 | t_partner_influencers | パートナー×IF紐付け | 多対多中間テーブル |
| 7 | t_unit_prices | 単価設定 | サイト・コンテンツ別単価 |
| 8 | t_daily_performance_details | 日次CV集計 | パフォーマンスデータ（パーティション） |
| 9 | t_daily_click_details | 日次クリック集計 | クリックデータ（パーティション） |

### テーブル間リレーション概要

#### 中心的なエンティティ
1. **t_influencers（インフルエンサー）**
   - 住所、口座、認証、SNSアカウント、担当者割当と紐付く

2. **t_campaigns（キャンペーン）**
   - クライアント、広告グループ、IFと紐付く

3. **t_partners（パートナー）**
   - サイト、IFと紐付く
   - 単価設定の起点

#### リレーション図の構造
```
m_countries
  └─ m_addresses, m_bank_accounts

m_categories（階層）
  └─ m_account_categories
       └─ m_influencer_sns_accounts
            └─ t_influencers

m_departments（階層）
  └─ m_agents
       ├─ m_agent_security
       ├─ m_influencer_agent_assignments
       └─ m_audit_logs

t_influencers
  ├─ m_addresses
  ├─ m_bank_accounts
  ├─ m_billing_info
  ├─ m_influencer_security
  ├─ m_influencer_sns_accounts
  ├─ m_influencer_agent_assignments
  ├─ t_campaign_influencers
  └─ t_partner_influencers

t_partners
  ├─ t_partner_sites
  │    └─ t_unit_prices
  └─ t_partner_influencers

t_campaigns
  ├─ m_clients
  ├─ m_ad_groups
  └─ t_campaign_influencers

t_unit_prices
  ├─ t_partner_sites
  ├─ m_ad_contents
  └─ m_clients

t_daily_performance_details（スナップショット方式・FK制約あり）
  ├─ t_partners（partner_id）
  ├─ t_partner_sites（site_id）
  ├─ m_clients（client_id）
  └─ m_ad_contents（content_id）

t_daily_click_details（スナップショット方式・FK制約あり）
  └─ t_partner_sites（site_id）
```

---

## 🎨 ER図

### 全体ER図（Mermaid）
```mermaid
erDiagram
    %% ============================================================
    %% 🌏 国・カテゴリ系マスタ
    %% ============================================================

    m_countries ||--o{ m_addresses : "country_type_id"
    m_countries ||--o{ m_bank_accounts : "country_type_id"

    m_categories ||--o{ m_categories : "parent_category_id (階層)"
    m_categories ||--o{ m_account_categories : "category_id"

    %% ============================================================
    %% 🏢 組織・エージェント系マスタ
    %% ============================================================

    m_departments ||--o{ m_departments : "parent_department_id (階層)"
    m_departments ||--o{ m_agents : "department_id"

    m_agents ||--o| m_agent_security : "agent_id (1対1)"
    m_agents ||--o{ m_agent_role_types : "role_type_id"
    m_agents ||--o{ m_influencer_agent_assignments : "agent_id"
    m_agents ||--o{ m_audit_logs : "operator_id"

    %% ============================================================
    %% 📱 SNS・カテゴリ系マスタ
    %% ============================================================

    m_sns_platforms ||--o{ m_influencer_sns_accounts : "platform_id"

    m_influencer_sns_accounts ||--o{ m_account_categories : "account_id"

    %% ============================================================
    %% 📢 広告・クライアント系マスタ
    %% ============================================================

    m_ad_groups ||--o{ m_ad_contents : "ad_group_id"
    m_agents ||--o{ m_ad_contents : "person_id"

    m_ad_contents ||--o{ t_campaign_influencers : "content_id"
    m_ad_contents ||--o{ t_unit_prices : "content_id"

    m_clients ||--o{ t_campaigns : "client_id"
    m_clients ||--o{ m_billing_info : "client_id"
    m_clients ||--o{ t_unit_prices : "client_id"

    %% ============================================================
    %% 👤 インフルエンサー系トランザクション
    %% ============================================================

    t_influencers ||--o| m_influencer_security : "influencer_id (1対1)"
    t_influencers ||--o{ m_addresses : "influencer_id"
    t_influencers ||--o{ m_bank_accounts : "influencer_id"
    t_influencers ||--o{ m_billing_info : "influencer_id"
    t_influencers ||--o{ m_influencer_sns_accounts : "influencer_id"
    t_influencers ||--o{ m_influencer_agent_assignments : "influencer_id"
    t_influencers ||--o{ t_campaign_influencers : "influencer_id"
    t_influencers ||--o{ t_partner_influencers : "influencer_id"

    %% ============================================================
    %% 🤝 パートナー系トランザクション
    %% ============================================================

    t_partners ||--o{ t_partner_sites : "partner_id"
    t_partners ||--o{ t_partner_influencers : "partner_id"

    t_partner_sites ||--o{ t_unit_prices : "site_id"

    %% ============================================================
    %% 📊 キャンペーン系トランザクション
    %% ============================================================

    t_campaigns ||--o{ t_campaign_influencers : "campaign_id"
    m_ad_groups ||--o{ t_campaigns : "ad_group_id"

    %% ============================================================
    %% 📈 集計系トランザクション（FK制約あり・スナップショット方式）
    %% ============================================================

    t_partners ||--o{ t_daily_performance_details : "partner_id"
    t_partner_sites ||--o{ t_daily_performance_details : "site_id"
    m_clients ||--o{ t_daily_performance_details : "client_id"
    m_ad_contents ||--o{ t_daily_performance_details : "content_id"

    t_partner_sites ||--o{ t_daily_click_details : "site_id"

    %% ============================================================
    %% テーブル定義（主要カラムのみ）
    %% ============================================================

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
        BIGINT department_id FK
        TEXT agent_name
    }

    m_agent_security {
        BIGINT agent_id PK_FK
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
        TEXT content_name
    }

    m_clients {
        BIGINT client_id PK
        TEXT client_name
    }

    t_influencers {
        BIGINT influencer_id PK
        TEXT influencer_name
    }

    t_partners {
        BIGINT partner_id PK
        TEXT partner_name
    }

    t_partner_sites {
        BIGINT site_id PK
        BIGINT partner_id FK
        TEXT site_name
    }

    t_campaigns {
        BIGINT campaign_id PK
        BIGINT client_id FK
        TEXT campaign_name
    }

    t_unit_prices {
        BIGINT unit_price_id PK
        BIGINT site_id FK
        DECIMAL unit_price
    }

    t_daily_performance_details {
        DATE action_date PK
        BIGINT partner_id PK_FK
        BIGINT site_id PK_FK
        BIGINT client_id PK_FK
        BIGINT content_id PK_FK
        SMALLINT status_id PK
        TEXT partner_name
        TEXT site_name
        TEXT client_name
        TEXT content_name
        INTEGER cv_count
        DECIMAL client_action_cost
        DECIMAL unit_price
    }

    t_daily_click_details {
        DATE action_date PK
        BIGINT site_id PK_FK
        TEXT site_name
        INTEGER click_count
    }
```

---

## 📊 テーブル詳細定義

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
```

#### 初期データ
```sql
INSERT INTO m_countries (country_id, country_name, country_code, country_code_3, currency_code, phone_prefix, display_order, created_by, updated_by) VALUES
(1, '日本', 'JP', 'JPN', 'JPY', '+81', 1, 1, 1),
(2, '中国', 'CN', 'CHN', 'CNY', '+86', 2, 1, 1),
(3, '韓国', 'KR', 'KOR', 'KRW', '+82', 3, 1, 1),
(4, 'タイ', 'TH', 'THA', 'THB', '+66', 4, 1, 1),
(5, 'ベトナム', 'VN', 'VNM', 'VND', '+84', 5, 1, 1),
(6, 'シンガポール', 'SG', 'SGP', 'SGD', '+65', 6, 1, 1),
(7, 'マレーシア', 'MY', 'MYS', 'MYR', '+60', 7, 1, 1),
(8, 'インドネシア', 'ID', 'IDN', 'IDR', '+62', 8, 1, 1),
(9, 'フィリピン', 'PH', 'PHL', 'PHP', '+63', 9, 1, 1),
(10, '台湾', 'TW', 'TWN', 'TWD', '+886', 10, 1, 1),
(11, '香港', 'HK', 'HKG', 'HKD', '+852', 11, 1, 1),
(12, 'インド', 'IN', 'IND', 'INR', '+91', 12, 1, 1),
(20, 'アメリカ', 'US', 'USA', 'USD', '+1', 20, 1, 1),
(21, 'カナダ', 'CA', 'CAN', 'CAD', '+1', 21, 1, 1),
(30, 'イギリス', 'GB', 'GBR', 'GBP', '+44', 30, 1, 1),
(31, 'ドイツ', 'DE', 'DEU', 'EUR', '+49', 31, 1, 1),
(32, 'フランス', 'FR', 'FRA', 'EUR', '+33', 32, 1, 1),
(33, 'イタリア', 'IT', 'ITA', 'EUR', '+39', 33, 1, 1),
(34, 'スペイン', 'ES', 'ESP', 'EUR', '+34', 34, 1, 1),
(40, 'オーストラリア', 'AU', 'AUS', 'AUD', '+61', 40, 1, 1),
(41, 'ニュージーランド', 'NZ', 'NZL', 'NZD', '+64', 41, 1, 1);
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

  CONSTRAINT uk_category_code UNIQUE (category_code)
);

CREATE INDEX idx_categories_parent ON m_categories(parent_category_id);
CREATE INDEX idx_categories_active ON m_categories(is_active, display_order);

COMMENT ON TABLE m_categories IS 'カテゴリマスタ（2階層: 大カテゴリ・小カテゴリ）';
COMMENT ON COLUMN m_categories.parent_category_id IS '親カテゴリID（NULL=大カテゴリ）';
```

#### 初期データ（66カテゴリ）
```sql
-- 大カテゴリ15個
INSERT INTO m_categories (category_id, parent_category_id, category_name, category_code, display_order, created_by, updated_by)
OVERRIDING SYSTEM VALUE VALUES
(1, NULL, 'ファッション・美容', 'fashion_beauty', 1, 1, 1),
(2, NULL, 'ライフスタイル', 'lifestyle', 2, 1, 1),
(3, NULL, 'グルメ・料理', 'food_cooking', 3, 1, 1),
(4, NULL, '子育て・ファミリー', 'parenting_family', 4, 1, 1),
(5, NULL, 'エンタメ', 'entertainment', 5, 1, 1),
(6, NULL, 'ビジネス・自己啓発', 'business_selfdev', 6, 1, 1),
(7, NULL, 'スポーツ・フィットネス', 'sports_fitness', 7, 1, 1),
(8, NULL, 'ゲーム・ホビー', 'game_hobby', 8, 1, 1),
(9, NULL, 'テック・ガジェット', 'tech_gadget', 9, 1, 1),
(10, NULL, '旅行', 'travel', 10, 1, 1),
(11, NULL, 'ペット', 'pet', 11, 1, 1),
(12, NULL, 'アート・クリエイティブ', 'art_creative', 12, 1, 1),
(13, NULL, '音楽', 'music', 13, 1, 1),
(14, NULL, 'アダルト', 'adult', 14, 1, 1),
(15, NULL, 'その他', 'other', 99, 1, 1);

-- 小カテゴリ51個
INSERT INTO m_categories (parent_category_id, category_name, category_code, display_order, created_by, updated_by) VALUES
-- ファッション・美容
(1, 'ファッション全般', 'fashion_general', 1, 1, 1),
(1, 'メイク・コスメ', 'makeup_cosmetics', 2, 1, 1),
(1, 'スキンケア', 'skincare', 3, 1, 1),
(1, 'ヘアケア・ヘアスタイル', 'haircare_hairstyle', 4, 1, 1),
(1, 'ネイル', 'nail', 5, 1, 1),
-- ライフスタイル
(2, 'ライフスタイル全般', 'lifestyle_general', 1, 1, 1),
(2, 'インテリア・DIY', 'interior_diy', 2, 1, 1),
(2, 'ガーデニング', 'gardening', 3, 1, 1),
(2, '節約・マネー', 'saving_money', 4, 1, 1),
-- グルメ・料理
(3, 'グルメ全般', 'food_general', 1, 1, 1),
(3, 'レシピ・料理', 'recipe_cooking', 2, 1, 1),
(3, 'スイーツ・カフェ', 'sweets_cafe', 3, 1, 1),
(3, 'お酒・バー', 'alcohol_bar', 4, 1, 1),
-- 子育て・ファミリー
(4, '子育て全般', 'parenting_general', 1, 1, 1),
(4, '妊娠・出産', 'pregnancy_birth', 2, 1, 1),
(4, 'キッズファッション', 'kids_fashion', 3, 1, 1),
(4, '教育', 'education', 4, 1, 1),
-- エンタメ
(5, 'エンタメ全般', 'entertainment_general', 1, 1, 1),
(5, '映画・ドラマ', 'movie_drama', 2, 1, 1),
(5, 'アニメ・漫画', 'anime_manga', 3, 1, 1),
(5, 'アイドル・芸能', 'idol_celebrity', 4, 1, 1),
(5, 'お笑い', 'comedy', 5, 1, 1),
-- ビジネス・自己啓発
(6, 'ビジネス全般', 'business_general', 1, 1, 1),
(6, '自己啓発', 'selfdev', 2, 1, 1),
(6, '転職・キャリア', 'career', 3, 1, 1),
(6, '起業・副業', 'startup_sidejob', 4, 1, 1),
-- スポーツ・フィットネス
(7, 'スポーツ全般', 'sports_general', 1, 1, 1),
(7, 'フィットネス・筋トレ', 'fitness_workout', 2, 1, 1),
(7, 'ヨガ・ピラティス', 'yoga_pilates', 3, 1, 1),
(7, 'ランニング', 'running', 4, 1, 1),
-- ゲーム・ホビー
(8, 'ゲーム全般', 'game_general', 1, 1, 1),
(8, 'e-Sports', 'esports', 2, 1, 1),
(8, 'プラモデル・フィギュア', 'model_figure', 3, 1, 1),
(8, 'カードゲーム', 'cardgame', 4, 1, 1),
-- テック・ガジェット
(9, 'テック全般', 'tech_general', 1, 1, 1),
(9, 'スマホ・PC', 'smartphone_pc', 2, 1, 1),
(9, 'カメラ・写真', 'camera_photo', 3, 1, 1),
(9, 'プログラミング', 'programming', 4, 1, 1),
-- 旅行
(10, '旅行全般', 'travel_general', 1, 1, 1),
(10, '国内旅行', 'travel_domestic', 2, 1, 1),
(10, '海外旅行', 'travel_overseas', 3, 1, 1),
-- ペット
(11, 'ペット全般', 'pet_general', 1, 1, 1),
(11, '犬', 'dog', 2, 1, 1),
(11, '猫', 'cat', 3, 1, 1),
-- アート・クリエイティブ
(12, 'アート全般', 'art_general', 1, 1, 1),
(12, 'イラスト・デザイン', 'illustration_design', 2, 1, 1),
(12, 'ハンドメイド', 'handmade', 3, 1, 1),
-- 音楽
(13, '音楽全般', 'music_general', 1, 1, 1),
(13, '楽器演奏', 'instrument', 2, 1, 1),
-- アダルト
(14, 'アダルトコンテンツ', 'adult_content', 1, 1, 1),
-- その他
(15, 'その他', 'other_general', 1, 1, 1);
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
```

#### 初期データ
```sql
-- 親部署（事業部）
INSERT INTO m_departments (department_id, parent_department_id, department_name, department_code, display_order, created_by, updated_by)
OVERRIDING SYSTEM VALUE VALUES
(1, NULL, 'インフルエンサー第一事業部', 'S1', 1, 1, 1),
(2, NULL, 'インフルエンサー第二事業部', 'S2', 2, 1, 1),
(3, NULL, '管理部', 'ADMIN', 3, 1, 1);

-- 子部署（部門）
INSERT INTO m_departments (parent_department_id, department_name, department_code, display_order, created_by, updated_by) VALUES
-- 第一事業部配下
(1, 'マーケティング部', 'S1-MKT', 1, 1, 1),
(1, '営業部', 'S1-SALES', 2, 1, 1),
(1, 'コンテンツ企画部', 'S1-CONTENT', 3, 1, 1),
-- 第二事業部配下
(2, 'マーケティング部', 'S2-MKT', 1, 1, 1),
(2, '営業部', 'S2-SALES', 2, 1, 1),
(2, 'コンテンツ企画部', 'S2-CONTENT', 3, 1, 1),
-- 管理部配下
(3, '経理部', 'ADMIN-ACC', 1, 1, 1),
(3, '人事部', 'ADMIN-HR', 2, 1, 1);
```

---

### 4. m_agents（エージェントマスタ）

#### 概要
社内担当者（営業・マーケ・企画）のマスタ。

#### CREATE文
```sql
CREATE TABLE m_agents (
  agent_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  department_id BIGINT,
  agent_name TEXT NOT NULL,
  email_address TEXT NOT NULL UNIQUE,
  phone_number TEXT,
  status_id SMALLINT NOT NULL DEFAULT 1,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  hired_at DATE,
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_agent_department
    FOREIGN KEY (department_id)
    REFERENCES m_departments(department_id)
    ON DELETE RESTRICT
);

CREATE INDEX idx_agents_department ON m_agents(department_id);
CREATE INDEX idx_agents_email ON m_agents(email_address);
CREATE INDEX idx_agents_status ON m_agents(status_id, is_active);

COMMENT ON TABLE m_agents IS 'エージェント（社内担当者）マスタ';
COMMENT ON COLUMN m_agents.status_id IS 'ステータス（1: 在籍中, 2: 休職中, 3: 退職済）';
```

---

### 5. m_agent_role_types（エージェント役割マスタ）

#### 概要
担当者の役割定義（メイン・サブ・スカウト）。

#### CREATE文
```sql
CREATE TABLE m_agent_role_types (
  role_type_id SMALLINT PRIMARY KEY,
  role_name TEXT NOT NULL UNIQUE,
  role_description TEXT,
  can_edit_profile BOOLEAN NOT NULL DEFAULT FALSE,
  can_view_financials BOOLEAN NOT NULL DEFAULT FALSE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  display_order INTEGER NOT NULL DEFAULT 0,
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE m_agent_role_types IS 'エージェント役割タイプマスタ';
COMMENT ON COLUMN m_agent_role_types.can_edit_profile IS 'プロフィール編集権限';
COMMENT ON COLUMN m_agent_role_types.can_view_financials IS '財務情報閲覧権限';
```

#### 初期データ
```sql
INSERT INTO m_agent_role_types (role_type_id, role_name, can_edit_profile, can_view_financials, display_order, created_by, updated_by) VALUES
(1, 'メイン担当', TRUE, TRUE, 1, 1, 1),
(2, 'サブ担当', TRUE, FALSE, 2, 1, 1),
(3, 'スカウト担当', FALSE, FALSE, 3, 1, 1);
```

---

### 6. m_agent_security（エージェント認証）

#### 概要
エージェント用の認証情報（1対1）。

#### CREATE文
```sql
CREATE TABLE m_agent_security (
  agent_id BIGINT PRIMARY KEY,
  password_hash TEXT NOT NULL,
  password_salt TEXT,
  session_token TEXT,
  session_expires_at TIMESTAMPTZ,
  last_login_at TIMESTAMPTZ,
  last_login_ip TEXT,
  password_changed_at TIMESTAMPTZ,
  failed_login_attempts INTEGER NOT NULL DEFAULT 0,
  locked_until TIMESTAMPTZ,
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_agent_security_agent
    FOREIGN KEY (agent_id)
    REFERENCES m_agents(agent_id)
    ON DELETE CASCADE
);

CREATE INDEX idx_agent_security_session ON m_agent_security(session_token)
  WHERE session_token IS NOT NULL;
CREATE INDEX idx_agent_security_locked ON m_agent_security(locked_until)
  WHERE locked_until IS NOT NULL;

COMMENT ON TABLE m_agent_security IS 'エージェント認証情報（1対1）';
```

---

### 7. m_addresses（住所情報）

#### 概要
インフルエンサーの住所管理。請求先・送付先を区別。

#### CREATE文
```sql
CREATE TABLE m_addresses (
  address_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  influencer_id BIGINT NOT NULL,
  address_type_id SMALLINT NOT NULL,
  country_type_id SMALLINT NOT NULL,
  recipient_name TEXT NOT NULL,
  zip_code TEXT,
  state_province TEXT,
  city TEXT NOT NULL,
  address_line1 TEXT NOT NULL,
  address_line2 TEXT,
  phone_number TEXT,
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_address_influencer
    FOREIGN KEY (influencer_id)
    REFERENCES t_influencers(influencer_id)
    ON DELETE RESTRICT,

  CONSTRAINT fk_address_country
    FOREIGN KEY (country_type_id)
    REFERENCES m_countries(country_id)
    ON DELETE RESTRICT
);

CREATE INDEX idx_addresses_influencer ON m_addresses(influencer_id, is_active);
CREATE INDEX idx_addresses_type ON m_addresses(address_type_id);

COMMENT ON TABLE m_addresses IS '住所情報';
COMMENT ON COLUMN m_addresses.address_type_id IS '住所タイプ（1: 請求先住所, 2: 送付先住所）';
```

---

### 8. m_bank_accounts（銀行口座）

#### 概要
インフルエンサーの振込先口座情報。

#### CREATE文
```sql
CREATE TABLE m_bank_accounts (
  bank_account_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  influencer_id BIGINT NOT NULL,
  country_type_id SMALLINT NOT NULL,
  bank_name TEXT NOT NULL,
  branch_name TEXT,
  account_type_id SMALLINT NOT NULL,
  account_number TEXT NOT NULL,
  account_holder_name TEXT NOT NULL,
  swift_code TEXT,
  iban TEXT,
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_bank_account_influencer
    FOREIGN KEY (influencer_id)
    REFERENCES t_influencers(influencer_id)
    ON DELETE RESTRICT,

  CONSTRAINT fk_bank_account_country
    FOREIGN KEY (country_type_id)
    REFERENCES m_countries(country_id)
    ON DELETE RESTRICT
);

CREATE INDEX idx_bank_accounts_influencer ON m_bank_accounts(influencer_id, is_active);

COMMENT ON TABLE m_bank_accounts IS '銀行口座情報';
COMMENT ON COLUMN m_bank_accounts.account_type_id IS '口座種別（1: 普通, 2: 当座, 3: 貯蓄）';
```

---

### 9. m_billing_info（請求先情報）

#### 概要
請求書発行用の情報。法人・個人を区別。

#### CREATE文
```sql
CREATE TABLE m_billing_info (
  billing_info_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  influencer_id BIGINT,
  client_id BIGINT,
  billing_type_id SMALLINT NOT NULL,
  billing_address_id BIGINT NOT NULL,
  billing_name TEXT NOT NULL,
  invoice_recipient_email TEXT NOT NULL,
  invoice_tax_id TEXT,
  payment_terms_days INTEGER NOT NULL DEFAULT 30,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_billing_influencer
    FOREIGN KEY (influencer_id)
    REFERENCES t_influencers(influencer_id)
    ON DELETE RESTRICT,

  CONSTRAINT fk_billing_client
    FOREIGN KEY (client_id)
    REFERENCES m_clients(client_id)
    ON DELETE RESTRICT,

  CONSTRAINT fk_billing_address
    FOREIGN KEY (billing_address_id)
    REFERENCES m_addresses(address_id)
    ON DELETE RESTRICT,

  CONSTRAINT chk_billing_owner
    CHECK ((influencer_id IS NOT NULL AND client_id IS NULL) OR
           (influencer_id IS NULL AND client_id IS NOT NULL))
);

CREATE INDEX idx_billing_influencer ON m_billing_info(influencer_id, is_active);
CREATE INDEX idx_billing_client ON m_billing_info(client_id, is_active);

COMMENT ON TABLE m_billing_info IS '請求先情報';
COMMENT ON COLUMN m_billing_info.billing_type_id IS '請求区分（1: 個人, 2: 法人）';
```

---

### 10. m_ad_groups（広告グループ）

#### 概要
広告の大分類（プロジェクト単位）。

#### CREATE文
```sql
CREATE TABLE m_ad_groups (
  ad_group_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  ad_group_name TEXT NOT NULL,
  ad_group_description TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  display_order INTEGER NOT NULL DEFAULT 0,
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ad_groups_active ON m_ad_groups(is_active, display_order);

COMMENT ON TABLE m_ad_groups IS '広告グループマスタ';
```

---

### 11. m_ad_contents（広告コンテンツ）

#### 概要
具体的な広告素材・訴求内容。

#### CREATE文
```sql
CREATE TABLE m_ad_contents (
  content_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  ad_group_id BIGINT NOT NULL,
  person_id BIGINT,
  content_name TEXT NOT NULL,
  content_description TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  display_order INTEGER NOT NULL DEFAULT 0,
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_content_ad_group
    FOREIGN KEY (ad_group_id)
    REFERENCES m_ad_groups(ad_group_id)
    ON DELETE RESTRICT,

  CONSTRAINT fk_content_person
    FOREIGN KEY (person_id)
    REFERENCES m_agents(agent_id)
    ON DELETE RESTRICT
);

CREATE INDEX idx_ad_contents_group ON m_ad_contents(ad_group_id, is_active);
CREATE INDEX idx_ad_contents_person ON m_ad_contents(person_id);

COMMENT ON TABLE m_ad_contents IS '広告コンテンツマスタ';
COMMENT ON COLUMN m_ad_contents.person_id IS '担当者ID（外部キー → m_agents）';
```

---

### 12. m_clients（クライアント）

#### 概要
広告主企業のマスタ。

#### CREATE文
```sql
CREATE TABLE m_clients (
  client_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  client_name TEXT NOT NULL,
  company_name TEXT NOT NULL,
  email_address TEXT,
  phone_number TEXT,
  status_id SMALLINT NOT NULL DEFAULT 1,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  contract_start_date DATE,
  contract_end_date DATE,
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_clients_status ON m_clients(status_id, is_active);
CREATE INDEX idx_clients_name ON m_clients(client_name);

COMMENT ON TABLE m_clients IS 'クライアント（広告主）マスタ';
COMMENT ON COLUMN m_clients.status_id IS 'ステータス（1: 契約中, 2: 契約終了）';
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
```

#### 初期データ
```sql
INSERT INTO m_sns_platforms (platform_id, platform_name, platform_code, url_pattern, display_order, created_by, updated_by)
OVERRIDING SYSTEM VALUE VALUES
(1, 'YouTube', 'YOUTUBE', 'https://youtube.com/@{handle}', 1, 1, 1),
(2, 'Instagram', 'INSTAGRAM', 'https://instagram.com/{handle}', 2, 1, 1),
(3, 'X (Twitter)', 'X', 'https://x.com/{handle}', 3, 1, 1),
(4, 'TikTok', 'TIKTOK', 'https://tiktok.com/@{handle}', 4, 1, 1),
(5, 'Facebook', 'FACEBOOK', 'https://facebook.com/{handle}', 5, 1, 1),
(6, 'LINE', 'LINE', NULL, 6, 1, 1),
(7, 'note', 'NOTE', 'https://note.com/{handle}', 7, 1, 1),
(8, 'ニコニコ動画', 'NICONICO', 'https://nicovideo.jp/user/{id}', 8, 1, 1),
(9, 'Twitch', 'TWITCH', 'https://twitch.tv/{handle}', 9, 1, 1),
(10, 'LinkedIn', 'LINKEDIN', 'https://linkedin.com/in/{handle}', 10, 1, 1),
(11, 'Threads', 'THREADS', 'https://threads.net/@{handle}', 11, 1, 1);
```

---

### 14. m_influencer_sns_accounts（IFのSNSアカウント）

#### 概要
インフルエンサーが運営するSNSアカウント情報。

#### CREATE文
```sql
CREATE TABLE m_influencer_sns_accounts (
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
    REFERENCES t_influencers(influencer_id)
    ON DELETE RESTRICT,

  CONSTRAINT fk_sns_account_platform
    FOREIGN KEY (platform_id)
    REFERENCES m_sns_platforms(platform_id)
    ON DELETE RESTRICT
);

CREATE INDEX idx_sns_accounts_influencer ON m_influencer_sns_accounts(influencer_id, status_id);
CREATE INDEX idx_sns_accounts_platform ON m_influencer_sns_accounts(platform_id);
CREATE INDEX idx_sns_accounts_follower ON m_influencer_sns_accounts(follower_count DESC)
  WHERE status_id = 1;

COMMENT ON TABLE m_influencer_sns_accounts IS 'インフルエンサーのSNSアカウント';
COMMENT ON COLUMN m_influencer_sns_accounts.status_id IS 'ステータス（1: 有効, 2: 停止中, 3: 削除済）';
```

---

### 15. m_account_categories（アカウント×カテゴリ紐付け）

#### 概要
SNSアカウントとカテゴリの多対多中間テーブル。

#### CREATE文
```sql
CREATE TABLE m_account_categories (
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
    REFERENCES m_influencer_sns_accounts(account_id)
    ON DELETE CASCADE,

  CONSTRAINT fk_account_category_category
    FOREIGN KEY (category_id)
    REFERENCES m_categories(category_id)
    ON DELETE RESTRICT,

  CONSTRAINT uk_account_category UNIQUE (account_id, category_id)
);

CREATE INDEX idx_account_categories_account ON m_account_categories(account_id);
CREATE INDEX idx_account_categories_category ON m_account_categories(category_id);

COMMENT ON TABLE m_account_categories IS 'アカウント×カテゴリ紐付け（多対多）';
COMMENT ON COLUMN m_account_categories.is_primary IS 'メインカテゴリフラグ';
```

---

### 16. m_influencer_security（IF認証）

#### 概要
インフルエンサー用の認証情報（1対1）。

#### CREATE文
```sql
CREATE TABLE m_influencer_security (
  influencer_id BIGINT PRIMARY KEY,
  password_hash TEXT NOT NULL,
  password_salt TEXT,
  session_token TEXT,
  session_expires_at TIMESTAMPTZ,
  last_login_at TIMESTAMPTZ,
  last_login_ip TEXT,
  failed_login_attempts INTEGER NOT NULL DEFAULT 0,
  locked_until TIMESTAMPTZ,
  password_reset_token TEXT,
  reset_token_expires_at TIMESTAMPTZ,
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_influencer_security_influencer
    FOREIGN KEY (influencer_id)
    REFERENCES t_influencers(influencer_id)
    ON DELETE CASCADE
);

CREATE INDEX idx_influencer_security_session ON m_influencer_security(session_token)
  WHERE session_token IS NOT NULL;
CREATE INDEX idx_influencer_security_reset ON m_influencer_security(password_reset_token)
  WHERE password_reset_token IS NOT NULL;

COMMENT ON TABLE m_influencer_security IS 'インフルエンサー認証情報（1対1）';
```

---

### 17. m_influencer_agent_assignments（IF×エージェント担当割当）

#### 概要
インフルエンサーへの担当者アサイン管理。履歴対応。

#### CREATE文
```sql
CREATE TABLE m_influencer_agent_assignments (
  assignment_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  influencer_id BIGINT NOT NULL,
  agent_id BIGINT NOT NULL,
  role_type_id SMALLINT NOT NULL,
  assigned_at DATE NOT NULL DEFAULT CURRENT_DATE,
  unassigned_at DATE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_assignment_influencer
    FOREIGN KEY (influencer_id)
    REFERENCES t_influencers(influencer_id)
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

CREATE INDEX idx_assignments_influencer ON m_influencer_agent_assignments(influencer_id, is_active);
CREATE INDEX idx_assignments_agent ON m_influencer_agent_assignments(agent_id, is_active);

COMMENT ON TABLE m_influencer_agent_assignments IS 'インフルエンサー×エージェント担当割当';
```

---

### 18. m_audit_logs（共通監査ログ）

#### 概要
全テーブル横断的な変更履歴管理（ハイブリッド設計）。

#### CREATE文
```sql
CREATE TABLE m_audit_logs (
  log_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  table_name TEXT NOT NULL,
  record_id BIGINT NOT NULL,
  action_type TEXT NOT NULL,
  old_value JSONB,
  new_value JSONB,
  operator_id BIGINT NOT NULL,
  operator_ip TEXT,
  operated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_audit_operator
    FOREIGN KEY (operator_id)
    REFERENCES m_agents(agent_id)
    ON DELETE RESTRICT,

  CONSTRAINT chk_action_type
    CHECK (action_type IN ('INSERT', 'UPDATE', 'DELETE'))
);

CREATE INDEX idx_audit_logs_table_record ON m_audit_logs(table_name, record_id);
CREATE INDEX idx_audit_logs_operator ON m_audit_logs(operator_id, operated_at);
CREATE INDEX idx_audit_logs_operated ON m_audit_logs(operated_at);
CREATE INDEX idx_audit_logs_old_value ON m_audit_logs USING GIN (old_value);
CREATE INDEX idx_audit_logs_new_value ON m_audit_logs USING GIN (new_value);

COMMENT ON TABLE m_audit_logs IS '共通監査ログ（全テーブル横断的な履歴管理）';
COMMENT ON COLUMN m_audit_logs.action_type IS '操作種別（INSERT/UPDATE/DELETE）';
```

---

### 19. t_influencers（インフルエンサー）

#### 概要
インフルエンサーのプロファイル情報。中心的エンティティ。

#### CREATE文
```sql
CREATE TABLE t_influencers (
  influencer_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  influencer_name TEXT NOT NULL,
  email_address TEXT NOT NULL UNIQUE,
  phone_number TEXT,
  date_of_birth DATE,
  gender_id SMALLINT,
  status_id SMALLINT NOT NULL DEFAULT 1,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  joined_at DATE NOT NULL DEFAULT CURRENT_DATE,
  notes TEXT,
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_influencers_email ON t_influencers(email_address);
CREATE INDEX idx_influencers_status ON t_influencers(status_id, is_active);
CREATE INDEX idx_influencers_name ON t_influencers(influencer_name);

COMMENT ON TABLE t_influencers IS 'インフルエンサーマスタ';
COMMENT ON COLUMN t_influencers.status_id IS 'ステータス（1: 契約中, 2: 休止中, 3: 契約終了）';
COMMENT ON COLUMN t_influencers.gender_id IS '性別（1: 男性, 2: 女性, 3: その他, 9: 未回答）';
```

---

### 20. t_partners（パートナー）

#### 概要
ASP・広告配信パートナー企業。

#### CREATE文
```sql
CREATE TABLE t_partners (
  partner_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  partner_name TEXT NOT NULL,
  company_name TEXT NOT NULL,
  email_address TEXT,
  phone_number TEXT,
  status_id SMALLINT NOT NULL DEFAULT 1,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  contract_start_date DATE,
  contract_end_date DATE,
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_partners_status ON t_partners(status_id, is_active);
CREATE INDEX idx_partners_name ON t_partners(partner_name);

COMMENT ON TABLE t_partners IS 'パートナー（ASP・広告配信企業）';
COMMENT ON COLUMN t_partners.status_id IS 'ステータス（1: 契約中, 2: 契約終了）';
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
    REFERENCES t_partners(partner_id)
    ON DELETE RESTRICT
);

CREATE INDEX idx_partner_sites_partner ON t_partner_sites(partner_id, is_active);
CREATE INDEX idx_partner_sites_status ON t_partner_sites(status_id);

COMMENT ON TABLE t_partner_sites IS 'パートナーサイト';
COMMENT ON COLUMN t_partner_sites.status_id IS 'ステータス（1: 稼働中, 2: 停止中）';
```

---

### 22. t_campaigns（キャンペーン）

#### 概要
広告キャンペーン管理。

#### CREATE文
```sql
CREATE TABLE t_campaigns (
  campaign_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  client_id BIGINT NOT NULL,
  ad_group_id BIGINT NOT NULL,
  campaign_name TEXT NOT NULL,
  campaign_description TEXT,
  start_date DATE NOT NULL,
  end_date DATE,
  budget_amount DECIMAL(12, 0),
  status_id SMALLINT NOT NULL DEFAULT 1,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_campaign_client
    FOREIGN KEY (client_id)
    REFERENCES m_clients(client_id)
    ON DELETE RESTRICT,

  CONSTRAINT fk_campaign_ad_group
    FOREIGN KEY (ad_group_id)
    REFERENCES m_ad_groups(ad_group_id)
    ON DELETE RESTRICT
);

CREATE INDEX idx_campaigns_client ON t_campaigns(client_id, status_id);
CREATE INDEX idx_campaigns_ad_group ON t_campaigns(ad_group_id);
CREATE INDEX idx_campaigns_dates ON t_campaigns(start_date, end_date);

COMMENT ON TABLE t_campaigns IS 'キャンペーン';
COMMENT ON COLUMN t_campaigns.status_id IS 'ステータス（1: 準備中, 2: 実施中, 3: 終了）';
```

---

### 23. t_campaign_influencers（キャンペーン×IF紐付け）

#### 概要
キャンペーンへのインフルエンサーアサイン（多対多中間）。

#### CREATE文
```sql
CREATE TABLE t_campaign_influencers (
  campaign_influencer_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  campaign_id BIGINT NOT NULL,
  influencer_id BIGINT NOT NULL,
  content_id BIGINT NOT NULL,
  assigned_at DATE NOT NULL DEFAULT CURRENT_DATE,
  status_id SMALLINT NOT NULL DEFAULT 1,
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_campaign_influencer_campaign
    FOREIGN KEY (campaign_id)
    REFERENCES t_campaigns(campaign_id)
    ON DELETE RESTRICT,

  CONSTRAINT fk_campaign_influencer_influencer
    FOREIGN KEY (influencer_id)
    REFERENCES t_influencers(influencer_id)
    ON DELETE RESTRICT,

  CONSTRAINT fk_campaign_influencer_content
    FOREIGN KEY (content_id)
    REFERENCES m_ad_contents(content_id)
    ON DELETE RESTRICT,

  CONSTRAINT uk_campaign_influencer_content UNIQUE (campaign_id, influencer_id, content_id)
);

CREATE INDEX idx_campaign_influencers_campaign ON t_campaign_influencers(campaign_id, status_id);
CREATE INDEX idx_campaign_influencers_influencer ON t_campaign_influencers(influencer_id);

COMMENT ON TABLE t_campaign_influencers IS 'キャンペーン×インフルエンサー紐付け';
COMMENT ON COLUMN t_campaign_influencers.status_id IS 'ステータス（1: 依頼中, 2: 承諾, 3: 拒否, 4: 完了）';
```

---

### 24. t_partner_influencers（パートナー×IF紐付け）

#### 概要
パートナーとインフルエンサーの提携関係（多対多中間）。

#### CREATE文
```sql
CREATE TABLE t_partner_influencers (
  partner_influencer_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  partner_id BIGINT NOT NULL,
  influencer_id BIGINT NOT NULL,
  joined_at DATE NOT NULL DEFAULT CURRENT_DATE,
  status_id SMALLINT NOT NULL DEFAULT 1,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_partner_influencer_partner
    FOREIGN KEY (partner_id)
    REFERENCES t_partners(partner_id)
    ON DELETE RESTRICT,

  CONSTRAINT fk_partner_influencer_influencer
    FOREIGN KEY (influencer_id)
    REFERENCES t_influencers(influencer_id)
    ON DELETE RESTRICT,

  CONSTRAINT uk_partner_influencer UNIQUE (partner_id, influencer_id)
);

CREATE INDEX idx_partner_influencers_partner ON t_partner_influencers(partner_id, is_active);
CREATE INDEX idx_partner_influencers_influencer ON t_partner_influencers(influencer_id, is_active);

COMMENT ON TABLE t_partner_influencers IS 'パートナー×インフルエンサー紐付け';
COMMENT ON COLUMN t_partner_influencers.status_id IS 'ステータス（1: 提携中, 2: 休止中, 3: 提携終了）';
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
COMMENT ON COLUMN t_unit_prices.semi_unit_price IS '準単価（用途要確認）';
COMMENT ON COLUMN t_unit_prices.limit_cap IS '上限キャップ（件数）';
COMMENT ON COLUMN t_unit_prices.end_at IS '有効期間終了日（NULL=無期限）';
```

---

### 26. t_daily_performance_details（日次CV集計）

#### 概要
日次コンバージョン集計データ。パーティション対応。外部キー制約なし。

#### CREATE文
```sql
-- ============================================================
-- 📊 日次パフォーマンス詳細（CV版・パーティション対応）
-- ============================================================

CREATE TABLE t_daily_performance_details (
  -- 集計軸（Dimensions）
  action_date DATE NOT NULL,
  partner_id BIGINT NOT NULL,
  site_id BIGINT,
  client_id BIGINT NOT NULL,
  content_id BIGINT,
  status_id SMALLINT NOT NULL DEFAULT 1,

  -- 表示用名称（Snapshots）
  partner_name TEXT,
  site_name TEXT,
  client_name TEXT,
  content_name TEXT,

  -- 集計値（Metrics）
  cv_count INTEGER NOT NULL DEFAULT 0,
  client_action_cost DECIMAL(12, 0) NOT NULL DEFAULT 0,
  unit_price DECIMAL(12, 0) NOT NULL DEFAULT 0,

  -- 監査
  created_by BIGINT NOT NULL DEFAULT 1,
  updated_by BIGINT NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  -- 複合主キー
  PRIMARY KEY (action_date, partner_id, COALESCE(site_id, 0), client_id, COALESCE(content_id, 0), status_id),

  -- 外部キー制約
  CONSTRAINT fk_daily_perf_partner
    FOREIGN KEY (partner_id)
    REFERENCES t_partners(partner_id)
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
    ON DELETE RESTRICT
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
COMMENT ON COLUMN t_daily_performance_details.partner_id IS 'パートナーID（FK → t_partners）';
COMMENT ON COLUMN t_daily_performance_details.site_id IS 'サイトID（FK → t_partner_sites / NULL=未設定）';
COMMENT ON COLUMN t_daily_performance_details.client_id IS 'クライアントID（FK → m_clients）';
COMMENT ON COLUMN t_daily_performance_details.content_id IS 'コンテンツID（FK → m_ad_contents / NULL=未設定）';
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
> `site_id` と `content_id` はNULL許容。未設定の場合はNULLが入る（FK制約はNULLをスキップするため整合性を保てる）。
> 複合主キーではCOALESCEでNULLを0に変換し、一意性を担保。

---

### 27. t_daily_click_details（日次クリック集計）

#### 概要
日次クリック集計データ。パーティション対応。外部キー制約なし。

#### CREATE文
```sql
-- ============================================================
-- 📊 日次クリック詳細（パーティション対応）
-- ============================================================

CREATE TABLE t_daily_click_details (
  -- 集計軸（Dimensions）
  action_date DATE NOT NULL,
  site_id BIGINT,

  -- 表示用名称（Snapshots）
  site_name TEXT,

  -- 集計値（Metrics）
  click_count INTEGER NOT NULL DEFAULT 0,

  -- 監査
  created_by BIGINT NOT NULL DEFAULT 1,
  updated_by BIGINT NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  -- 複合主キー
  PRIMARY KEY (action_date, COALESCE(site_id, 0)),

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
COMMENT ON COLUMN t_daily_click_details.site_id IS 'サイトID（FK → t_partner_sites / NULL=未設定）';
COMMENT ON COLUMN t_daily_click_details.site_name IS 'サイト名（スナップショット・集計時点の名称）';
COMMENT ON COLUMN t_daily_click_details.click_count IS 'クリック件数（広告リンクのクリック数）';
COMMENT ON COLUMN t_daily_click_details.created_by IS '作成者（システムユーザーID=1）';
COMMENT ON COLUMN t_daily_click_details.updated_by IS '最終更新者（システムユーザーID=1）';
COMMENT ON COLUMN t_daily_click_details.created_at IS '作成日時';
COMMENT ON COLUMN t_daily_click_details.updated_at IS '最終更新日時';
```

> [!NOTE]
> `site_id` はNULL許容。未設定の場合はNULLが入る。
> 複合主キーではCOALESCEでNULLを0に変換し、一意性を担保。

---

## 💡 初期データ

### システム管理者
```sql
-- システム管理者（ID=1）を事前に作成
INSERT INTO m_agents (agent_id, agent_name, email_address, status_id, created_by, updated_by)
OVERRIDING SYSTEM VALUE VALUES
(1, 'システム管理者', 'system@ansem.local', 1, 1, 1);
```

### 完全な初期データセット
前述の各テーブル定義に含まれる初期データを順番に投入：

1. m_countries（21カ国）
2. m_categories（大15 + 小51 = 66カテゴリ）
3. m_departments（親3 + 子8 = 11部署）
4. m_agent_role_types（3役割）
5. m_sns_platforms（11プラットフォーム）

---

## 🔍 使用例

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
FROM t_influencers i
LEFT JOIN m_influencer_agent_assignments iaa
  ON i.influencer_id = iaa.influencer_id AND iaa.is_active = TRUE
LEFT JOIN m_agents a ON iaa.agent_id = a.agent_id
LEFT JOIN m_agent_role_types art ON iaa.role_type_id = art.role_type_id
LEFT JOIN m_influencer_sns_accounts isa
  ON i.influencer_id = isa.influencer_id AND isa.status_id = 1
LEFT JOIN m_sns_platforms sp ON isa.platform_id = sp.platform_id
WHERE i.is_active = TRUE
GROUP BY i.influencer_id, i.influencer_name, i.email_address
ORDER BY i.influencer_name;
```

### 現在有効なキャンペーン一覧
```sql
SELECT
  c.campaign_name,
  cl.client_name,
  ag.ad_group_name,
  c.start_date,
  c.end_date,
  COUNT(ci.campaign_influencer_id) AS アサイン数
FROM t_campaigns c
INNER JOIN m_clients cl ON c.client_id = cl.client_id
INNER JOIN m_ad_groups ag ON c.ad_group_id = ag.ad_group_id
LEFT JOIN t_campaign_influencers ci ON c.campaign_id = ci.campaign_id
WHERE c.status_id = 2  -- 実施中
  AND c.start_date <= CURRENT_DATE
  AND (c.end_date IS NULL OR c.end_date >= CURRENT_DATE)
GROUP BY c.campaign_id, c.campaign_name, cl.client_name, ag.ad_group_name, c.start_date, c.end_date
ORDER BY c.start_date DESC;
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

## 🛠️ 運用ガイドライン

### パーティション管理

#### 新年度のパーティション作成
```sql
-- 2027年用パーティション作成（2026年12月に実施）
CREATE TABLE t_daily_performance_details_2027 PARTITION OF t_daily_performance_details
  FOR VALUES FROM ('2027-01-01') TO ('2028-01-01');

CREATE TABLE t_daily_click_details_2027 PARTITION OF t_daily_click_details
  FOR VALUES FROM ('2027-01-01') TO ('2028-01-01');
```

#### 古いパーティションの削除
```sql
-- 3年以上前のデータは削除（要アーカイブ後）
DROP TABLE t_daily_performance_details_2024;
DROP TABLE t_daily_click_details_2024;
```

### 監査ログの検索
```sql
-- 特定レコードの変更履歴
SELECT
  al.operated_at,
  a.agent_name AS 操作者,
  al.action_type AS 操作,
  al.old_value,
  al.new_value
FROM m_audit_logs al
LEFT JOIN m_agents a ON al.operator_id = a.agent_id
WHERE al.table_name = 't_influencers'
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

### インデックスのメンテナンス
```sql
-- 定期的なREINDEX（週次・夜間バッチ）
REINDEX TABLE t_daily_performance_details;
REINDEX TABLE t_daily_click_details;

-- VACUUM ANALYZE（日次・深夜実施）
VACUUM ANALYZE m_influencer_sns_accounts;
VACUUM ANALYZE t_campaign_influencers;
```

### バックアップ戦略
```sql
-- フルバックアップ（日次）
pg_dump -Fc ansem_db > ansem_db_$(date +%Y%m%d).dump

-- テーブル単位バックアップ（重要マスタのみ）
pg_dump -Fc -t m_countries -t m_categories ansem_db > masters_$(date +%Y%m%d).dump

-- パーティション単位バックアップ（月次）
pg_dump -Fc -t t_daily_performance_details_2026 ansem_db > perf_2026_$(date +%Y%m%d).dump
```

---

## 📚 参考情報

### 設計判断の記録

| 項目 | 判断 | 理由 |
|-----|------|------|
| 国マスタ | 作成 | 国際化対応・ISO準拠・外部キー制約 |
| 部署マスタ | 作成 | 階層構造・将来の組織変更対応 |
| 辞書テーブル | 選択的 | 種類が少なければコメント管理 |
| 集計テーブルの外部キー | あり | データ整合性を担保。スナップショット名称カラムは別途保持 |
| t_partner_sitesの命名 | t_プレフィックス | 可変データ・状態変化あり |

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

## ✅ チェックリスト

### テーブル作成時
- [ ] 命名規則（m_/t_プレフィックス）に従っているか
- [ ] TEXT型・TIMESTAMPTZ型を使用しているか
- [ ] 監査カラム（4つ）をすべて含んでいるか
- [ ] 主キーはGENERATED ALWAYS AS IDENTITYか
- [ ] 外部キー制約は適切か（ON DELETE RESTRICT）
- [ ] インデックスは必要十分か
- [ ] コメントは充実しているか

### データ投入時
- [ ] トランザクション内で実施しているか
- [ ] created_by/updated_byを設定しているか
- [ ] タイポ（t→m等）がないか確認したか
- [ ] 外部キー制約違反がないか

### 本番リリース前
- [ ] 全テーブルのCREATE文が実行可能か
- [ ] 初期データが投入されているか
- [ ] パーティションが作成されているか
- [ ] バックアップ体制は整っているか
- [ ] 監視・アラート設定は完了しているか

---

## 🎓 まとめ

### 設計の特徴
- **完全正規化**: 第3正規形準拠
- **国際化対応**: ISO準拠の国マスタ
- **監査対応**: 全テーブル監査カラム完備
- **柔軟性**: 階層構造・期間管理・多対多対応
- **パフォーマンス**: インデックス最適化・パーティション
- **セキュリティ**: 認証情報分離・外部キー制約

### テーブル数
- **マスタ**: 18テーブル
- **トランザクション**: 9テーブル
- **合計**: 27テーブル

### 主要エンティティ
- **t_influencers**: 中心的存在
- **t_campaigns**: キャンペーン管理
- **t_partners**: パートナー管理
- **t_unit_prices**: 単価管理
- **集計テーブル**: パフォーマンス測定

---

**作成日**: 2026-02-06
**バージョン**: 1.0.0
**ステータス**: 完成
**最終更新**: 2026-02-06
