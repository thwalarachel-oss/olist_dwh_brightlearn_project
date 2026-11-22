# Data Dictionary — Olist E-Commerce Data Warehouse (`olist_dwh`)

## Overview
This data dictionary documents the schemas, tables, and key business columns across the **Medallion Architecture** (`bronze`, `silver`, and `gold`) built on the Brazilian E-Commerce Public Dataset by Olist.

## Medallion Layers
* **`bronze` (Raw / Ingestion Layer):** Stores raw source records loaded from the 9 Olist CSV files with minimal structural changes for auditability and replayability.
* **`silver` (Cleaned / Conformed Layer):** Applies data type casting, null/whitespace handling, deduplication, and standardized key/timestamp fields across e-commerce entities.
* **`gold` (Analytics / Star Schema Layer):** Exposes dimensional (`dim_*`) and fact (`fact_*`) tables/views optimized for reporting in SQL and Power BI.

## Core Entities & Fields

### Customers (`bronze` / `silver` / `gold.dim_customers`)
| Column / Field | Layer | Type / Format | Description |
| :--- | :--- | :--- | :--- |
| `customer_id` | Bronze, Silver, Gold | String / Key | Order-specific customer identifier from Olist. |
| `customer_unique_id` | Bronze, Silver, Gold | String / Key | Unique identifier representing an individual customer across orders. |
| `customer_zip_code_prefix` | Bronze, Silver, Gold | String / Integer | First 5 digits of the customer's Brazilian postal code (`CEP`). |
| `customer_city` | Bronze, Silver, Gold | String | Customer city name (standardized casing in Silver/Gold). |
| `customer_state` | Bronze, Silver, Gold | String (2 chars) | Two-letter Brazilian state code (e.g., `SP`, `RJ`, `MG`). |

### Orders (`bronze` / `silver` / `gold.fact_orders`)
| Column / Field | Layer | Type / Format | Description |
| :--- | :--- | :--- | :--- |
| `order_id` | Bronze, Silver, Gold | String / Key | Unique identifier for each customer order. |
| `customer_id` | Bronze, Silver, Gold | String / Key | Foreign reference to the ordering customer record. |
| `order_status` | Bronze, Silver, Gold | String | Lifecycle state of the order (e.g., `delivered`, `shipped`, `canceled`, `invoiced`). |
| `order_purchase_timestamp` | Bronze, Silver, Gold | Timestamp | Date and time when the customer placed the order. |
| `order_approved_at` | Bronze, Silver, Gold | Timestamp | Date and time when payment approval occurred. |
| `order_delivered_carrier_date` | Bronze, Silver, Gold | Timestamp | Date and time when the order was handed over to the logistics partner. |
| `order_delivered_customer_date` | Bronze, Silver, Gold | Timestamp | Actual delivery date and time to the customer. |
| `order_estimated_delivery_date` | Bronze, Silver, Gold | Timestamp | Estimated delivery date shown to the customer at purchase time. |

### Order Items (`bronze` / `silver` / `gold.fact_order_items`)
| Column / Field | Layer | Type / Format | Description |
| :--- | :--- | :--- | :--- |
| `order_id` | Bronze, Silver, Gold | String / Key | Order identifier linking line items to an order. |
| `order_item_id` | Bronze, Silver, Gold | Integer | Sequential line number of the item within a single order. |
| `product_id` | Bronze, Silver, Gold | String / Key | Unique identifier for the purchased product. |
| `seller_id` | Bronze, Silver, Gold | String / Key | Unique identifier for the seller fulfilling the item. |
| `shipping_limit_date` | Bronze, Silver, Gold | Timestamp | Seller shipping deadline for handing the item to the carrier. |
| `price` | Bronze, Silver, Gold | Decimal / Currency | Item unit price (in BRL). |
| `freight_value` | Bronze, Silver, Gold | Decimal / Currency | Item shipping/freight cost (in BRL). |

