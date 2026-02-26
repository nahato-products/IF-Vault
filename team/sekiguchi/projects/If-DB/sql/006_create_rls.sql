-- =============================================================================
-- 006_create_rls.sql
-- インフルエンサー管理システム — Row Level Security 定義
-- PostgreSQL 15 / Cloud SQL
-- =============================================================================
-- 実行前提: 001〜005 が適用済みであること
--
-- 【Cloud SQL 注意事項】
--   - cloudsqlsuperuser は FORCE ROW LEVEL SECURITY でも RLS をバイパスする。
--     アプリ用ロールは必ず NOSUPERUSER で作成すること。
--   - PgBouncer を使用する場合は session mode を推奨。
--     transaction mode では SET LOCAL のスコープが保証されないため
--     セッション変数が正しく引き継がれない場合がある。
--
-- 【セッション変数（アプリ側から SET LOCAL で渡す）】
--   app.current_agent_id      BIGINT
--   app.current_influencer_id BIGINT
--   app.current_role          TEXT  ('agent'/'manager'/'admin'/'influencer'/'batch')
--
-- 【ポリシー設計原則】
--   - agent    : 自分が担当中（is_active=true）のインフルエンサーに紐づくデータのみ
--   - manager  : 全件参照・更新可
--   - admin    : 全テーブルフルアクセス
--   - influencer: 自分自身のデータのみ参照
--   - batch    : 集計テーブルへの INSERT/UPDATE のみ
-- =============================================================================


-- =============================================================================
-- ロール作成
-- =============================================================================

-- アプリ用ロール（全て NOSUPERUSER: Cloud SQL の RLS バイパス防止）
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_agent') THEN
        CREATE ROLE app_agent NOSUPERUSER NOINHERIT NOCREATEDB NOCREATEROLE NOREPLICATION LOGIN;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_manager') THEN
        CREATE ROLE app_manager NOSUPERUSER NOINHERIT NOCREATEDB NOCREATEROLE NOREPLICATION LOGIN;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_admin') THEN
        CREATE ROLE app_admin NOSUPERUSER NOINHERIT NOCREATEDB NOCREATEROLE NOREPLICATION LOGIN;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_influencer') THEN
        CREATE ROLE app_influencer NOSUPERUSER NOINHERIT NOCREATEDB NOCREATEROLE NOREPLICATION LOGIN;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_batch') THEN
        CREATE ROLE app_batch NOSUPERUSER NOINHERIT NOCREATEDB NOCREATEROLE NOREPLICATION LOGIN;
    END IF;
END
$$;


-- =============================================================================
-- テーブル権限付与
-- =============================================================================

-- app_agent: 担当インフルエンサー関連テーブルの参照・更新
GRANT SELECT, INSERT, UPDATE ON
    t_influencers,
    t_influencer_groups,
    t_group_members,
    t_partners,
    t_daily_performance_details
TO app_agent;

GRANT SELECT, INSERT, UPDATE ON t_influencer_sns_accounts TO app_agent;
GRANT SELECT, INSERT, UPDATE ON t_group_addresses TO app_agent;
GRANT SELECT, INSERT, UPDATE ON t_group_bank_accounts TO app_agent;
GRANT SELECT ON t_partner_sites TO app_agent;
GRANT SELECT ON t_ad_contents TO app_agent;
GRANT SELECT ON t_campaigns TO app_agent;
GRANT SELECT ON t_unit_prices TO app_agent;
GRANT SELECT ON t_influencer_agent_assignments TO app_agent;

-- app_manager: 全テーブル参照・更新
GRANT SELECT, INSERT, UPDATE ON
    t_influencers,
    t_influencer_groups,
    t_group_members,
    t_partners,
    t_daily_performance_details
TO app_manager;

GRANT ALL ON t_influencer_sns_accounts TO app_manager;
GRANT ALL ON t_group_addresses TO app_manager;
GRANT ALL ON t_group_bank_accounts TO app_manager;
GRANT ALL ON t_partner_sites TO app_manager;
GRANT ALL ON t_ad_contents TO app_manager;
GRANT ALL ON t_campaigns TO app_manager;
GRANT ALL ON t_unit_prices TO app_manager;
GRANT ALL ON t_influencer_agent_assignments TO app_manager;
GRANT ALL ON t_agent_logs TO app_manager;
GRANT ALL ON t_influencer_logs TO app_manager;

-- app_admin: 全テーブルフルアクセス
GRANT ALL ON ALL TABLES IN SCHEMA public TO app_admin;

