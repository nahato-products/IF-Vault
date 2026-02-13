-- ============================================================
-- ANSEMプロジェクト データベース設計書 v5.5.0
-- ファイル: 003_create_comments.sql
-- 説明: 全テーブル・カラムのCOMMENT ON文
-- 生成日: 2026-02-10
-- 更新日: 2026-02-12
-- 変更点: 監査4カラムコメント全テーブル追加, v5.5.0制約コメント追加
--
-- 実行順序: 001 → 002 → 003 → 004 → 005
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- m_countries（国マスタ）
-- ------------------------------------------------------------
COMMENT ON TABLE m_countries IS '国マスタ（ISO 3166-1準拠）';
COMMENT ON COLUMN m_countries.country_id IS '主キー（PK）';
COMMENT ON COLUMN m_countries.country_name IS '国名（例: 日本）';
COMMENT ON COLUMN m_countries.country_code IS '国コード2文字（ISO 3166-1 alpha-2 / 例: JP）';
COMMENT ON COLUMN m_countries.country_code_3 IS '国コード3文字（ISO 3166-1 alpha-3 / 例: JPN）';
COMMENT ON COLUMN m_countries.currency_code IS '通貨コード（ISO 4217 / 例: JPY）';
COMMENT ON COLUMN m_countries.phone_prefix IS '電話番号プレフィックス（例: +81）';
COMMENT ON COLUMN m_countries.is_active IS '有効フラグ（TRUE: 有効, FALSE: 無効）';
COMMENT ON COLUMN m_countries.display_order IS '表示順（昇順ソート用）';

-- ------------------------------------------------------------
-- m_categories（カテゴリマスタ）
-- ------------------------------------------------------------
COMMENT ON TABLE m_categories IS 'カテゴリマスタ（2階層: 大カテゴリ・小カテゴリ）';
COMMENT ON COLUMN m_categories.parent_category_id IS '親カテゴリID（NULL=大カテゴリ）';
COMMENT ON COLUMN m_categories.category_id IS '主キー（PK）。自動採番';
COMMENT ON COLUMN m_categories.category_name IS 'カテゴリ名（例: 美容, ファッション）';
COMMENT ON COLUMN m_categories.category_code IS 'カテゴリコード（ユニーク）';
COMMENT ON COLUMN m_categories.category_description IS 'カテゴリ説明';
COMMENT ON COLUMN m_categories.is_active IS '有効フラグ（TRUE: 有効, FALSE: 無効）';
COMMENT ON COLUMN m_categories.display_order IS '表示順（昇順ソート用）';

-- ------------------------------------------------------------
-- m_departments（部署マスタ）
-- ------------------------------------------------------------
COMMENT ON TABLE m_departments IS '部署マスタ（階層構造対応）';
COMMENT ON COLUMN m_departments.parent_department_id IS '親部署ID（NULL=トップレベル）';
COMMENT ON COLUMN m_departments.department_id IS '主キー（PK）。自動採番';
COMMENT ON COLUMN m_departments.department_name IS '部署名';
COMMENT ON COLUMN m_departments.department_code IS '部署コード（ユニーク）';
COMMENT ON COLUMN m_departments.is_active IS '有効フラグ（TRUE: 有効, FALSE: 無効）';
COMMENT ON COLUMN m_departments.display_order IS '表示順（昇順ソート用）';

-- ------------------------------------------------------------
-- m_agents（エージェントマスタ）
-- ------------------------------------------------------------
COMMENT ON TABLE m_agents IS 'エージェント（社内担当者）マスタ';
COMMENT ON COLUMN m_agents.agent_id IS '主キー（PK）。自動採番';
COMMENT ON COLUMN m_agents.agent_name IS '氏名（フルネーム）';
COMMENT ON COLUMN m_agents.email_address IS '連絡用メールアドレス（ユニーク）';
COMMENT ON COLUMN m_agents.login_id IS '管理画面ログイン用ID（ユニーク）';
COMMENT ON COLUMN m_agents.department_id IS '所属部署（FK → m_departments）';
COMMENT ON COLUMN m_agents.job_title IS '役職（例: マネージャー, リーダー）';
COMMENT ON COLUMN m_agents.join_date IS '入社年月日';
COMMENT ON COLUMN m_agents.status_id IS 'ステータス（1: 現役, 2: 退任, 3: 休職）';

