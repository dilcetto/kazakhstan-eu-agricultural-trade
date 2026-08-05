-- ======================================================
-- Kazakhstan–EU Agricultural Trade
-- Trade Analysis
-- ======================================================

CREATE OR REPLACE VIEW trade AS
SELECT *
FROM read_parquet('data/processed/prepared_trade_data.parquet');

-- ======================================================
-- 1. ANNUAL DEVELOPMENT
-- Question: Did Kazakhstan -> EU agricultural trade grow over the years?
-- ======================================================

SELECT
    year,
    SUM(export_quantity) AS total_export_quantity,
    SUM(export_value) AS total_export_value
FROM trade
GROUP BY year
ORDER BY year;

-- =======================================================
-- 2. COMMODITY TRENDS
-- Question: Which commodities have the highest export value and quantity?
-- =======================================================  

SELECT
    item,
    SUM(export_quantity) AS total_export_quantity,
    SUM(export_value) AS total_export_value
FROM trade
GROUP BY item
ORDER BY total_export_value DESC;

-- ======================================================
-- 3. EU TRADING PARTNERS
-- Question: Which EU countries are the main trading partners of Kazakhstan?
-- ======================================================

SELECT
    partner_countries,
    SUM(export_quantity) AS total_export_quantity,
    SUM(export_value) AS total_export_value
FROM trade
GROUP BY partner_countries
ORDER BY total_export_value DESC;

-- ======================================================
-- 4. COMMODITY x YEAR
-- Question: How did the export value and quantity of each commodity change over the years?
-- ======================================================

SELECT
    year,
    item,
    SUM(export_quantity) AS total_export_quantity,
    SUM(export_value) AS total_export_value
FROM trade
GROUP BY year, item
ORDER BY year, total_export_value DESC;

-- ======================================================
-- 5. PARTNER x YEAR
-- Question: How did the export value and quantity to each EU country change over the years?
-- ======================================================

SELECT
    year,
    partner_countries,
    SUM(export_quantity) AS total_export_quantity,
    SUM(export_value) AS total_export_value
FROM trade
GROUP BY year, partner_countries
ORDER BY year, total_export_value DESC;

-- ======================================================
-- 6. YEAR-OVER-YEAR EXPORT VALUE CHANGE
-- Question: How much did total export value change each year?
-- ======================================================

WITH annual_trade AS (
    SELECT
        year,
        SUM(export_value) AS total_export_value
    FROM trade
    GROUP BY year
), 
annual_change AS (
    SELECT
        year,
        total_export_value,
        LAG(total_export_value) OVER (ORDER BY year) AS previous_year_value
    FROM annual_trade
)
SELECT
    year,
    total_export_value,
    previous_year_value,
    total_export_value - previous_year_value AS absolute_change,
    ROUND(
        100.0 * (total_export_value - previous_year_value)/NULLIF(previous_year_value, 0), 
        2) AS percentage_change
FROM annual_change
OrDER BY year;

-- ======================================================
-- 7. COMMODITY EXPORT-VALUE SHARES
-- Question: What percentage of total export value does each commodity represent?
-- ======================================================

SELECT
    item,
    SUM(export_value) AS total_export_value,
    ROUND(
        100.0 * SUM(export_value) / 
        (SUM(SUM(export_value)) OVER ()), 
        2
    ) AS export_value_share
FROM trade
GROUP BY item
ORDER BY total_export_value DESC;

-- ======================================================
-- 8. PARTNER-COUNTRY EXPORT-VALUE SHARES
-- Question: What percentage of export value goes to each EU destination market?
-- ======================================================

SELECT
    partner_countries,
    SUM(export_value) AS total_export_value,
    ROUND(
        100.0 * SUM(export_value) / 
        (SUM(SUM(export_value)) OVER ()), 
        2
    ) AS export_value_share
FROM trade
GROUP BY partner_countries
ORDER BY total_export_value DESC;

-- ======================================================
-- 9. 2018 VS 2024 COMMODITY COMPARISON
-- Question: How did the composition of exports change between 2018 and 2024?
-- ======================================================

SELECT
    item, 
    SUM(CASE WHEN year = 2018 THEN export_value
             ELSE 0 END) AS export_value_2018,
    SUM(CASE WHEN year = 2024 THEN export_value
             ELSE 0 END) AS export_value_2024,
    SUM(CASE WHEN year = 2024 THEN export_value
             ELSE 0 END)
    -
    SUM(CASE WHEN year = 2018 THEN export_value
                ELSE 0 END) AS absolute_change
FROM trade
WHERE year IN (2018, 2024)
GROUP BY item
ORDER BY absolute_change DESC;