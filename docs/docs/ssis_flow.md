flowchart TD
    M["00_master.dtsx\n(ServerName, DataBaseName)"] --> B["01_bronze_load.dtsx"]
    B --> S["02_silver_transform.dtsx"]
    S --> D["03_gold_dimensions.dtsx"]
    D --> F["04_gold_facts.dtsx"]