-- ------------------------------------------------------------
-- m_agent_role_types（エージェント役割マスタ）
-- ------------------------------------------------------------
COMMENT ON TABLE m_agent_role_types IS '役割マスタテーブル';
COMMENT ON COLUMN m_agent_role_types.role_type_id IS '主キー（PK）';
COMMENT ON COLUMN m_agent_role_types.role_name IS '役割名';
COMMENT ON COLUMN m_agent_role_types.role_code IS '役割コード';
COMMENT ON COLUMN m_agent_role_types.description IS '説明';
COMMENT ON COLUMN m_agent_role_types.can_edit_profile IS 'プロフィール編集権限';
COMMENT ON COLUMN m_agent_role_types.can_approve_content IS 'コンテンツ承認権限';
COMMENT ON COLUMN m_agent_role_types.display_order IS '表示順（昇順ソート用）';
COMMENT ON COLUMN m_agent_role_types.is_active IS '有効フラグ（TRUE: 有効, FALSE: 無効）';

-- ------------------------------------------------------------
-- m_agent_security（エージェント認証）
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- m_influencers（インフルエンサー）
-- ------------------------------------------------------------
COMMENT ON TABLE m_influencers IS 'インフルエンサー基本情報テーブル（正規化版）';
COMMENT ON COLUMN m_influencers.influencer_id IS '主キー（PK）';
COMMENT ON COLUMN m_influencers.login_id IS 'ログインID（ユニーク）';
COMMENT ON COLUMN m_influencers.influencer_name IS 'インフルエンサー名（本名）。NOT NULL DEFAULT ''（未登録）''';
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

-- ------------------------------------------------------------
-- m_influencer_security（IF認証）
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- m_ad_groups（広告グループ）
-- ------------------------------------------------------------
COMMENT ON TABLE m_ad_groups IS '広告グループ（案件・キャンペーン）マスタ';
COMMENT ON COLUMN m_ad_groups.ad_group_id IS '主キー（PK）。groupIdに相当';
COMMENT ON COLUMN m_ad_groups.ad_group_name IS '広告グループ名';

-- ------------------------------------------------------------
-- m_ad_contents（広告コンテンツ）
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- m_clients（クライアント）
-- ------------------------------------------------------------
COMMENT ON TABLE m_clients IS 'クライアント（広告主）マスタ';
COMMENT ON COLUMN m_clients.client_id IS '主キー（PK）。自動採番';
COMMENT ON COLUMN m_clients.client_name IS '正式名称（例: 株式会社ナハト）';
COMMENT ON COLUMN m_clients.industry IS '業種（例: 美容、ゲーム、金融）';
COMMENT ON COLUMN m_clients.status_id IS 'ステータス（1: 取引中, 2: 取引停止）';

-- ------------------------------------------------------------
-- m_sns_platforms（SNSプラットフォームマスタ）
-- ------------------------------------------------------------
COMMENT ON TABLE m_sns_platforms IS 'SNSプラットフォームマスタ';
COMMENT ON COLUMN m_sns_platforms.url_pattern IS 'URL形式（例: https://youtube.com/@{handle}）';
COMMENT ON COLUMN m_sns_platforms.platform_id IS '主キー（PK）。自動採番';
COMMENT ON COLUMN m_sns_platforms.platform_name IS 'プラットフォーム名（例: YouTube, Instagram）';
COMMENT ON COLUMN m_sns_platforms.platform_code IS 'プラットフォームコード（例: youtube, instagram）';
COMMENT ON COLUMN m_sns_platforms.is_active IS '有効フラグ（TRUE: 有効, FALSE: 無効）';
COMMENT ON COLUMN m_sns_platforms.display_order IS '表示順（昇順ソート用）';

