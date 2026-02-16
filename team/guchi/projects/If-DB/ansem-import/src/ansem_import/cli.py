"""CLIエントリポイント"""

import sys
from pathlib import Path

import click
import yaml

from .validator import validate_csv
from .transformer import transform_rows
from .loader import generate_sql, execute_insert


@click.group()
@click.version_option()
def main():
    """ANSEM DB一括登録CLIツール"""
    pass


@main.command()
@click.option("--table", "-t", required=True, help="対象テーブル名（例: influencers）")
@click.option("--file", "-f", "filepath", required=True, type=click.Path(exists=True), help="CSVファイルパス")
@click.option("--dry-run", is_flag=True, help="SQL出力のみ（DB変更なし）")
@click.option("--skip-errors", is_flag=True, help="エラー行をスキップして続行")
@click.option("--report", type=click.Path(), help="エラーレポートの出力先")
@click.option("--verbose", "-v", is_flag=True, help="詳細ログ出力")
@click.option("--db-url", envvar="ANSEM_DATABASE_URL", help="PostgreSQL接続URL")
def import_data(table, filepath, dry_run, skip_errors, report, verbose, db_url):
    """CSVファイルからデータをインポート"""

    # 1. テーブル定義YAMLの読み込み
    tables_dir = Path(__file__).parent.parent.parent / "tables"
    config_path = tables_dir / f"{table}.yaml"
    if not config_path.exists():
        click.echo(f"エラー: テーブル定義 {config_path} が見つかりません", err=True)
        sys.exit(1)

    with open(config_path) as f:
        config = yaml.safe_load(f)

    if verbose:
        click.echo(f"テーブル定義: {config['display_name']} ({config['table']})")

    # 2. CSV読み込み
    import csv
    with open(filepath, encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    click.echo(f"CSV読み込み: {len(rows)}行")

    # 3. バリデーション
    valid_rows, errors = validate_csv(rows, config)
    if errors:
        click.echo(f"\n⚠️  バリデーションエラー: {len(errors)}件")
        for err in errors:
            click.echo(f"  行{err['row']}: {err['message']}")
        if report:
            _write_error_report(errors, report)
            click.echo(f"エラーレポート: {report}")
        if not skip_errors and errors:
            click.echo("\n--skip-errors で続行可能")
            sys.exit(1)

    click.echo(f"バリデーション通過: {len(valid_rows)}行")

    # 4. 変換（名前→ID等）
    transformed = transform_rows(valid_rows, config)

    # 5. SQL生成 or DB投入
    if dry_run:
        click.echo("\n--- DRY RUN ---")
        sql_statements = generate_sql(transformed, config)
        for stmt in sql_statements:
            click.echo(stmt)
        click.echo(f"\n合計: {len(sql_statements)}件のINSERT文")
    else:
        if not db_url:
            click.echo("エラー: --db-url または ANSEM_DATABASE_URL が必要です", err=True)
            sys.exit(1)
        count = execute_insert(transformed, config, db_url)
        click.echo(f"\n✅ {count}件を {config['table']} に投入しました")


def _write_error_report(errors, path):
    """エラーレポートをCSV出力"""
    import csv
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["row", "column", "value", "message"])
        writer.writeheader()
        writer.writerows(errors)


if __name__ == "__main__":
    main()
