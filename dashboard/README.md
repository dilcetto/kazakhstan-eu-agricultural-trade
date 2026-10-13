# Tableau Dashboard Build Guide

This guide turns the prepared trade data into a portfolio-ready Tableau Public dashboard. The first version should take about two to four hours.

## 1. Prepare the data

From the repository root, run:

```bash
python src/export_tableau_data.py
```

This creates `data/processed/tableau_trade.csv`, a 257-row file with display-ready field names and explicit units.

## 2. Connect Tableau

1. Open [Tableau Public](https://public.tableau.com/) in the browser or install Tableau Desktop Public Edition.
2. Select **Create** or **Connect to Data**.
3. Choose **Text File** and open `data/processed/tableau_trade.csv`.
4. Confirm these field types:
   - `Reporter`, `Partner`, and `Commodity`: text dimensions.
   - `Year`: whole number dimension.
   - `Export Quantity (tonnes)` and `Export Value (USD)`: numeric measures.
5. Right-click `Partner`, select **Geographic Role**, then **Country/Region**. This is optional for the first dashboard but enables a map later.

## 3. Create the calculated fields

In the Data pane, select **Create Calculated Field** and add:

### Export Value (USD M)

```text
SUM([Export Value (USD)]) / 1000000
```

Set its default number format to **Number (Custom)** with one decimal place and the suffix `M`.

### Highlight 2022

```text
IF [Year] = 2022 THEN "2022 peak" ELSE "Other years" END
```

## 4. Build the worksheets

### Sheet 1: Total Export Value

1. Rename the sheet `KPI - Total Export Value`.
2. Set the Marks type to **Text**.
3. Drag `Export Value (USD M)` to **Text**.
4. Increase the value size and title the sheet `Total Export Value, 2018–2024`.
5. The result should be approximately **USD 1,515.8M**.

### Sheet 2: Annual Export Value

1. Rename the sheet `Annual Export Value`.
2. Drag `Year` to **Columns** and make it discrete.
3. Drag `Export Value (USD M)` to **Rows**.
4. Select **Bar** marks.
5. Drag `Highlight 2022` to **Color**.
6. Use a gold color for `2022 peak` and a light blue or gray for other years.
7. Turn on mark labels.
8. The 2022 bar should be the highest at approximately **USD 301.0M**.

### Sheet 3: Export Value by Commodity

1. Rename the sheet `Commodity Concentration`.
2. Drag `Commodity` to **Rows**.
3. Drag `Export Value (USD M)` to **Columns**.
4. Sort descending and turn on mark labels.
5. Drag `Year` to **Filters**, select all years, and choose **Show Filter**.
6. Linseed and wheat should appear first.

### Sheet 4: Export Value by Destination

1. Rename the sheet `Destination Concentration`.
2. Drag `Partner` to **Rows**.
3. Drag `Export Value (USD M)` to **Columns**.
4. Sort descending and turn on mark labels.
5. Drag `Year` to **Filters**, select all years, and choose **Show Filter**.
6. Belgium and Italy should appear first.

### Optional Sheet 5: Destination Map

1. Double-click `Partner` to create a map.
2. Drag `Export Value (USD M)` to **Size** and **Color**.
3. Add `Partner` and `Export Value (USD M)` to **Tooltip**.
4. If Tableau reports an unknown location, use **Map > Edit Locations** and set the country manually.

## 5. Assemble the dashboard

1. Create a dashboard with a fixed size of approximately `1200 × 800` pixels.
2. Add the title `Kazakhstan–EU Agricultural Trade, 2018–2024`.
3. Put the KPI at the top.
4. Place `Annual Export Value` across the middle.
5. Put `Commodity Concentration` and `Destination Concentration` side by side at the bottom.
6. Show one shared `Year` filter and apply it to all related worksheets.
7. Add the note: `Source: FAOSTAT detailed trade matrix. Export value in current USD.`
8. Keep the dashboard to one accent color, one neutral color, and a white background.

## 6. Validate the dashboard

Before publishing, confirm these all-years results:

| Check | Expected result |
|---|---:|
| Total export value | USD 1,515.8M |
| Peak year | 2022 — USD 301.0M |
| Linseed share | 54.94% |
| Wheat share | 42.17% |
| Belgium share | 35.17% |
| Italy share | 34.83% |

## 7. Publish and add it to the repository

1. Publish the workbook to your Tableau Public profile.
2. Use a descriptive title such as `Kazakhstan–EU Agricultural Trade Dashboard`.
3. Add a short description naming Python, pandas, DuckDB, SQL, Tableau, and FAOSTAT.
4. Save a local packaged workbook as `dashboard/kazakhstan_eu_trade_dashboard.twbx`.
5. Export a dashboard screenshot to `outputs/figures/tableau_dashboard.png`.
6. Confirm the main `README.md` links to the current Tableau Public URL.

## CV bullet after publishing

> Built and published an interactive Tableau dashboard analyzing USD 1.52B of Kazakhstan–EU agricultural exports across 23 destination markets and seven years, using Python, SQL, DuckDB, and FAOSTAT data to identify commodity and geographic concentration.