-- ------------------------------------------------------------
-- m_partners（パートナー）
-- ------------------------------------------------------------
COMMENT ON TABLE m_partners IS 'パートナー（ASP・広告配信パートナー）マスタ（企業・個人）';
COMMENT ON COLUMN m_partners.partner_id IS '主キー（PK）。自動採番';
COMMENT ON COLUMN m_partners.partner_name IS '氏名または企業名';
COMMENT ON COLUMN m_partners.email_address IS 'メールアドレス';
COMMENT ON COLUMN m_partners.influencer_id IS 'IF兼業管理用（FK → m_influencers）';
COMMENT ON COLUMN m_partners.status_id IS 'ステータス（1: 有効, 2: 無効）';

-- ------------------------------------------------------------
-- m_partners_division（パートナー区分）
-- ------------------------------------------------------------
COMMENT ON TABLE m_partners_division IS 'パートナー区分（IF卸/トータルマーケティング）';
COMMENT ON COLUMN m_partners_division.partner_id IS '主キー（PK・FK → m_partners）。BigQuery/ASP側のIDと一致';
COMMENT ON COLUMN m_partners_division.partner_name IS 'パートナー名';
COMMENT ON COLUMN m_partners_division.division_type IS '区分タイプ（1: IF卸, 2: トータルマーケ）';
COMMENT ON COLUMN m_partners_division.is_comprehensive IS 'IF総合追加フラグ';
COMMENT ON COLUMN m_partners_division.is_excluded IS 'フィルタ除外フラグ';

-- ------------------------------------------------------------
-- m_campaigns（キャンペーン）
-- ------------------------------------------------------------
COMMENT ON TABLE m_campaigns IS 'キャンペーン（案件）管理テーブル';
COMMENT ON COLUMN m_campaigns.site_id IS 'パートナーサイトID（FK → t_partner_sites）';
COMMENT ON COLUMN m_campaigns.influencer_id IS '担当インフルエンサーID（FK → m_influencers）';
COMMENT ON COLUMN m_campaigns.platform_id IS 'SNSプラットフォームID（FK → m_sns_platforms）';
COMMENT ON COLUMN m_campaigns.reward_type IS '報酬体系（1:固定, 2:予算, 3:成果）';
COMMENT ON COLUMN m_campaigns.price_type IS '価格体系（1:Gross, 2:Net）';
COMMENT ON COLUMN m_campaigns.status_id IS 'ステータス（1: 進行中, 2: 完了, 3: 中止）';
COMMENT ON COLUMN m_campaigns.version IS '楽観ロック用バージョン番号';
COMMENT ON COLUMN m_campaigns.campaign_id IS '主キー（PK）。自動採番';

-- ------------------------------------------------------------
-- t_addresses（住所情報）
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- t_bank_accounts（銀行口座）
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- t_billing_info（請求先情報）
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- t_influencer_sns_accounts（SNSアカウント）
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- t_account_categories（アカウント×カテゴリ紐付け）
-- ------------------------------------------------------------
COMMENT ON TABLE t_account_categories IS 'アカウント×カテゴリ紐付け（多対多）';
COMMENT ON COLUMN t_account_categories.account_id IS 'SNSアカウントID（FK → t_influencer_sns_accounts）';
COMMENT ON COLUMN t_account_categories.category_id IS 'カテゴリID（FK → m_categories）';
COMMENT ON COLUMN t_account_categories.is_primary IS 'メインカテゴリフラグ';
COMMENT ON COLUMN t_account_categories.account_category_id IS '主キー（PK）。自動採番';

-- ------------------------------------------------------------
-- t_partner_sites（パートナーサイト）
-- ------------------------------------------------------------
COMMENT ON TABLE t_partner_sites IS 'パートナーサイト（媒体・枠）';
COMMENT ON COLUMN t_partner_sites.site_id IS '主キー（PK）。siteIdに相当';
COMMENT ON COLUMN t_partner_sites.partner_id IS 'パートナーID（FK → m_partners）';
COMMENT ON COLUMN t_partner_sites.site_name IS 'サイト名';
COMMENT ON COLUMN t_partner_sites.site_url IS 'URLやアプリBundle ID';
COMMENT ON COLUMN t_partner_sites.status_id IS 'ステータス（1: 稼働中, 2: 審査中, 3: 一時停止, 9: 停止）';
COMMENT ON COLUMN t_partner_sites.is_active IS '有効フラグ（TRUE: 有効, FALSE: 無効）';

