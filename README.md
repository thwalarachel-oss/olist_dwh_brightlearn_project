# 🛒 Olist E-Commerce Data Warehouse — SSIS Medallion Architecture

[![SQL Server](https://img.shields.io/badge/SQL%20Server-T--SQL-CC2927?logo=microsoftsqlserver&logoColor=white)](#)
[![SSIS](https://img.shields.io/badge/ETL-Microsoft%20SSIS-0078D4?logo=visualstudio&logoColor=white)](#)
[![Architecture](https://img.shields.io/badge/Architecture-Medallion%20(Bronze%20%E2%86%92%20Silver%20%E2%86%92%20Gold)-FFB000)](#)
[![Modeling](https://img.shields.io/badge/Data%20Model-Star%20Schema%20%7C%20SCD%20Type%202-2EA44F)](#)

An end-to-end, idempotent enterprise Data Warehouse built on **Microsoft SQL Server** and **SQL Server Integration Services (SSIS)** for the [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (~100k orders across 9 source CSV files, 2016–2018).

The solution ingests raw source extracts into an untouched **Bronze** staging layer, applies cleansing, standardization (`snake_case`), and deduplication in **Silver**, and models a multi-fact **Star Schema** in **Gold**—orchestrated end-to-end from a single master SSIS package (`00_master.dtsx`) with execution logging.

---

## 📋 Table of Contents
1. [Architecture & Data Flow](#1-architecture--data-flow)
2. [Star Schema Dimensional Model](#2-star-schema-dimensional-model)
3. [End-to-End Data Lineage](#3-end-to-end-data-lineage)
4. [Key Engineering & Design Decisions](#4-key-engineering--design-decisions)
5. [Data Dictionary (Gold Layer)](#5-data-dictionary-gold-layer)
6. [Data Quality & Validation Proof](#6-data-quality--validation-proof)
7. [Repository Structure](#7-repository-structure)
8. [How to Run & Reproduce](#8-how-to-run--reproduce)

---

## 1. Architecture & Data Flow

The pipeline follows the **Medallion Architecture** (`Bronze → Silver → Gold`) and is fully re-runnable starting from an empty SQL Server database.

```mermaid
flowchart LR
    CSV["Source CSVs (Olist)"] -->|"01_bronze_load.dtsx"| B_TBL["Bronze Layer (Raw Tables)"]
    B_TBL -->|"02_silver_transform.dtsx"| S_TBL["Silver Layer (Cleansed & Conformed)"]

    subgraph GLD["Gold Layer (Star Schema)"]
        DIMS["Dimensions<br/>dim_customers (SCD2), dim_products, dim_sellers, dim_geolocation"]
        FACTS["Facts<br/>fact_order_items, fact_order_payments, fact_order_reviews"]
    end

    S_TBL -->|"03_gold_views.dtsx / SQL"| DIMS
    S_TBL -->|"03_gold_views.dtsx / SQL"| FACTS
    DIMS --> FACTS

    subgraph BI["Analytics & Validation"]
        DQ["10 Data Quality Tests"]
        SQL["8 Gold Analytics Queries"]
        PBI["Power BI Executive Dashboard"]
    end

    FACTS --> DQ
    FACTS --> SQL
    FACTS --> PBI
```

