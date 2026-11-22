
USE olist_dwh;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'gold')
BEGIN
    EXEC('CREATE SCHEMA gold');
END
GO

-- Fact: Order Items
CREATE OR ALTER VIEW gold.fact_order_items
AS
SELECT *
FROM silver.fact_order_items;
GO

-- Fact: Order Payments
CREATE OR ALTER VIEW gold.fact_order_payments
AS
SELECT *
FROM silver.fact_order_payments;
GO

-- Fact: Order Reviews
CREATE OR ALTER VIEW gold.fact_order_reviews
AS
SELECT *
FROM silver.fact_order_reviews;
GO
