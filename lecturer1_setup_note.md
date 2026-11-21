Setup Note for Lecturer — Olist SSIS Data Warehouse Project
​1. Configure Project Parameters (Project.params)
​Before running the packages, open Project.params and update the following parameters to match your environment:

​ServerName: Set to your SQL Server instance name (currently configured as geenkhensi).
​DatabaseName: Set to your target database name (default/used: olist_dwh).
​CsvFolderPath: Set to the folder path containing the source CSV files (currently pointing to my local folder path).
​2. Prepare Source Files & Database
​Ensure the source CSV files are placed inside the folder specified in CsvFolderPath.
​Verify that SQL Server is running and accessible using your connection credentials.
​3. Build & Run
​Open the solution/project in Visual Studio (SSDT) and run Build -> Build Solution (Ctrl + Shift + B) to verify 0 Errors.
​Run 00_master.dtsx (or run individual packages in order: 01_bronze_load.dtsx -> 02_silver_transform 1.dtsx -> 03_gold_views.dtsx). 
