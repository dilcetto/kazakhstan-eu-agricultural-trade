-- ======================================================
-- Kazakhstan Agricultural Production
-- Data Exploration
-- ======================================================

CREATE OR REPLACE VIEW production AS
SELECT *
FROM read_parquet('data/processed/prepared_production_data.parquet');

-- =======================================================
-- 1. TIME COVERAGE
-- Question: What period does the dataset cover?
-- =======================================================

SELECT
    MIN(year) AS first_year,
    MAX(year) AS last_year,
    COUNT(DISTINCT year) AS number_of_years
FROM production;

-- =======================================================
-- 2. DATASET SIZE
-- Question: How many rows are in the dataset?
-- =======================================================

SELECT
    COUNT(*) AS number_of_rows
FROM production;

-- =======================================================
-- 3. COMMODITY COVERAGE
-- Question: Which commodities are included in the dataset?
-- =======================================================

SELECT
    COUNT(DISTINCT item) AS number_of_commodities
FROM production;

SELECT DISTINCT
    item
FROM production
ORDER BY item;

-- =======================================================
-- 4. OBSERVATIONS BY COMMODITY
-- Question: How many annual observations exist for each commodity?
-- =======================================================

SELECT
    item, 
    COUNT(*) AS number_of_observations,
    MIN(year) AS first_year,
    MAX(year) AS last_year
FROM production
GROUP BY item
ORDER BY item;

-- =======================================================
-- 5. MISSING VALUES
-- Question: Which analytical variables contain missing observations?
-- =======================================================

SELECT
    SUM(CASE WHEN production IS NULL THEN 1 ELSE 0 END) AS missing_production,
    SUM(CASE WHEN area_harvested IS NULL THEN 1 ELSE 0 END) AS missing_area_harvested, 
    SUM(CASE WHEN yield IS NULL THEN 1 ELSE 0 END) AS missing_yield
FROM production;

-- =======================================================
-- 6. LOCATE MISSING AREA/ YIELD VALUES
-- Question: Which commodities account for the missing area harvested and yield observations?
-- =======================================================

SELECT
    item,
    COUNT(*) AS observations,
    SUM(CASE WHEN area_harvested IS NULL THEN 1 ELSE 0 END) AS missing_area_harvested,
    SUM(CASE WHEN yield IS NULL THEN 1 ELSE 0 END) AS missing_yield
FROM production
GROUP BY item
ORDER BY item;

-- =======================================================
-- 7. DUPLICATE OBSERVATIONS
-- Question: Is there more than one observation for the same commodity and year?
-- =======================================================

SELECT
    item,
    year,
    COUNT(*) AS row_count
FROM production
GROUP BY item, year
HAVING COUNT(*) > 1;

-- =======================================================
-- 8. BASIC DESCRIPTIVE STATISTICS
-- =======================================================

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

-- =======================================================
-- 9. SAMPLE OBSERVATIONS
-- =======================================================

SELECT
    item, 
    year,
    production, 
    area_harvested,
    yield
FROM production
ORDER BY item, year
LIMIT 15;
