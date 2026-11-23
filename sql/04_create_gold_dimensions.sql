/* ============================================================================
   Script: 04_create_gold_dimensions.sql
   Purpose: Build Gold star-schema dimensions with surrogate keys,
            -1 Unknown members, and SCD Type 2 tracking on customers.
   Declared Grains:
     - gold.dim_customers: 1 row per customer version (SCD Type 2 by customer_id / natural key)
     - gold.dim_products: 1 row per product (product_id)
     - gold.dim_sellers: 1 row per seller (seller_id)
     - gold.dim_geolocation: 1 row per zip code prefix (zip_code_prefix)
   ============================================================================ */

USE olist_dwh;
GO

DROP VIEW IF EXISTS gold.fact_order_items;
DROP VIEW IF EXISTS gold.fact_order_payments;
DROP VIEW IF EXISTS gold.fact_order_reviews;
DROP VIEW IF EXISTS gold.dim_customers;
DROP VIEW IF EXISTS gold.dim_products;
DROP VIEW IF EXISTS gold.dim_sellers;
DROP VIEW IF EXISTS gold.dim_geolocation;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'gold')
BEGIN
    EXEC('CREATE SCHEMA gold');
END
GO

-- ----------------------------------------------------------------------------
-- 1. GOLD.DIM_CUSTOMERS (SCD Type 2 + -1 Unknown Row)
-- ----------------------------------------------------------------------------
IF OBJECT_ID('gold.dim_customers', 'U') IS NULL
BEGIN
    CREATE TABLE gold.dim_customers (
        customer_sk INT IDENTITY(1,1) PRIMARY KEY,
        customer_id VARCHAR(100) NOT NULL,
        customer_unique_id VARCHAR(100) NOT NULL,
        customer_zip_code_prefix VARCHAR(20) NULL,
        customer_city VARCHAR(100) NULL,
        customer_state VARCHAR(20) NULL,
        valid_from DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
        valid_to DATETIME2(0) NULL,
        is_current BIT NOT NULL DEFAULT 1
    );
END
GO

-- Ensure -1 Unknown member exists (using IDENTITY_INSERT)
IF NOT EXISTS (SELECT 1 FROM gold.dim_customers WHERE customer_sk = -1)
BEGIN
    SET IDENTITY_INSERT gold.dim_customers ON;
    INSERT INTO gold.dim_customers (
        customer_sk, customer_id, customer_unique_id,
        customer_zip_code_prefix, customer_city, customer_state,
        valid_from, valid_to, is_current
    )
    VALUES (
        -1, 'UNKNOWN', 'UNKNOWN',
        '-1', 'Unknown', 'UNK',
        '1900-01-01T00:00:00', '9999-12-31T23:59:59', 1
    );
    SET IDENTITY_INSERT gold.dim_customers OFF;
END
GO

-- SCD Type 2 Merge/Update Logic for Customers
-- Step A: Expire existing current rows where tracked attributes changed
UPDATE tgt
SET
    tgt.valid_to = SYSUTCDATETIME(),
    tgt.is_current = 0
FROM gold.dim_customers tgt
INNER JOIN silver.dim_customers src
    ON tgt.customer_id = src.customer_id
WHERE tgt.is_current = 1
  AND tgt.customer_sk <> -1
  AND (
        ISNULL(tgt.customer_zip_code_prefix, '') <> ISNULL(src.customer_zip_code_prefix, '')
     OR ISNULL(tgt.customer_city, '') <> ISNULL(src.customer_city, '')
     OR ISNULL(tgt.customer_state, '') <> ISNULL(src.customer_state, '')
  );
GO

-- Step B: Insert new customers OR new versions for changed attributes
INSERT INTO gold.dim_customers (
    customer_id, customer_unique_id,
    customer_zip_code_prefix, customer_city, customer_state,
    valid_from, valid_to, is_current
)
SELECT
    src.customer_id,
    src.customer_unique_id,
    src.customer_zip_code_prefix,
    src.customer_city,
    src.customer_state,
    SYSUTCDATETIME() AS valid_from,
    '9999-12-31T23:59:59' AS valid_to,
    1 AS is_current
