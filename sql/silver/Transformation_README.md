## 1. Overview

The SILVER layer is the second layer of the Olist Data Warehouse project.

Its purpose is to transform raw data from the BRONZE layer into cleaned, standardised and structured data that can be used for business analysis.

Data transformations are executed using SQL Server Integration Services (SSIS).

## 2. Transformation Process

The transformation process follows this workflow:

BRONZE → SSIS → SILVER

The SSIS package used is:

`02_silver_transform 1.dtsx`

The package uses OLE DB connections and Execute SQL Tasks to transform and load data into the SILVER layer.

## 3. Data Cleaning Techniques

The following SQL techniques are used:

| Technique | Purpose |
|---|---|
| TRIM() | Removes unnecessary spaces |
| LOWER() | Converts text to lowercase |
| UPPER() | Converts text to uppercase |
| TRY_CAST() | Converts values into appropriate data types |
| COALESCE() | Replaces missing product categories with 'uncategorized' |
| NULLIF() | Converts empty review comments into NULL |
| DISTINCT | Removes duplicate category translation records |
| GROUP BY | Groups geographical records by postal code |
| AVG() | Calculates average latitude and longitude |

## 4. SILVER Tables

### Dimension Tables
- `silver.dim_customers`
- `silver.dim_products`
- `silver.dim_sellers`
- `silver.dim_geolocation`
- `silver.product_category_name_translation`

### Fact Tables
- `silver.fact_orders`
- `silver.fact_order_items`
- `silver.fact_order_payments`
- `silver.fact_order_reviews`

## 5. SSIS Package Execution

The SILVER transformation package contains three main Execute SQL Tasks:

1. Rebuild Silver Fact Tables (Orders and Items).
2. Rebuild Silver Fact Tables (Payments and Reviews).
3. Rebuild Silver Dimension Tables (Customers, Products, Sellers and Geolocation).

The package uses precedence constraints to control the execution sequence.

**Execution result:** The package completed successfully in Visual Studio, with all three tasks showing green success indicators.

## 6. Data Quality Checks

A separate SQL script is provided:

`silver_data_quality_checks.sql`

The checks performed on `silver.fact_orders` include:

- Missing order ID validation.
- Duplicate order ID validation.
- Order status validation.
- Missing purchase date validation.

The missing ID, duplicate ID and order status checks passed during validation. The missing purchase date check is still to be confirmed.

## 7. Tools and Technologies

- Microsoft SQL Server
- SQL Server Management Studio (SSMS)
- SQL Server Integration Services (SSIS)
- Visual Studio
- GitHub
- SQL

## 8. Project Outcome

The SILVER layer provides standardised and transformed data for the GOLD layer.

The GOLD layer uses this data to create analytical views for order details, payment summaries and customer reviews.
