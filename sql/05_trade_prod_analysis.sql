-- Kazakhstan–EU Agricultural Trade: Trade and Production Analysis

CREATE OR REPLACE VIEW trade AS
SELECT *
FROM read_parquet('data/processed/prepared_trade_data.parquet');

CREATE OR REPLACE VIEW production AS
SELECT *
FROM read_parquet('data/processed/prepared_production_data.parquet');

-- 1. Join production with EU exports
-- How do domestic production and EU exports compare by commodity and year?

WITH annual_exports AS (
    SELECT
        item,
        year,
        SUM(export_quantity) AS eu_export_quantity,
        SUM(export_value) AS eu_export_value
    FROM trade
    GROUP BY item, year
)
SELECT
    production.item,
    production.year,
    production.production,
    production.area_harvested,
    production.yield,
    annual_exports.eu_export_quantity,
    annual_exports.eu_export_value
FROM production
LEFT JOIN annual_exports
    ON production.item = annual_exports.item
    AND production.year = annual_exports.year
ORDER BY production.item, production.year;

-- 2. EU export quantity as a share of production
-- What share of production was exported to the observed EU markets?

WITH annual_exports AS (
    SELECT
        item,
        year,
        SUM(export_quantity) AS eu_export_quantity
    FROM trade
    GROUP BY item, year
)
SELECT
    production.item,
    production.year,
    production.production,
    COALESCE(annual_exports.eu_export_quantity, 0) AS eu_export_quantity,
    ROUND(
        100.0 * COALESCE(annual_exports.eu_export_quantity, 0)
        / NULLIF(production.production, 0),
        2
    ) AS eu_export_share_of_production_pct
FROM production
LEFT JOIN annual_exports
    ON production.item = annual_exports.item
    AND production.year = annual_exports.year
WHERE production.item NOT IN (
    'Rapeseed or canola oil, crude',
    'Sunflower-seed oil, crude'
)
ORDER BY production.item, production.year;

-- 3. Wheat and linseed: production vs EU exports

WITH annual_exports AS (
    SELECT
        item,
        year,
        SUM(export_quantity) AS eu_export_quantity,
        SUM(export_value) AS eu_export_value
    FROM trade
    GROUP BY item, year
)
SELECT
    production.year,
    production.item,
    production.production,
    production.area_harvested,
    production.yield,
    COALESCE(annual_exports.eu_export_quantity, 0) AS eu_export_quantity,
    COALESCE(annual_exports.eu_export_value, 0) AS eu_export_value,
    ROUND(
        100.0 * COALESCE(annual_exports.eu_export_quantity, 0)
        / NULLIF(production.production, 0),
        2
    ) AS eu_export_share_of_production_pct
FROM production
LEFT JOIN annual_exports
    ON production.item = annual_exports.item
    AND production.year = annual_exports.year
WHERE production.item IN ('Wheat', 'Linseed')
ORDER BY production.item, production.year;

-- 4. Production growth vs EU export-quantity growth
-- Do production and EU export quantities move in the same direction?

WITH annual_exports AS (
    SELECT
        item,
        year,
        SUM(export_quantity) AS eu_export_quantity
    FROM trade
    GROUP BY item, year
),
combined AS (
    SELECT
        production.item,
        production.year,
        production.production,
        COALESCE(annual_exports.eu_export_quantity, 0) AS eu_export_quantity
    FROM production
    LEFT JOIN annual_exports
        ON production.item = annual_exports.item
        AND production.year = annual_exports.year
    WHERE production.item IN ('Wheat', 'Linseed')
),
changes AS (
    SELECT
        item,
        year,
        production,
        eu_export_quantity,
        LAG(production) OVER (
            PARTITION BY item
            ORDER BY year
        ) AS previous_production,
        LAG(eu_export_quantity) OVER (
            PARTITION BY item
            ORDER BY year
        ) AS previous_export_quantity
    FROM combined
)
SELECT
    item,
    year,
    ROUND(
        100.0 * (production - previous_production)
        / NULLIF(previous_production, 0),
        2
    ) AS production_change_pct,
    ROUND(
        100.0 * (eu_export_quantity - previous_export_quantity)
        / NULLIF(previous_export_quantity, 0),
        2
    ) AS eu_export_quantity_change_pct
FROM changes
ORDER BY item, year;