### Order Payments (`bronze` / `silver`)
| Column / Field | Layer | Type / Format | Description |
| :--- | :--- | :--- | :--- |
| `order_id` | Bronze, Silver | String / Key | Order identifier associated with the payment record. |
| `payment_sequential` | Bronze, Silver | Integer | Sequence number when an order uses multiple payment methods or installments. |
| `payment_type` | Bronze, Silver | String | Payment method (e.g., `credit_card`, `boleto`, `voucher`, `debit_card`). |
| `payment_installments` | Bronze, Silver | Integer | Number of installments chosen for the payment. |
| `payment_value` | Bronze, Silver | Decimal / Currency | Payment amount in BRL. |

### Order Reviews (`bronze` / `silver`)
| Column / Field | Layer | Type / Format | Description |
| :--- | :--- | :--- | :--- |
| `review_id` | Bronze, Silver | String / Key | Unique identifier for the customer review. |
| `order_id` | Bronze, Silver | String / Key | Order identifier associated with the review. |
| `review_score` | Bronze, Silver | Integer (1–5) | Customer satisfaction rating from `1` (lowest) to `5` (highest). |
| `review_comment_title` | Bronze, Silver | String | Optional short title provided by the reviewer. |
| `review_comment_message` | Bronze, Silver | String | Optional detailed review text provided by the reviewer. |
| `review_creation_date` | Bronze, Silver | Timestamp | Date when the satisfaction survey was sent to the customer. |
| `review_answer_timestamp` | Bronze, Silver | Timestamp | Date and time when the customer answered the review survey. |

### Products & Category Translation (`bronze` / `silver` / `gold.dim_products`)
| Column / Field | Layer | Type / Format | Description |
| :--- | :--- | :--- | :--- |
| `product_id` | Bronze, Silver, Gold | String / Key | Unique identifier for each product. |
| `product_category_name` | Bronze, Silver, Gold | String | Original Portuguese product category name from Olist. |
| `product_category_name_english` | Silver, Gold | String | English category translation joined from `product_category_name_translation`. |
| `product_name_lenght` | Bronze, Silver | Integer | Character length of the product name (raw Olist column spelling). |
| `product_description_lenght` | Bronze, Silver | Integer | Character length of the product description (raw Olist column spelling). |
| `product_photos_qty` | Bronze, Silver | Integer | Number of published product photos. |
| `product_weight_g` | Bronze, Silver, Gold | Decimal / Integer | Product weight in grams. |
| `product_length_cm` | Bronze, Silver, Gold | Decimal / Integer | Product length in centimeters. |
| `product_height_cm` | Bronze, Silver, Gold | Decimal / Integer | Product height in centimeters. |
| `product_width_cm` | Bronze, Silver, Gold | Decimal / Integer | Product width in centimeters. |

### Sellers (`bronze` / `silver` / `gold.dim_sellers`)
| Column / Field | Layer | Type / Format | Description |
| :--- | :--- | :--- | :--- |
| `seller_id` | Bronze, Silver, Gold | String / Key | Unique identifier for each marketplace seller. |
| `seller_zip_code_prefix` | Bronze, Silver, Gold | String / Integer | First 5 digits of the seller's Brazilian postal code (`CEP`). |
| `seller_city` | Bronze, Silver, Gold | String | Seller city name. |
| `seller_state` | Bronze, Silver, Gold | String (2 chars) | Two-letter Brazilian state code. |

### Geolocation (`bronze` / `silver`)
| Column / Field | Layer | Type / Format | Description |
| :--- | :--- | :--- | :--- |
| `geolocation_zip_code_prefix` | Bronze, Silver | String / Integer | First 5 digits of the postal code (`CEP`). |
| `geolocation_lat` | Bronze, Silver | Decimal / Float | Latitude coordinate for the location. |
| `geolocation_lng` | Bronze, Silver | Decimal / Float | Longitude coordinate for the location. |
| `geolocation_city` | Bronze, Silver | String | City name associated with the coordinate. |
| `geolocation_state` | Bronze, Silver | String (2 chars) | Two-letter Brazilian state code. |

> **Tip:** Adjust any exact column names or table names above to match your SQL scripts in `sql/` and your `03_gold_dimensions.dtsx` / `04_gold_facts.dtsx` packages.
