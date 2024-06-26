USE gold_db
GO

CREATE OR ALTER PROCEDURE [sp_CreateSQLServerlessDatabaseViewGold] @ViewName nvarchar(100)
AS
BEGIN

DECLARE @statement VARCHAR(MAX)

	SET @statement = N'CREATE OR ALTER VIEW' + @ViewName + AS
		SELECT *
		FROM
			OPENROWSET(
			BULK ''https://salesdatalake130324.dfs.core.windows.net/gold/SalesLT/' + @ViewName + '/'',
			FORMAT = ''DELTA''
			) AS [result]



EXEC (@statement)

END
GO

