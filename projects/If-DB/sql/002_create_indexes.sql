-- ============================================================
-- ANSEMプロジェクト データベース設計書 v5.5.0
-- ファイル: 002_create_indexes.sql
-- 説明: 全テーブルのCREATE INDEX文
-- 生成日: 2026-02-10
-- 更新日: 2026-02-12
-- 変更点: cancelled_by部分インデックス追加
--
-- 実行順序: 001 → 002 → 003 → 004 → 005
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- m_countries
-- ------------------------------------------------------------
CREATE INDEX idx_countries_active ON m_countries(is_active, display_order);

-- ------------------------------------------------------------
-- m_categories
-- ------------------------------------------------------------
CREATE INDEX idx_categories_parent ON m_categories(parent_category_id);
CREATE INDEX idx_categories_active ON m_categories(is_active, display_order);

-- ------------------------------------------------------------
-- m_departments
-- ------------------------------------------------------------
CREATE INDEX idx_departments_parent ON m_departments(parent_department_id);
CREATE INDEX idx_departments_active ON m_departments(is_active, display_order);

-- ------------------------------------------------------------
-- m_agents
-- ------------------------------------------------------------
CREATE INDEX idx_agents_department_status ON m_agents(department_id, status_id);
CREATE INDEX idx_agents_status ON m_agents(status_id)
  WHERE status_id = 1;
CREATE INDEX idx_agents_name ON m_agents(agent_name);

-- ------------------------------------------------------------
-- m_agent_role_types
-- ------------------------------------------------------------
CREATE INDEX idx_agent_role_types_active ON m_agent_role_types(is_active, display_order);

-- ------------------------------------------------------------
-- m_agent_security
-- ------------------------------------------------------------
CREATE INDEX idx_agent_security_session ON m_agent_security(session_token)
  WHERE session_token IS NOT NULL;
CREATE INDEX idx_agent_security_locked ON m_agent_security(agent_id, locked_until)
  WHERE locked_until IS NOT NULL;
CREATE INDEX idx_agent_security_password_changed ON m_agent_security(password_changed_at);
CREATE INDEX idx_agent_security_reset_token ON m_agent_security(password_reset_token)
  WHERE password_reset_token IS NOT NULL;

-- ------------------------------------------------------------
-- m_influencers
-- ------------------------------------------------------------
CREATE INDEX idx_influencers_status ON m_influencers(status_id);
CREATE INDEX idx_influencers_country ON m_influencers(country_id);
CREATE INDEX idx_influencers_affiliation ON m_influencers(affiliation_type_id);
CREATE INDEX idx_influencers_submitted ON m_influencers(submitted_at)
  WHERE submitted_at IS NOT NULL;

-- ------------------------------------------------------------
-- m_influencer_security
-- ------------------------------------------------------------
CREATE INDEX idx_influencer_security_session ON m_influencer_security(session_token)
  WHERE session_token IS NOT NULL;
CREATE INDEX idx_influencer_security_password_changed ON m_influencer_security(password_changed_at);
CREATE INDEX idx_influencer_security_reset_token ON m_influencer_security(password_reset_token)
  WHERE password_reset_token IS NOT NULL;
CREATE INDEX idx_influencer_security_locked ON m_influencer_security(influencer_id, locked_until)
  WHERE locked_until IS NOT NULL;

-- ------------------------------------------------------------
-- m_ad_groups
-- ------------------------------------------------------------
CREATE INDEX idx_ad_groups_name ON m_ad_groups(ad_group_name);

-- ------------------------------------------------------------
-- m_ad_contents
-- ------------------------------------------------------------
CREATE INDEX idx_ad_contents_ad_group ON m_ad_contents(ad_group_id, delivery_status_id);
CREATE INDEX idx_ad_contents_client ON m_ad_contents(client_id)
  WHERE client_id IS NOT NULL;
CREATE INDEX idx_ad_contents_person ON m_ad_contents(person_id)
  WHERE person_id IS NOT NULL;
CREATE INDEX idx_ad_contents_delivery_status ON m_ad_contents(delivery_status_id, delivery_start_at, delivery_end_at);
CREATE INDEX idx_ad_contents_delivery_period ON m_ad_contents(delivery_start_at, delivery_end_at)
  WHERE delivery_status_id = 1;

-- ------------------------------------------------------------
-- m_clients
-- ------------------------------------------------------------
CREATE INDEX idx_clients_status ON m_clients(status_id);
CREATE INDEX idx_clients_industry ON m_clients(industry)
  WHERE industry IS NOT NULL;
