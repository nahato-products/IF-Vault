-- ============================================================
-- ANSEMプロジェクト データベース設計書 v5.5.0
-- ファイル: 001_create_tables.sql
-- 説明: 全32テーブルのCREATE TABLE文（FK依存関係順）
-- 生成日: 2026-02-10
-- 更新日: 2026-02-12
-- 変更点: FK緩和(NO ACTION), CHECK制約追加, 自己参照ループ防止, influencer_nameデフォルト
--
-- 実行順序: 001 → 002 → 003 → 004 → 005
-- ============================================================

BEGIN;

-- ============================================================
-- レイヤー1: 依存なし（ルートテーブル）
-- ============================================================

-- ------------------------------------------------------------
-- 1. m_countries（国マスタ）
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- 2. m_departments（部署マスタ・階層）
-- ------------------------------------------------------------
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
    ON DELETE RESTRICT,

  CONSTRAINT chk_no_self_parent CHECK (parent_department_id != department_id)
);

-- ------------------------------------------------------------
-- 3. m_categories（カテゴリマスタ・2階層）
-- ------------------------------------------------------------
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

  CONSTRAINT uq_category_code UNIQUE (category_code),

  CONSTRAINT chk_no_self_parent CHECK (parent_category_id != category_id)
);

-- ------------------------------------------------------------
-- 4. m_ad_groups（広告グループ）
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- 5. m_clients（クライアント）
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- 6. m_sns_platforms（SNSプラットフォームマスタ）
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- 7. m_agent_role_types（エージェント役割マスタ）
-- ------------------------------------------------------------
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

-- ============================================================
-- レイヤー2: レイヤー1に依存
-- ============================================================

-- ------------------------------------------------------------
-- 8. m_agents（エージェントマスタ）
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- 9. m_influencers（インフルエンサー）
-- ------------------------------------------------------------
CREATE TABLE m_influencers (
  influencer_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  -- 基本情報
  login_id TEXT NOT NULL UNIQUE,
  influencer_name TEXT NOT NULL DEFAULT '（未登録）',
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

-- ============================================================
-- レイヤー3: レイヤー2に依存
-- ============================================================

-- ------------------------------------------------------------
-- 10. m_agent_security（エージェント認証）
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- 11. m_influencer_security（IF認証）
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- 12. m_partners（パートナー）
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- 13. t_addresses（住所情報）
-- ------------------------------------------------------------
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
    ON DELETE RESTRICT,

  CONSTRAINT chk_address_valid_period CHECK (valid_to IS NULL OR valid_to >= valid_from)
);

-- ------------------------------------------------------------
-- 14. t_bank_accounts（銀行口座）
-- ------------------------------------------------------------
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
    ON DELETE RESTRICT,

  CONSTRAINT chk_bank_valid_period CHECK (valid_to IS NULL OR valid_to >= valid_from)
);

-- ------------------------------------------------------------
-- 15. t_billing_info（請求先情報）
-- ------------------------------------------------------------
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
  purchase_order_status_id SMALLINT,
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
    ON DELETE CASCADE,

  CONSTRAINT chk_billing_info_po_status CHECK (purchase_order_status_id IN (1, 2, 3, 9)),
  CONSTRAINT chk_billing_info_valid_period CHECK (valid_to IS NULL OR valid_to >= valid_from)
);

-- ------------------------------------------------------------
-- 16. t_influencer_sns_accounts（IFのSNSアカウント）
-- ------------------------------------------------------------
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

  CONSTRAINT chk_sns_account_status CHECK (status_id IN (1, 2, 3)),

  CONSTRAINT chk_follower_positive CHECK (follower_count >= 0)
);

-- ------------------------------------------------------------
-- 17. t_influencer_agent_assignments（IF×エージェント担当割当）
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- 18. m_ad_contents（広告コンテンツ）
-- ------------------------------------------------------------
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

-- ============================================================
-- レイヤー4: レイヤー3に依存
-- ============================================================

-- ------------------------------------------------------------
-- 19. t_account_categories（アカウント×カテゴリ紐付け）
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- 20. t_partner_sites（パートナーサイト）
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- 21. m_partners_division（パートナー区分）
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- 22. t_audit_logs（共通監査ログ）
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- 23. t_notifications（通知）
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- 24. t_translations（翻訳）
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- 25. t_files（ファイル管理）
-- ------------------------------------------------------------
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

