/*
	============================================================================
	File:		03 - SQL Anti Paterns - CONVERT_IMPLICIT.sql

	Description:

	This script demonstrates some typical SQL Antipatterns which should be avoid.

	Summary:	This demonstration shows the side effects/pro & con of implicit
				conversion rules
				
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
SET STATISTICS IO, TIME ON;
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

USE ERP_Demo;
GO

EXEC sp_drop_statistics @table_name = N'ALL';
GO

/*
	List all customers with placed orders at 2019-01-01.
*/
SELECT	c.c_custkey,
		c.c_mktsegment,
		c.c_nationkey,
		c.c_name,
		COUNT_BIG(*)	AS	num_of_orders
FROM	demo.customers AS c
		INNER JOIN demo.orders AS o
		ON (c.c_custkey = o.o_custkey)
WHERE	o.o_orderdate BETWEEN '2019-01-01' AND '2019-01-07'
GROUP BY
		c.c_custkey,
		c.c_mktsegment,
		c.c_nationkey,
		c.c_name
ORDER BY
		c.c_custkey
OPTION	(MAXDOP 4, QUERYTRACEON 9130);
GO

/*
	Let's try to optimize the query by using a covering index
	on demo.orders (o_orderdate and o_custkey)
*/
CREATE NONCLUSTERED INDEX nix_demo_orders_o_orderdate_o_custkey
ON demo.orders
(
	o_orderdate,
	o_custkey
)
WITH
(
	SORT_IN_TEMPDB = ON,
	DATA_COMPRESSION = PAGE
);
GO

/*
	Let's see whether the index will help to improve the performance
*/
SELECT	c.c_custkey,
		c.c_mktsegment,
		c.c_nationkey,
		c.c_name,
		COUNT_BIG(*)	AS	num_of_orders
FROM	demo.customers AS c
		INNER JOIN demo.orders AS o
		ON (c.c_custkey = o.o_custkey)
WHERE	o.o_orderdate = '2019-01-01'
GROUP BY
		c.c_custkey,
		c.c_mktsegment,
		c.c_nationkey,
		c.c_name
ORDER BY
		c.c_custkey
OPTION	(MAXDOP 4, QUERYTRACEON 9130);
GO

/*
	Perfect for the demo.orders table. But what happens to demo.customers?
	Have a look into the extended event recordings about the CONVERT_IMPLICIT
*/

/*
	Let's fix the problem by using the correct data type for the relationship
	between demo.customers and demo.orders!

	- Drop all indexes
	- change the data type
	- recreate the index(es)
*/
IF EXISTS
(
	SELECT	*
	FROM	sys.indexes
	WHERE	name = N'nix_demo_customers_c_phone'
			AND object_id = OBJECT_ID(N'demo.customers', N'U')
)
	DROP INDEX nix_demo_customers_c_phone ON demo.customers;
	GO

IF EXISTS
(
	SELECT	*
	FROM	sys.indexes
	WHERE	name = N'pk_demo_customers'
			AND object_id = OBJECT_ID(N'demo.customers', N'U')
)
	ALTER TABLE demo.customers DROP CONSTRAINT pk_demo_customers;
	GO

/*
	Change the data type of the column c_custkey
*/
ALTER TABLE demo.customers
ALTER COLUMN c_custkey BIGINT NOT NULL;
GO

/*
	Add constraints and indexes back to the table
*/
ALTER TABLE demo.customers
ADD CONSTRAINT pk_demo_customers PRIMARY KEY CLUSTERED (c_custkey)
WITH (SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE);
GO

/*
	Run the query again and watch for improvements!
*/
SELECT	c.c_custkey,
		c.c_mktsegment,
		c.c_nationkey,
		c.c_name,
		COUNT_BIG(*)	AS	num_of_orders
FROM	demo.customers AS c
		INNER JOIN demo.orders AS o
		ON (c.c_custkey = o.o_custkey)
WHERE	o.o_orderdate = '2019-01-01'
GROUP BY
		c.c_custkey,
		c.c_mktsegment,
		c.c_nationkey,
		c.c_name
ORDER BY
		c.c_custkey
OPTION	(MAXDOP 4, QUERYTRACEON 9130);
GO

/*
	Clean the environment!
*/
EXEC dbo.sp_drop_foreign_keys @table_name = N'ALL';
EXEC dbo.sp_drop_indexes @table_name = N'ALL';
EXEC dbo.sp_drop_statistics @table_name = N'ALL';
GO

DROP TABLE IF EXISTS demo.orders;
DROP TABLE IF EXISTS demo.customers;
DROP TABLE IF EXISTS demo.nations;
DROP TABLE IF EXISTS demo.regions;
GO

