flowchart LR
    SRC["Kaggle Olist CSVs\n(data/raw/)"] --> BRZ["Bronze Schema\nRaw Ingestion\n(01_bronze_load.dtsx)"]
    BRZ --> SLV["Silver Schema\nCleaned & Conformed\n(02_silver_transform.dtsx)"]
    SLV --> CHK["Quality Checks\n(tests/data_quality_checks.sql)"]
    SLV --> GLD["Gold Schema\nDimensions & Facts\n(03_gold_dimensions.dtsx / 04_gold_facts.dtsx)"]
    GLD --> BI["SQL Analytics &\nPower BI Report"]
