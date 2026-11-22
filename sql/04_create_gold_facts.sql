/* ============================================================================
   Script: 04_create_gold_dimensions.sql
   Purpose: Expose / conform Gold-layer dimension objects from Silver tables
   Database: olist_dwh (SQL Server)
   ============================================================================ */

USE olist_dwh;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'gold')
BEGIN
    EXEC('CREATE SCHEMA gold');
END
GO

-- Gold Customer Dimension
CREATE OR ALTER VIEW gold.dim_customers
AS
SELECT *
FROM silver.dim_customers;
GO

-- Gold Product Dimension
CREATE OR ALTER VIEW gold.dim_products
AS
SELECT *
FROM silver.dim_products;
GO

-- Gold Seller Dimension
CREATE OR ALTER VIEW gold.dim_sellers
AS
SELECT *
FROM silver.dim_sellers;
GO

-- Gold Geolocation Dimension
CREATE OR ALTER VIEW gold.dim_geolocation
AS
SELECT *
FROM silver.dim_geolocation;
GO