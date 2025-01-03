/*
	============================================================================
	File:		03 - SQL Anti Paterns - EXISTS.sql

	Description:

	This script demonstrates some typical SQL Antipatterns which should be avoid.

	Summary:	This demonstration shows the side effects/pro & con of EXISTS
				
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
USE ERP_Demo;
GO

ALTER DATABASE ERP_Demo SET QUERY_STORE CLEAR;
GO

/*
	Challenge:	List all customers with placed orders between 
				at 2023-01-01.
*/
SELECT	DISTINCT
		c.c_custkey,
		c.c_mktsegment,
		c.c_nationkey,
		c.c_name,
		c.c_address,
		c.c_phone,
		c.c_acctbal,
		c.c_comment
FROM	dbo.customers AS c
		INNER JOIN
		(
			SELECT	o_orderkey,
					o_custkey
			FROM	dbo.orders
			WHERE	o_orderdate = '2023-01-01'
		) AS o
		ON (c.c_custkey = o.o_custkey)
ORDER BY
		c.c_custkey
OPTION	(MAXDOP 4);
GO

/*
	the DISTINCT has a side effect on statistics!
	which will happen if we don't have any unique constraint:
	- Primary Key
	- Unique Key
	- Unique [clustered] index
*/
SELECT	*
FROM	dbo.get_statistics_columns_info(N'dbo.customers', N'U');
GO

/* Let's remove all available statistics in the database */
EXEC sp_drop_statistics;
GO

EXEC sp_create_indexes_customers;
EXEC sp_create_indexes_orders
	@column_list = N'o_orderkey, o_custkey, o_orderdate';
GO

SELECT	t.name,
		gsci.*
FROM	sys.tables AS t
		CROSS APPLY dbo.get_statistics_columns_info(t.name, t.type) gsci
WHERE	t.name IN ('orders', 'customers')
		AND t.schema_id = SCHEMA_ID(N'dbo');
GO

/*
	Challenge:	List all customers with placed orders between 
				at 2023-01-01.
*/
SELECT	DISTINCT
		c.c_custkey,
		c.c_mktsegment,
		c.c_nationkey,
		c.c_name,
		c.c_address,
		c.c_phone,
		c.c_acctbal,
		c.c_comment
FROM	dbo.customers AS c
		INNER JOIN
		(
			SELECT	o_orderkey,
					o_custkey
			FROM	dbo.orders
			WHERE	o_orderdate = '2023-01-01'
		) AS o
		ON (c.c_custkey = o.o_custkey)
ORDER BY
		c.c_custkey
OPTION	(MAXDOP 4);
GO


/*
	The same results can be achieved by using EXISTS.
	With this statement a DISTINCT is not required any more!
*/
SELECT	c.c_custkey,
		c.c_mktsegment,
		c.c_nationkey,
		c.c_name,
		c.c_address,
		c.c_phone,
		c.c_acctbal,
		c.c_comment
FROM	dbo.customers AS c
WHERE	EXISTS
		(
			SELECT	*
			FROM	dbo.orders AS o
			WHERE	o.o_orderdate = '2023-01-01'
					AND o.o_custkey = c.c_custkey
		)
ORDER BY
		c.c_custkey
OPTION	(MAXDOP 4);
GO

/*
	We optimize the query by having an index on o_orderdate and o_custkey
	to prevent the second scan on dbo.orders!

	Look to the SORT-Operator:
	- when will SORT 
*/
CREATE NONCLUSTERED INDEX nix_orders_o_custkey_o_orderdate
ON dbo.orders (o_custkey, o_orderdate)
WITH (SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE);
GO

/* First attempt to get the customer list */
SELECT	DISTINCT
		c.c_custkey,
		c.c_mktsegment,
		c.c_nationkey,
		c.c_name,
		c.c_address,
		c.c_phone,
		c.c_acctbal,
		c.c_comment
FROM	dbo.customers AS c
		INNER JOIN
		(
			SELECT	o_orderkey,
					o_custkey
			FROM	dbo.orders
			WHERE	o_orderdate = '2023-01-01'
		) AS o
		ON (c.c_custkey = o.o_custkey)
ORDER BY
		c.c_custkey
OPTION	(MAXDOP 4);
GO

/* Second attempt to get the customer list */
SELECT	c.c_custkey,
		c.c_mktsegment,
		c.c_nationkey,
		c.c_name,
		c.c_address,
		c.c_phone,
		c.c_acctbal,
		c.c_comment
FROM	dbo.customers AS c
WHERE	EXISTS
		(
			SELECT	*
			FROM	dbo.orders AS o
			WHERE	o.o_orderdate = '2023-01-01'
					AND o.o_custkey = c.c_custkey
		)
ORDER BY
		c.c_custkey
OPTION	(MAXDOP 4);
GO

/* Clean the kitchen */
EXEC sp_drop_indexes @table_name = N'ALL';
GO