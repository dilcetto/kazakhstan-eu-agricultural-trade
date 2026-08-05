from pathlib import Path
import duckdb

PROJECT_ROOT = Path(__file__).resolve().parent.parent
SQL_DIR = PROJECT_ROOT / "sql"
DATA_DIR = PROJECT_ROOT / "data"

query_file = SQL_DIR / "05_trade_prod_analysis.sql"


query = query_file.read_text(encoding="utf-8")
print(PROJECT_ROOT)

print(SQL_DIR)

print(DATA_DIR)

print(query_file)

print(query_file.exists())

con = duckdb.connect()

#split the sql file into individual statements
statements = [
    statement.strip() 
    for statement in query.split(";") 
    if statement.strip()
]
#execute each statement 
for statement in statements:
    result = con.execute(statement)

    if result.description is not None:
        print(result.fetchdf())