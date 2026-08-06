import pandas as pd

from data_utils import prepare_wide_dataset


def prepare_prod_dataset(input_file: str, output_file: str) -> pd.DataFrame:
    """Prepare annual commodity production measures for analysis."""
    return prepare_wide_dataset(
        input_file,
        output_file,
        index_columns=["item", "year"],
        expected_elements={"Production", "Area harvested", "Yield"},
        required_columns={"production", "area_harvested", "yield"},
    )


if __name__ == "__main__":
    prepare_prod_dataset(
        "data/processed/clean_production_data.parquet",
        "data/processed/prepared_production_data.parquet",
    )
    print("Production preparation complete")
