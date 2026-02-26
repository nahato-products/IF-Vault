-- =============================================================================
-- 007_seed_data.sql
-- インフルエンサー管理システム — マスタ初期データ（シードデータ）
-- PostgreSQL 15 / Cloud SQL
-- =============================================================================
-- 実行前提: 001〜006 が適用済みであること
-- created_by / updated_by = 1（システム管理者エージェント）
-- status_id = 1（有効）
-- =============================================================================

BEGIN;

-- =============================================================================
-- t_sns_platforms — SNSプラットフォームマスタ
-- =============================================================================

INSERT INTO t_sns_platforms
    (platform_key, platform_name, status_id, created_by, updated_by, created_at, updated_at)
VALUES
    ('instagram', 'Instagram',     1, 1, 1, NOW(), NOW()),
    ('tiktok',    'TikTok',        1, 1, 1, NOW(), NOW()),
    ('youtube',   'YouTube',       1, 1, 1, NOW(), NOW()),
    ('x',         'X（旧Twitter）', 1, 1, 1, NOW(), NOW()),
    ('facebook',  'Facebook',      1, 1, 1, NOW(), NOW()),
    ('threads',   'Threads',       1, 1, 1, NOW(), NOW()),
    ('note',      'note',          1, 1, 1, NOW(), NOW())
ON CONFLICT (platform_key) DO NOTHING;


-- =============================================================================
-- t_categories — カテゴリマスタ（階層構造）
-- =============================================================================
-- 大カテゴリ（parent_category_id = NULL）を先に挿入し、
-- 小カテゴリから RETURNING id を使わずに
-- サブクエリで parent_category_id を解決する方式を採用。
-- =============================================================================

-- -------------------------------------
-- 大カテゴリ（Level 1）
-- -------------------------------------
INSERT INTO t_categories
    (category_name, parent_category_id, status_id, created_by, updated_by, created_at, updated_at)
VALUES
    ('ビューティ',     NULL, 1, 1, 1, NOW(), NOW()),
    ('ファッション',   NULL, 1, 1, 1, NOW(), NOW()),
    ('フード',         NULL, 1, 1, 1, NOW(), NOW()),
    ('旅行',           NULL, 1, 1, 1, NOW(), NOW()),
    ('ライフスタイル', NULL, 1, 1, 1, NOW(), NOW()),
    ('フィットネス',   NULL, 1, 1, 1, NOW(), NOW()),
    ('ゲーム',         NULL, 1, 1, 1, NOW(), NOW()),
    ('テック',         NULL, 1, 1, 1, NOW(), NOW()),
    ('エンタメ',       NULL, 1, 1, 1, NOW(), NOW()),
    ('教育',           NULL, 1, 1, 1, NOW(), NOW()),
    ('ビジネス',       NULL, 1, 1, 1, NOW(), NOW()),
    ('アート',         NULL, 1, 1, 1, NOW(), NOW()),
    ('スポーツ',       NULL, 1, 1, 1, NOW(), NOW()),
    ('ペット',         NULL, 1, 1, 1, NOW(), NOW()),
    ('育児',           NULL, 1, 1, 1, NOW(), NOW())
ON CONFLICT ON CONSTRAINT uq_category_name_parent DO NOTHING;

-- -------------------------------------
-- 小カテゴリ（Level 2）— ビューティ配下
-- -------------------------------------
INSERT INTO t_categories
    (category_name, parent_category_id, status_id, created_by, updated_by, created_at, updated_at)
SELECT
    sub.category_name,
    p.category_id,
    1, 1, 1, NOW(), NOW()
FROM (
    VALUES
        ('メイク'),
        ('スキンケア'),
        ('ヘアケア'),
        ('ネイル')
) AS sub(category_name)
CROSS JOIN (
    SELECT category_id
    FROM t_categories
    WHERE category_name = 'ビューティ'
      AND parent_category_id IS NULL
) p
ON CONFLICT ON CONSTRAINT uq_category_name_parent DO NOTHING;

-- -------------------------------------
-- 小カテゴリ（Level 2）— ファッション配下
-- -------------------------------------
INSERT INTO t_categories
    (category_name, parent_category_id, status_id, created_by, updated_by, created_at, updated_at)
SELECT
    sub.category_name,
    p.category_id,
    1, 1, 1, NOW(), NOW()
FROM (
    VALUES
        ('レディース'),
        ('メンズ'),
        ('ストリート'),
        ('ラグジュアリー')
) AS sub(category_name)
CROSS JOIN (
    SELECT category_id
    FROM t_categories
    WHERE category_name = 'ファッション'
      AND parent_category_id IS NULL
) p
ON CONFLICT ON CONSTRAINT uq_category_name_parent DO NOTHING;

-- -------------------------------------
-- 小カテゴリ（Level 2）— フード配下
-- -------------------------------------
INSERT INTO t_categories
    (category_name, parent_category_id, status_id, created_by, updated_by, created_at, updated_at)
SELECT
    sub.category_name,
    p.category_id,
    1, 1, 1, NOW(), NOW()
FROM (
    VALUES
        ('グルメ'),
        ('料理'),
        ('スイーツ'),
        ('ダイエット')
) AS sub(category_name)
CROSS JOIN (
    SELECT category_id
    FROM t_categories
    WHERE category_name = 'フード'
      AND parent_category_id IS NULL
) p
ON CONFLICT ON CONSTRAINT uq_category_name_parent DO NOTHING;

COMMIT;

-- =============================================================================
-- 確認クエリ（実行後に手動で確認する用）
-- =============================================================================
--
-- SELECT platform_id, platform_key, platform_name FROM t_sns_platforms ORDER BY platform_id;
--
-- SELECT
--     c.category_id,
--     p.category_name AS parent_name,
--     c.category_name,
--     c.parent_category_id
-- FROM t_categories c
-- LEFT JOIN t_categories p ON c.parent_category_id = p.category_id
-- ORDER BY COALESCE(c.parent_category_id, c.category_id), c.parent_category_id NULLS FIRST;
-- =============================================================================
