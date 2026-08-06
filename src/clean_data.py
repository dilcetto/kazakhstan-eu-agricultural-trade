from pathlib import Path

import pandas as pd

from data_utils import normalize_column_names


def clean_data(input_file: str, output_file: str) -> pd.DataFrame:
    """Clean a FAOSTAT CSV file and save it in Parquet format."""
    print("=" * 60)
    print(f"Loading: {input_file}")

    dataframe = pd.read_csv(input_file)
    print(f"Original shape: {dataframe.shape}")
    normalize_column_names(dataframe)

    text_columns = dataframe.select_dtypes(include=["object"]).columns
    for column in text_columns:
        dataframe[column] = dataframe[column].str.strip()

    if "year" in dataframe.columns:
        dataframe["year"] = pd.to_numeric(
            dataframe["year"], errors="coerce"
        ).astype("Int64")
    if "value" in dataframe.columns:
        dataframe["value"] = pd.to_numeric(dataframe["value"], errors="coerce")

    duplicate_count = int(dataframe.duplicated().sum())
    print(f"Duplicate rows: {duplicate_count}")
    if duplicate_count:
        dataframe = dataframe.drop_duplicates()

    print("\nMissing values:")
    print(dataframe.isna().sum())

    output_path = Path(output_file)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    dataframe.to_parquet(output_path, index=False)
    print(f"Cleaned data saved to: {output_path}")
    print(f"Final shape: {dataframe.shape}")
    return dataframe


if __name__ == "__main__":
    clean_data(
        "data/raw/FAOSTAT_data_en_matrix.csv",
        "data/processed/clean_trade_data.parquet",
    )
    clean_data(
        "data/raw/FAOSTAT_data_production.csv",
        "data/processed/clean_production_data.parquet",
    )
    print("Cleaning complete")
