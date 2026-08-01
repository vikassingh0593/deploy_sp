# Databricks notebook source

# COMMAND ----------

# MAGIC %md
# MAGIC # Environment Setup
# MAGIC Creates the required catalog, schema, and all dependent tables.
# MAGIC This notebook is self-sufficient and should be run before any stored procedures.

# COMMAND ----------

# MAGIC %sql
# MAGIC -- 1. Create catalog
# MAGIC CREATE CATALOG IF NOT EXISTS dev_catalog;

# COMMAND ----------

# MAGIC %sql
# MAGIC -- 2. Create schema
# MAGIC CREATE SCHEMA IF NOT EXISTS dev_catalog.analytics;

# COMMAND ----------

# MAGIC %sql
# MAGIC -- 3. Create source table: orders
# MAGIC CREATE TABLE IF NOT EXISTS dev_catalog.analytics.orders (
# MAGIC   customer_id STRING NOT NULL,
# MAGIC   amount DECIMAL(18, 2) NOT NULL,
# MAGIC   order_date DATE NOT NULL
# MAGIC )
# MAGIC USING DELTA
# MAGIC COMMENT 'Source table containing customer order records';

# COMMAND ----------

# MAGIC %sql
# MAGIC -- 4. Create target table: daily_metrics (populated by sp_calculate_metrics)
# MAGIC CREATE TABLE IF NOT EXISTS dev_catalog.analytics.daily_metrics (
# MAGIC   customer_id STRING NOT NULL,
# MAGIC   total_spend DECIMAL(18, 2) NOT NULL
# MAGIC )
# MAGIC USING DELTA
# MAGIC COMMENT 'Aggregated daily metrics per customer, populated by sp_calculate_metrics';

# COMMAND ----------

# MAGIC %sql
# MAGIC -- 5. Create staging table (cleaned by sp_clean_staging)
# MAGIC CREATE TABLE IF NOT EXISTS dev_catalog.analytics.staging_table (
# MAGIC   arrival_timestamp TIMESTAMP NOT NULL
# MAGIC )
# MAGIC USING DELTA
# MAGIC COMMENT 'Staging table for incoming data, cleaned by sp_clean_staging';
