
USE olist_dwh;
GO

/*
=====================================================
PROJECT: OLIST DATA WAREHOUSE
LAYER: SILVER
FILE: SILVER DATA QUALITY CHECKS
PURPOSE: Validate the quality of transformed data
=====================================================
*/

-- ==========================================
-- 1. CHECK TOTAL NUMBER OF ORDERS
-- ==========================================

SELECT
    COUNT(*) AS Total_Orders
FROM silver.fact_orders;
GO

-- ==========================================
-- 2. CHECK FOR MISSING ORDER IDs
-- ==========================================

SELECT
    COUNT(*) AS Total_Rows,
    COUNT(order_id) AS Orders_With_ID,
    COUNT(*) - COUNT(order_id) AS Missing_Order_IDs
FROM silver.fact_orders;
GO

-- ==========================================
-- 3. CHECK FOR DUPLICATE ORDER IDs
-- ==========================================

SELECT
    order_id,
    COUNT(*) AS Number_Of_Times
FROM silver.fact_orders
GROUP BY order_id
HAVING COUNT(*) > 1;
GO

-- ==========================================
-- 4. CHECK ORDER STATUSES
-- ==========================================

SELECT
    order_status,
    COUNT(*) AS Total_Orders
FROM silver.fact_orders
GROUP BY order_status
ORDER BY Total_Orders DESC;
GO

-- ==========================================
-- 5. CHECK FOR MISSING ORDER DATES
-- ==========================================

SELECT
    COUNT(*) AS Total_Orders,
    COUNT(order_purchase_timestamp) AS Orders_With_Date,
    COUNT(*) - COUNT(order_purchase_timestamp)
        AS Missing_Order_Dates
FROM silver.fact_orders;
GO

-- ==========================================
-- END OF SILVER DATA QUALITY CHECKS
-- ==========================================