-- ------------------------------------------------------------
-- t_unit_prices（単価設定）
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- t_influencer_agent_assignments（担当割当）
-- ------------------------------------------------------------
COMMENT ON TABLE t_influencer_agent_assignments IS 'インフルエンサー×エージェント担当割当';
COMMENT ON COLUMN t_influencer_agent_assignments.influencer_id IS 'インフルエンサーID（FK → m_influencers）';
COMMENT ON COLUMN t_influencer_agent_assignments.agent_id IS 'エージェントID（FK → m_agents）';
COMMENT ON COLUMN t_influencer_agent_assignments.role_type_id IS '役割タイプID（FK → m_agent_role_types）';
COMMENT ON COLUMN t_influencer_agent_assignments.assignment_id IS '主キー（PK）。自動採番';
COMMENT ON COLUMN t_influencer_agent_assignments.assigned_at IS '担当開始日時';
COMMENT ON COLUMN t_influencer_agent_assignments.unassigned_at IS '担当終了日時（NULL=現在担当中）';
COMMENT ON COLUMN t_influencer_agent_assignments.is_active IS '有効フラグ（TRUE: 担当中, FALSE: 解除済）';

-- ------------------------------------------------------------
-- t_audit_logs（共通監査ログ）
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- t_notifications（通知）
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- t_translations（翻訳）
-- ------------------------------------------------------------
COMMENT ON TABLE t_translations IS '翻訳テーブル（汎用多言語対応）';
COMMENT ON COLUMN t_translations.translation_id IS '主キー（PK）。自動採番';
COMMENT ON COLUMN t_translations.table_name IS '対象テーブル名（例: m_categories, m_sns_platforms）';
COMMENT ON COLUMN t_translations.record_id IS '対象レコードのPK値';
COMMENT ON COLUMN t_translations.column_name IS '対象カラム名（例: category_name, platform_name）';
COMMENT ON COLUMN t_translations.language_code IS '言語コード（ISO 639-1: en, ko, zh, th 等）';
COMMENT ON COLUMN t_translations.translated_value IS '翻訳後の値';

-- ------------------------------------------------------------
-- t_files（ファイル管理）
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- t_daily_performance_details（日次CV集計）
-- ------------------------------------------------------------
COMMENT ON TABLE t_daily_performance_details IS '日次パフォーマンス詳細（CV版・トランザクション）。レンジパーティション対応で大量データを効率的に管理。';
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

-- ------------------------------------------------------------
-- t_daily_click_details（日次クリック集計）
-- ------------------------------------------------------------
COMMENT ON TABLE t_daily_click_details IS '日次クリック詳細（トランザクション）。レンジパーティション対応で大量データを効率的に管理。';
COMMENT ON COLUMN t_daily_click_details.action_date IS '集計日（パーティションキー）';
COMMENT ON COLUMN t_daily_click_details.site_id IS 'サイトID（FK → t_partner_sites）';
COMMENT ON COLUMN t_daily_click_details.site_name IS 'サイト名（スナップショット・集計時点の名称）';
COMMENT ON COLUMN t_daily_click_details.click_count IS 'クリック件数（広告リンクのクリック数）';
COMMENT ON COLUMN t_daily_click_details.created_by IS '作成者（システムユーザーID=1）';
COMMENT ON COLUMN t_daily_click_details.updated_by IS '最終更新者（システムユーザーID=1）';
COMMENT ON COLUMN t_daily_click_details.created_at IS '作成日時';
COMMENT ON COLUMN t_daily_click_details.updated_at IS '最終更新日時';

