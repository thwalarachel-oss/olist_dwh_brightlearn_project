/* ============================================================================
   Project: Olist E-Commerce Data Warehouse (SSIS Medallion)
   File: sql/02_data_quality_tests.sql
   Purpose: Automated Data Quality & Reconciliation Test Suite (10 Checks)
   ============================================================================ */

USE olist_dwh;
GO

WITH dq_results AS (

    /* ------------------------------------------------------------------------
       TEST 1: Bronze vs. Silver Order Row Reconciliation
       Ensures no orders were dropped during Silver ingestion.
       ------------------------------------------------------------------------ */
    SELECT 
        1 AS test_id,
        'dq_bronze_silver_order_reconciliation' AS test_name,
        'Bronze -> Silver' AS layer,
        ABS(
            (SELECT COUNT(*) FROM bronze.orders) - 
            (SELECT COUNT(*) FROM silver.orders)
        ) AS failed_records

    UNION ALL

    /* ------------------------------------------------------------------------
       TEST 2: Silver Orders Uniqueness
       Confirms order_id is strictly unique (1 row per order).
       ------------------------------------------------------------------------ */
    SELECT 
        2 AS test_id,
        'dq_silver_no_duplicate_orders' AS test_name,
        'Silver' AS layer,
        (SELECT COUNT(*) - COUNT(DISTINCT order_id) FROM silver.orders) AS failed_records

    UNION ALL

    /* ------------------------------------------------------------------------
       TEST 3: Silver Geolocation ZIP Prefix Deduplication
       Confirms geolocation was deduplicated to 1 canonical row per ZIP prefix.
       ------------------------------------------------------------------------ */
    SELECT 
        3 AS test_id,
        'dq_silver_unique_zip_prefixes' AS test_name,
        'Silver' AS layer,
        (
            SELECT COUNT(*) 
            FROM (
                SELECT zip_code_prefix 
                FROM silver.geolocation 
                GROUP BY zip_code_prefix 
                HAVING COUNT(*) > 1
            ) dup_zips
        ) AS failed_records

    UNION ALL

    /* ------------------------------------------------------------------------
       TEST 4: Gold Dimensions Contain -1 Unknown Member Row
       Expects 1 row with surrogate key = -1 in all 5 Gold dimensions (5 total).
       ------------------------------------------------------------------------ */
    SELECT 
        4 AS test_id,
        'dq_gold_unknown_member_exists' AS test_name,
        'Gold' AS layer,
        5 - (
            (SELECT COUNT(*) FROM gold.dim_customer WHERE customer_key = -1) +
            (SELECT COUNT(*) FROM gold.dim_product WHERE product_key = -1) +
            (SELECT COUNT(*) FROM gold.dim_seller WHERE seller_key = -1) +
            (SELECT COUNT(*) FROM gold.dim_geolocation WHERE geolocation_key = -1) +
            (SELECT COUNT(*) FROM gold.dim_date WHERE date_key = -1)
        ) AS failed_records

    UNION ALL

    /* ------------------------------------------------------------------------
       TEST 5: Zero NULL Foreign Keys Across All Gold Fact Tables
       Orphan records must resolve to -1 rather than NULL.
       ------------------------------------------------------------------------ */
    SELECT 
        5 AS test_id,
        'dq_gold_no_null_foreign_keys' AS test_name,
        'Gold' AS layer,
        (
            SELECT COUNT(*) 
            FROM gold.fact_sales 
            WHERE customer_key IS NULL 
               OR product_key IS NULL 
               OR seller_key IS NULL 
               OR order_date_key IS NULL
        ) +
        (
            SELECT COUNT(*) 
            FROM gold.fact_payments 
            WHERE customer_key IS NULL 
               OR order_date_key IS NULL
        ) +
        (
            SELECT COUNT(*) 
            FROM gold.fact_reviews 
            WHERE customer_key IS NULL 
               OR review_creation_date_key IS NULL
        ) AS failed_records

    UNION ALL

    /* ------------------------------------------------------------------------
       TEST 6: Gold fact_sales Grain Uniqueness (order_id + order_item_id)
       Confirms 1 row per order line item with zero fan-out.
       ------------------------------------------------------------------------ */
    SELECT 
        6 AS test_id,
        'dq_gold_sales_grain_uniqueness' AS test_name,
        'Gold' AS layer,
        (
            SELECT COUNT(*) 
            FROM (
                SELECT order_id, order_item_id 
                FROM gold.fact_sales 
                GROUP BY order_id, order_item_id 
                HAVING COUNT(*) > 1
            ) dup_items
        ) AS failed_records

    UNION ALL

    /* ------------------------------------------------------------------------
       TEST 7: SCD Type 2 Single Current Record per Customer
       Each customer_unique_id must have at most one active (is_current = 1) row.
       ------------------------------------------------------------------------ */
    SELECT 
        7 AS test_id,
        'dq_gold_scd2_single_current_row' AS test_name,
        'Gold' AS layer,
        (
            SELECT COUNT(*) 
            FROM (
                SELECT customer_unique_id 
                FROM gold.dim_customer 
                WHERE is_current = 1 AND customer_key <> -1
                GROUP BY customer_unique_id 
                HAVING COUNT(*) > 1
            ) multi_current
        ) AS failed_records

    UNION ALL

    /* ------------------------------------------------------------------------
       TEST 8: Non-Negative Financial Measures
       Validates price, freight_value, and payment_value are >= 0.
       ------------------------------------------------------------------------ */
    SELECT 
        8 AS test_id,
        'dq_gold_non_negative_amounts' AS test_name,
        'Gold' AS layer,
        (
            SELECT COUNT(*) 
            FROM gold.fact_sales 
            WHERE price < 0 OR freight_value < 0
        ) +
        (
            SELECT COUNT(*) 
            FROM gold.fact_payments 
            WHERE payment_value < 0
        ) AS failed_records

    UNION ALL

    /* ------------------------------------------------------------------------
       TEST 9: Valid Review Score Range (1 to 5)
       Ensures all survey ratings fall within Olist's 1-5 scale.
       ------------------------------------------------------------------------ */
    SELECT 
        9 AS test_id,
        'dq_gold_valid_review_scores' AS test_name,
        'Gold' AS layer,
        (
            SELECT COUNT(*) 
            FROM gold.fact_reviews 
            WHERE review_score NOT BETWEEN 1 AND 5 OR review_score IS NULL
        ) AS failed_records

    UNION ALL

    /* ------------------------------------------------------------------------
       TEST 10: Silver -> Gold Gross Merchandise Value (GMV) Reconciliation
       Confirms total item price in gold.fact_sales matches silver.order_items.
       ------------------------------------------------------------------------ */
    SELECT 
        10 AS test_id,
        'dq_gold_revenue_reconciliation' AS test_name,
        'Silver -> Gold' AS layer,
        CASE 
            WHEN ABS(
                ISNULL((SELECT SUM(CAST(price AS DECIMAL(18,2))) FROM silver.order_items), 0) -
                ISNULL((SELECT SUM(CAST(price AS DECIMAL(18,2))) FROM gold.fact_sales), 0)
            ) < 0.01 THEN 0
            ELSE 1
        END AS failed_records
)
SELECT 
    test_id,
    test_name,
    layer,
    failed_records,
    CASE WHEN failed_records = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM dq_results
ORDER BY test_id;
GO
