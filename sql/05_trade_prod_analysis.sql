-- ======================================================
-- Kazakhstan–EU Agricultural Trade
-- Trade and Production Analysis
-- ======================================================


CREATE OR REPLACE VIEW trade AS
SELECT *
FROM read_parquet('data/processed/prepared_trade_data.parquet');

CREATE OR REPLACE VIEW production AS
SELECT *
FROM read_parquet('data/processed/prepared_production_data.parquet');


-- ======================================================
-- 1. JOIN PRODUCTION WITH EU EXPORTS
-- Question: How do domestic production and EU exports
-- compare for each commodity and year?
-- ======================================================

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
    p.item,
    p.year,
    p.production,
    p.area_harvested,
    p.yield,
    e.eu_export_quantity,
    e.eu_export_value
FROM production AS p

LEFT JOIN annual_exports AS e
    ON p.item = e.item
    AND p.year = e.year

ORDER BY p.item, p.year;

-- ======================================================
-- 2. EU EXPORT QUANTITY AS SHARE OF PRODUCTION
-- Question: What share of Kazakhstan's domestic production 
-- was represented by exports to observed EU partner markets?
-- ======================================================

WITH annual_exports AS (
    SELECT
        item,
        year,
        SUM(export_quantity) AS eu_export_quantity
    FROM trade
    GROUP BY item, year
)

SELECT
    p.item,
    p.year,
    p.production,
    COALESCE(e.eu_export_quantity, 0) AS eu_export_quantity,

    ROUND(
        100.0 * COALESCE(e.eu_export_quantity, 0)
        / NULLIF(p.production, 0),
        2
    ) AS eu_export_share_of_production_pct

FROM production AS p

LEFT JOIN annual_exports AS e
    ON p.item = e.item
    AND p.year = e.year

WHERE p.item NOT IN (
    'Rapeseed or canola oil, crude',
    'Sunflower-seed oil, crude'
)

ORDER BY p.item, p.year;

-- ======================================================
-- 3. WHEAT AND LINSEED: PRODUCTION VS EU EXPORTS
-- ======================================================

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
    p.year,
    p.item,
    p.production,
    p.area_harvested,
    p.yield,
    COALESCE(e.eu_export_quantity, 0) AS eu_export_quantity,
    COALESCE(e.eu_export_value, 0) AS eu_export_value,

    ROUND(
        100.0 * COALESCE(e.eu_export_quantity, 0)
        / NULLIF(p.production, 0),
        2
    ) AS eu_export_share_of_production_pct

FROM production AS p

LEFT JOIN annual_exports AS e
    ON p.item = e.item
    AND p.year = e.year

WHERE p.item IN ('Wheat', 'Linseed')

ORDER BY p.item, p.year;

-- ======================================================
-- 4. PRODUCTION GROWTH VS EU EXPORT-QUANTITY GROWTH
-- Question: Do production and EU export quantities generally
-- move in the same direction?
-- ======================================================

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
        p.item,
        p.year,
        p.production,
        COALESCE(e.eu_export_quantity, 0) AS eu_export_quantity
    FROM production AS p

    LEFT JOIN annual_exports AS e
        ON p.item = e.item
        AND p.year = e.year

    WHERE p.item IN ('Wheat', 'Linseed')
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