-- ------------------------------------------------------------
-- t_billing_runs（請求確定バッチ）
-- ------------------------------------------------------------
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
COMMENT ON COLUMN t_billing_runs.created_by IS '作成者ID';
COMMENT ON COLUMN t_billing_runs.updated_by IS '最終更新者ID';
COMMENT ON COLUMN t_billing_runs.created_at IS '作成日時';
COMMENT ON COLUMN t_billing_runs.updated_at IS '最終更新日時';

-- ------------------------------------------------------------
-- t_billing_line_items（請求明細）
-- ------------------------------------------------------------
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
COMMENT ON COLUMN t_billing_line_items.created_by IS '作成者ID';
COMMENT ON COLUMN t_billing_line_items.updated_by IS '最終更新者ID';
COMMENT ON COLUMN t_billing_line_items.created_at IS '作成日時';
COMMENT ON COLUMN t_billing_line_items.updated_at IS '最終更新日時';

-- ------------------------------------------------------------
-- ingestion_logs（BQ取り込みログ）
-- ------------------------------------------------------------
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

-- ============================================================
-- 全CHECK制約コメント
-- ============================================================

-- ステータス系
COMMENT ON CONSTRAINT chk_client_status ON m_clients IS 'ステータス（1: 取引中, 2: 取引停止）';
COMMENT ON CONSTRAINT chk_agent_status ON m_agents IS 'ステータス（1: 現役, 2: 退任, 3: 休職）';
COMMENT ON CONSTRAINT chk_influencer_status ON m_influencers IS 'ステータス（1: 契約中, 2: 休止中, 3: 契約終了）';
COMMENT ON CONSTRAINT chk_partner_status ON m_partners IS 'ステータス（1: 有効, 2: 無効）';
COMMENT ON CONSTRAINT chk_partner_site_status ON t_partner_sites IS 'ステータス（1: 稼働中, 2: 審査中, 3: 一時停止, 9: 停止）';
COMMENT ON CONSTRAINT chk_sns_account_status ON t_influencer_sns_accounts IS 'ステータス（1: 有効, 2: 停止中, 3: 削除済）';
COMMENT ON CONSTRAINT chk_campaign_status ON m_campaigns IS 'ステータス（1: 進行中, 2: 完了, 3: 中止）';
COMMENT ON CONSTRAINT chk_daily_perf_status ON t_daily_performance_details IS 'ステータス（1: 承認済, 2: 未承認, 9: キャンセル）';
COMMENT ON CONSTRAINT chk_content_delivery_status ON m_ad_contents IS '配信ステータス（1: 承認待ち, 2: 配信中, 3: 停止）';
COMMENT ON CONSTRAINT chk_content_itp_status ON m_ad_contents IS 'ITPパラメータ（0: 未設定, 1: 設定済）';

-- 区分・種別系
COMMENT ON CONSTRAINT chk_campaign_reward_type ON m_campaigns IS '報酬体系（1: 固定, 2: 予算, 3: 成果）';
COMMENT ON CONSTRAINT chk_campaign_price_type ON m_campaigns IS '価格体系（1: Gross, 2: Net）';
COMMENT ON CONSTRAINT chk_billing_info_po_status ON t_billing_info IS '発注書ステータス（1: 未発行, 2: 発行済, 3: 承認済, 9: 取消）';
COMMENT ON CONSTRAINT chk_ingestion_status ON ingestion_logs IS '実行ステータス（RUNNING/SUCCESS/FAILED）';
COMMENT ON CONSTRAINT chk_action_type ON t_audit_logs IS '操作種別（INSERT/UPDATE/DELETE）';
COMMENT ON CONSTRAINT chk_operator_type ON t_audit_logs IS '操作者種別（1: Agent, 2: Influencer）';
COMMENT ON CONSTRAINT chk_user_type ON t_notifications IS '通知先種別（1: Agent, 2: Influencer, 3: Partner）';
COMMENT ON CONSTRAINT chk_entity_type ON t_files IS 'エンティティ種別（1: Agent, 2: Influencer, 3: Partner, 4: AdContent, 5: Campaign）';

