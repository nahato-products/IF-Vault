"""DB投入（DRY RUN / 本番）"""


def generate_sql(rows: list[dict], config: dict) -> list[str]:
    """INSERT SQLを生成する（DRY RUN用）"""
    table_name = config["table"]
    statements = []

    for row in rows:
        cols = [k for k, v in row.items() if v is not None]
        vals = [_sql_value(row[c]) for c in cols]

        sql = f"INSERT INTO {table_name} ({', '.join(cols)}) VALUES ({', '.join(vals)});"
        statements.append(sql)

    return statements


def execute_insert(rows: list[dict], config: dict, db_url: str) -> int:
    """DBに直接INSERT（トランザクション）"""
    import psycopg

    table_name = config["table"]
    count = 0

    with psycopg.connect(db_url) as conn:
        with conn.cursor() as cur:
            for row in rows:
                cols = [k for k, v in row.items() if v is not None]
                placeholders = ["%s"] * len(cols)
                values = [row[c] for c in cols]

                sql = f"INSERT INTO {table_name} ({', '.join(cols)}) VALUES ({', '.join(placeholders)})"
                cur.execute(sql, values)
                count += 1

        conn.commit()

    return count


def _sql_value(value) -> str:
    """Python値をSQL値に変換"""
    if value is None:
        return "NULL"
    if isinstance(value, bool):
        return "TRUE" if value else "FALSE"
    if isinstance(value, (int, float)):
        return str(value)
    escaped = str(value).replace("'", "''")
    return f"'{escaped}'"
