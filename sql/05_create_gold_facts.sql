/* ============================================================================
   Script: 05_create_gold_facts.sql
   Purpose: Create Gold fact views resolving natural keys to dimension
            surrogate keys with fallback to -1 (Unknown).
   Declared Grains:
     - gold.fact_order_items: 1 row per order + order_item_id
     - gold.fact_order_payments: 1 row per order + payment_sequential
     - gold.fact_order_reviews: 1 row per review + order_id
   ============================================================================ */

USE olist_dwh;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'gold')
BEGIN
    EXEC('CREATE SCHEMA gold');
END
GO

-- Clean up any prior table or view versions
DROP TABLE IF EXISTS gold.fact_order_items;
DROP TABLE IF EXISTS gold.fact_order_payments;
DROP TABLE IF EXISTS gold.fact_order_reviews;

DROP VIEW IF EXISTS gold.fact_order_items;
DROP VIEW IF EXISTS gold.fact_order_payments;
DROP VIEW IF EXISTS gold.fact_order_reviews;
GO

-- Fact: Order Items (resolving product_sk and seller_sk)
CREATE OR ALTER VIEW gold.fact_order_items
AS
SELECT
    f.*,
    COALESCE(dp.product_sk, -1) AS product_sk,
    COALESCE(ds.seller_sk, -1) AS seller_sk
FROM silver.fact_order_items f
LEFT JOIN gold.dim_products dp
    ON f.product_id = dp.product_id
   AND dp.product_sk <> -1
LEFT JOIN gold.dim_sellers ds
    ON f.seller_id = ds.seller_id
   AND ds.seller_sk <> -1;
GO

-- Fact: Order Payments
CREATE OR ALTER VIEW gold.fact_order_payments
AS
SELECT
    f.*
FROM silver.fact_order_payments f;
GO

-- Fact: Order Reviews
CREATE OR ALTER VIEW gold.fact_order_reviews
AS
SELECT
    f.*
FROM silver.fact_order_reviews f;
GO
