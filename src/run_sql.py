import argparse
from pathlib import Path

import duckdb

PROJECT_ROOT = Path(__file__).resolve().parent.parent
SQL_DIR = PROJECT_ROOT / "sql"
DEFAULT_QUERY_FILE = SQL_DIR / "05_trade_prod_analysis.sql"


def run_sql_file(query_file: Path) -> None:
    """Execute every statement in a SQL file and print tabular results."""
    query_path = query_file if query_file.is_absolute() else PROJECT_ROOT / query_file
    if not query_path.is_file():
        raise FileNotFoundError(f"SQL file not found: {query_path}")

    statements = [
        statement.strip()
        for statement in query_path.read_text(encoding="utf-8").split(";")
        if statement.strip()
    ]

    with duckdb.connect() as connection:
        for statement in statements:
            result = connection.execute(statement)
            if result.description is not None:
                print(result.fetchdf())


def parse_args() -> argparse.Namespace:
    """Parse the optional SQL file path."""
    parser = argparse.ArgumentParser(description="Run a project SQL analysis file.")
    parser.add_argument(
        "query_file",
        nargs="?",
        type=Path,
        default=DEFAULT_QUERY_FILE,
        help="SQL file to run (default: sql/05_trade_prod_analysis.sql)",
    )
    return parser.parse_args()


if __name__ == "__main__":
    arguments = parse_args()
    run_sql_file(arguments.query_file)
