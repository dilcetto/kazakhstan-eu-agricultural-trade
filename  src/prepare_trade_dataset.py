import pandas as pd 

def prepare_trade_dataset(input_file: str, output_file: str):

    print("=" * 60)
    trade = pd.read_parquet(input_file)
    print(f"Original shape: {trade.shape}")
    #dropping rows with missing values in the 'value' column
    missing_values = trade["value"].isna().sum()
    print(f"Missing values in 'value' column: {missing_values}")
    if missing_values > 0:
        trade = trade.dropna(subset=["value"])
    print(f"Shape after dropping missing values: {trade.shape}")
    #convert trade observations from long format (one row per element) 
    # to wide format (one row per partner–commodity–year)
    assert trade["element"].nunique() == 2
    trade = trade.pivot_table(
    index=[
        "reporter_countries",
        "partner_countries",
        "item",
        "year",
    ],
    columns="element",
    values="value",
    aggfunc="first",
).reset_index()
    #standardizing new column names
    trade.columns = (
        trade.columns
        .str.strip()
        .str.lower()
        .str.replace(" ", "_")
    )
    assert "export_quantity" in trade.columns
    assert "export_value" in trade.columns
    print(f"Rows after pivot: {trade.shape[0]}")
    print(trade.head())
    print(trade.isna().sum())
    print(trade.dtypes)

    duplicates = trade.duplicated(
        subset = [
            "reporter_countries", 
            "partner_countries", 
            "item",
            "year",
        ]
    ).sum()
    print(f"Number of duplicate rows: {duplicates}")

    trade.to_parquet(output_file, index=False)
if __name__ == "__main__":
    prepare_trade_dataset(
        "data/processed/clean_trade_data.parquet",
        "data/processed/prepared_trade_data.parquet"
    )
    print("Success")