-- app_influencer: 参照のみ
GRANT SELECT ON
    t_influencers,
    t_influencer_groups,
    t_group_members,
    t_partners,
    t_daily_performance_details
TO app_influencer;

GRANT SELECT ON t_influencer_sns_accounts TO app_influencer;
GRANT SELECT ON t_group_addresses TO app_influencer;
GRANT SELECT ON t_influencer_agent_assignments TO app_influencer;

-- app_batch: 集計テーブルへの書き込みのみ
GRANT INSERT, UPDATE ON
    t_daily_performance_details
TO app_batch;

GRANT INSERT, UPDATE ON t_daily_click_details TO app_batch;


-- =============================================================================
-- RLS 有効化
-- =============================================================================

ALTER TABLE t_influencers                ENABLE ROW LEVEL SECURITY;
ALTER TABLE t_influencer_groups          ENABLE ROW LEVEL SECURITY;
ALTER TABLE t_group_members              ENABLE ROW LEVEL SECURITY;
ALTER TABLE t_partners                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE t_daily_performance_details  ENABLE ROW LEVEL SECURITY;

-- テーブルオーナー（マイグレーション用ロール等）にも RLS を適用する
ALTER TABLE t_influencers                FORCE ROW LEVEL SECURITY;
ALTER TABLE t_influencer_groups          FORCE ROW LEVEL SECURITY;
ALTER TABLE t_group_members              FORCE ROW LEVEL SECURITY;
ALTER TABLE t_partners                   FORCE ROW LEVEL SECURITY;
ALTER TABLE t_daily_performance_details  FORCE ROW LEVEL SECURITY;


-- =============================================================================
-- ヘルパー関数
-- =============================================================================

-- セッション変数を安全に取得する関数群
-- missing_ok = true にすることで変数未設定時に NULL を返す（エラー回避）

CREATE OR REPLACE FUNCTION rls_current_agent_id() RETURNS BIGINT
    LANGUAGE sql STABLE SECURITY DEFINER AS
$$
    SELECT NULLIF(current_setting('app.current_agent_id', true), '')::BIGINT;
$$;

CREATE OR REPLACE FUNCTION rls_current_influencer_id() RETURNS BIGINT
    LANGUAGE sql STABLE SECURITY DEFINER AS
$$
    SELECT NULLIF(current_setting('app.current_influencer_id', true), '')::BIGINT;
$$;

CREATE OR REPLACE FUNCTION rls_current_role_name() RETURNS TEXT
    LANGUAGE sql STABLE SECURITY DEFINER AS
$$
    SELECT NULLIF(current_setting('app.current_role', true), '');
$$;

-- セッション変数の設定状態を確認するデバッグ関数（開発時のみ使用）
CREATE OR REPLACE FUNCTION rls_check_session()
RETURNS TABLE(variable TEXT, value TEXT, is_set BOOLEAN) AS $$
BEGIN
    RETURN QUERY VALUES
        ('app.current_agent_id',      current_setting('app.current_agent_id', true),      current_setting('app.current_agent_id', true) IS NOT NULL),
        ('app.current_influencer_id', current_setting('app.current_influencer_id', true),  current_setting('app.current_influencer_id', true) IS NOT NULL),
        ('app.current_role',          current_setting('app.current_role', true),            current_setting('app.current_role', true) IS NOT NULL);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION rls_check_session() IS 'SET LOCAL漏れのデバッグ用。SELECT * FROM rls_check_session();';


-- =============================================================================
-- t_influencers ポリシー
-- =============================================================================

-- admin: 全件アクセス
CREATE POLICY influencers_admin_all
    ON t_influencers
    AS PERMISSIVE
    FOR ALL
    TO app_admin
    USING (true)
    WITH CHECK (true);

-- manager: 全件参照・更新
CREATE POLICY influencers_manager_all
    ON t_influencers
    AS PERMISSIVE
    FOR ALL
    TO app_manager
    USING (true)
    WITH CHECK (true);

-- agent: 自分が担当中（is_active=true）のインフルエンサーのみ
CREATE POLICY influencers_agent_own
    ON t_influencers
    AS PERMISSIVE
    FOR ALL
    TO app_agent
    USING (
        influencer_id IN (
            SELECT influencer_id
            FROM t_influencer_agent_assignments
            WHERE agent_id = rls_current_agent_id()
              AND is_active = true
        )
    )
    WITH CHECK (
        influencer_id IN (
            SELECT influencer_id
            FROM t_influencer_agent_assignments
            WHERE agent_id = rls_current_agent_id()
              AND is_active = true
        )
    );