-- 論理整合
COMMENT ON CONSTRAINT chk_billing_run_cancel ON t_billing_runs IS '取消整合性: is_cancelled=TRUEならcancelled_by/cancelled_atが必須、FALSEなら両方NULL';

-- 自己参照ループ防止
COMMENT ON CONSTRAINT chk_no_self_parent ON m_departments IS '自己参照ループ防止: 自分自身を親部署に設定できない';
COMMENT ON CONSTRAINT chk_no_self_parent ON m_categories IS '自己参照ループ防止: 自分自身を親カテゴリに設定できない';

-- 値域
COMMENT ON CONSTRAINT chk_follower_positive ON t_influencer_sns_accounts IS 'フォロワー数は0以上';
COMMENT ON CONSTRAINT chk_price_positive ON t_unit_prices IS '単価は0以上';
COMMENT ON CONSTRAINT chk_cv_non_negative ON t_daily_performance_details IS 'CV件数は0以上';

-- 期間逆転防止
COMMENT ON CONSTRAINT chk_address_valid_period ON t_addresses IS '有効期間: 終了日は開始日以降（NULLは無期限）';
COMMENT ON CONSTRAINT chk_bank_valid_period ON t_bank_accounts IS '有効期間: 終了日は開始日以降（NULLは無期限）';
COMMENT ON CONSTRAINT chk_unit_price_period ON t_unit_prices IS '有効期間: 終了日は開始日以降（NULLは無期限）';
COMMENT ON CONSTRAINT chk_billing_info_valid_period ON t_billing_info IS '有効期間: 終了日は開始日以降（NULLは無期限）';
COMMENT ON CONSTRAINT chk_billing_run_period ON t_billing_runs IS '請求対象期間: 終了日は開始日以降';

-- FK ON DELETE NO ACTION（集計テーブル）
COMMENT ON CONSTRAINT fk_daily_perf_partner ON t_daily_performance_details IS 'パートナーID（ON DELETE NO ACTION: 集計データ保護）';
COMMENT ON CONSTRAINT fk_daily_perf_site ON t_daily_performance_details IS 'サイトID（ON DELETE NO ACTION: 集計データ保護）';
COMMENT ON CONSTRAINT fk_daily_perf_client ON t_daily_performance_details IS 'クライアントID（ON DELETE NO ACTION: 集計データ保護）';
COMMENT ON CONSTRAINT fk_daily_perf_content ON t_daily_performance_details IS 'コンテンツID（ON DELETE NO ACTION: 集計データ保護）';
COMMENT ON CONSTRAINT fk_daily_click_site ON t_daily_click_details IS 'サイトID（ON DELETE NO ACTION: 集計データ保護）';

-- ============================================================
-- 共通監査カラムコメント（全テーブル一括）
-- t_daily_performance_details, t_daily_click_details,
-- t_billing_runs, t_billing_line_items は既に個別定義済み
-- ============================================================
COMMENT ON COLUMN m_countries.created_by IS '作成者ID';
COMMENT ON COLUMN m_countries.updated_by IS '最終更新者ID';
COMMENT ON COLUMN m_countries.created_at IS '作成日時';
COMMENT ON COLUMN m_countries.updated_at IS '最終更新日時（トリガーで自動更新）';

COMMENT ON COLUMN m_departments.created_by IS '作成者ID';
COMMENT ON COLUMN m_departments.updated_by IS '最終更新者ID';
COMMENT ON COLUMN m_departments.created_at IS '作成日時';
COMMENT ON COLUMN m_departments.updated_at IS '最終更新日時（トリガーで自動更新）';

COMMENT ON COLUMN m_categories.created_by IS '作成者ID';
COMMENT ON COLUMN m_categories.updated_by IS '最終更新者ID';
COMMENT ON COLUMN m_categories.created_at IS '作成日時';
COMMENT ON COLUMN m_categories.updated_at IS '最終更新日時（トリガーで自動更新）';

