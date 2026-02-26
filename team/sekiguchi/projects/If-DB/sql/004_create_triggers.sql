-- ============================================================
-- ANSEMプロジェクト データベース設計書 v7.0.0
-- ファイル: 004_create_triggers.sql
-- 説明: update_updated_at() 関数 + 全テーブルのトリガー定義
-- 更新日: 2026-02-26
--
-- 実行順序: 001 → 002 → 003 → 004 → 005
-- 除外テーブル:
--   t_audit_logs    — operated_at で管理。UPDATEされない前提（追記のみ）。
--   ingestion_logs  — finished_at で管理。ジョブ専用テーブル。
--   t_agent_logs    — 追記のみ
--   t_influencer_logs — 追記のみ
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- 共通関数（1回だけ作成）
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ------------------------------------------------------------
-- レイヤー1: ルートテーブル
-- ------------------------------------------------------------
CREATE TRIGGER trg_countries_updated_at
  BEFORE UPDATE ON t_countries FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_departments_updated_at
  BEFORE UPDATE ON t_departments FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_influencers_updated_at
  BEFORE UPDATE ON t_influencers FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_sns_platforms_updated_at
  BEFORE UPDATE ON t_sns_platforms FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_categories_updated_at
  BEFORE UPDATE ON t_categories FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_clients_updated_at
  BEFORE UPDATE ON t_clients FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_ad_groups_updated_at
  BEFORE UPDATE ON t_ad_groups FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_influencer_groups_updated_at
  BEFORE UPDATE ON t_influencer_groups FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ------------------------------------------------------------
-- レイヤー2: レイヤー1に依存
-- ------------------------------------------------------------
CREATE TRIGGER trg_agents_updated_at
  BEFORE UPDATE ON t_agents FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_influencer_security_updated_at
  BEFORE UPDATE ON t_influencer_security FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_sns_accounts_updated_at
  BEFORE UPDATE ON t_influencer_sns_accounts FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_group_members_updated_at
  BEFORE UPDATE ON t_group_members FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_group_addresses_updated_at
  BEFORE UPDATE ON t_group_addresses FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_group_bank_accounts_updated_at
  BEFORE UPDATE ON t_group_bank_accounts FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_group_billing_info_updated_at
  BEFORE UPDATE ON t_group_billing_info FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ------------------------------------------------------------
-- レイヤー3: レイヤー2に依存
-- ------------------------------------------------------------
CREATE TRIGGER trg_agent_security_updated_at
  BEFORE UPDATE ON t_agent_security FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_assignments_updated_at
  BEFORE UPDATE ON t_influencer_agent_assignments FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_account_categories_updated_at
  BEFORE UPDATE ON t_account_categories FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ------------------------------------------------------------
-- レイヤー4: パートナー系
-- ------------------------------------------------------------
CREATE TRIGGER trg_partners_updated_at
  BEFORE UPDATE ON t_partners FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_partner_sites_updated_at
  BEFORE UPDATE ON t_partner_sites FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ------------------------------------------------------------
-- レイヤー5: 広告系
-- ------------------------------------------------------------
CREATE TRIGGER trg_ad_contents_updated_at
  BEFORE UPDATE ON t_ad_contents FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_unit_prices_updated_at
  BEFORE UPDATE ON t_unit_prices FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_campaigns_updated_at
  BEFORE UPDATE ON t_campaigns FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ------------------------------------------------------------
-- レイヤー6: 集計系（パーティションテーブル）
-- ------------------------------------------------------------
CREATE TRIGGER trg_daily_performance_updated_at
  BEFORE UPDATE ON t_daily_performance_details FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_daily_click_updated_at
  BEFORE UPDATE ON t_daily_click_details FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ------------------------------------------------------------
-- レイヤー7: 請求系・ユーティリティ系
-- ------------------------------------------------------------
CREATE TRIGGER trg_billing_runs_updated_at
  BEFORE UPDATE ON t_billing_runs FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_billing_line_items_updated_at
  BEFORE UPDATE ON t_billing_line_items FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_files_updated_at
  BEFORE UPDATE ON t_files FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_notifications_updated_at
  BEFORE UPDATE ON t_notifications FOR EACH ROW EXECUTE FUNCTION update_updated_at();

COMMIT;
