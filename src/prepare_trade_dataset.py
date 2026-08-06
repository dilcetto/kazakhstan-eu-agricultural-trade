import pandas as pd

from data_utils import prepare_wide_dataset


def prepare_trade_dataset(input_file: str, output_file: str) -> pd.DataFrame:
    """Prepare partner-commodity-year trade measures for analysis."""
    return prepare_wide_dataset(
        input_file,
        output_file,
        index_columns=[
            "reporter_countries",
            "partner_countries",
            "item",
            "year",
        ],
        expected_elements={"Export quantity", "Export value"},
        required_columns={"export_quantity", "export_value"},
    )


if __name__ == "__main__":
    prepare_trade_dataset(
        "data/processed/clean_trade_data.parquet",
        "data/processed/prepared_trade_data.parquet",
    )
    print("Trade preparation complete")
