-- ======================================================
-- Kazakhstan–EU Agricultural Trade
-- Trade Analysis
-- ======================================================

CREATE OR REPLACE VIEW production AS
SELECT *
FROM read_parquet('data/processed/prepared_production_data.parquet');

-- ======================================================
-- 1. PRODUCTION DEVELOPMENT BY COMMODITY
-- Question: How did domestic production changes over the years?
-- ======================================================

SELECT
    year,
    item,
    production
FROM production
ORDER BY item, year;

-- ======================================================
-- 2. WHEAT AND LINSEED PRODUCTION
-- Question: How did production of the two dominant export commodities change over the time?
-- ======================================================

SELECT
    year,
    item, 
    production,
    area_harvested,
    yield
FROM production
WHERE item IN ('Wheat','Linseed')
ORDER BY item, year;

-- ======================================================
-- 3. YEAR-OVER-YEAR PRODUCTION CHANGE
-- Question: How quickly did commodity production change each year?
-- ======================================================

WITH production_change AS (
    SELECT
        year,
        item,
        production,
        LAG(production) OVER (
            PARTITION BY item
            ORDER BY year
        ) AS previous_year_production
    FROM production
)

SELECT
    year,
    item,
    production,
    previous_year_production,
    ROUND(
        100.0 * (production - previous_year_production)
        / NULLIF(previous_year_production, 0),
        2
    ) AS production_change_percentage
FROM production_change
ORDER BY item, year;

-- ======================================================
-- 4. 2018 vs 2024 PRODUCTION
-- Question: How has domestic production changed between the beginning and end of the analysis period?
-- ======================================================

SELECT

    item,

    SUM(

        CASE WHEN year = 2018

        THEN production

        ELSE 0 END

    ) AS production_2018,

    SUM(

        CASE WHEN year = 2024

        THEN production

        ELSE 0 END

    ) AS production_2024,

    SUM(

        CASE WHEN year = 2024

        THEN production

        ELSE 0 END

    )

    -

    SUM(

        CASE WHEN year = 2018

        THEN production

        ELSE 0 END

    ) AS absolute_change

FROM production

WHERE year IN (2018, 2024)

AND item NOT IN (

    'Rapeseed or canola oil, crude',

    'Sunflower-seed oil, crude'

)

GROUP BY item

ORDER BY absolute_change DESC;