FROM silver.dim_customers src
WHERE NOT EXISTS (
    SELECT 1
    FROM gold.dim_customers cur
    WHERE cur.customer_id = src.customer_id
      AND cur.is_current = 1
      AND cur.customer_sk <> -1
);
GO

-- ----------------------------------------------------------------------------
-- 2. GOLD.DIM_GEOLOCATION (Surrogate Key + -1 Unknown Row)
-- ----------------------------------------------------------------------------
IF OBJECT_ID('gold.dim_geolocation', 'U') IS NULL
BEGIN
    CREATE TABLE gold.dim_geolocation (
        geolocation_sk INT IDENTITY(1,1) PRIMARY KEY,
        zip_code_prefix VARCHAR(20) NOT NULL,
        avg_latitude FLOAT NULL,
        avg_longitude FLOAT NULL
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM gold.dim_geolocation WHERE geolocation_sk = -1)
BEGIN
    SET IDENTITY_INSERT gold.dim_geolocation ON;
    INSERT INTO gold.dim_geolocation (geolocation_sk, zip_code_prefix, avg_latitude, avg_longitude)
    VALUES (-1, '-1', NULL, NULL);
    SET IDENTITY_INSERT gold.dim_geolocation OFF;
END
GO

INSERT INTO gold.dim_geolocation (zip_code_prefix, avg_latitude, avg_longitude)
SELECT
    src.zip_code_prefix,
    src.avg_latitude,
    src.avg_longitude
FROM silver.dim_geolocation src
WHERE src.zip_code_prefix IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM gold.dim_geolocation tgt
      WHERE tgt.zip_code_prefix = src.zip_code_prefix
        AND tgt.geolocation_sk <> -1
  );
GO

-- ----------------------------------------------------------------------------
-- 3. GOLD.DIM_PRODUCTS & GOLD.DIM_SELLERS (-1 Unknown Row Pattern)
-- Adjust column names if your silver.dim_products / silver.dim_sellers differ.
-- ----------------------------------------------------------------------------
IF OBJECT_ID('gold.dim_products', 'U') IS NULL
BEGIN
    CREATE TABLE gold.dim_products (
        product_sk INT IDENTITY(1,1) PRIMARY KEY,
        product_id VARCHAR(100) NOT NULL
        -- Add product category / dimension attributes from silver.dim_products as needed
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM gold.dim_products WHERE product_sk = -1)
BEGIN
    SET IDENTITY_INSERT gold.dim_products ON;
    INSERT INTO gold.dim_products (product_sk, product_id)
    VALUES (-1, 'UNKNOWN');
    SET IDENTITY_INSERT gold.dim_products OFF;
END
GO

INSERT INTO gold.dim_products (product_id)
SELECT DISTINCT src.product_id
FROM silver.dim_products src
WHERE src.product_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM gold.dim_products tgt
      WHERE tgt.product_id = src.product_id
        AND tgt.product_sk <> -1
  );
GO

IF OBJECT_ID('gold.dim_sellers', 'U') IS NULL
BEGIN
    CREATE TABLE gold.dim_sellers (
        seller_sk INT IDENTITY(1,1) PRIMARY KEY,
        seller_id VARCHAR(100) NOT NULL
        -- Add seller city / state attributes from silver.dim_sellers as needed
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM gold.dim_sellers WHERE seller_sk = -1)
BEGIN
    SET IDENTITY_INSERT gold.dim_sellers ON;
    INSERT INTO gold.dim_sellers (seller_sk, seller_id)
    VALUES (-1, 'UNKNOWN');
    SET IDENTITY_INSERT gold.dim_sellers OFF;
END
GO

INSERT INTO gold.dim_sellers (seller_id)
SELECT DISTINCT src.seller_id
FROM silver.dim_sellers src
WHERE src.seller_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM gold.dim_sellers tgt
      WHERE tgt.seller_id = src.seller_id
        AND tgt.seller_sk <> -1
  );
GO