COMMENT ON COLUMN m_agents.created_by IS '作成者ID';
COMMENT ON COLUMN m_agents.updated_by IS '最終更新者ID';
COMMENT ON COLUMN m_agents.created_at IS '作成日時';
COMMENT ON COLUMN m_agents.updated_at IS '最終更新日時（トリガーで自動更新）';

COMMENT ON COLUMN m_agent_role_types.created_by IS '作成者ID';
COMMENT ON COLUMN m_agent_role_types.updated_by IS '最終更新者ID';
COMMENT ON COLUMN m_agent_role_types.created_at IS '作成日時';
COMMENT ON COLUMN m_agent_role_types.updated_at IS '最終更新日時（トリガーで自動更新）';

COMMENT ON COLUMN m_agent_security.created_by IS '作成者ID';
COMMENT ON COLUMN m_agent_security.updated_by IS '最終更新者ID';
COMMENT ON COLUMN m_agent_security.created_at IS '作成日時';
COMMENT ON COLUMN m_agent_security.updated_at IS '最終更新日時（トリガーで自動更新）';

COMMENT ON COLUMN m_influencers.created_by IS '作成者ID';
COMMENT ON COLUMN m_influencers.updated_by IS '最終更新者ID';
COMMENT ON COLUMN m_influencers.created_at IS '作成日時';
COMMENT ON COLUMN m_influencers.updated_at IS '最終更新日時（トリガーで自動更新）';

COMMENT ON COLUMN m_influencer_security.created_by IS '作成者ID';
COMMENT ON COLUMN m_influencer_security.updated_by IS '最終更新者ID';
COMMENT ON COLUMN m_influencer_security.created_at IS '作成日時';
COMMENT ON COLUMN m_influencer_security.updated_at IS '最終更新日時（トリガーで自動更新）';

COMMENT ON COLUMN m_ad_groups.created_by IS '作成者ID';
COMMENT ON COLUMN m_ad_groups.updated_by IS '最終更新者ID';
COMMENT ON COLUMN m_ad_groups.created_at IS '作成日時';
COMMENT ON COLUMN m_ad_groups.updated_at IS '最終更新日時（トリガーで自動更新）';

COMMENT ON COLUMN m_ad_contents.created_by IS '作成者ID';
COMMENT ON COLUMN m_ad_contents.updated_by IS '最終更新者ID';
COMMENT ON COLUMN m_ad_contents.created_at IS '作成日時';
COMMENT ON COLUMN m_ad_contents.updated_at IS '最終更新日時（トリガーで自動更新）';

COMMENT ON COLUMN m_clients.created_by IS '作成者ID';
COMMENT ON COLUMN m_clients.updated_by IS '最終更新者ID';
COMMENT ON COLUMN m_clients.created_at IS '作成日時';
COMMENT ON COLUMN m_clients.updated_at IS '最終更新日時（トリガーで自動更新）';

COMMENT ON COLUMN m_sns_platforms.created_by IS '作成者ID';
COMMENT ON COLUMN m_sns_platforms.updated_by IS '最終更新者ID';
COMMENT ON COLUMN m_sns_platforms.created_at IS '作成日時';
COMMENT ON COLUMN m_sns_platforms.updated_at IS '最終更新日時（トリガーで自動更新）';

COMMENT ON COLUMN m_partners.created_by IS '作成者ID';
COMMENT ON COLUMN m_partners.updated_by IS '最終更新者ID';
COMMENT ON COLUMN m_partners.created_at IS '作成日時';
COMMENT ON COLUMN m_partners.updated_at IS '最終更新日時（トリガーで自動更新）';

COMMENT ON COLUMN m_partners_division.created_at IS '作成日時';
COMMENT ON COLUMN m_partners_division.updated_at IS '最終更新日時（トリガーで自動更新）';

COMMENT ON COLUMN m_campaigns.created_by IS '作成者ID';
COMMENT ON COLUMN m_campaigns.updated_by IS '最終更新者ID';
COMMENT ON COLUMN m_campaigns.created_at IS '作成日時';
COMMENT ON COLUMN m_campaigns.updated_at IS '最終更新日時（トリガーで自動更新）';

