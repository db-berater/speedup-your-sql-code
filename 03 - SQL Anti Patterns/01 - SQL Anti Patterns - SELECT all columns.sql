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

/*
	For measurement of the used resources we use the STATISTICS output
*/
SET STATISTICS IO, TIME ON;
GO

/*
	The first example demonstrates a SELECT against all columns
	when the table does not have any index!

	Enable the execution plan to show the choice of the optimizer!
*/
SELECT	c.*
FROM	dbo.customers AS c;
GO

SELECT	c.c_custkey
FROM	dbo.customers AS c
GO

/*
	Now we create the primary key on the c_custkey
*/
ALTER TABLE dbo.customers
ADD CONSTRAINT pk_customers PRIMARY KEY NONCLUSTERED (c_custkey);
GO

SELECT	c.*
FROM	dbo.customers AS c;
GO

SELECT	c.c_custkey
FROM	dbo.customers AS c
GO

/* Clean the kitchen */
EXEC dbo.sp_drop_indexes @table_name = N'dbo.customers';
GO