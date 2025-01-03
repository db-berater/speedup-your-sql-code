/*
	============================================================================
	File:		04 - SQL Anti Paterns - NOT EXISTS.sql

	Description:

	This script demonstrates some typical SQL Antipatterns which should be avoid.

	Summary:	This demonstration shows the side effects/pro & con of NOT EXISTS
				
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

SET STATISTICS IO, TIME ON;
GO

/*
	Challenge:	Give me the number of customers from Portugal who never
				placed an order in 2023
*/
SELECT	COUNT_BIG(*)	AS	num_of_customers
FROM	dbo.customers AS c
		INNER JOIN dbo.nations AS n
		ON (c.c_nationkey = n.n_nationkey)
		LEFT JOIN dbo.orders AS o
		ON
		(
			c.c_custkey = o.o_custkey
			AND
			(
				o.o_orderdate >= '2023-01-01'
				AND o.o_orderdate <= '2023-12-31'
			)
		)
WHERE	n.n_name = 'PORTUGAL'
		AND o.o_orderkey IS NULL
OPTION	(MAXDOP 4);
GO

/*
	We run the same query with NOT EXISTS to check any differences
*/

SELECT	COUNT_BIG(*)	AS	num_of_customers
FROM	dbo.customers AS c
		INNER JOIN dbo.nations AS n
		ON (c.c_nationkey = n.n_nationkey)
WHERE	n.n_name = 'PORTUGAL'
		AND NOT EXISTS
		(
			SELECT	*
			FROM	dbo.orders AS o
			WHERE	o.o_custkey = c.c_custkey
					AND
					(
						o.o_orderdate >= '2023-01-01'
						AND o.o_orderdate <= '2023-12-31'
					)
		)
OPTION	(MAXDOP 4);
GO

/*
	Let's create an index on dbo.orders for a better performance
*/
CREATE NONCLUSTERED INDEX nix_orders_o_custkey_o_orderdate
ON dbo.orders (o_custkey, o_orderdate)
WITH (SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE);
GO


SELECT	COUNT_BIG(*)	AS	num_of_customers
FROM	dbo.customers AS c
		INNER JOIN dbo.nations AS n
		ON (c.c_nationkey = n.n_nationkey)
		LEFT JOIN dbo.orders AS o
		ON
		(
			c.c_custkey = o.o_custkey
			AND
			(
				o.o_orderdate >= '2023-01-01'
				AND o.o_orderdate <= '2023-12-31'
			)
		)
WHERE	n.n_name = 'PORTUGAL'
		AND o.o_orderkey IS NULL
OPTION	(MAXDOP 4);
GO

/*
	We run the same query with NOT EXISTS to check any differences
*/

SELECT	COUNT_BIG(*)	AS	num_of_customers
FROM	dbo.customers AS c
		INNER JOIN dbo.nations AS n
		ON (c.c_nationkey = n.n_nationkey)
WHERE	n.n_name = 'PORTUGAL'
		AND NOT EXISTS
		(
			SELECT	*
			FROM	dbo.orders AS o
			WHERE	o.o_custkey = c.c_custkey
					AND
					(
						o.o_orderdate >= '2023-01-01'
						AND o.o_orderdate <= '2023-12-31'
					)
		)
OPTION	(MAXDOP 4);
GO

/* Clean the kitchen */
EXEC sp_drop_indexes @table_name = N'ALL';
GO

ALTER DATABASE ERP_DEmo SET QUERY_STORE CLEAR;
GO