COMMENT ON COLUMN t_addresses.created_by IS '作成者ID';
COMMENT ON COLUMN t_addresses.updated_by IS '最終更新者ID';
COMMENT ON COLUMN t_addresses.created_at IS '作成日時';
COMMENT ON COLUMN t_addresses.updated_at IS '最終更新日時（トリガーで自動更新）';

COMMENT ON COLUMN t_bank_accounts.created_by IS '作成者ID';
COMMENT ON COLUMN t_bank_accounts.updated_by IS '最終更新者ID';
COMMENT ON COLUMN t_bank_accounts.created_at IS '作成日時';
COMMENT ON COLUMN t_bank_accounts.updated_at IS '最終更新日時（トリガーで自動更新）';

COMMENT ON COLUMN t_billing_info.created_by IS '作成者ID';
COMMENT ON COLUMN t_billing_info.updated_by IS '最終更新者ID';
COMMENT ON COLUMN t_billing_info.created_at IS '作成日時';
COMMENT ON COLUMN t_billing_info.updated_at IS '最終更新日時（トリガーで自動更新）';

COMMENT ON COLUMN t_influencer_sns_accounts.created_by IS '作成者ID';
COMMENT ON COLUMN t_influencer_sns_accounts.updated_by IS '最終更新者ID';
COMMENT ON COLUMN t_influencer_sns_accounts.created_at IS '作成日時';
COMMENT ON COLUMN t_influencer_sns_accounts.updated_at IS '最終更新日時（トリガーで自動更新）';

COMMENT ON COLUMN t_account_categories.created_by IS '作成者ID';
COMMENT ON COLUMN t_account_categories.updated_by IS '最終更新者ID';
COMMENT ON COLUMN t_account_categories.created_at IS '作成日時';
COMMENT ON COLUMN t_account_categories.updated_at IS '最終更新日時（トリガーで自動更新）';

COMMENT ON COLUMN t_partner_sites.created_by IS '作成者ID';
COMMENT ON COLUMN t_partner_sites.updated_by IS '最終更新者ID';
COMMENT ON COLUMN t_partner_sites.created_at IS '作成日時';
COMMENT ON COLUMN t_partner_sites.updated_at IS '最終更新日時（トリガーで自動更新）';

COMMENT ON COLUMN t_unit_prices.created_by IS '作成者ID';
COMMENT ON COLUMN t_unit_prices.updated_by IS '最終更新者ID';
COMMENT ON COLUMN t_unit_prices.created_at IS '作成日時';
COMMENT ON COLUMN t_unit_prices.updated_at IS '最終更新日時（トリガーで自動更新）';

COMMENT ON COLUMN t_influencer_agent_assignments.created_by IS '作成者ID';
COMMENT ON COLUMN t_influencer_agent_assignments.updated_by IS '最終更新者ID';
COMMENT ON COLUMN t_influencer_agent_assignments.created_at IS '作成日時';
COMMENT ON COLUMN t_influencer_agent_assignments.updated_at IS '最終更新日時（トリガーで自動更新）';

COMMENT ON COLUMN t_notifications.created_by IS '作成者ID';
COMMENT ON COLUMN t_notifications.updated_by IS '最終更新者ID';
COMMENT ON COLUMN t_notifications.created_at IS '作成日時';
COMMENT ON COLUMN t_notifications.updated_at IS '最終更新日時（トリガーで自動更新）';

COMMENT ON COLUMN t_translations.created_by IS '作成者ID';
COMMENT ON COLUMN t_translations.updated_by IS '最終更新者ID';
COMMENT ON COLUMN t_translations.created_at IS '作成日時';
COMMENT ON COLUMN t_translations.updated_at IS '最終更新日時（トリガーで自動更新）';

COMMENT ON COLUMN t_files.created_by IS '作成者ID';
COMMENT ON COLUMN t_files.updated_by IS '最終更新者ID';
COMMENT ON COLUMN t_files.created_at IS '作成日時';
COMMENT ON COLUMN t_files.updated_at IS '最終更新日時（トリガーで自動更新）';

COMMIT;
