import pandas as pd
from sqlalchemy import create_engine
import urllib

# ---- FILL THESE IN ----
SERVER = "mfgabtesting.database.windows.net"
DATABASE = "free-sql-db-2847881"
USERNAME = "mfgadmin"
PASSWORD = "YOUR_PASSWORD_HERE"   # <-- fill in locally, never share this
CSV_PATH = "manufacturing_defect_dataset.csv"  # update to your actual file path
# ------------------------

# Build ODBC connection string
odbc_str = (
    f"DRIVER={{ODBC Driver 18 for SQL Server}};"
    f"SERVER={SERVER};"
    f"DATABASE={DATABASE};"
    f"UID={USERNAME};"
    f"PWD={PASSWORD};"
    f"Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
)
params = urllib.parse.quote_plus(odbc_str)
engine = create_engine(f"mssql+pyodbc:///?odbc_connect={params}")

# Confirm which database we're actually connected to
with engine.connect() as conn:
    actual_db = conn.exec_driver_sql("SELECT DB_NAME()").fetchone()[0]
    print(f"Connected to database: {actual_db}")
    assert actual_db == DATABASE, f"MISMATCH: expected {DATABASE}, connected to {actual_db}"

# Load CSV
df = pd.read_csv(CSV_PATH)
print(f"Loaded CSV: {df.shape[0]} rows, {df.shape[1]} columns")

# Push to Azure SQL as a new table
df.to_sql("manufacturing_defects", engine, if_exists="replace", index=False)
print("Successfully loaded into Azure SQL Database as table 'manufacturing_defects'")

# Verify with a quick query
with engine.connect() as conn:
    result = conn.exec_driver_sql("SELECT COUNT(*) FROM manufacturing_defects")
    count = result.fetchone()[0]
    print(f"Verified: {count} rows now in Azure SQL table")
