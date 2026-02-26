-- =============================================================================
-- 002_create_indexes.sql
-- インフルエンサー管理システム — インデックス定義
-- PostgreSQL 15 / Cloud SQL
-- Version: v7.0.1
-- =============================================================================
-- 実行前提: 001_create_tables.sql が適用済みであること
-- =============================================================================

-- -----------------------------------------------------------------------------
-- t_group_members
-- -----------------------------------------------------------------------------

-- グループ↔インフルエンサーの頻繁なJOIN（ER図インデックス戦略）
CREATE INDEX idx_group_members_group_active
    ON t_group_members (group_id, is_active);

-- インフルエンサー→グループの逆引き（ER図インデックス戦略）
CREATE INDEX idx_group_members_influencer_active
    ON t_group_members (influencer_id, is_active);

-- -----------------------------------------------------------------------------
-- t_influencer_agent_assignments
-- -----------------------------------------------------------------------------

-- 担当者検索で頻繁に使用（ER図インデックス戦略）
CREATE INDEX idx_iaa_influencer_active
    ON t_influencer_agent_assignments (influencer_id, is_active);

-- エージェント→担当インフルエンサーの逆引き（ER図インデックス戦略）
CREATE INDEX idx_iaa_agent_active
    ON t_influencer_agent_assignments (agent_id, is_active);

-- RLS用: アクティブなエージェント割当の部分インデックス（高選択率 + 高頻度アクセス）
CREATE INDEX idx_iaa_agent_id_active
    ON t_influencer_agent_assignments (agent_id)
    WHERE is_active = true;

-- -----------------------------------------------------------------------------
-- t_unit_prices
-- -----------------------------------------------------------------------------

-- 適用単価の期間検索（ER図インデックス戦略）
CREATE INDEX idx_unit_prices_site_period
    ON t_unit_prices (site_id, start_at, end_at, status_id);

-- -----------------------------------------------------------------------------
-- t_partners
-- -----------------------------------------------------------------------------

-- group_id経由JOINが多発（ER図インデックス戦略）
CREATE INDEX idx_partners_group_id
    ON t_partners (group_id);

-- FKカラム: status_idでの絞り込み補助
CREATE INDEX idx_partners_status_id
    ON t_partners (status_id);

-- -----------------------------------------------------------------------------
-- t_daily_performance_details
-- -----------------------------------------------------------------------------

-- 日次集計の主要検索パターン（ER図インデックス戦略）
CREATE INDEX idx_dpd_date_partner_status
    ON t_daily_performance_details (action_date, partner_id, status_id);

-- グループ別成果集計・RLSフィルタ（ER図インデックス戦略 + RLS用）
CREATE INDEX idx_dpd_group_date
    ON t_daily_performance_details (group_id, action_date);

-- FKカラム: site_id
CREATE INDEX idx_dpd_site_id
    ON t_daily_performance_details (site_id);

-- FKカラム: client_id
CREATE INDEX idx_dpd_client_id
    ON t_daily_performance_details (client_id);

-- FKカラム: ad_content_id
CREATE INDEX idx_dpd_ad_content_id
    ON t_daily_performance_details (ad_content_id);

-- -----------------------------------------------------------------------------
-- t_daily_click_details
-- -----------------------------------------------------------------------------

-- 日次クリック集計（ER図インデックス戦略）
CREATE INDEX idx_dcd_date_site
    ON t_daily_click_details (action_date, site_id);

-- -----------------------------------------------------------------------------
-- t_influencer_sns_accounts
-- -----------------------------------------------------------------------------

-- インフルエンサー別SNSアカウント絞り込み（ER図インデックス戦略）
CREATE INDEX idx_isa_influencer_status
    ON t_influencer_sns_accounts (influencer_id, status_id);

-- プラットフォーム別絞り込み（ER図インデックス戦略）
CREATE INDEX idx_isa_platform_id
    ON t_influencer_sns_accounts (platform_id);

-- -----------------------------------------------------------------------------
-- FKカラムへの基本インデックス（JOIN最適化）
-- -----------------------------------------------------------------------------

-- t_departments
CREATE INDEX idx_departments_parent_id
    ON t_departments (parent_department_id);

-- t_agents
CREATE INDEX idx_agents_department_id
    ON t_agents (department_id);

-- t_agent_logs
CREATE INDEX idx_agent_logs_agent_id
    ON t_agent_logs (agent_id);

-- t_influencer_logs
CREATE INDEX idx_influencer_logs_influencer_id
    ON t_influencer_logs (influencer_id);

-- t_account_categories
CREATE INDEX idx_account_categories_account_id
    ON t_account_categories (account_id);

CREATE INDEX idx_account_categories_category_id
    ON t_account_categories (category_id);

-- t_categories（自己参照FK）
CREATE INDEX idx_categories_parent_id
    ON t_categories (parent_category_id);

-- t_group_addresses
CREATE INDEX idx_group_addresses_group_id
    ON t_group_addresses (group_id);

-- t_group_bank_accounts
CREATE INDEX idx_group_bank_accounts_group_id
    ON t_group_bank_accounts (group_id);

-- t_partner_sites
CREATE INDEX idx_partner_sites_partner_id
    ON t_partner_sites (partner_id);

-- t_ad_contents
CREATE INDEX idx_ad_contents_ad_group_id
    ON t_ad_contents (ad_group_id);