CREATE INDEX idx_clients_name ON m_clients(client_name);

-- ------------------------------------------------------------
-- m_sns_platforms
-- ------------------------------------------------------------
CREATE INDEX idx_sns_platforms_active ON m_sns_platforms(is_active, display_order);

-- ------------------------------------------------------------
-- m_partners
-- ------------------------------------------------------------
CREATE INDEX idx_partners_influencer ON m_partners(influencer_id);
CREATE INDEX idx_partners_status ON m_partners(status_id);

-- ------------------------------------------------------------
-- m_partners_division
-- ------------------------------------------------------------
CREATE INDEX idx_partners_division ON m_partners_division(division_type);

-- ------------------------------------------------------------
-- m_campaigns
-- ------------------------------------------------------------
CREATE INDEX idx_campaigns_site ON m_campaigns(site_id, status_id);
CREATE INDEX idx_campaigns_influencer ON m_campaigns(influencer_id, status_id);
CREATE INDEX idx_campaigns_platform ON m_campaigns(platform_id, status_id);
CREATE INDEX idx_campaigns_status ON m_campaigns(status_id, created_at);

-- ------------------------------------------------------------
-- t_addresses
-- ------------------------------------------------------------
CREATE INDEX idx_addresses_influencer ON t_addresses(influencer_id, is_active);
CREATE INDEX idx_addresses_primary ON t_addresses(influencer_id, is_primary)
  WHERE is_primary = TRUE;
CREATE INDEX idx_addresses_type ON t_addresses(address_type_id);
CREATE INDEX idx_addresses_country ON t_addresses(country_id);
CREATE INDEX idx_addresses_valid ON t_addresses(influencer_id, valid_from, valid_to)
  WHERE is_active = TRUE;

-- ------------------------------------------------------------
-- t_bank_accounts
-- ------------------------------------------------------------
CREATE INDEX idx_bank_accounts_influencer ON t_bank_accounts(influencer_id, is_active);
CREATE INDEX idx_bank_accounts_primary ON t_bank_accounts(influencer_id, is_primary)
  WHERE is_primary = TRUE;
CREATE INDEX idx_bank_accounts_country ON t_bank_accounts(country_id);
CREATE INDEX idx_bank_accounts_currency ON t_bank_accounts(currency_code);
CREATE INDEX idx_bank_accounts_valid ON t_bank_accounts(influencer_id, valid_from, valid_to)
  WHERE is_active = TRUE;

-- ------------------------------------------------------------
-- t_billing_info
-- ------------------------------------------------------------
CREATE INDEX idx_billing_info_influencer ON t_billing_info(influencer_id, is_active);
CREATE INDEX idx_billing_info_primary ON t_billing_info(influencer_id, is_primary)
  WHERE is_primary = TRUE;
CREATE INDEX idx_billing_info_type ON t_billing_info(billing_type_id);
CREATE INDEX idx_billing_info_invoice ON t_billing_info(invoice_tax_id)
  WHERE invoice_tax_id IS NOT NULL;
CREATE INDEX idx_billing_info_valid ON t_billing_info(influencer_id, valid_from, valid_to)
  WHERE is_active = TRUE;

-- ※ t_addresses, t_bank_accounts, t_billing_info の3テーブルとも
--    influencer_id × valid期間 × is_active のインデックスパターンを統一

-- ------------------------------------------------------------
-- t_influencer_sns_accounts
-- ------------------------------------------------------------
CREATE INDEX idx_sns_accounts_influencer ON t_influencer_sns_accounts(influencer_id, status_id);
CREATE INDEX idx_sns_accounts_platform ON t_influencer_sns_accounts(platform_id);
CREATE INDEX idx_sns_accounts_follower ON t_influencer_sns_accounts(follower_count DESC)
  WHERE status_id = 1;

-- ------------------------------------------------------------
-- t_account_categories
-- ------------------------------------------------------------
-- UNIQUE制約 uq_account_category(account_id, category_id) が account_id の検索にも利用可能
CREATE INDEX idx_account_categories_category ON t_account_categories(category_id);

-- ------------------------------------------------------------
-- t_partner_sites
-- ------------------------------------------------------------
CREATE INDEX idx_partner_sites_partner ON t_partner_sites(partner_id, is_active);
CREATE INDEX idx_partner_sites_status ON t_partner_sites(status_id);

