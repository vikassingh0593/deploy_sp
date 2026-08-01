-- sql/00_setup_env.sql
-- Script to create the required catalog and schema in Unity Catalog.
-- This script should typically be executed by an admin with the `CREATE CATALOG` privilege.

CREATE CATALOG IF NOT EXISTS ${catalog};

-- Switch to the new catalog context
USE CATALOG ${catalog};

CREATE SCHEMA IF NOT EXISTS ${catalog}.${schema};

-- Optionally, define the schema ownership or grant permissions here
-- GRANT USE CATALOG ON CATALOG ${catalog} TO `data-engineers`;
-- GRANT USE SCHEMA, CREATE TABLE, CREATE ROUTINE ON SCHEMA ${catalog}.${schema} TO `data-engineers`;
