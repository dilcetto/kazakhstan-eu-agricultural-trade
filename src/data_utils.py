from collections.abc import Collection, Sequence
from pathlib import Path

import pandas as pd


def normalize_column_names(dataframe: pd.DataFrame) -> pd.DataFrame:
    """Normalize dataframe column names to lowercase snake case."""
    dataframe.columns = (
        dataframe.columns.str.strip()
        .str.lower()
        .str.replace(" ", "_", regex=False)
        .str.replace("(", "", regex=False)
        .str.replace(")", "", regex=False)
    )
    return dataframe


def prepare_wide_dataset(
    input_file: str,
    output_file: str,
    *,
    index_columns: Sequence[str],
    expected_elements: Collection[str],
    required_columns: Collection[str],
) -> pd.DataFrame:
    """Pivot a cleaned FAOSTAT dataset and validate its analytical schema."""
    print("=" * 60)
    dataframe = pd.read_parquet(input_file)
    print(f"Original shape: {dataframe.shape}")

    missing_values = int(dataframe["value"].isna().sum())
    print(f"Missing values in 'value' column: {missing_values}")
    if missing_values:
        dataframe = dataframe.dropna(subset=["value"])
    print(f"Shape after dropping missing values: {dataframe.shape}")

    actual_elements = set(dataframe["element"].unique())
    if actual_elements != set(expected_elements):
        raise ValueError(
            "Unexpected elements: "
            f"expected {sorted(expected_elements)}, got {sorted(actual_elements)}"
        )

    source_keys = [*index_columns, "element"]
    source_duplicate_count = int(dataframe.duplicated(subset=source_keys).sum())
    if source_duplicate_count:
        raise ValueError(
            f"Found {source_duplicate_count} duplicate source observations"
        )

    dataframe = dataframe.pivot_table(
        index=list(index_columns),
        columns="element",
        values="value",
        aggfunc="first",
    ).reset_index()
    normalize_column_names(dataframe)

    missing_columns = set(required_columns) - set(dataframe.columns)
    if missing_columns:
        raise ValueError(f"Missing required columns: {sorted(missing_columns)}")

    duplicate_count = int(dataframe.duplicated(subset=index_columns).sum())
    print(f"Rows after pivot: {dataframe.shape[0]}")
    print(f"Duplicate rows: {duplicate_count}")
    print(dataframe.isna().sum())
    print(dataframe.dtypes)
    if duplicate_count:
        raise ValueError(f"Found {duplicate_count} duplicate rows after pivot")

    output_path = Path(output_file)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    dataframe.to_parquet(output_path, index=False)
    print(f"Prepared data saved to: {output_path}")
    return dataframe
