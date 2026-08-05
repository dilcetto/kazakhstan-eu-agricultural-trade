import pandas as pd
import os

def clean_data(input_file: str, output_file: str):
    print("=" * 60)
    print(f"Loading: {input_file}")

    df = pd.read_csv(input_file)
    print(f"Original shape: {df.shape}")

    #standardizing column names
    df.columns = (
        df.columns
        .str.strip()
        .str.lower()
        .str.replace(' ', '_')
        .str.replace('(', '', regex = False)
        .str.replace(')', '', regex = False)
    )

    #removing whitespace from string columns
    text_columns = df.select_dtypes(include=['object']).columns
    for column in text_columns:
        df[column] = df[column].str.strip()

    #converting data types
    if 'year' in df.columns:
        df['year'] = pd.to_numeric(df['year'], errors='coerce').astype('Int64')
    if 'value' in df.columns:
        df['value'] = pd.to_numeric(df['value'], errors='coerce')
    #duplicates check
    duplicates = df.duplicated().sum()
    print(f"Duplicate rows: {duplicates}")
    if duplicates > 0:
        df = df.drop_duplicates()
    #missing values check
    print("\nMissing values:")
    print(df.isna().sum())

    #save
    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    df.to_parquet(output_file, index=False)
    print(f"Cleaned data saved to:\n{output_file}")
    print(f"Final shape: {df.shape}")

if __name__ == "__main__":
    clean_data(
            "data/raw/FAOSTAT_data_en_matrix.csv", 
            "data/processed/clean_trade_data.parquet")
    clean_data(
        "data/raw/FAOSTAT_data_production.csv",
        "data/processed/clean_production_data.parquet")
    print("Success") 