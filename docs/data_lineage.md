# Data Lineage — Olist E-Commerce Data Warehouse (`olist_dwh`)

## End-to-End Pipeline Flow
1. **Source (`data/raw/`):** Nine raw CSV files from the Kaggle Olist dataset (`olist_customers_dataset.csv`, `olist_geolocation_dataset.csv`, `olist_order_items_dataset.csv`, `olist_order_payments_dataset.csv`, `olist_order_reviews_dataset.csv`, `olist_orders_dataset.csv`, `olist_products_dataset.csv`, `olist_sellers_dataset.csv`, and `product_category_name_translation.csv`).
2. **Orchestration (`ssis/olist_dwh/00_master.dtsx`):** Coordinates execution across the warehouse stages using parameterized connection managers and project parameters (`ServerName`, `DataBaseName`).
3. **Bronze Load (`ssis/olist_dwh/01_bronze_load.dtsx`):** Reads raw CSV files via Flat File connection managers and loads raw data into the `bronze` schema tables.
4. **Silver Transform (`ssis/olist_dwh/02_silver_transform.dtsx`):** Cleans, casts, standardizes, and enriches records (including mapping Portuguese product categories to English via `product_category_name_translation`) into `silver` schema tables, validated by quality checks in `tests/data_quality_checks.sql`.
5. **Gold Dimensions & Facts (`03_gold_dimensions.dtsx` & `04_gold_facts.dtsx`):** Builds curated dimension and fact structures in the `gold` schema for reporting and analytics.
6. **Consumption (`sql/` & Power BI):** Queried by SQL analytics scripts and visualized in Power BI Desktop (`OLIST PROJECT FINAL REPORT.pbix`).

## Source-to-Target Lineage Matrix

| Source CSV (`data/raw/`) | Bronze Target (`bronze.*`) | Silver Target (`silver.*`) | Gold Target (`gold.*`) | SSIS & SQL Touchpoints |
| :--- | :--- | :--- | :--- | :--- |
| `olist_orders_dataset.csv` | `bronze.orders` | `silver.orders` | `gold.fact_orders` | `01_bronze_load.dtsx`, `02_silver_transform.dtsx`, `04_gold_facts.dtsx` |
| `olist_order_items_dataset.csv` | `bronze.order_items` | `silver.order_items` | `gold.fact_order_items` / `gold.fact_orders` | `01_bronze_load.dtsx`, `02_silver_transform.dtsx`, `04_gold_facts.dtsx` |
| `olist_order_payments_dataset.csv` | `bronze.order_payments` | `silver.order_payments` | Payment metrics / `gold.fact_orders` | `01_bronze_load.dtsx`, `02_silver_transform.dtsx`, `04_gold_facts.dtsx` |
| `olist_order_reviews_dataset.csv` | `bronze.order_reviews` | `silver.order_reviews` | Review metrics / `gold.fact_orders` | `01_bronze_load.dtsx`, `02_silver_transform.dtsx` |
| `olist_customers_dataset.csv` | `bronze.customers` | `silver.customers` | `gold.dim_customers` | `01_bronze_load.dtsx`, `02_silver_transform.dtsx`, `03_gold_dimensions.dtsx` |
| `olist_products_dataset.csv` + `product_category_name_translation.csv` | `bronze.products`, `bronze.product_category_name_translation` | `silver.products` (with English category) | `gold.dim_products` | `01_bronze_load.dtsx`, `02_silver_transform.dtsx`, `03_gold_dimensions.dtsx` |
| `olist_sellers_dataset.csv` | `bronze.sellers` | `silver.sellers` | `gold.dim_sellers` | `01_bronze_load.dtsx`, `02_silver_transform.dtsx`, `03_gold_dimensions.dtsx` |
| `olist_geolocation_dataset.csv` | `bronze.geolocation` | `silver.geolocation` | Location reference / dimension enrichment | `01_bronze_load.dtsx`, `02_silver_transform.dtsx`, `03_gold_dimensions.dtsx` |

## Quality Gates & Governance
* **Data Quality Checks:** Executed against `silver` tables using `tests/data_quality_checks.sql` (checking nulls, duplicates, referential integrity, and valid ranges/statuses) prior to or alongside Gold layer loading.
* **Configuration Management:** Database server and catalog targets are parameterized in `Project.params` and bound to connection managers inside `ssis/olist_dwh/`.