-- Kazakhstan Agricultural Production: Data Exploration

CREATE OR REPLACE VIEW production AS
SELECT *
FROM read_parquet('data/processed/prepared_production_data.parquet');

-- 1. Time coverage
-- What period does the dataset cover?

SELECT
    MIN(year) AS first_year,
    MAX(year) AS last_year,
    COUNT(DISTINCT year) AS number_of_years
FROM production;

-- 2. Dataset size

SELECT
    COUNT(*) AS number_of_rows
FROM production;

-- 3. Commodity coverage
-- Which commodities are included?

SELECT
    COUNT(DISTINCT item) AS number_of_commodities
FROM production;

SELECT DISTINCT
    item
FROM production
ORDER BY item;

-- 4. Observations by commodity

SELECT
    item,
    COUNT(*) AS number_of_observations,
    MIN(year) AS first_year,
    MAX(year) AS last_year
FROM production
GROUP BY item
ORDER BY item;

-- 5. Missing values
-- Which analytical measures contain missing observations?

SELECT
    SUM(
        CASE WHEN production IS NULL THEN 1 ELSE 0 END
    ) AS missing_production,
    SUM(
        CASE WHEN area_harvested IS NULL THEN 1 ELSE 0 END
    ) AS missing_area_harvested,
    SUM(
        CASE WHEN yield IS NULL THEN 1 ELSE 0 END
    ) AS missing_yield
FROM production;

-- 6. Missing area and yield values by commodity

SELECT
    item,
    COUNT(*) AS observations,
    SUM(
        CASE WHEN area_harvested IS NULL THEN 1 ELSE 0 END
    ) AS missing_area_harvested,
    SUM(
        CASE WHEN yield IS NULL THEN 1 ELSE 0 END
    ) AS missing_yield
FROM production
GROUP BY item
ORDER BY item;

-- 7. Duplicate observations
-- Is each commodity-year combination unique?

SELECT
    item,
    year,
    COUNT(*) AS row_count
FROM production
GROUP BY item, year
HAVING COUNT(*) > 1;

-- 8. Descriptive statistics

SELECT
    MIN(production) AS min_production,
    MAX(production) AS max_production,
    AVG(production) AS avg_production,
    MIN(area_harvested) AS min_area_harvested,
    MAX(area_harvested) AS max_area_harvested,
    AVG(area_harvested) AS avg_area_harvested,
    MIN(yield) AS min_yield,
    MAX(yield) AS max_yield,
    AVG(yield) AS avg_yield
FROM production;

-- 9. Sample observations

SELECT
    item,
    year,
    production,
    area_harvested,
    yield
FROM production
ORDER BY item, year
LIMIT 15;
