/*
	============================================================================
	File:		02 - SQL Anti Paterns - ISNULL.sql

	Description:

	This script demonstrates some typical SQL Antipatterns which should be avoid.

	Summary:	This demonstration shows the side effects of ISNULL in a query
				
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
	Many developers like the convenience of using ISNULL to avoid complex checks
	in a WHERE clause or to produce alternative output when no value is present. 
*/
SELECT	[c_custkey],
		[c_mktsegment],
		[c_nationkey],
		[c_name],
		[c_address],
		[c_phone],
		[c_acctbal],
		[c_comment]
FROM	demo.customers
WHERE	ISNULL(c_phone, 'n.a.') = 'n.a.'
OPTION	(QUERYTRACEON 9130);
GO

/* Even a COALESCE will not help to optimize the query */
SELECT	[c_custkey],
		[c_mktsegment],
		[c_nationkey],
		[c_name],
		[c_address],
		[c_phone],
		[c_acctbal],
		[c_comment]
FROM	demo.customers
WHERE	COALESCE(c_phone, 'n.a.') = 'n.a.'
OPTION	(QUERYTRACEON 9130);
GO

/*
	A full scan on the table can be avoided by an appropriate index
*/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'demo.customers', N'U') AND name = N'nix_demo_customers_c_phone')
	CREATE NONCLUSTERED INDEX nix_demo_customers_c_phone
	ON demo.customers (c_phone)
	WITH (SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE);
	GO

/*
	We run the query again to check whether the index helps to improve the query
*/
SELECT	[c_custkey],
		[c_mktsegment],
		[c_nationkey],
		[c_name],
		[c_address],
		[c_phone],
		[c_acctbal],
		[c_comment]
FROM	demo.customers
WHERE	ISNULL(c_phone, 'n.a.') = 'n.a.'
OPTION	(QUERYTRACEON 9130);
GO

/*
	Although the index gets used it is not a real improvement because
	Microsoft SQL Server SCAN the entire index to find the 16 affected
	rows!

	Avoid functions to transform attributes from tables.
	These attributes become NONSARGable!
*/
SELECT	[c_custkey],
		[c_mktsegment],
		[c_nationkey],
		[c_name],
		[c_address],
		[c_phone],
		[c_acctbal],
		[c_comment]
FROM	demo.customers
WHERE	c_phone IS NULL
		OR c_phone = 'n.a.'
OPTION	(QUERYTRACEON 9130);
GO

/*
	NOTE:	UNION ALL returns the same result as OR
*/
SELECT	[c_custkey],
		[c_mktsegment],
		[c_nationkey],
		[c_name],
		[c_address],
		[c_phone],
		[c_acctbal],
		[c_comment]
FROM	demo.customers
WHERE	c_phone IS NULL

UNION ALL

SELECT	*
FROM	demo.customers
WHERE	c_phone = 'n.a.';
GO


/*
	Clean not necessary indexes before we go the the next exercise
*/
IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'demo.customers', N'U') AND name = N'nix_demo_customers_c_phone')
	DROP INDEX nix_demo_customers_c_phone ON demo.customers;
	GO