/*
	============================================================================
	File:		02 - SQL Anti Paterns - High CPU.sql

	Description:

	This script demonstrates some typical SQL Antipatterns which should be avoid.

	Summary:	This demo shows the high usage of CPU concerning the usage of
				anti pattern design of the query.
				
				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Workshop - Spped Up Your SQL Code"

	Date:		October 2024
	Revion:		January 2025

	SQL Server Version: >= 2016
	------------------------------------------------------------------------------
	Written by Uwe Ricken, db Berater GmbH

	This script is intended only as a supplement to demos and lectures
	given by Uwe Ricken.  
  
	THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
	ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
	TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
	PARTICULAR PURPOSE.
	============================================================================
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET STATISTICS IO, TIME ON;
GO

USE ERP_Demo;
GO

/*
	Let's create a demo schema first before we create the object
*/
BEGIN TRY
	RAISERROR (N'creating schema [demo]...', 0, 1) WITH NOWAIT;
	EXEC sp_executesql N'CREATE SCHEMA demo AUTHORIZATION dbo;'
END TRY
BEGIN CATCH
	PRINT 'Schema [demo] already exists...'
END CATCH
GO

DROP TABLE IF EXISTS demo.customers;
GO

CREATE TABLE demo.customers
(
	c_id		INT				NOT NULL	IDENTITY (1, 1),
	c_custkey	NVARCHAR(10)	NOT NULL,
	c_name		VARCHAR(64)		NOT NULL,
	c_comment	CHAR(512)		NOT NULL
);
GO

CREATE NONCLUSTERED INDEX nix_demo_customers_c_id
ON demo.customers (c_id)
WITH
(
	SORT_IN_TEMPDB = ON,
	DATA_COMPRESSION = PAGE
);
GO

CREATE NONCLUSTERED INDEX nix_demo_customers_c_custkey
ON demo.customers (c_custkey)
WITH
(
	SORT_IN_TEMPDB = ON,
	DATA_COMPRESSION = PAGE
);
GO

/* Insert 100,00o rows into the new table */
INSERT INTO demo.customers WITH (TABLOCK)
(c_custkey, c_name, c_comment)
SELECT c_custkey, c_name, c_comment
FROM	dbo.customers;
GO

/* Now we create a stored procedure which access the data by the c_custkey */
CREATE OR ALTER PROCEDURE demo.get_customer_by_c_custkey
	@c_custkey NVARCHAR(10)
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	SELECT	*
	FROM	demo.customers
	WHERE	c_custkey = @c_custkey;
END
GO


ALTER DATABASE ERP_DEMO SET QUERY_STORE CLEAR;
GO
