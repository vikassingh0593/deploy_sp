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
│   ├── 02_sp_clean_staging.sql         # Stored Procedure: clean old staging data
│   └── 03_sp_run_simulation.sql        # Stored Procedure: JSON-driven demand/supply simulation
├── resources/
│   ├── variables.yml                   # Bundle variables (catalog, schema, warehouse ID)
│   ├── setup_env_job.yml               # Job definition: runs the setup notebook (serverless)
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

---

## Tables

All tables are provisioned by the `code/00_setup_env.py` notebook.

| Table | Columns | Purpose |
|---|---|---|
| `orders` | `customer_id`, `amount`, `order_date` | Source table for order data |
| `daily_metrics` | `customer_id`, `total_spend` | Target table populated by `sp_calculate_metrics` |
| `staging_table` | `arrival_timestamp` | Staging table cleaned by `sp_clean_staging` |
| `product_planning` | `product_id`, `region`, `demand`, `supply`, `price`, `simulation_flag`, `last_updated` | Base table for demand/supply simulation |

---

## Stored Procedures

### `sp_calculate_metrics` — `sql/01_sp_calculate_metrics.sql`
Aggregates daily customer spending from the `orders` table and inserts results into `daily_metrics`.

```sql
CALL dev_catalog.analytics.sp_calculate_metrics('2026-08-01');
```

### `sp_clean_staging` — `sql/02_sp_clean_staging.sql`
Deletes records older than a configurable retention period (default: 30 days) from `staging_table`.

```sql
CALL dev_catalog.analytics.sp_clean_staging(30);
```

### `sp_run_simulation` — `sql/03_sp_run_simulation.sql`
Accepts a JSON payload and returns a simulated result set from the `product_planning` table. **Read-only** — does not modify any data.

**Payload format:**
```json
{
  "filters":    { "region": "APAC", "product_id": "P100" },
  "demand":     { "product_id": "P100", "demand": 500 },
  "supply":     { "product_id": "P100", "supply": 300 },
  "simulation": { "product_id": "P100", "price_change": 10 }
}
```

**Conditional logic:**
| Section | JSON Key | Skip Condition | Behaviour |
|---|---|---|---|
| Filters | `filters.region`, `filters.product_id` | Absent → no filter applied | Narrows scope of returned rows |
| Demand | `demand.product_id`, `demand.demand` | Absent or `demand = -1` | Returns overridden demand value, or original |
| Supply | `supply.product_id`, `supply.supply` | Absent or `supply = -1` | Returns overridden supply value, or original |
| Simulation | `simulation.product_id`, `simulation.price_change` | Absent or `price_change = -1` | Returns adjusted price, or original |

**Example calls:**

Full simulation:
```sql
CALL dev_catalog.analytics.sp_run_simulation('{
  "filters":    { "region": "APAC", "product_id": "P100" },
  "demand":     { "product_id": "P100", "demand": 500 },
  "supply":     { "product_id": "P100", "supply": 300 },
  "simulation": { "product_id": "P100", "price_change": 10 }
}');
```

Only adjust supply (demand and price unchanged):
```sql
CALL dev_catalog.analytics.sp_run_simulation('{
  "filters": { "region": "APAC" },
  "supply":  { "product_id": "P100", "supply": 300 }
}');
```

Return filtered data with no changes:
```sql
CALL dev_catalog.analytics.sp_run_simulation('{
  "filters": { "region": "EMEA" }
}');
```

**Output columns:** `product_id`, `region`, `demand`, `supply`, `price`, `simulation_flag`, `simulated_at`

---

## Databricks Jobs

### `setup_environment` — `resources/setup_env_job.yml`
Runs the `code/00_setup_env.py` notebook on **serverless compute** to create the catalog, schema, and all dependent tables.

### `deploy_stored_procedures` — `resources/deploy_procedures_job.yml`
Executes the SQL DDL files against a SQL Warehouse to create/update all three stored procedures in Unity Catalog. All tasks run in parallel.

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