from pathlib import Path

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_INPUT = PROJECT_ROOT / "data/processed/prepared_trade_data.parquet"
DEFAULT_OUTPUT = PROJECT_ROOT / "data/processed/tableau_trade.csv"


def export_tableau_data(
    input_file: Path = DEFAULT_INPUT,
    output_file: Path = DEFAULT_OUTPUT,
) -> pd.DataFrame:
    """Export analysis-ready trade data with Tableau-friendly fields and units."""
    trade = pd.read_parquet(input_file)
    required_columns = {
        "reporter_countries",
        "partner_countries",
        "item",
        "year",
        "export_quantity",
        "export_value",
    }
    missing_columns = required_columns - set(trade.columns)
    if missing_columns:
        raise ValueError(f"Missing required columns: {sorted(missing_columns)}")

    dashboard_data = trade.rename(
        columns={
            "reporter_countries": "Reporter",
            "partner_countries": "Partner",
            "item": "Commodity",
            "year": "Year",
            "export_quantity": "Export Quantity (tonnes)",
        }
    )
    dashboard_data["Export Value (USD)"] = (
        dashboard_data.pop("export_value") * 1_000
    )
    dashboard_data["Year"] = dashboard_data["Year"].astype(int)
    dashboard_data = dashboard_data[
        [
            "Reporter",
            "Partner",
            "Commodity",
            "Year",
            "Export Quantity (tonnes)",
            "Export Value (USD)",
        ]
    ].sort_values(["Year", "Commodity", "Partner"])

    output_file.parent.mkdir(parents=True, exist_ok=True)
    dashboard_data.to_csv(output_file, index=False)
    print(f"Exported {len(dashboard_data)} rows to {output_file}")
    return dashboard_data


if __name__ == "__main__":
    export_tableau_data()
