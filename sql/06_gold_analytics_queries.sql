/* ============================================================================
   Script: sql/06_gold_analytics_queries.sql
   Purpose: 8 business analytics queries querying ONLY the Gold star schema
            in olist_dwh, matched to your exact Gold table columns.
   ============================================================================ */

USE olist_dwh;
GO

-- 1. Executive KPI Summary (Total Orders, Items Sold, Price, Freight, Total Value)
SELECT
    COUNT(DISTINCT f.order_id) AS total_orders,
    COUNT(*) AS total_items_sold,
    CAST(SUM(f.price) AS DECIMAL(18, 2)) AS gross_merchandise_value,
    CAST(SUM(f.freight_value) AS DECIMAL(18, 2)) AS total_freight_revenue,
    CAST(SUM(f.price + f.freight_value) AS DECIMAL(18, 2)) AS total_order_value,
    CAST(AVG(f.price) AS DECIMAL(10, 2)) AS avg_item_price
FROM gold.fact_order_items f;

-- 2. Top 10 Products by Revenue and Order Volume
SELECT TOP 10
    p.product_sk,
    p.product_id,
    COUNT(DISTINCT f.order_id) AS total_orders,
    COUNT(*) AS total_units_sold,
    CAST(SUM(f.price) AS DECIMAL(18, 2)) AS product_revenue,
    CAST(AVG(f.price) AS DECIMAL(10, 2)) AS avg_unit_price
FROM gold.fact_order_items f
INNER JOIN gold.dim_products p
    ON f.product_sk = p.product_sk
WHERE p.product_sk <> -1
GROUP BY p.product_sk, p.product_id
ORDER BY product_revenue DESC;

-- 3. Monthly Item Revenue & Freight Trend by Shipping Limit Date
SELECT
    YEAR(f.shipping_limit_date) AS shipping_year,
    MONTH(f.shipping_limit_date) AS shipping_month,
    COUNT(DISTINCT f.order_id) AS total_orders,
    COUNT(*) AS total_items_sold,
    CAST(SUM(f.price) AS DECIMAL(18, 2)) AS monthly_item_revenue,
    CAST(SUM(f.freight_value) AS DECIMAL(18, 2)) AS monthly_freight_value
FROM gold.fact_order_items f
WHERE f.shipping_limit_date IS NOT NULL
GROUP BY
    YEAR(f.shipping_limit_date),
    MONTH(f.shipping_limit_date)
ORDER BY shipping_year, shipping_month;

-- 4. Active Customer Distribution by State and City (Gold dim_customers)
SELECT
    COALESCE(c.customer_state, 'Unknown') AS customer_state,
    COALESCE(c.customer_city, 'Unknown') AS customer_city,
    COUNT(DISTINCT c.customer_unique_id) AS unique_customers,
    COUNT(*) AS customer_records
FROM gold.dim_customers c
WHERE c.is_current = 1
GROUP BY
    COALESCE(c.customer_state, 'Unknown'),
    COALESCE(c.customer_city, 'Unknown')
ORDER BY unique_customers DESC, customer_state, customer_city;

-- 5. Top 10 Sellers by Gross Sales and Freight Ratio
SELECT TOP 10
    s.seller_sk,
    s.seller_id,
    COUNT(DISTINCT f.order_id) AS orders_fulfilled,
    COUNT(*) AS items_sold,
    CAST(SUM(f.price) AS DECIMAL(18, 2)) AS total_sales,
    CAST(SUM(f.freight_value) AS DECIMAL(18, 2)) AS total_freight,
    CAST(SUM(f.freight_value) * 100.0 / NULLIF(SUM(f.price), 0) AS DECIMAL(6, 2)) AS freight_to_price_pct
FROM gold.fact_order_items f
INNER JOIN gold.dim_sellers s
    ON f.seller_sk = s.seller_sk
WHERE s.seller_sk <> -1
GROUP BY s.seller_sk, s.seller_id
ORDER BY total_sales DESC;

-- 6. Payment Method Breakdown & Installment Behavior
SELECT
    COALESCE(p.payment_type, 'Unknown') AS payment_type,
    COUNT(DISTINCT p.order_id) AS orders_count,
    COUNT(*) AS payment_transactions,
    CAST(SUM(p.payment_value) AS DECIMAL(18, 2)) AS total_paid,
    CAST(AVG(p.payment_value) AS DECIMAL(10, 2)) AS avg_payment_value,
    CAST(AVG(CAST(p.payment_installments AS DECIMAL(10, 2))) AS DECIMAL(6, 2)) AS avg_installments
FROM gold.fact_order_payments p
GROUP BY COALESCE(p.payment_type, 'Unknown')
ORDER BY total_paid DESC;

-- 7. Customer Review Score Distribution & Share Percentage
SELECT
    r.review_score,
    COUNT(*) AS review_count,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS DECIMAL(6, 2)) AS pct_of_reviews
FROM gold.fact_order_reviews r
WHERE r.review_score BETWEEN 1 AND 5
GROUP BY r.review_score
ORDER BY r.review_score DESC;

-- 8. SCD Type 2 Customer History Audit (Customers with Multiple Versions)
SELECT
    c.customer_unique_id,
    COUNT(*) AS version_count,
    SUM(CASE WHEN c.is_current = 1 THEN 1 ELSE 0 END) AS active_versions,
    MIN(c.valid_from) AS first_seen_date,
    MAX(c.valid_from) AS latest_change_date
FROM gold.dim_customers c
GROUP BY c.customer_unique_id
HAVING COUNT(*) > 1
ORDER BY version_count DESC, c.customer_unique_id;
GO

