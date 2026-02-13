-- ============================================================
-- ANSEMプロジェクト データベース設計書 v5.5.0
-- ファイル: 005_create_partitions.sql
-- 説明: パーティション作成文（年次・月次パーティション）+ アーカイブ関数
-- 生成日: 2026-02-10
-- 更新日: 2026-02-12
-- 変更点: DEFAULTパーティション追加, スキーマ安全な自動作成/アーカイブ関数, daily自動作成関数
--
-- 実行順序: 001 → 002 → 003 → 004 → 005
-- ============================================================

BEGIN;

-- ============================================================
-- t_audit_logs 月次パーティション（直近3年分 = 36パーティション）
-- ============================================================
CREATE TABLE t_audit_logs_2024_01 PARTITION OF t_audit_logs FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
CREATE TABLE t_audit_logs_2024_02 PARTITION OF t_audit_logs FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
CREATE TABLE t_audit_logs_2024_03 PARTITION OF t_audit_logs FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');
CREATE TABLE t_audit_logs_2024_04 PARTITION OF t_audit_logs FOR VALUES FROM ('2024-04-01') TO ('2024-05-01');
CREATE TABLE t_audit_logs_2024_05 PARTITION OF t_audit_logs FOR VALUES FROM ('2024-05-01') TO ('2024-06-01');
CREATE TABLE t_audit_logs_2024_06 PARTITION OF t_audit_logs FOR VALUES FROM ('2024-06-01') TO ('2024-07-01');
CREATE TABLE t_audit_logs_2024_07 PARTITION OF t_audit_logs FOR VALUES FROM ('2024-07-01') TO ('2024-08-01');
CREATE TABLE t_audit_logs_2024_08 PARTITION OF t_audit_logs FOR VALUES FROM ('2024-08-01') TO ('2024-09-01');
CREATE TABLE t_audit_logs_2024_09 PARTITION OF t_audit_logs FOR VALUES FROM ('2024-09-01') TO ('2024-10-01');
CREATE TABLE t_audit_logs_2024_10 PARTITION OF t_audit_logs FOR VALUES FROM ('2024-10-01') TO ('2024-11-01');
CREATE TABLE t_audit_logs_2024_11 PARTITION OF t_audit_logs FOR VALUES FROM ('2024-11-01') TO ('2024-12-01');
CREATE TABLE t_audit_logs_2024_12 PARTITION OF t_audit_logs FOR VALUES FROM ('2024-12-01') TO ('2025-01-01');

CREATE TABLE t_audit_logs_2025_01 PARTITION OF t_audit_logs FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
CREATE TABLE t_audit_logs_2025_02 PARTITION OF t_audit_logs FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');
CREATE TABLE t_audit_logs_2025_03 PARTITION OF t_audit_logs FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');
CREATE TABLE t_audit_logs_2025_04 PARTITION OF t_audit_logs FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');
CREATE TABLE t_audit_logs_2025_05 PARTITION OF t_audit_logs FOR VALUES FROM ('2025-05-01') TO ('2025-06-01');
CREATE TABLE t_audit_logs_2025_06 PARTITION OF t_audit_logs FOR VALUES FROM ('2025-06-01') TO ('2025-07-01');
CREATE TABLE t_audit_logs_2025_07 PARTITION OF t_audit_logs FOR VALUES FROM ('2025-07-01') TO ('2025-08-01');
CREATE TABLE t_audit_logs_2025_08 PARTITION OF t_audit_logs FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');
CREATE TABLE t_audit_logs_2025_09 PARTITION OF t_audit_logs FOR VALUES FROM ('2025-09-01') TO ('2025-10-01');
CREATE TABLE t_audit_logs_2025_10 PARTITION OF t_audit_logs FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');
CREATE TABLE t_audit_logs_2025_11 PARTITION OF t_audit_logs FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');
CREATE TABLE t_audit_logs_2025_12 PARTITION OF t_audit_logs FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');

CREATE TABLE t_audit_logs_2026_01 PARTITION OF t_audit_logs FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE t_audit_logs_2026_02 PARTITION OF t_audit_logs FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
CREATE TABLE t_audit_logs_2026_03 PARTITION OF t_audit_logs FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE t_audit_logs_2026_04 PARTITION OF t_audit_logs FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
CREATE TABLE t_audit_logs_2026_05 PARTITION OF t_audit_logs FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');
CREATE TABLE t_audit_logs_2026_06 PARTITION OF t_audit_logs FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');
CREATE TABLE t_audit_logs_2026_07 PARTITION OF t_audit_logs FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');
CREATE TABLE t_audit_logs_2026_08 PARTITION OF t_audit_logs FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');
CREATE TABLE t_audit_logs_2026_09 PARTITION OF t_audit_logs FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');
CREATE TABLE t_audit_logs_2026_10 PARTITION OF t_audit_logs FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');
CREATE TABLE t_audit_logs_2026_11 PARTITION OF t_audit_logs FOR VALUES FROM ('2026-11-01') TO ('2026-12-01');
CREATE TABLE t_audit_logs_2026_12 PARTITION OF t_audit_logs FOR VALUES FROM ('2026-12-01') TO ('2027-01-01');

-- ------------------------------------------------------------
-- t_daily_performance_details パーティション（直近3年分）
-- ------------------------------------------------------------
CREATE TABLE t_daily_perf_2024 PARTITION OF t_daily_performance_details
  FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

CREATE TABLE t_daily_perf_2025 PARTITION OF t_daily_performance_details
  FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

CREATE TABLE t_daily_perf_2026 PARTITION OF t_daily_performance_details
  FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');

-- ------------------------------------------------------------
-- t_daily_click_details パーティション（直近3年分）
-- ------------------------------------------------------------
CREATE TABLE t_daily_click_2024 PARTITION OF t_daily_click_details
  FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

