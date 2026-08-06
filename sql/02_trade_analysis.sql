-- Kazakhstan–EU Agricultural Trade: Trade Analysis

CREATE OR REPLACE VIEW trade AS
SELECT *
FROM read_parquet('data/processed/prepared_trade_data.parquet');

-- 1. Annual development
-- Did Kazakhstan's agricultural exports to the EU grow over time?

SELECT
    year,
    SUM(export_quantity) AS total_export_quantity,
    SUM(export_value) AS total_export_value
FROM trade
GROUP BY year
ORDER BY year;

-- 2. Commodity totals
-- Which commodities have the highest export value and quantity?

SELECT
    item,
    SUM(export_quantity) AS total_export_quantity,
    SUM(export_value) AS total_export_value
FROM trade
GROUP BY item
ORDER BY total_export_value DESC;

-- 3. EU trading partners
-- Which EU countries are Kazakhstan's main destination markets?

SELECT
    partner_countries,
    SUM(export_quantity) AS total_export_quantity,
    SUM(export_value) AS total_export_value
FROM trade
GROUP BY partner_countries
ORDER BY total_export_value DESC;

-- 4. Commodity trends by year
-- How did each commodity's export value and quantity change over time?

SELECT
    year,
    item,
    SUM(export_quantity) AS total_export_quantity,
    SUM(export_value) AS total_export_value
FROM trade
GROUP BY year, item
ORDER BY year, total_export_value DESC;

-- 5. Partner trends by year
-- How did exports to each EU country change over time?

SELECT
    year,
    partner_countries,
    SUM(export_quantity) AS total_export_quantity,
    SUM(export_value) AS total_export_value
FROM trade
GROUP BY year, partner_countries
ORDER BY year, total_export_value DESC;

-- 6. Year-over-year export value change

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
        100.0 * (total_export_value - previous_year_value)
        / NULLIF(previous_year_value, 0),
        2
    ) AS percentage_change
FROM annual_change
ORDER BY year;

-- 7. Commodity export-value shares

SELECT
    item,
    SUM(export_value) AS total_export_value,
    ROUND(
        100.0 * SUM(export_value)
        / SUM(SUM(export_value)) OVER (),
        2
    ) AS export_value_share
FROM trade
GROUP BY item
ORDER BY total_export_value DESC;

-- 8. Partner-country export-value shares

SELECT
    partner_countries,
    SUM(export_value) AS total_export_value,
    ROUND(
        100.0 * SUM(export_value)
        / SUM(SUM(export_value)) OVER (),
        2
    ) AS export_value_share
FROM trade
GROUP BY partner_countries
ORDER BY total_export_value DESC;

-- 9. Commodity comparison: 2018 vs 2024

SELECT
    item,
    SUM(
        CASE WHEN year = 2018 THEN export_value ELSE 0 END
    ) AS export_value_2018,
    SUM(
        CASE WHEN year = 2024 THEN export_value ELSE 0 END
    ) AS export_value_2024,
    SUM(
        CASE WHEN year = 2024 THEN export_value ELSE 0 END
    ) - SUM(
        CASE WHEN year = 2018 THEN export_value ELSE 0 END
    ) AS absolute_change
FROM trade
WHERE year IN (2018, 2024)
GROUP BY item
ORDER BY absolute_change DESC;