-- influencer: 自分自身のみ参照
CREATE POLICY influencers_self_select
    ON t_influencers
    AS PERMISSIVE
    FOR SELECT
    TO app_influencer
    USING (
        influencer_id = rls_current_influencer_id()
    );


-- =============================================================================
-- t_influencer_groups ポリシー
-- =============================================================================

-- admin
CREATE POLICY influencer_groups_admin_all
    ON t_influencer_groups
    AS PERMISSIVE
    FOR ALL
    TO app_admin
    USING (true)
    WITH CHECK (true);

-- manager: 全件
CREATE POLICY influencer_groups_manager_all
    ON t_influencer_groups
    AS PERMISSIVE
    FOR ALL
    TO app_manager
    USING (true)
    WITH CHECK (true);

-- agent: 担当インフルエンサーが所属するグループのみ
CREATE POLICY influencer_groups_agent_own
    ON t_influencer_groups
    AS PERMISSIVE
    FOR ALL
    TO app_agent
    USING (
        group_id IN (
            SELECT gm.group_id
            FROM t_group_members gm
            JOIN t_influencer_agent_assignments iaa
                ON gm.influencer_id = iaa.influencer_id
            WHERE iaa.agent_id = rls_current_agent_id()
              AND iaa.is_active = true
              AND gm.is_active = true
        )
    )
    WITH CHECK (
        group_id IN (
            SELECT gm.group_id
            FROM t_group_members gm
            JOIN t_influencer_agent_assignments iaa
                ON gm.influencer_id = iaa.influencer_id
            WHERE iaa.agent_id = rls_current_agent_id()
              AND iaa.is_active = true
              AND gm.is_active = true
        )
    );

-- influencer: 自分が所属するグループのみ参照
CREATE POLICY influencer_groups_self_select
    ON t_influencer_groups
    AS PERMISSIVE
    FOR SELECT
    TO app_influencer
    USING (
        group_id IN (
            SELECT group_id
            FROM t_group_members
            WHERE influencer_id = rls_current_influencer_id()
              AND is_active = true
        )
    );


-- =============================================================================
-- t_group_members ポリシー
-- =============================================================================

-- admin
CREATE POLICY group_members_admin_all
    ON t_group_members
    AS PERMISSIVE
    FOR ALL
    TO app_admin
    USING (true)
    WITH CHECK (true);

-- manager: 全件
CREATE POLICY group_members_manager_all
    ON t_group_members
    AS PERMISSIVE
    FOR ALL
    TO app_manager
    USING (true)
    WITH CHECK (true);

-- agent: 担当インフルエンサーのメンバーレコードのみ
CREATE POLICY group_members_agent_own
    ON t_group_members
    AS PERMISSIVE
    FOR ALL
    TO app_agent
    USING (
        influencer_id IN (
            SELECT influencer_id
            FROM t_influencer_agent_assignments
            WHERE agent_id = rls_current_agent_id()
              AND is_active = true
        )
    )
    WITH CHECK (
        influencer_id IN (
            SELECT influencer_id
            FROM t_influencer_agent_assignments
            WHERE agent_id = rls_current_agent_id()
              AND is_active = true
        )
    );

-- influencer: 自分自身のメンバーレコードのみ参照
CREATE POLICY group_members_self_select
    ON t_group_members
    AS PERMISSIVE
    FOR SELECT
    TO app_influencer
    USING (
        influencer_id = rls_current_influencer_id()
    );


-- =============================================================================
-- t_partners ポリシー
-- =============================================================================

-- admin
CREATE POLICY partners_admin_all
    ON t_partners
    AS PERMISSIVE
    FOR ALL
    TO app_admin
    USING (true)
    WITH CHECK (true);

-- manager: 全件
CREATE POLICY partners_manager_all
    ON t_partners
    AS PERMISSIVE
    FOR ALL
    TO app_manager
    USING (true)
    WITH CHECK (true);

