/* ============================================================================
   Project: Olist E-Commerce Data Warehouse (SSIS Medallion)
   File: sql/03_gold_analytics_queries.sql
   Purpose: 8 Business Analytics Queries Answered Exclusively from Gold Layer
   ============================================================================ */

USE olist_dwh;
go

-- ============================================================================
-- QUERY 1: Total Revenue and Freight Cost by Product Category (Top 10)
-- ============================================================================
SELECT TOP 10 
    COALESCE(p.product_category_en, 'Unknown') AS product_category,
    COUNT(DISTINCT s.order_id) AS total_orders,
    SUM(s.price) AS total_revenue,
    SUM(s.freight_value) AS total_freight,
    AVG(s.delivery_days) AS avg_delivery_days
FROM gold.fact_sales s
JOIN gold.dim_product p ON s.product_key = p.product_key
GROUP BY p.product_category_en
ORDER BY total_revenue DESC;
GO

-- ============================================================================
-- QUERY 2: Monthly Sales Performance & Order Volume Trends
-- ============================================================================
SELECT 
    d.year,
    d.month,
    d.month_name,
    COUNT(DISTINCT s.order_id) AS monthly_orders,
    SUM(s.price) AS monthly_revenue
FROM gold.fact_sales s
JOIN gold.dim_date d ON s.order_date_key = d.date_key
GROUP BY d.year, d.month, d.month_name
ORDER BY d.year, d.month;
GO

-- ============================================================================
-- QUERY 3: Customer Distribution and Revenue by State
-- ============================================================================
SELECT 
    c.customer_state,
    COUNT(DISTINCT c.customer_unique_id) AS total_unique_customers,
    COUNT(DISTINCT s.order_id) AS total_orders,
    SUM(s.price) AS state_revenue
FROM gold.fact_sales s
JOIN gold.dim_customer c ON s.customer_key = c.customer_key
GROUP BY c.customer_state
ORDER BY state_revenue DESC;
GO

-- ============================================================================
-- QUERY 4: Average Delivery Delay vs. Promised Delivery Date by State
-- ============================================================================
SELECT 
    c.customer_state,
    COUNT(s.order_id) AS delivered_orders,
    AVG(CAST(s.delivery_days AS FLOAT)) AS avg_actual_delivery_days,
    AVG(CAST(s.delivery_delay_days AS FLOAT)) AS avg_delivery_delay_days
FROM gold.fact_sales s
JOIN gold.dim_customer c ON s.customer_key = c.customer_key
WHERE s.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY avg_delivery_delay_days DESC;
GO

-- ============================================================================
-- QUERY 5: Payment Methods Breakdown & Installment Analysis
-- ============================================================================
SELECT 
    p.payment_type,
    COUNT(DISTINCT p.order_id) AS total_orders,
    AVG(p.payment_installments) AS avg_installments,
    SUM(p.payment_value) AS total_payment_value,
    (SUM(p.payment_value) * 100.0 / SUM(SUM(p.payment_value)) OVER()) AS revenue_percentage
FROM gold.fact_payments p
GROUP BY p.payment_type
ORDER BY total_payment_value DESC;
GO

-- ============================================================================
-- QUERY 6: Customer Review Scores & Satisfaction Analysis
-- ============================================================================
SELECT 
    r.review_score,
    COUNT(DISTINCT r.order_id) AS total_orders_reviewed,
    (COUNT(DISTINCT r.order_id) * 100.0 / SUM(COUNT(DISTINCT r.order_id)) OVER()) AS review_percentage
FROM gold.fact_reviews r
GROUP BY r.review_score
ORDER BY r.review_score DESC;
GO

-- ============================================================================
-- QUERY 7: Top 10 Performing Sellers by Revenue
-- ============================================================================
SELECT TOP 10 
    sl.seller_id,
    sl.seller_city,
    sl.seller_state,
    COUNT(DISTINCT s.order_id) AS total_orders_fulfilled,
    SUM(s.price) AS total_seller_revenue
FROM gold.fact_sales s
JOIN gold.dim_seller sl ON s.seller_key = sl.seller_key
GROUP BY sl.seller_id, sl.seller_city, sl.seller_state
ORDER BY total_seller_revenue DESC;
GO

-- ============================================================================
-- QUERY 8: Weekend vs. Weekday Order Volume & Revenue Patterns
-- ============================================================================
SELECT 
    CASE WHEN d.is_weekend = 1 THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    COUNT(DISTINCT s.order_id) AS total_orders,
    SUM(s.price) AS total_revenue,
    AVG(s.price) AS avg_order_item_price
FROM gold.fact_sales s
JOIN gold.dim_date d ON s.order_date_key = d.date_key
GROUP BY d.is_weekend;
GO