-- ============================================================
-- レイヤー5: レイヤー4に依存
-- ============================================================

-- ------------------------------------------------------------
-- 26. m_campaigns（キャンペーン・加工用）
-- ------------------------------------------------------------
CREATE TABLE m_campaigns (
  campaign_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  site_id BIGINT NOT NULL,
  influencer_id BIGINT,
  platform_id BIGINT NOT NULL,
  reward_type SMALLINT NOT NULL DEFAULT 1,
  price_type SMALLINT NOT NULL DEFAULT 1,
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

  CONSTRAINT chk_campaign_reward_type CHECK (reward_type IN (1, 2, 3)),
  CONSTRAINT chk_campaign_price_type CHECK (price_type IN (1, 2)),
  CONSTRAINT chk_campaign_status CHECK (status_id IN (1, 2, 3))
);

-- ------------------------------------------------------------
-- 27. t_unit_prices（単価設定）
-- ------------------------------------------------------------
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
    ON DELETE RESTRICT,

  CONSTRAINT chk_price_positive CHECK (unit_price >= 0),

  CONSTRAINT chk_unit_price_period CHECK (end_at IS NULL OR end_at >= start_at)
);

-- ============================================================
-- レイヤー6: レイヤー5に依存（パーティションテーブル）
-- ============================================================

-- ------------------------------------------------------------
-- 28. t_daily_performance_details（日次CV集計・パーティション対応）
-- ------------------------------------------------------------
-- ============================================================
-- 日次パフォーマンス詳細（CV版・パーティション対応）
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
    ON DELETE NO ACTION,

  CONSTRAINT fk_daily_perf_site
    FOREIGN KEY (site_id)
    REFERENCES t_partner_sites(site_id)
    ON DELETE NO ACTION,

  CONSTRAINT fk_daily_perf_client
    FOREIGN KEY (client_id)
    REFERENCES m_clients(client_id)
    ON DELETE NO ACTION,

  CONSTRAINT fk_daily_perf_content
    FOREIGN KEY (content_id)
    REFERENCES m_ad_contents(content_id)
    ON DELETE NO ACTION,

  CONSTRAINT chk_daily_perf_status CHECK (status_id IN (1, 2, 9)),

  CONSTRAINT chk_cv_non_negative CHECK (cv_count >= 0)
) PARTITION BY RANGE (action_date);

-- ------------------------------------------------------------
-- 29. t_daily_click_details（日次クリック集計・パーティション対応）
-- ------------------------------------------------------------
-- ============================================================
-- 日次クリック詳細（パーティション対応）
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
    ON DELETE NO ACTION
) PARTITION BY RANGE (action_date);

-- ============================================================
-- 独立テーブル（依存なし）
-- ============================================================

-- ------------------------------------------------------------
-- 31. t_billing_runs（請求確定バッチ）※番号はカテゴリ順。ファイル配置はFK依存順
-- ------------------------------------------------------------
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

  CONSTRAINT chk_billing_run_cancel
    CHECK (
      (is_cancelled = FALSE AND cancelled_by IS NULL AND cancelled_at IS NULL)
      OR (is_cancelled = TRUE AND cancelled_by IS NOT NULL AND cancelled_at IS NOT NULL)
    ),

  CONSTRAINT chk_billing_run_period CHECK (billing_period_to >= billing_period_from)
);

-- ------------------------------------------------------------
-- 32. t_billing_line_items（請求明細）
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- 30. ingestion_logs（BQ取り込みログ）
-- ------------------------------------------------------------
CREATE TABLE ingestion_logs (
  ingestion_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  job_type TEXT NOT NULL,
  target_from TIMESTAMPTZ NOT NULL,
  target_to TIMESTAMPTZ NOT NULL,
  parameters JSONB,
  status TEXT NOT NULL,
  records_count INTEGER NOT NULL DEFAULT 0,
  error_message TEXT,
  started_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  finished_at TIMESTAMPTZ,

  CONSTRAINT chk_ingestion_status CHECK (status IN ('RUNNING', 'SUCCESS', 'FAILED'))
);

COMMIT;