-- agent: 担当インフルエンサーが所属するグループに紐づくパートナーのみ
--   t_partners.group_id → t_group_members → t_influencer_agent_assignments
CREATE POLICY partners_agent_own
    ON t_partners
    AS PERMISSIVE
    FOR ALL
    TO app_agent
    USING (
        group_id IN (
            SELECT gm.group_id
            FROM t_group_members gm
            JOIN t_influencer_agent_assignments iaa
                ON gm.influencer_id = iaa.influencer_id
            WHERE iaa.agent_id = rls_current_agent_id()
              AND iaa.is_active = true
              AND gm.is_active = true
        )
    )
    WITH CHECK (
        group_id IN (
            SELECT gm.group_id
            FROM t_group_members gm
            JOIN t_influencer_agent_assignments iaa
                ON gm.influencer_id = iaa.influencer_id
            WHERE iaa.agent_id = rls_current_agent_id()
              AND iaa.is_active = true
              AND gm.is_active = true
        )
    );

-- influencer: 自分が所属するグループのパートナーのみ参照
CREATE POLICY partners_self_select
    ON t_partners
    AS PERMISSIVE
    FOR SELECT
    TO app_influencer
    USING (
        group_id IN (
            SELECT group_id
            FROM t_group_members
            WHERE influencer_id = rls_current_influencer_id()
              AND is_active = true
        )
    );


-- =============================================================================
-- t_daily_performance_details ポリシー
-- =============================================================================
--
-- 【設計ポイント】
--   - group_id カラム（スナップショット）でフィルタリングする。
--   - influencer_id は持たないため、agent は以下の経路で担当グループを特定する:
--       t_group_members (group_id, influencer_id, is_active)
--       → t_influencer_agent_assignments (influencer_id, agent_id, is_active)
--   - これにより「グループ単位管理」の設計思想を維持する。
--
-- 【NULL guard】
--   - 注意: group_id IS NULL のレコードは agent/influencer ポリシーでは見えない（IN句はNULLを評価しない）
--   - マイグレーション戦略に従い、CVデータ移行前に t_partners.group_id IS NULL = 0件 を確認すること
-- =============================================================================

-- admin
CREATE POLICY dpd_admin_all
    ON t_daily_performance_details
    AS PERMISSIVE
    FOR ALL
    TO app_admin
    USING (true)
    WITH CHECK (true);

-- manager: 全件
CREATE POLICY dpd_manager_all
    ON t_daily_performance_details
    AS PERMISSIVE
    FOR ALL
    TO app_manager
    USING (true)
    WITH CHECK (true);

-- agent: 担当グループの成果データのみ（group_id でフィルタ）
CREATE POLICY dpd_agent_own
    ON t_daily_performance_details
    AS PERMISSIVE
    FOR ALL
    TO app_agent
    USING (
        group_id IN (
            SELECT gm.group_id
            FROM t_group_members gm
            JOIN t_influencer_agent_assignments iaa
                ON gm.influencer_id = iaa.influencer_id
            WHERE iaa.agent_id = rls_current_agent_id()
              AND iaa.is_active = true
              AND gm.is_active = true
        )
    )
    WITH CHECK (
        group_id IN (
            SELECT gm.group_id
            FROM t_group_members gm
            JOIN t_influencer_agent_assignments iaa
                ON gm.influencer_id = iaa.influencer_id
            WHERE iaa.agent_id = rls_current_agent_id()
              AND iaa.is_active = true
              AND gm.is_active = true
        )
    );

-- influencer: 自分が所属するグループの成果データのみ参照
CREATE POLICY dpd_influencer_own
    ON t_daily_performance_details
    AS PERMISSIVE
    FOR SELECT
    TO app_influencer
    USING (
        group_id IN (
            SELECT group_id
            FROM t_group_members
            WHERE influencer_id = rls_current_influencer_id()
              AND is_active = true
        )
    );

-- batch: INSERT / UPDATE のみ許可（全行対象）
CREATE POLICY dpd_batch_write
    ON t_daily_performance_details
    AS PERMISSIVE
    FOR INSERT
    TO app_batch
    WITH CHECK (true);

CREATE POLICY dpd_batch_update
    ON t_daily_performance_details
    AS PERMISSIVE
    FOR UPDATE
    TO app_batch
    USING (true)
    WITH CHECK (true);


-- =============================================================================
-- 使用例（アプリ側 SET LOCAL パターン）
-- =============================================================================
--
-- BEGIN;
--   SET LOCAL app.current_agent_id      = '42';
--   SET LOCAL app.current_role          = 'agent';
--   -- 以降のクエリは agent_id=42 の担当データのみ参照可能
--   SELECT * FROM t_influencers;
-- COMMIT;
--
-- BEGIN;
--   SET LOCAL app.current_influencer_id = '101';
--   SET LOCAL app.current_role          = 'influencer';
--   SELECT * FROM t_daily_performance_details;
-- COMMIT;
-- =============================================================================
