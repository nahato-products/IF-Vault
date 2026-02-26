-- ============================================================
-- ANSEMプロジェクト データベース設計書 v7.0.1
-- ファイル: 001_create_tables.sql
-- 説明: 全テーブルのCREATE TABLE文（FK依存順）
-- ER図: team/sekiguchi/projects/If-DB/インフルエンサー管理システムER図.md
-- 更新日: 2026-02-26
-- ============================================================

-- 期間重複排他制約に必要（Cloud SQL for PostgreSQL 15 でサポート済み）
CREATE EXTENSION IF NOT EXISTS btree_gist;

BEGIN;

-- ============================================================
-- レイヤー1: 依存なし（ルートテーブル）
-- ============================================================

-- ------------------------------------------------------------
-- 0. t_countries（国マスタ）
-- ------------------------------------------------------------
CREATE TABLE t_countries (
    country_id    SMALLINT PRIMARY KEY,
    country_name  TEXT    NOT NULL UNIQUE,
    country_code  TEXT    NOT NULL UNIQUE,
    country_code3 TEXT    NOT NULL UNIQUE,
    currency_code TEXT    NOT NULL,
    phone_prefix  TEXT,
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    display_order INTEGER NOT NULL DEFAULT 0,
    created_by    BIGINT  NOT NULL,
    updated_by    BIGINT  NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------
-- 1. t_departments（部署マスタ・階層構造）
-- ------------------------------------------------------------
CREATE TABLE t_departments (
    department_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    parent_department_id BIGINT,
    department_name TEXT    NOT NULL,
    department_code TEXT    NOT NULL UNIQUE,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_by      BIGINT  NOT NULL,
    updated_by      BIGINT  NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_department_parent
        FOREIGN KEY (parent_department_id)
        REFERENCES t_departments(department_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_department_no_self_parent
        CHECK (parent_department_id != department_id)
);

-- ------------------------------------------------------------
-- 2. t_influencers（インフルエンサーマスタ）
-- ------------------------------------------------------------
CREATE TABLE t_influencers (
    influencer_id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    influencer_name  TEXT    NOT NULL DEFAULT '（未登録）',
    influencer_alias TEXT,
    login_id         TEXT    NOT NULL UNIQUE,
    status_id        SMALLINT NOT NULL DEFAULT 1,
    country_id       SMALLINT,
    compliance_check BOOLEAN  NOT NULL DEFAULT FALSE,
    created_by       BIGINT   NOT NULL,
    updated_by       BIGINT   NOT NULL,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_influencer_country
        FOREIGN KEY (country_id)
        REFERENCES t_countries(country_id)
        ON DELETE SET NULL
);

-- ------------------------------------------------------------
-- 3. t_sns_platforms（SNSプラットフォームマスタ）
-- ------------------------------------------------------------
CREATE TABLE t_sns_platforms (
    platform_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    platform_name TEXT     NOT NULL,
    platform_key  TEXT     NOT NULL,
    status_id     SMALLINT NOT NULL DEFAULT 1,
    created_by    BIGINT   NOT NULL,
    updated_by    BIGINT   NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_sns_platform_key UNIQUE (platform_key)
);

-- ------------------------------------------------------------
-- 4. t_categories（カテゴリマスタ・階層対応）
-- ------------------------------------------------------------
CREATE TABLE t_categories (
    category_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_name      TEXT     NOT NULL,
    parent_category_id BIGINT,
    status_id          SMALLINT NOT NULL DEFAULT 1,
    created_by         BIGINT   NOT NULL,
    updated_by         BIGINT   NOT NULL,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_category_parent
        FOREIGN KEY (parent_category_id)
        REFERENCES t_categories(category_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_category_no_self_parent
        CHECK (parent_category_id != category_id),

    CONSTRAINT uq_category_name_parent UNIQUE NULLS NOT DISTINCT (category_name, parent_category_id)
);

-- ------------------------------------------------------------
-- 5. t_clients（クライアント・広告主マスタ）
-- ------------------------------------------------------------
CREATE TABLE t_clients (
    client_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_name TEXT     NOT NULL,
    industry    TEXT,
    status_id   SMALLINT NOT NULL DEFAULT 1,
    created_by  BIGINT   NOT NULL,
    updated_by  BIGINT   NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------
-- 6. t_ad_groups（広告グループ・案件単位）
-- ------------------------------------------------------------
CREATE TABLE t_ad_groups (
    ad_group_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ad_group_name TEXT     NOT NULL,
    status_id     SMALLINT NOT NULL DEFAULT 1,
    created_by    BIGINT   NOT NULL,
    updated_by    BIGINT   NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------
-- 7. t_influencer_groups（インフルエンサーグループマスタ）
-- ------------------------------------------------------------
CREATE TABLE t_influencer_groups (
    group_id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    group_name         TEXT     NOT NULL,
    billing_type_id    SMALLINT NOT NULL DEFAULT 1,
    invoice_tax_id     TEXT,
    affiliation_type_id SMALLINT NOT NULL DEFAULT 1,
    status_id          SMALLINT NOT NULL DEFAULT 1,
    start_at           DATE     NOT NULL,
    end_at             DATE     NOT NULL DEFAULT '2999-12-31',
    created_by         BIGINT   NOT NULL,
    updated_by         BIGINT   NOT NULL,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- レイヤー2: レイヤー1に依存
-- ============================================================

-- ------------------------------------------------------------
-- 9. t_agents（エージェント・担当者マスタ）
-- ------------------------------------------------------------
CREATE TABLE t_agents (
    agent_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    department_id BIGINT   NOT NULL,
    agent_name    TEXT     NOT NULL,
    email_address TEXT     NOT NULL UNIQUE,
    login_id      TEXT     NOT NULL UNIQUE,
    status_id     SMALLINT NOT NULL DEFAULT 1,
    join_date     DATE,
    created_by    BIGINT   NOT NULL,
    updated_by    BIGINT   NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_agent_department
        FOREIGN KEY (department_id)
        REFERENCES t_departments(department_id)
        ON DELETE RESTRICT
);

-- ------------------------------------------------------------
-- 10. t_influencer_security（インフルエンサー認証情報・1:1従属）
-- ------------------------------------------------------------
CREATE TABLE t_influencer_security (
    influencer_id           BIGINT PRIMARY KEY,
    password_hash           TEXT        NOT NULL,
    password_salt           TEXT,
    session_token           TEXT,
    session_expires_at      TIMESTAMPTZ,
    password_changed_at     TIMESTAMPTZ,
    password_reset_token    TEXT,
    reset_token_expires_at  TIMESTAMPTZ,
    locked_until            TIMESTAMPTZ,
    last_login_at           TIMESTAMPTZ,
    login_failure_count     SMALLINT    NOT NULL DEFAULT 0,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_influencer_security_influencer
        FOREIGN KEY (influencer_id)
        REFERENCES t_influencers(influencer_id)
        ON DELETE CASCADE
);

-- ------------------------------------------------------------
-- 11. t_influencer_sns_accounts（SNSアカウント・1:N）
-- ------------------------------------------------------------
CREATE TABLE t_influencer_sns_accounts (
    account_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    influencer_id   BIGINT   NOT NULL,
    platform_id     BIGINT   NOT NULL,
    account_url     TEXT,
    account_handle  TEXT,
    follower_count  BIGINT,
    engagement_rate DECIMAL,
    is_primary      BOOLEAN  NOT NULL DEFAULT FALSE,
    is_verified     BOOLEAN  NOT NULL DEFAULT FALSE,
    status_id       SMALLINT NOT NULL DEFAULT 1,
    created_by      BIGINT   NOT NULL,
    updated_by      BIGINT   NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_sns_account_influencer
        FOREIGN KEY (influencer_id)
        REFERENCES t_influencers(influencer_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_sns_account_platform
        FOREIGN KEY (platform_id)
        REFERENCES t_sns_platforms(platform_id)
        ON DELETE RESTRICT,

    CONSTRAINT uq_sns_account_primary_per_platform
        UNIQUE (influencer_id, platform_id) WHERE (is_primary = TRUE)
);

-- ------------------------------------------------------------
-- 12. t_group_members（グループメンバー中間テーブル）
-- ------------------------------------------------------------
CREATE TABLE t_group_members (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    group_id      BIGINT   NOT NULL,
    influencer_id BIGINT   NOT NULL,
    is_active     BOOLEAN  NOT NULL DEFAULT TRUE,
    start_at      DATE     NOT NULL,
    end_at        DATE     NOT NULL DEFAULT '2999-12-31',
    created_by    BIGINT   NOT NULL,
    updated_by    BIGINT   NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_group_member_group
        FOREIGN KEY (group_id)
        REFERENCES t_influencer_groups(group_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_group_member_influencer
        FOREIGN KEY (influencer_id)
        REFERENCES t_influencers(influencer_id)
        ON DELETE RESTRICT,

    CONSTRAINT uq_group_member UNIQUE (group_id, influencer_id)
);

-- ------------------------------------------------------------
-- 13. t_group_addresses（グループ住所・複数対応）
-- ------------------------------------------------------------
CREATE TABLE t_group_addresses (
    address_id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    group_id      BIGINT  NOT NULL,
    zip_code      TEXT,
    address_line1 TEXT,
    address_line2 TEXT,
    is_primary    BOOLEAN NOT NULL DEFAULT FALSE,
    created_by    BIGINT  NOT NULL,
    updated_by    BIGINT  NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_group_address_group
        FOREIGN KEY (group_id)
        REFERENCES t_influencer_groups(group_id)
        ON DELETE RESTRICT,

    CONSTRAINT uq_group_address_primary
        UNIQUE (group_id) WHERE (is_primary = TRUE)
);

-- ------------------------------------------------------------
-- 14. t_group_bank_accounts（グループ口座・複数対応）
-- ------------------------------------------------------------
CREATE TABLE t_group_bank_accounts (
    id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    group_id       BIGINT   NOT NULL,
    bank_name      TEXT,
    branch_name    TEXT,
    account_type   SMALLINT,
    account_number TEXT,
    account_holder TEXT,
    is_primary     BOOLEAN  NOT NULL DEFAULT FALSE,
    created_by     BIGINT   NOT NULL,
    updated_by     BIGINT   NOT NULL,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_group_bank_account_group
        FOREIGN KEY (group_id)
        REFERENCES t_influencer_groups(group_id)
        ON DELETE RESTRICT,

    CONSTRAINT uq_group_bank_account_primary
        UNIQUE (group_id) WHERE (is_primary = TRUE)
);

-- ------------------------------------------------------------
-- 15. t_group_billing_info（グループ請求先情報）
-- ------------------------------------------------------------
CREATE TABLE t_group_billing_info (
    billing_info_id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    group_id                 BIGINT   NOT NULL,
    billing_name             TEXT     NOT NULL,
    billing_type_id          SMALLINT,
    invoice_tax_id           TEXT,
    purchase_order_status_id SMALLINT,
    is_primary               BOOLEAN  NOT NULL DEFAULT FALSE,
    is_active                BOOLEAN  NOT NULL DEFAULT TRUE,
    valid_from               DATE,
    valid_to                 DATE,
    created_by               BIGINT   NOT NULL,
    updated_by               BIGINT   NOT NULL,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_group_billing_info_group
        FOREIGN KEY (group_id)
        REFERENCES t_influencer_groups(group_id)
        ON DELETE RESTRICT,

    CONSTRAINT uq_group_billing_info_primary
        UNIQUE (group_id) WHERE (is_primary = TRUE),

    CONSTRAINT chk_group_billing_info_valid_period
        CHECK (valid_to IS NULL OR valid_to >= valid_from)
);

-- ============================================================
-- レイヤー3: レイヤー2に依存
-- ============================================================

-- ------------------------------------------------------------
-- 16. t_agent_security（エージェント認証情報・1:1従属）
-- ------------------------------------------------------------
CREATE TABLE t_agent_security (
    agent_id                BIGINT PRIMARY KEY,
    password_hash           TEXT        NOT NULL,
    password_salt           TEXT,
    session_token           TEXT,
    session_expires_at      TIMESTAMPTZ,
    password_changed_at     TIMESTAMPTZ,
    password_reset_token    TEXT,
    reset_token_expires_at  TIMESTAMPTZ,
    locked_until            TIMESTAMPTZ,
    last_login_at           TIMESTAMPTZ,
    login_failure_count     SMALLINT    NOT NULL DEFAULT 0,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_agent_security_agent
        FOREIGN KEY (agent_id)
        REFERENCES t_agents(agent_id)
        ON DELETE CASCADE
);

-- ------------------------------------------------------------
-- 17. t_agent_logs（エージェント操作履歴）
-- ------------------------------------------------------------
CREATE TABLE t_agent_logs (
    log_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    agent_id    BIGINT NOT NULL,
    action_type TEXT   NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_agent_log_agent
        FOREIGN KEY (agent_id)
        REFERENCES t_agents(agent_id)
        ON DELETE RESTRICT
);

-- ------------------------------------------------------------
-- 18. t_influencer_logs（インフルエンサー操作履歴）
-- ------------------------------------------------------------
CREATE TABLE t_influencer_logs (
    log_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    influencer_id BIGINT NOT NULL,
    action_type   TEXT   NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_influencer_log_influencer
        FOREIGN KEY (influencer_id)
        REFERENCES t_influencers(influencer_id)
        ON DELETE RESTRICT
);

-- ------------------------------------------------------------
-- 19. t_influencer_agent_assignments（担当者割当・履歴管理）
-- ------------------------------------------------------------
CREATE TABLE t_influencer_agent_assignments (
    assignment_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    influencer_id BIGINT   NOT NULL,
    agent_id      BIGINT   NOT NULL,
    role_type     SMALLINT NOT NULL,
    start_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    end_at        TIMESTAMPTZ NOT NULL DEFAULT '2999-12-31 00:00:00+00',
    is_active     BOOLEAN  NOT NULL DEFAULT TRUE,
    created_by    BIGINT   NOT NULL,
    updated_by    BIGINT   NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_assignment_influencer
        FOREIGN KEY (influencer_id)
        REFERENCES t_influencers(influencer_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_assignment_agent
        FOREIGN KEY (agent_id)
        REFERENCES t_agents(agent_id)
        ON DELETE RESTRICT
);

-- ------------------------------------------------------------
-- 20. t_account_categories（SNSアカウント×カテゴリ中間テーブル）
-- ------------------------------------------------------------
CREATE TABLE t_account_categories (
    account_category_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id          BIGINT  NOT NULL,
    category_id         BIGINT  NOT NULL,
    is_primary          BOOLEAN NOT NULL DEFAULT FALSE,
    created_by          BIGINT  NOT NULL,
    updated_by          BIGINT  NOT NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_account_category_account
        FOREIGN KEY (account_id)
        REFERENCES t_influencer_sns_accounts(account_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_account_category_category
        FOREIGN KEY (category_id)
        REFERENCES t_categories(category_id)
        ON DELETE RESTRICT,

    CONSTRAINT uq_account_category UNIQUE (account_id, category_id),

    CONSTRAINT uq_account_category_primary
        UNIQUE (account_id) WHERE (is_primary = TRUE)
);

-- ============================================================
-- レイヤー4: パートナー系
-- ============================================================

-- ------------------------------------------------------------
-- 21. t_partners（パートナー・ASPマスタ）
-- ------------------------------------------------------------
CREATE TABLE t_partners (
    partner_id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    group_id      BIGINT,
    partner_name  TEXT     NOT NULL,
    email_address TEXT,
    login_id      TEXT,
    status_id     SMALLINT NOT NULL DEFAULT 1,
    created_by    BIGINT   NOT NULL,
    updated_by    BIGINT   NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_partner_group
        FOREIGN KEY (group_id)
        REFERENCES t_influencer_groups(group_id)
        ON DELETE SET NULL  -- グループ削除時もパートナー履歴は保持する
);

-- ------------------------------------------------------------
-- 22. t_partner_sites（サイト・媒体マスタ）
-- ------------------------------------------------------------
CREATE TABLE t_partner_sites (
    site_id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    partner_id BIGINT   NOT NULL,
    site_name  TEXT     NOT NULL,
    status_id  SMALLINT NOT NULL DEFAULT 1,
    created_by BIGINT   NOT NULL,
    updated_by BIGINT   NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_partner_site_partner
        FOREIGN KEY (partner_id)
        REFERENCES t_partners(partner_id)
        ON DELETE RESTRICT
);

-- ============================================================
-- レイヤー5: 広告系
-- ============================================================

-- ------------------------------------------------------------
-- 23. t_ad_contents（広告コンテンツ・クリエイティブ）
-- ------------------------------------------------------------
CREATE TABLE t_ad_contents (
    ad_content_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ad_group_id     BIGINT   NOT NULL,
    client_id       BIGINT   NOT NULL,
    person_id       BIGINT,
    ad_name         TEXT     NOT NULL,
    start_at        TIMESTAMPTZ,
    end_at          TIMESTAMPTZ,
    delivery_status SMALLINT NOT NULL DEFAULT 1,
    created_by      BIGINT   NOT NULL,
    updated_by      BIGINT   NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_ad_content_ad_group
        FOREIGN KEY (ad_group_id)
        REFERENCES t_ad_groups(ad_group_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_ad_content_client
        FOREIGN KEY (client_id)
        REFERENCES t_clients(client_id)
        ON DELETE RESTRICT
    -- person_id: FK制約なし（固定運用のため）
);

-- ------------------------------------------------------------
-- 24. t_unit_prices（単価マスタ・期間・上限管理）
-- ------------------------------------------------------------
CREATE TABLE t_unit_prices (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    site_id         BIGINT   NOT NULL,
    unit_price      DECIMAL  NOT NULL,
    limit_cap       DECIMAL,
    semi_unit_price DECIMAL,
    start_at        TIMESTAMPTZ NOT NULL,
    end_at          TIMESTAMPTZ NOT NULL DEFAULT '2999-12-31 00:00:00+00',
    status_id       SMALLINT NOT NULL DEFAULT 1,
    version         INTEGER  NOT NULL DEFAULT 1,
    created_by      BIGINT   NOT NULL,
    updated_by      BIGINT   NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_unit_price_site
        FOREIGN KEY (site_id)
        REFERENCES t_partner_sites(site_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_unit_price_non_negative
        CHECK (unit_price >= 0),

    CONSTRAINT chk_unit_prices_version CHECK (version >= 1),

    -- 同一サイトで有効期間が重複する単価の登録を防ぐ
    -- '[)' = 開始を含み終了を含まない（2026-06-30 23:59まで有効 → 2026-07-01 00:00 開始と重複しない）
    CONSTRAINT excl_unit_price_no_overlap
        EXCLUDE USING gist (
            site_id WITH =,
            tstzrange(start_at, end_at, '[)') WITH &&
        )
);

-- ------------------------------------------------------------
-- 25. t_campaigns（キャンペーン設定・媒体×報酬体系）
-- ------------------------------------------------------------
CREATE TABLE t_campaigns (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    site_id       BIGINT   NOT NULL,
    platform_type SMALLINT NOT NULL,
    reward_type   SMALLINT NOT NULL,
    price_type    SMALLINT NOT NULL,
    status_id     SMALLINT NOT NULL DEFAULT 1,
    version       INTEGER  NOT NULL DEFAULT 1,
    created_by    BIGINT   NOT NULL,
    updated_by    BIGINT   NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_campaign_site
        FOREIGN KEY (site_id)
        REFERENCES t_partner_sites(site_id)
        ON DELETE RESTRICT,

    CONSTRAINT uq_campaign_site_params
        UNIQUE (site_id, platform_type, reward_type, price_type),

    CONSTRAINT chk_campaigns_version CHECK (version >= 1)
);

-- ============================================================
-- レイヤー6: 集計系（パーティション）
-- ============================================================

-- ------------------------------------------------------------
-- 26. t_daily_performance_details（日次CV成果・RANGEパーティション）
-- ------------------------------------------------------------
CREATE TABLE t_daily_performance_details (
    id               BIGINT GENERATED ALWAYS AS IDENTITY,
    action_date      DATE     NOT NULL,
    partner_id       BIGINT   NOT NULL,
    -- group_id はスナップショット値（partner.group_id をコピー）。FK制約なし
    group_id         BIGINT,
    site_id          BIGINT   NOT NULL,
    client_id        BIGINT   NOT NULL,
    ad_content_id    BIGINT   NOT NULL,
    status_id        SMALLINT NOT NULL DEFAULT 1,
    rejection_reason TEXT,
    -- スナップショット（名称変更時も当時の値を保持）
    partner_name     TEXT,
    site_name        TEXT,
    client_name      TEXT,
    content_name     TEXT,
    -- 集計値
    -- cv_count: BQ取り込み時点で確定。NOT NULL。
    -- unit_price / client_action_cost: BQで単価JOIN後に計算してセット。
    --   NULL = BQ未計算（集計バッチ未実行 or 集計エラー）。
    --   請求処理は NULL のレコードを除外すること。
    cv_count             INTEGER  NOT NULL DEFAULT 0,
    client_action_cost   DECIMAL,
    unit_price           DECIMAL,
    -- 監査（バッチ生成のため created_by / updated_by なし）
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (action_date, id),

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
        REFERENCES t_clients(client_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_daily_perf_ad_content
        FOREIGN KEY (ad_content_id)
        REFERENCES t_ad_contents(ad_content_id)
        ON DELETE RESTRICT,

    CONSTRAINT uq_daily_perf_business_key
        UNIQUE (action_date, partner_id, site_id, client_id, ad_content_id),

    CONSTRAINT chk_daily_perf_cv_non_negative
        CHECK (cv_count >= 0)
) PARTITION BY RANGE (action_date);

-- パーティション: 2025年
CREATE TABLE t_daily_performance_details_2025
    PARTITION OF t_daily_performance_details
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

-- パーティション: 2026年
CREATE TABLE t_daily_performance_details_2026
    PARTITION OF t_daily_performance_details
    FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');

-- パーティション: 2027年
CREATE TABLE t_daily_performance_details_2027
    PARTITION OF t_daily_performance_details
    FOR VALUES FROM ('2027-01-01') TO ('2028-01-01');

-- 2024年（移行用・旧データ受け皿）
CREATE TABLE t_daily_performance_details_2024
    PARTITION OF t_daily_performance_details
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

-- デフォルト（範囲外データの受け皿）
CREATE TABLE t_daily_performance_details_default
    PARTITION OF t_daily_performance_details DEFAULT;

-- ------------------------------------------------------------
-- 27. t_daily_click_details（日次クリック数・RANGEパーティション）
-- ------------------------------------------------------------
CREATE TABLE t_daily_click_details (
    id          BIGINT GENERATED ALWAYS AS IDENTITY,
    action_date DATE    NOT NULL,
    site_id     BIGINT  NOT NULL,
    -- スナップショット
    site_name   TEXT,
    -- 集計値
    click_count INTEGER NOT NULL DEFAULT 0,
    -- 監査（バッチ生成のため created_by / updated_by なし）
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (action_date, id),

    CONSTRAINT fk_daily_click_site
        FOREIGN KEY (site_id)
        REFERENCES t_partner_sites(site_id)
        ON DELETE RESTRICT,

    CONSTRAINT uq_daily_click_business_key
        UNIQUE (action_date, site_id),

    CONSTRAINT chk_daily_click_count_non_negative
        CHECK (click_count >= 0)
) PARTITION BY RANGE (action_date);

-- パーティション: 2025年
CREATE TABLE t_daily_click_details_2025
    PARTITION OF t_daily_click_details
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

-- パーティション: 2026年
CREATE TABLE t_daily_click_details_2026
    PARTITION OF t_daily_click_details
    FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');

-- パーティション: 2027年
CREATE TABLE t_daily_click_details_2027
    PARTITION OF t_daily_click_details
    FOR VALUES FROM ('2027-01-01') TO ('2028-01-01');

-- 2024年（移行用・旧データ受け皿）
CREATE TABLE t_daily_click_details_2024
    PARTITION OF t_daily_click_details
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

-- デフォルト（範囲外データの受け皿）
CREATE TABLE t_daily_click_details_default
    PARTITION OF t_daily_click_details DEFAULT;

-- ============================================================
-- レイヤー7: 請求系・ユーティリティ系
-- ============================================================

-- ------------------------------------------------------------
-- 28. t_billing_runs（請求確定バッチ）
-- ------------------------------------------------------------
CREATE TABLE t_billing_runs (
    billing_run_id       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    billing_period_from  DATE   NOT NULL,
    billing_period_to    DATE   NOT NULL,
    filter_conditions    JSONB  NOT NULL DEFAULT '{}',
    confirmed_by         BIGINT NOT NULL,
    confirmed_at         TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_cancelled         BOOLEAN NOT NULL DEFAULT FALSE,
    cancelled_by         BIGINT,
    cancelled_at         TIMESTAMPTZ,
    notes                TEXT,
    created_by           BIGINT NOT NULL,
    updated_by           BIGINT NOT NULL,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_billing_run_confirmed_by
        FOREIGN KEY (confirmed_by)
        REFERENCES t_agents(agent_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_billing_run_cancelled_by
        FOREIGN KEY (cancelled_by)
        REFERENCES t_agents(agent_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_billing_run_cancel
        CHECK (
            (is_cancelled = FALSE AND cancelled_by IS NULL AND cancelled_at IS NULL)
            OR (is_cancelled = TRUE AND cancelled_by IS NOT NULL AND cancelled_at IS NOT NULL)
        ),

    CONSTRAINT chk_billing_run_period CHECK (billing_period_to >= billing_period_from)
);

-- ------------------------------------------------------------
-- 29. t_billing_line_items（請求明細）
-- ------------------------------------------------------------
-- 【設計メモ】
--   t_daily_performance_details（パーティションテーブル）への FK は意図的に持たない。
--   請求確定時点の集計値を action_date + partner_id + site_id + client_id + ad_content_id
--   の組み合わせでスナップショット保存する設計のため、FK制約は不要。
--   PostgreSQL はパーティション親テーブルへの FK 参照をサポートしていないという
--   技術的制約もある。
-- ------------------------------------------------------------
CREATE TABLE t_billing_line_items (
    line_item_id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    billing_run_id  BIGINT NOT NULL,
    action_date     DATE   NOT NULL,
    partner_id      BIGINT NOT NULL,
    site_id         BIGINT NOT NULL,
    client_id       BIGINT NOT NULL,
    ad_content_id   BIGINT NOT NULL,
    -- スナップショット
    partner_name    TEXT,
    site_name       TEXT,
    client_name     TEXT,
    content_name    TEXT,
    -- 集計値
    cv_count        INTEGER     NOT NULL DEFAULT 0,
    unit_price      DECIMAL     NOT NULL DEFAULT 0,
    amount          DECIMAL     NOT NULL DEFAULT 0,
    created_by      BIGINT      NOT NULL,
    updated_by      BIGINT      NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_line_item_run
        FOREIGN KEY (billing_run_id)
        REFERENCES t_billing_runs(billing_run_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_line_item_partner
        FOREIGN KEY (partner_id)
        REFERENCES t_partners(partner_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_line_item_site
        FOREIGN KEY (site_id)
        REFERENCES t_partner_sites(site_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_line_item_client
        FOREIGN KEY (client_id)
        REFERENCES t_clients(client_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_line_item_ad_content
        FOREIGN KEY (ad_content_id)
        REFERENCES t_ad_contents(ad_content_id)
        ON DELETE RESTRICT
);

-- ------------------------------------------------------------
-- 30. t_files（ファイル管理・ポリモーフィック）
-- ------------------------------------------------------------
CREATE TABLE t_files (
    file_id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    entity_type     SMALLINT NOT NULL,
    entity_id       BIGINT   NOT NULL,
    file_category   TEXT     NOT NULL,
    file_name       TEXT     NOT NULL,
    storage_path    TEXT     NOT NULL,
    mime_type       TEXT     NOT NULL,
    file_size_bytes BIGINT   NOT NULL,
    sort_order      SMALLINT NOT NULL DEFAULT 0,
    is_primary      BOOLEAN  NOT NULL DEFAULT FALSE,
    created_by      BIGINT   NOT NULL,
    updated_by      BIGINT   NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_files_entity_type CHECK (entity_type IN (1, 2, 3, 4, 5))
);

-- ------------------------------------------------------------
-- 31. t_notifications（通知）
-- ------------------------------------------------------------
CREATE TABLE t_notifications (
    notification_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id           BIGINT   NOT NULL,
    user_type         SMALLINT NOT NULL,
    notification_type TEXT     NOT NULL,
    title             TEXT     NOT NULL,
    message           TEXT,
    link_url          TEXT,
    is_read           BOOLEAN  NOT NULL DEFAULT FALSE,
    read_at           TIMESTAMPTZ,
    created_by        BIGINT   NOT NULL,
    updated_by        BIGINT   NOT NULL,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_notifications_user_type CHECK (user_type IN (1, 2))
);

-- ------------------------------------------------------------
-- 32. t_audit_logs（共通監査ログ・月次パーティション）
-- ------------------------------------------------------------
CREATE TABLE t_audit_logs (
    log_id        BIGINT GENERATED ALWAYS AS IDENTITY,
    table_name    TEXT     NOT NULL,
    record_id     BIGINT   NOT NULL,
    action_type   TEXT     NOT NULL,
    old_value     JSONB,
    new_value     JSONB,
    operator_type SMALLINT NOT NULL,
    operator_id   BIGINT   NOT NULL,
    operator_ip   TEXT,
    operated_at   TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (operated_at, log_id),

    CONSTRAINT chk_audit_action_type
        CHECK (action_type IN ('INSERT', 'UPDATE', 'DELETE')),
    CONSTRAINT chk_audit_operator_type
        CHECK (operator_type IN (1, 2))
) PARTITION BY RANGE (operated_at);

-- ------------------------------------------------------------
-- 33. t_ingestion_logs（BQ取り込みログ）
-- ------------------------------------------------------------
CREATE TABLE t_ingestion_logs (
    ingestion_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    job_type       TEXT  NOT NULL,
    target_from    TIMESTAMPTZ NOT NULL,
    target_to      TIMESTAMPTZ NOT NULL,
    parameters     JSONB,
    status         TEXT  NOT NULL,
    records_count  INTEGER NOT NULL DEFAULT 0,
    error_message  TEXT,
    started_at     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    finished_at    TIMESTAMPTZ,

    CONSTRAINT chk_ingestion_status CHECK (status IN ('RUNNING', 'SUCCESS', 'FAILED'))
);

COMMIT;
