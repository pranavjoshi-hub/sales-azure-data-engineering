# Azure Sales Data Engineering : Project Overview
- Extracted data from tables in an on-premises MS SQL Server database and stored in parquet file format in an ADLS Gen 2 storage account, using the 'Lookup', 'For Each' and 'Copy' activities in an Azure Data Factory Pipeline.
- Performed transformations on data using PySpark code in Azure Databricks notebooks, which are also activities in the same ADF pipeline.
- Loaded the transformed data onto a SQL database in Azure Synapse Analytics.
- Analyzed and visualized the transformed data with Power BI.
- Stored secrets in an Azure Key Vault resource.

# Resources and Tools Used
- Resource Group: sales-project
- Azure Key Vault: sales-key-vault
- Azure Data Factory: sales-data-factory-130324
- Azure Databricks: sales-databricks
- Azure Synapse Analytics: sales-ws
- Azure Data Lake Gen 2 Storage Account: salesdatalake130324
- Power BI
- MS SQL Server

# Data Extraction
- A sample relational database called 'AdventureWorksLT2019' is first downloaded and loaded on MS SQL Server.
- Database download link: https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorksLT2022.bak
- A new login and user are created and 'db_datareader' role is assigned to the user. Secrets are stored in the Key Vault resource.
- A self-hosted integration runtime is initiated to connect to the on-premises SQL Server database.
- Data is extracted from the database with an Azure Data Factory pipeline called 'Copy-All-Tables-Pipeline'.

!['Copy-All-Tables-Pipeline' work-flow in ADF resource 'sales-data-factory-130324'](https://github.com/pranavjoshi-hub/sales-azure-data-engineering/blob/master/images/data_factory.png)

- The 'Lookup' activity in the pipeline is used to fetch the list of schemas and tables using the following SQL query:  
  _SELECT s.name AS SchemaName, t.name AS TableName_  
  _FROM sys.tables t_  
  _INNER JOIN sys.schemas s_  
  _ON t.schema_id = s.schema_id_  
  _WHERE s.name = 'SalesLT'_  
  
- The next activity is 'For Each' and it encapsulates a 'Copy' activity. This will enable looping through each table belonging to schema 'SalesLT'.
- The 'Items' parameter in the 'For Each' activity is set to the following expression in order to loop through each object in the output of the 'Lookup' activity:  
  _@activity('LookupAllTables').output.value_

- Next, the 'Copy' activity will copy data in each of the tables to a container called 'Bronze' in the ADLS Gen 2 storage account, in parquet format. The parquet format is a columnar storage format that has in-built encoding and compression techniques, thus making it a highly efficient format option for data storage.
- The 'Copy' activity source is dynamically configured with it's 'Query' parameter set as follows:  
  _@{concat('SELECT * FROM ', item().SchemaName, '.', item().TableName)}_

- The 'Copy' activity sink is also dynamically configured in order to ensure that each parquet file containing data of each table is stored to an individual directory in the storage account. The sink dataset file path is set to the following:  
  _bronze / @{concat(dataset().schemaname, '/',dataset().tablename)} / @{concat(dataset().tablename, '.parquet')}_

  The sink dataset has the following paramters set to values as follows:  
  _schemaname = @item().SchemaName_    
  _tablename = @item.TableName_
  
- Below is a list of tables belonging to the schema 'SalesLT' that are copied to the storage account:
1. Address
2. Customer
3. CustomerAddress
4. Product
5. ProductCategory
6. ProductDescription
7. ProductModel
8. ProductModelProductDescription
9. SalesOrderDetail
10. SalesOrderHeader

# Data Transformation
- The next two activites in the pipeline are 'Notebook' activities. The ADF resource is granted a 'Contributor' role in the Azure Databricks workspace.
- The ADLS Gen2 storage account is first mounted onto Databricks using PySpark code in the 'MountStorageAccount' notebook.
- Then, the data is transformed using PySpark in a notebook called 'DataTransformationBronzeSilver' and written in 'delta' format in the 'Silver' container. This notebook is also included in the ADF pipeline and labeled as 'BronzeToSilver'.
- The data is transformed again using PySpark in a notebook called 'DataTransformationSilverGold' and written in 'delta' format in the 'Gold' container. This notebook is also included in the ADF pipeline and labeled as as 'SilverToGold'.

# Data Loading and Analysis
- The individual files pertaining to each table are then moved to a Synapse Analytics database called 'gold_db'. A stored procedure is employed to move each of the files and store as views in the database in the serverless SQL pool. The serverless SQL pool is a comparatively cheaper compute option than a dedicated SQL pool and supports external tables and views but does not have the data persistence capabilities of the latter.
- Finally, the serverless SQL pool is connected to Power BI Desktop. Power BI desktop is used to create a dashboard.

  
