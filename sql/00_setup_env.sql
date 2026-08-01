-- sql/00_setup_env.sql
-- Script to create the required catalog and schema in Unity Catalog.
-- This script should typically be executed by an admin with the `CREATE CATALOG` privilege.

CREATE CATALOG IF NOT EXISTS dev_catalog;

-- Switch to the new catalog context
USE CATALOG dev_catalog;

CREATE SCHEMA IF NOT EXISTS dev_catalog.analytics;

-- Optionally, define the schema ownership or grant permissions here
-- GRANT USE CATALOG ON CATALOG dev_catalog TO `data-engineers`;
-- GRANT USE SCHEMA, CREATE TABLE, CREATE ROUTINE ON SCHEMA dev_catalog.analytics TO `data-engineers`;