CREATE INDEX idx_ad_contents_client_id
    ON t_ad_contents (client_id);

-- t_campaigns
CREATE INDEX idx_campaigns_site_id
    ON t_campaigns (site_id);

-- ============================================================
-- 統合追加インデックス（v7.0.0）
-- ============================================================

-- ------------------------------------------------------------
-- t_countries
-- ------------------------------------------------------------
CREATE INDEX idx_countries_active ON t_countries(is_active, display_order);

-- ------------------------------------------------------------
-- t_influencers（country_idインデックス追加）
-- ------------------------------------------------------------
CREATE INDEX idx_influencers_country ON t_influencers(country_id)
  WHERE country_id IS NOT NULL;

-- ------------------------------------------------------------
-- t_agent_security（認証拡充インデックス）
-- ------------------------------------------------------------
CREATE INDEX idx_agent_security_session ON t_agent_security(session_token)
  WHERE session_token IS NOT NULL;
CREATE INDEX idx_agent_security_reset_token ON t_agent_security(password_reset_token)
  WHERE password_reset_token IS NOT NULL;
CREATE INDEX idx_agent_security_locked ON t_agent_security(agent_id, locked_until)
  WHERE locked_until IS NOT NULL;

-- ------------------------------------------------------------
-- t_influencer_security（認証拡充インデックス）
-- ------------------------------------------------------------
CREATE INDEX idx_influencer_security_session ON t_influencer_security(session_token)
  WHERE session_token IS NOT NULL;
CREATE INDEX idx_influencer_security_reset_token ON t_influencer_security(password_reset_token)
  WHERE password_reset_token IS NOT NULL;
CREATE INDEX idx_influencer_security_locked ON t_influencer_security(influencer_id, locked_until)
  WHERE locked_until IS NOT NULL;

-- ------------------------------------------------------------
-- t_group_billing_info
-- ------------------------------------------------------------
CREATE INDEX idx_group_billing_info_group ON t_group_billing_info(group_id, is_active);
CREATE INDEX idx_group_billing_info_invoice ON t_group_billing_info(invoice_tax_id)
  WHERE invoice_tax_id IS NOT NULL;
CREATE INDEX idx_group_billing_info_valid ON t_group_billing_info(group_id, valid_from, valid_to)
  WHERE is_active = TRUE;

-- ------------------------------------------------------------
-- t_billing_runs
-- ------------------------------------------------------------
CREATE INDEX idx_billing_runs_period ON t_billing_runs(billing_period_from, billing_period_to);
CREATE INDEX idx_billing_runs_confirmed_by ON t_billing_runs(confirmed_by);
CREATE INDEX idx_billing_runs_cancelled_by ON t_billing_runs(cancelled_by)
  WHERE cancelled_by IS NOT NULL;
CREATE INDEX idx_billing_runs_active ON t_billing_runs(is_cancelled, confirmed_at DESC)
  WHERE is_cancelled = FALSE;

-- ------------------------------------------------------------
-- t_billing_line_items
-- ------------------------------------------------------------
CREATE INDEX idx_line_items_run ON t_billing_line_items(billing_run_id);
CREATE INDEX idx_line_items_partner ON t_billing_line_items(partner_id, action_date);
CREATE INDEX idx_line_items_site ON t_billing_line_items(site_id, action_date);
CREATE INDEX idx_line_items_client ON t_billing_line_items(client_id, action_date);
CREATE INDEX idx_line_items_ad_content ON t_billing_line_items(ad_content_id, action_date);
CREATE INDEX idx_line_items_date ON t_billing_line_items(action_date);

-- ------------------------------------------------------------
-- t_files
-- ------------------------------------------------------------
CREATE INDEX idx_files_entity ON t_files(entity_type, entity_id, file_category);
CREATE INDEX idx_files_primary ON t_files(entity_type, entity_id)
  WHERE is_primary = TRUE;

-- ------------------------------------------------------------
-- t_notifications
-- ------------------------------------------------------------
CREATE INDEX idx_notifications_user ON t_notifications(user_id, user_type, is_read, created_at DESC);
CREATE INDEX idx_notifications_type ON t_notifications(notification_type, created_at DESC);
CREATE INDEX idx_notifications_unread ON t_notifications(user_id, user_type, created_at DESC)
  WHERE is_read = FALSE;

-- ------------------------------------------------------------
-- t_audit_logs
-- ------------------------------------------------------------
CREATE INDEX idx_audit_logs_table_record ON t_audit_logs(table_name, record_id);
CREATE INDEX idx_audit_logs_operator ON t_audit_logs(operator_type, operator_id, operated_at);
CREATE INDEX idx_audit_logs_operated ON t_audit_logs(operated_at);
CREATE INDEX idx_audit_logs_old_value ON t_audit_logs USING GIN (old_value);
CREATE INDEX idx_audit_logs_new_value ON t_audit_logs USING GIN (new_value);

-- ------------------------------------------------------------
-- ingestion_logs
-- ------------------------------------------------------------
CREATE INDEX idx_ingestion_logs_started_at ON ingestion_logs(started_at DESC);
CREATE INDEX idx_ingestion_logs_status ON ingestion_logs(status, started_at DESC);
CREATE INDEX idx_ingestion_logs_job_type ON ingestion_logs(job_type, started_at DESC);
CREATE INDEX idx_ingestion_logs_target_period ON ingestion_logs(target_from, target_to);

COMMIT;
