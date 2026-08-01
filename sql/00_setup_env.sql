-- Setup script: Create the required catalog, schema, and all dependent tables.
-- This script is self-sufficient and should be run before any stored procedures.

-- 1. Create catalog and schema
CREATE CATALOG IF NOT EXISTS dev_catalog;
CREATE SCHEMA IF NOT EXISTS dev_catalog.analytics;

-- 2. Create source table: orders
CREATE TABLE IF NOT EXISTS dev_catalog.analytics.orders (
  customer_id STRING NOT NULL,
  amount DECIMAL(18, 2) NOT NULL,
  order_date DATE NOT NULL
)
USING DELTA
COMMENT 'Source table containing customer order records';

-- 3. Create target table: daily_metrics (populated by sp_calculate_metrics)
CREATE TABLE IF NOT EXISTS dev_catalog.analytics.daily_metrics (
  customer_id STRING NOT NULL,
  total_spend DECIMAL(18, 2) NOT NULL
)
USING DELTA
COMMENT 'Aggregated daily metrics per customer, populated by sp_calculate_metrics';

-- 4. Create staging table (cleaned by sp_clean_staging)
CREATE TABLE IF NOT EXISTS dev_catalog.analytics.staging_table (
  arrival_timestamp TIMESTAMP NOT NULL
)
USING DELTA
COMMENT 'Staging table for incoming data, cleaned by sp_clean_staging';