-- ------------------------------------------------------------
-- t_unit_prices
-- ------------------------------------------------------------
CREATE INDEX idx_unit_prices_site ON t_unit_prices(site_id, is_active);
CREATE INDEX idx_unit_prices_content ON t_unit_prices(content_id, is_active);
CREATE INDEX idx_unit_prices_client ON t_unit_prices(client_id, is_active);
CREATE INDEX idx_unit_prices_period ON t_unit_prices(start_at, end_at)
  WHERE is_active = TRUE;

-- ------------------------------------------------------------
-- t_influencer_agent_assignments
-- ------------------------------------------------------------
CREATE INDEX idx_assignments_influencer ON t_influencer_agent_assignments(influencer_id, is_active);
CREATE INDEX idx_assignments_agent ON t_influencer_agent_assignments(agent_id, is_active);
CREATE INDEX idx_assignments_role ON t_influencer_agent_assignments(role_type_id);

-- ------------------------------------------------------------
-- t_audit_logs
-- ------------------------------------------------------------
CREATE INDEX idx_audit_logs_table_record ON t_audit_logs(table_name, record_id);
CREATE INDEX idx_audit_logs_operator ON t_audit_logs(operator_type, operator_id, operated_at);
CREATE INDEX idx_audit_logs_operated ON t_audit_logs(operated_at);
CREATE INDEX idx_audit_logs_old_value ON t_audit_logs USING GIN (old_value);
CREATE INDEX idx_audit_logs_new_value ON t_audit_logs USING GIN (new_value);

-- ------------------------------------------------------------
-- t_notifications
-- ------------------------------------------------------------
CREATE INDEX idx_notifications_user ON t_notifications(user_id, user_type, is_read, created_at DESC);
CREATE INDEX idx_notifications_type ON t_notifications(notification_type, created_at DESC);
CREATE INDEX idx_notifications_unread ON t_notifications(user_id, user_type, created_at DESC)
  WHERE is_read = FALSE;

-- ------------------------------------------------------------
-- t_translations
-- ------------------------------------------------------------
CREATE INDEX idx_translations_lookup ON t_translations(table_name, record_id, language_code);
CREATE INDEX idx_translations_lang ON t_translations(language_code);

-- ------------------------------------------------------------
-- t_files
-- ------------------------------------------------------------
CREATE INDEX idx_files_entity ON t_files(entity_type, entity_id, file_category);
CREATE INDEX idx_files_primary ON t_files(entity_type, entity_id)
  WHERE is_primary = TRUE;

-- ------------------------------------------------------------
-- t_daily_performance_details
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- t_daily_click_details
-- ------------------------------------------------------------
CREATE INDEX idx_click_detail_date
  ON t_daily_click_details(action_date);

CREATE INDEX idx_click_detail_site
  ON t_daily_click_details(site_id, action_date);

CREATE INDEX idx_click_detail_count
  ON t_daily_click_details(click_count DESC)
  WHERE click_count > 0;

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
CREATE INDEX idx_line_items_content ON t_billing_line_items(content_id, action_date);
CREATE INDEX idx_line_items_date ON t_billing_line_items(action_date);

-- ------------------------------------------------------------
-- ingestion_logs
-- ------------------------------------------------------------
CREATE INDEX idx_ingestion_logs_started_at ON ingestion_logs(started_at DESC);
CREATE INDEX idx_ingestion_logs_status_started ON ingestion_logs(status, started_at DESC);
CREATE INDEX idx_ingestion_logs_job_type ON ingestion_logs(job_type, started_at DESC);
CREATE INDEX idx_ingestion_logs_target_period ON ingestion_logs(target_from, target_to);

-- ============================================================
-- is_primary 排他制約（部分UNIQUEインデックス）
-- 同一インフルエンサーにつき is_primary = TRUE は1件のみ
-- ============================================================
CREATE UNIQUE INDEX uq_addresses_primary
  ON t_addresses(influencer_id) WHERE is_primary = TRUE;

CREATE UNIQUE INDEX uq_bank_accounts_primary
  ON t_bank_accounts(influencer_id) WHERE is_primary = TRUE;

CREATE UNIQUE INDEX uq_billing_info_primary
  ON t_billing_info(influencer_id) WHERE is_primary = TRUE;

CREATE UNIQUE INDEX uq_sns_accounts_primary
  ON t_influencer_sns_accounts(influencer_id) WHERE is_primary = TRUE;

COMMIT;
