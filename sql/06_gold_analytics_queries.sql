USE olist_dwh;
GO

-- Ensure the gold schema exists
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'gold')
BEGIN
    EXEC('CREATE SCHEMA gold;')
END
GO

-- ==========================================
-- 1. GOLD: ORDER ITEM DETAILS VIEW
-- ==========================================
DROP VIEW IF EXISTS gold.vw_order_item_details;
GO

CREATE VIEW gold.vw_order_item_details AS
SELECT 
    o.order_id,
    o.customer_id,
    c.customer_city,
    c.customer_state,
    o.order_status,
    o.order_purchase_timestamp,
    i.order_item_id,
    i.product_id,
    p.product_category_name_en,
    i.seller_id,
    TRY_CAST(i.price AS DECIMAL(10,2)) AS price,
    TRY_CAST(i.freight_value AS DECIMAL(10,2)) AS freight_value,
    TRY_CAST((i.price + i.freight_value) AS DECIMAL(10,2)) AS total_item_value
FROM silver.fact_orders o
JOIN silver.fact_order_items i 
    ON o.order_id = i.order_id
LEFT JOIN silver.dim_customers c 
    ON o.customer_id = c.customer_id
LEFT JOIN silver.dim_products p 
    ON i.product_id = p.product_id;
GO


-- ==========================================
-- 2. GOLD: ORDER PAYMENTS SUMMARY VIEW
-- ==========================================
DROP VIEW IF EXISTS gold.vw_order_payments_summary;
GO

CREATE VIEW gold.vw_order_payments_summary AS
SELECT 
    order_id,
    COUNT(DISTINCT payment_type) AS payment_type_count,
    SUM(TRY_CAST(payment_installments AS INT)) AS total_installments,
    SUM(TRY_CAST(payment_value AS DECIMAL(10,2))) AS total_payment_value
FROM silver.fact_order_payments
GROUP BY order_id;
GO


-- ==========================================
-- 3. GOLD: ORDER REVIEWS SUMMARY VIEW
-- ==========================================
DROP VIEW IF EXISTS gold.vw_order_reviews_summary;
GO

CREATE VIEW gold.vw_order_reviews_summary AS
SELECT 
    order_id,
    review_id,
    TRY_CAST(review_score AS INT) AS review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date
FROM silver.fact_order_reviews;
GO

