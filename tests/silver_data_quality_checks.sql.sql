/* ============================================================================
   Script: tests/data_quality_checks.sql
   Purpose: 10 automated data quality tests across Bronze, Silver, and Gold
            layers for olist_dwh. Every query returns failing_rows (0 = PASS).
   ============================================================================ */

USE olist_dwh;
GO

-- 1. [BRONZE] Non-empty ingestion across core raw order/item tables
SELECT
    'DQ_01_bronze_non_empty' AS test_name,
    'bronze' AS layer_name,
    CASE
        WHEN (SELECT COUNT(*) FROM bronze.orders) = 0
          OR (SELECT COUNT(*) FROM bronze.order_items) = 0
        THEN 1 ELSE 0
    END AS failing_rows;

-- 2. [SILVER] Business grain uniqueness on silver.fact_order_items
SELECT
    'DQ_02_silver_order_items_grain_unique' AS test_name,
    'silver' AS layer_name,
    COUNT(*) AS failing_rows
FROM (
    SELECT order_id, order_item_id
    FROM silver.fact_order_items
    GROUP BY order_id, order_item_id
    HAVING COUNT(*) > 1
) d;

-- 3. [SILVER] No null business keys in silver.fact_order_items
SELECT
    'DQ_03_silver_no_null_order_item_keys' AS test_name,
    'silver' AS layer_name,
    COUNT(*) AS failing_rows
FROM silver.fact_order_items
WHERE order_id IS NULL
   OR order_item_id IS NULL
   OR product_id IS NULL
   OR seller_id IS NULL;

-- 4. [GOLD] All Gold dimensions contain the -1 Unknown member row
SELECT
    'DQ_04_gold_unknown_member_exists' AS test_name,
    'gold' AS layer_name,
    (
        CASE WHEN NOT EXISTS (SELECT 1 FROM gold.dim_customers WHERE customer_sk = -1) THEN 1 ELSE 0 END +
        CASE WHEN NOT EXISTS (SELECT 1 FROM gold.dim_products WHERE product_sk = -1) THEN 1 ELSE 0 END +
        CASE WHEN NOT EXISTS (SELECT 1 FROM gold.dim_sellers WHERE seller_sk = -1) THEN 1 ELSE 0 END +
        CASE WHEN NOT EXISTS (SELECT 1 FROM gold.dim_geolocation WHERE geolocation_sk = -1) THEN 1 ELSE 0 END
    ) AS failing_rows;

-- 5. [GOLD] At most one active/current record (is_current = 1) per customer (SCD Type 2)
SELECT
    'DQ_05_gold_dim_customers_single_current_row' AS test_name,
    'gold' AS layer_name,
    COUNT(*) AS failing_rows
FROM (
    SELECT customer_id
    FROM gold.dim_customers
    WHERE customer_sk <> -1
      AND is_current = 1
    GROUP BY customer_id
    HAVING COUNT(*) > 1
) c;

-- 6. [GOLD] Valid SCD Type 2 effective date ranges (valid_from <= valid_to when valid_to is present)
SELECT
    'DQ_06_gold_dim_customers_valid_date_range' AS test_name,
    'gold' AS layer_name,
    COUNT(*) AS failing_rows
FROM gold.dim_customers
WHERE customer_sk <> -1
  AND valid_to IS NOT NULL
  AND valid_from > valid_to;

-- 7. [GOLD] Zero orphan product_sk references in gold.fact_order_items
SELECT
    'DQ_07_gold_orphan_product_sk' AS test_name,
    'gold' AS layer_name,
    COUNT(*) AS failing_rows
FROM gold.fact_order_items f
LEFT JOIN gold.dim_products p
    ON f.product_sk = p.product_sk
WHERE f.product_sk IS NULL
   OR p.product_sk IS NULL;

-- 8. [GOLD] Zero orphan seller_sk references in gold.fact_order_items
SELECT
    'DQ_08_gold_orphan_seller_sk' AS test_name,
    'gold' AS layer_name,
    COUNT(*) AS failing_rows
FROM gold.fact_order_items f
LEFT JOIN gold.dim_sellers s
    ON f.seller_sk = s.seller_sk
WHERE f.seller_sk IS NULL
   OR s.seller_sk IS NULL;

-- 9. [GOLD] Non-negative monetary amounts (price, freight_value, payment_value)
SELECT
    'DQ_09_gold_non_negative_amounts' AS test_name,
    'gold' AS layer_name,
    (
        SELECT COUNT(*)
        FROM gold.fact_order_items
        WHERE price < 0 OR freight_value < 0
    ) + (
        SELECT COUNT(*)
        FROM gold.fact_order_payments
        WHERE payment_value < 0
    ) AS failing_rows;

-- 10. [GOLD] Valid review score range (1 to 5) and Silver-to-Gold item row reconciliation
SELECT
    'DQ_10_gold_review_score_and_row_reconciliation' AS test_name,
    'gold' AS layer_name,
    (
        SELECT COUNT(*)
        FROM gold.fact_order_reviews
        WHERE review_score < 1 OR review_score > 5
    ) + ABS(
        (SELECT COUNT(*) FROM silver.fact_order_items) -
        (SELECT COUNT(*) FROM gold.fact_order_items)
    ) AS failing_rows;
GO