CREATE TABLE t_daily_click_2025 PARTITION OF t_daily_click_details
  FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

CREATE TABLE t_daily_click_2026 PARTITION OF t_daily_click_details
  FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');

-- ============================================================
-- DEFAULTパーティション（保険: 対応パーティション未作成時のINSERTエラー防止）
-- 本番運用では自動作成関数を正しくcron実行し、DEFAULTにデータが溜まらないようにする
-- ============================================================
CREATE TABLE t_audit_logs_default PARTITION OF t_audit_logs DEFAULT;
CREATE TABLE t_daily_perf_default PARTITION OF t_daily_performance_details DEFAULT;
CREATE TABLE t_daily_click_default PARTITION OF t_daily_click_details DEFAULT;

-- ============================================================
-- audit_logs パーティション自動作成関数（月次）
-- 月初にcronで呼び出し、翌月分のパーティションを事前作成する
-- 使用例: SELECT create_audit_log_partition('2027-01-01'::DATE);
-- 冪等: 既存パーティションがあればスキップ
-- ============================================================
CREATE OR REPLACE FUNCTION create_audit_log_partition(target_month DATE)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  partition_name TEXT;
  start_date DATE;
  end_date DATE;
BEGIN
  start_date := date_trunc('month', target_month);
  end_date := start_date + INTERVAL '1 month';
  partition_name := 't_audit_logs_' || to_char(start_date, 'YYYY_MM');

  IF EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relname = partition_name
      AND n.nspname = current_schema()
  ) THEN
    RETURN partition_name || ' already exists';
  END IF;

  EXECUTE format(
    'CREATE TABLE %I PARTITION OF t_audit_logs FOR VALUES FROM (%L) TO (%L)',
    partition_name, start_date, end_date
  );

  RETURN partition_name || ' created';
END;
$$;

-- ============================================================
-- 日次集計テーブル パーティション自動作成関数（年次）
-- 年末にcronで呼び出し、翌年分のパーティションを事前作成する
-- 使用例: SELECT create_daily_partitions(2027);
-- 冪等: 既存パーティションがあればスキップ
-- ============================================================
CREATE OR REPLACE FUNCTION create_daily_partitions(target_year INTEGER)
RETURNS TABLE(partition_name TEXT, result TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
  start_date DATE;
  end_date DATE;
  perf_name TEXT;
  click_name TEXT;
BEGIN
  start_date := make_date(target_year, 1, 1);
  end_date := make_date(target_year + 1, 1, 1);
  perf_name := 't_daily_perf_' || target_year;
  click_name := 't_daily_click_' || target_year;

  -- t_daily_performance_details
  IF EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relname = perf_name AND n.nspname = current_schema()
  ) THEN
    partition_name := perf_name;
    result := 'already exists';
    RETURN NEXT;
  ELSE
    EXECUTE format(
      'CREATE TABLE %I PARTITION OF t_daily_performance_details FOR VALUES FROM (%L) TO (%L)',
      perf_name, start_date, end_date
    );
    partition_name := perf_name;
    result := 'created';
    RETURN NEXT;
  END IF;

  -- t_daily_click_details
  IF EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relname = click_name AND n.nspname = current_schema()
  ) THEN
    partition_name := click_name;
    result := 'already exists';
    RETURN NEXT;
  ELSE
    EXECUTE format(
      'CREATE TABLE %I PARTITION OF t_daily_click_details FOR VALUES FROM (%L) TO (%L)',
      click_name, start_date, end_date
    );
    partition_name := click_name;
    result := 'created';
    RETURN NEXT;
  END IF;
END;
$$;

-- ============================================================
-- audit_logs 5年保持 アーカイブ対象リスト関数
-- DETACH PARTITION CONCURRENTLY はトランザクション内で実行できないため、
-- この関数はアーカイブ対象パーティション名のリストだけを返す。
-- 実際のDETACHは外部スクリプトで実行する:
--
-- 使用例:
--   SELECT * FROM list_audit_log_partitions_to_archive();
--
-- 外部スクリプト例（シェル）:
--   for part in $(psql -t -c "SELECT partition_name FROM list_audit_log_partitions_to_archive()"); do
--     psql -c "ALTER TABLE t_audit_logs DETACH PARTITION $part CONCURRENTLY;"
--   done
--
-- 保持基準: パーティション開始月から5年以上経過したものが対象
-- ============================================================
CREATE OR REPLACE FUNCTION list_audit_log_partitions_to_archive()
RETURNS TABLE(partition_name TEXT, partition_start DATE)
LANGUAGE plpgsql
AS $$
DECLARE
  rec RECORD;
  cutoff_date DATE;
  part_date DATE;
BEGIN
  cutoff_date := CURRENT_DATE - INTERVAL '5 years';

  FOR rec IN
    SELECT c.relname
    FROM pg_inherits i
    JOIN pg_class c ON c.oid = i.inhrelid
    JOIN pg_class p ON p.oid = i.inhparent
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE p.relname = 't_audit_logs'
      AND n.nspname = current_schema()
      AND c.relname != 't_audit_logs_default'
    ORDER BY c.relname
  LOOP
    part_date := to_date(
      substring(rec.relname FROM 't_audit_logs_(\d{4}_\d{2})'),
      'YYYY_MM'
    );

    -- 命名規則に合わないパーティションはスキップ
    IF part_date IS NULL THEN
      CONTINUE;
    END IF;

    IF part_date < cutoff_date THEN
      partition_name := rec.relname;
      partition_start := part_date;
      RETURN NEXT;
    END IF;
  END LOOP;
END;
$$;

COMMIT;
