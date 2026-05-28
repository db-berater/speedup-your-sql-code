/*
	============================================================================
	File:			01 - SQL Anti Paterns - SELECT *.sql

	Description:	This script demonstrates a typical SQL Antipatterns which
					should be avoid. A SELECT * can lead to unexpected resource
					usage!

					THIS SCRIPT IS PART OF THE WORKSHOP:
						"Workshop - SQL Server Anti Patterns"

	Date:		October 2024
	Revion:		January 2025

	SQL Server Version: >= 2016
	============================================================================
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

USE ERP_Demo;
GO

EXEC dbo.sp_create_indexes_customers;
GO

/*
	For measurement of the used resources we use the STATISTICS output
*/
SET STATISTICS IO, TIME ON;
GO

EXEC dbo.sp_clear_query_store;
GO

/* Simple Parameterization */
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

SELECT * FROM dbo.customers
WHERE	c_custkey = 10;
GO

SELECT	t.text,
		p.objtype,
		p.refcounts,
		p.usecounts,
		p.size_in_bytes
FROM	sys.dm_exec_cached_plans AS p
		CROSS APPLY sys.dm_exec_sql_text(p.plan_handle) AS t
WHERE	t.text NOT LIKE N'%dm_exec_query_stats%'
		AND t.text LIKE '%customers%';
GO

/*
	Now we run the query with 10 clients and check afterwards
	the plan cache of SQL Server.

	Note:	To see a result in Query Store the sql statement must
			be run > 29 times!
*/
DECLARE	@i INT = 50;
DECLARE	@sql_stmt	NVARCHAR(1024) = N'SELECT * FROM dbo.customers WHERE c_custkey = ';
DECLARE	@exec_stmt	NVARCHAR(1024);
WHILE @i > 0
BEGIN
	SET	@exec_stmt = @sql_stmt + N' ' + CAST(@i AS NVARCHAR(16));
	EXEC dbo.sp_executesql @exec_stmt;

	SET	@i -= 1;
END
GO

SELECT	t.text,
		p.objtype,
		p.refcounts,
		p.usecounts,
		p.size_in_bytes
FROM	sys.dm_exec_cached_plans AS p
		CROSS APPLY sys.dm_exec_sql_text(p.plan_handle) AS t
WHERE	t.text NOT LIKE N'%dm_exec_query_stats%'
		AND t.text LIKE '%customers%'
ORDER BY
		p.refcounts DESC;
GO

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

DECLARE	@i INT = 50;
DECLARE	@sql_stmt	NVARCHAR(1024) = N'SELECT * FROM dbo.customers WHERE 1 = 1 AND c_custkey = ';
DECLARE	@exec_stmt	NVARCHAR(1024);
WHILE @i > 0
BEGIN
	SET	@exec_stmt = @sql_stmt + N' ' + CAST(@i AS NVARCHAR(16));
	EXEC dbo.sp_executesql @exec_stmt;

	SET	@i -= 1;
END
GO

SELECT	t.text,
		p.objtype,
		p.refcounts,
		p.usecounts,
		p.size_in_bytes
FROM	sys.dm_exec_cached_plans AS p
		CROSS APPLY sys.dm_exec_sql_text(p.plan_handle) AS t
WHERE	t.text NOT LIKE N'%dm_exec_query_stats%'
		AND t.text LIKE '%customers%'
ORDER BY
		p.refcounts DESC;
GO

/*
	Clean the kitchen!
*/
EXEC dbo.sp_drop_indexes @table_name = N'dbo.customers';
GO