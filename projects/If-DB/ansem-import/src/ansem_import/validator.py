"""バリデーションエンジン"""

import re


def validate_csv(rows: list[dict], config: dict) -> tuple[list[dict], list[dict]]:
    """CSV行をバリデーションし、正常行とエラーを分離する"""
    valid = []
    errors = []

    for i, row in enumerate(rows, start=2):  # ヘッダーが1行目なので2行目から
        row_errors = _validate_row(row, config, i)
        if row_errors:
            errors.extend(row_errors)
        else:
            valid.append(row)

    return valid, errors


def _validate_row(row: dict, config: dict, row_num: int) -> list[dict]:
    """1行のバリデーション"""
    errors = []

    for col_def in config["columns"]:
        csv_col = col_def["csv"]
        value = row.get(csv_col, "").strip()

        # 必須チェック
        if col_def.get("required") and not value:
            errors.append({
                "row": row_num,
                "column": csv_col,
                "value": "",
                "message": f"必須項目「{csv_col}」が空です",
            })
            continue

        if not value:
            continue

        # 形式チェック
        fmt = col_def.get("format")
        if fmt == "email" and not _is_valid_email(value):
            errors.append({
                "row": row_num,
                "column": csv_col,
                "value": value,
                "message": f"メールアドレス形式不正: {value}",
            })

        if fmt and fmt.startswith("digits:"):
            length = int(fmt.split(":")[1])
            if not re.fullmatch(r"\d{" + str(length) + "}", value):
                errors.append({
                    "row": row_num,
                    "column": csv_col,
                    "value": value,
                    "message": f"{csv_col}は{length}桁の数字が必要: {value}",
                })

        # ドロップダウンチェック
        if col_def.get("type") == "dropdown":
            mapping = col_def.get("mapping", {})
            if value not in mapping:
                allowed = ", ".join(mapping.keys())
                errors.append({
                    "row": row_num,
                    "column": csv_col,
                    "value": value,
                    "message": f"「{csv_col}」の値が不正: {value}（有効値: {allowed}）",
                })

    return errors


def _is_valid_email(email: str) -> bool:
    """簡易メールアドレスバリデーション"""
    return bool(re.fullmatch(r"[^@\s]+@[^@\s]+\.[^@\s]+", email))
