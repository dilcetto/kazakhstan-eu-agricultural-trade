import pandas as pd

def prepare_prod_dataset(input_file: str, output_file: str):
    print("=" * 60)
    production = pd.read_parquet(input_file)
    print(f"Original shape: {production.shape}")
    #dropping rows with missing values in the 'value' column
    missing_values = production["value"].isna().sum()
    print(f"Missing values in 'value' column: {missing_values}")
    if missing_values > 0:
        production = production.dropna(subset=["value"])
    print(f"Shape after dropping missing values: {production.shape}")
    print(production["element"].value_counts())
    expected = {"Production", "Area harvested", "Yield"}
    actual = set(production["element"].unique())
    assert actual == expected
    production = production.pivot_table(
        index=[
            "item",
            "year",
        ],
        columns="element",
        values="value",
        aggfunc="first",
    ).reset_index()
    #standardizing new column names
    production.columns = (
        production.columns
        .str.strip()
        .str.lower()
        .str.replace(" ", "_")
    )
    assert "production" in production.columns
    assert "area_harvested" in production.columns
    assert "yield" in production.columns
    print(f"Rows after pivot: {production.shape[0]}")
    print(production.head())
    print(production.isna().sum())
    print(production.dtypes)

    duplicates = production.duplicated(
        subset = [
            "item",
            "year",
        ]
    ).sum()
    print(f"Number of duplicate rows: {duplicates}")
    assert duplicates == 0
    production.to_parquet(output_file, index=False)

if __name__ == "__main__":
    prepare_prod_dataset(
        "data/processed/clean_production_data.parquet",
        "data/processed/prepared_production_data.parquet",
    )
    print("Success")