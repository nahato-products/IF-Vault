"""ID変換・正規化"""


def transform_rows(rows: list[dict], config: dict) -> list[dict]:
    """CSV値をDB投入用に変換する"""
    transformed = []

    for row in rows:
        record = {}
        for col_def in config["columns"]:
            csv_col = col_def["csv"]
            db_col = col_def["db"]
            value = row.get(csv_col, "").strip()

            if not value:
                record[db_col] = None
                continue

            col_type = col_def.get("type")
            if col_type == "dropdown":
                record[db_col] = col_def["mapping"].get(value, value)
            elif col_type == "boolean":
                record[db_col] = col_def["mapping"].get(value, False)
            else:
                record[db_col] = value

        transformed.append(record)

    return transformed


def transform_related(rows: list[dict], config: dict) -> dict[str, list[dict]]:
    """関連テーブル（SNS、口座等）のデータを分離・変換する"""
    related_data = {}

    for rel in config.get("related_tables", []):
        table_name = rel["table"]
        records = []

        for row in rows:
            for col_def in rel["columns"]:
                csv_col = col_def["csv"]
                value = row.get(csv_col, "").strip()
                if not value:
                    continue

                record = {col_def["db"]: value}
                if "extra" in col_def:
                    record.update(col_def["extra"])
                records.append(record)

        if records:
            related_data[table_name] = records

    return related_data
