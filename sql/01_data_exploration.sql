-- ======================================================
-- Kazakhstan–EU Agricultural Trade
-- Data Exploration
-- ======================================================

-- Load datasets 
-- Dataset dimensions
-- Time coverage
-- Commodities
-- Trading partners
-- Missing values
-- Duplicate checks
-- Descriptive statistics
-- Preview data

CREATE OR REPLACE VIEW trade AS
SELECT *
FROM read_parquet('data/processed/prepared_trade_data.parquet');

-- =======================================================
-- 1. TIME COVERAGE
-- Question: What period does the dataset cover?
-- =======================================================

SELECT
    MIN(year) AS first_year,
    MAX(year) AS last_year,
    COUNT(DISTINCT year) AS number_of_years
FROM trade;

-- =======================================================
-- 2. COMMODITY COVERAGE
-- Question: How many agricultural commodities are included in the dataset?
-- =======================================================

SELECT
    COUNT(DISTINCT item) AS number_of_commodities
FROM trade;

-- List of commodities

SELECT DISTINCT item
FROM trade
ORDER BY item;

-- =======================================================
-- 3. EU TRADING PARTNERS
-- Question: How many EU countries are present in the dataset?
-- =======================================================

SELECT
    COUNT(DISTINCT partner_countries) AS number_of_partners
FROM trade;

-- List of EU trading partners

SELECT DISTINCT partner_countries
FROM trade
ORDER BY partner_countries;

-- =======================================================
-- 4. MISSING VALUES
-- Question: Are there any missing values in the dataset?
-- =======================================================

SELECT
    SUM(CASE WHEN export_quantity IS NULL THEN 1 ELSE 0 END) AS missing_export_quantity,
    SUM(CASE WHEN export_value IS NULL THEN 1 ELSE 0 END) AS missing_export_value
FROM trade;

-- =======================================================
-- 5. DUPLICATE CHECKS
-- Question: Does more than one row exist for the same
-- partner + commodity + year combination?
-- =======================================================

SELECT
    partner_countries,
    item,
    year,
    COUNT(*) AS row_count
FROM trade
GROUP BY partner_countries, item, year
HAVING COUNT(*) > 1;

-- =======================================================
-- 6. DESCRIPTIVE STATISTICS
-- Question: What are the basic ranges of trade values?
-- =======================================================

SELECT
    MIN(export_quantity) AS min_export_quantity,
    MAX(export_quantity) AS max_export_quantity,
    AVG(export_quantity) AS avg_export_quantity,
    MIN(export_value) AS min_export_value,
    MAX(export_value) AS max_export_value,
    AVG(export_value) AS avg_export_value
FROM trade;

-- =======================================================
-- 7. PREVIEW DATA
-- Question: What does the dataset look like?
-- =======================================================

SELECT
    partner_countries,
    item,
    year,
    export_quantity,
    export_value
FROM trade
ORDER BY year, partner_countries, item
LIMIT 10;

