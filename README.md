# deploy_sp — Databricks Asset Bundle for SQL Stored Procedures

Automated deployment of Unity Catalog SQL stored procedures using [Databricks Asset Bundles (DABs)](https://docs.databricks.com/en/dev-tools/bundles/index.html) and GitHub Actions CI/CD.

---

## Project Structure

```
deploy_sp/
├── .github/
│   └── workflows/
│       └── deploy_main.yml             # GitHub Actions CI/CD pipeline
├── code/
│   └── 00_setup_env.py                 # Notebook: creates catalog, schema & tables (serverless)
├── sql/
│   ├── 01_sp_calculate_metrics.sql     # Stored Procedure: aggregate daily metrics
│   └── 02_sp_clean_staging.sql         # Stored Procedure: clean old staging data
├── resources/
│   ├── variables.yml                   # Bundle variables (catalog, schema, warehouse ID)
│   ├── setup_env_job.yml               # Job definition: runs the setup notebook
│   └── deploy_procedures_job.yml       # Job definition: deploys stored procedures via SQL warehouse
├── databricks.yml                      # Root DABs configuration
└── README.md
```

---

## Components

### `databricks.yml`
Root bundle configuration. Defines the bundle name (`data_modeling`), includes all resource YAML files, and configures the `dev` deployment target pointing to:
- **Workspace:** `https://dbc-2e4d9781-997b.cloud.databricks.com`
- **Deployment Path:** `/Workspace/Users/vikassingh0593@gmail.com/git_deploy_dev`

### `resources/variables.yml`
Centralised variable definitions used across all jobs:
| Variable | Description |
|---|---|
| `catalog` | Unity Catalog name (default: `dev_catalog`) |
| `schema` | Schema name (default: `analytics`) |
| `sql_warehouse_id` | Databricks SQL Warehouse ID for executing SQL tasks |

### `code/00_setup_env.py`
A Databricks notebook (runs on **serverless compute**) that provisions the environment:
- Creates `dev_catalog` catalog
- Creates `dev_catalog.analytics` schema
- Creates the following tables:

| Table | Purpose |
|---|---|
| `orders` | Source table with `customer_id`, `amount`, `order_date` |
| `daily_metrics` | Target table populated by `sp_calculate_metrics` |
| `staging_table` | Staging table cleaned by `sp_clean_staging` |

### `sql/01_sp_calculate_metrics.sql`
Stored procedure that aggregates daily customer spending from the `orders` table and inserts results into `daily_metrics`.

### `sql/02_sp_clean_staging.sql`
Stored procedure that deletes records older than a configurable retention period (default: 30 days) from `staging_table`.

### `resources/setup_env_job.yml`
Databricks Job definition that runs the `00_setup_env.py` notebook on serverless compute to create all required infrastructure.

### `resources/deploy_procedures_job.yml`
Databricks Job definition with two SQL tasks that execute the stored procedure DDL files against a SQL Warehouse to create/update the procedures in Unity Catalog.

---

## CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/deploy_main.yml`) automates deployment.

### Trigger
- Runs **only** when a Pull Request is **merged** into the `main` branch.
- Pushes to `dev` or other branches do **not** trigger a deployment.

### Pipeline Steps
1. **Checkout** — Pulls the latest code from the repository.
2. **Setup Databricks CLI** — Installs the Databricks CLI on the runner.
3. **Validate** — Runs `databricks bundle validate -t dev` to check for configuration errors.
4. **Deploy** — Runs `databricks bundle deploy -t dev` to sync all files and job definitions to the workspace.
5. **Execute** — Runs `databricks bundle run deploy_stored_procedures -t dev` to execute the DDL and create/update the stored procedures.

### Authentication
The pipeline authenticates using a **Databricks Service Principal** via OAuth (M2M):
- `DATABRICKS_CLIENT_ID` — Service Principal Application ID
- `DATABRICKS_CLIENT_SECRET` — Service Principal OAuth Secret

Both are stored as **GitHub Repository Secrets**.

---

## Getting Started

### Prerequisites
- [Databricks CLI](https://docs.databricks.com/en/dev-tools/cli/install.html) installed locally
- A Databricks Service Principal with:
  - Workspace access and permissions to the deployment folder
  - `USE CATALOG`, `USE SCHEMA`, `CREATE FUNCTION`, `SELECT`, `MODIFY` grants on `dev_catalog.analytics`
  - `CAN USE` permission on the SQL Warehouse

### Local Development

```bash
# Authenticate with your Databricks workspace
databricks auth login --host https://dbc-2e4d9781-997b.cloud.databricks.com

# Validate the bundle configuration
databricks bundle validate -t dev

# Deploy bundle to the workspace
databricks bundle deploy -t dev

# Run the setup notebook to create catalog, schema, and tables
databricks bundle run setup_environment -t dev

# Run the stored procedure deployment job
databricks bundle run deploy_stored_procedures -t dev
```

### Deployment via CI/CD

1. Create a feature branch from `dev` and make your changes.
2. Push your changes to the `dev` branch.
3. Open a **Pull Request** from `dev` → `main`.
4. Once the PR is **merged**, the GitHub Action automatically deploys and applies the stored procedures.

---

## Git Branching Strategy

| Branch | Purpose |
|---|---|
| `dev` | Active development. Push all changes here first. |
| `main` | Protected branch. Merging a PR triggers automated deployment. |

> **Note:** Direct pushes to `main` are blocked via GitHub Branch Protection Rules. All changes must go through a Pull Request.