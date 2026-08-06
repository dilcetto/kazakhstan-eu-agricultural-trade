-- Kazakhstan–EU Agricultural Trade: Data Exploration

CREATE OR REPLACE VIEW trade AS
SELECT *
FROM read_parquet('data/processed/prepared_trade_data.parquet');

-- 1. Time coverage
-- What period does the dataset cover?

SELECT
    MIN(year) AS first_year,
    MAX(year) AS last_year,
    COUNT(DISTINCT year) AS number_of_years
FROM trade;

-- 2. Commodity coverage
-- How many agricultural commodities are included?

SELECT
    COUNT(DISTINCT item) AS number_of_commodities
FROM trade;

SELECT DISTINCT
    item
FROM trade
ORDER BY item;

-- 3. EU trading partners
-- How many EU partner countries are represented?

SELECT
    COUNT(DISTINCT partner_countries) AS number_of_partners
FROM trade;

SELECT DISTINCT
    partner_countries
FROM trade
ORDER BY partner_countries;

-- 4. Missing values
-- Do the analytical measures contain missing values?

SELECT
    SUM(
        CASE WHEN export_quantity IS NULL THEN 1 ELSE 0 END
    ) AS missing_export_quantity,
    SUM(
        CASE WHEN export_value IS NULL THEN 1 ELSE 0 END
    ) AS missing_export_value
FROM trade;

-- 5. Duplicate observations
-- Is each partner-commodity-year combination unique?

SELECT
    partner_countries,
    item,
    year,
    COUNT(*) AS row_count
FROM trade
GROUP BY partner_countries, item, year
HAVING COUNT(*) > 1;

-- 6. Descriptive statistics
-- What are the ranges of export quantity and value?

SELECT
    MIN(export_quantity) AS min_export_quantity,
    MAX(export_quantity) AS max_export_quantity,
    AVG(export_quantity) AS avg_export_quantity,
    MIN(export_value) AS min_export_value,
    MAX(export_value) AS max_export_value,
    AVG(export_value) AS avg_export_value
FROM trade;

-- 7. Sample observations

SELECT
    partner_countries,
    item,
    year,
    export_quantity,
    export_value
FROM trade
ORDER BY year, partner_countries, item
LIMIT 10;
