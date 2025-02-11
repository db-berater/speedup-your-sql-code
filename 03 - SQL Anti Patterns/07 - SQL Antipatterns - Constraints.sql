/*
	============================================================================
	File:		07 - SQL Anti Paterns - constraints.sql

	Description:	This script demonstrates some typical SQL Antipatterns which should be avoid.

	Summary:		This script prepares tables in the database ERP_Demo
					for the chapter
					- SQL Anti Patterns
				
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
GO

USE ERP_Demo;
GO

EXEC sp_drop_foreign_keys @table_name = N'ALL';
EXEC sp_drop_indexes @table_name = N'ALL';
EXEC sp_drop_statistics @table_name = N'ALL';
GO

DROP TABLE IF EXISTS demo.regions;
DROP TABLE IF EXISTS demo.nations;
DROP TABLE IF EXISTS demo.customers;
DROP TABLE IF EXISTS demo.orders;
GO

/*
	Create the schema [demo] for the demos
*/
IF SCHEMA_ID(N'demo') IS NULL
	EXEC sp_executesql N'CREATE SCHEMA [demo] AUTHORIZATION dbo;';
	GO

SELECT	TOP (1000000)
		[o_orderdate],
		[o_orderkey],
		[o_custkey],
		CAST (1 AS smallint)	AS	[o_orderpriority],
		[o_shippriority],
		[o_clerk],
		[o_orderstatus],
		[o_totalprice],
		[o_comment],
		[o_storekey]
INTO	demo.orders
FROM	dbo.orders;
GO

/*
	Create a clustered index on the demo.orders table
*/
ALTER TABLE demo.orders
ADD CONSTRAINT pk_demo_orders PRIMARY KEY CLUSTERED (o_orderkey)
WITH (SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE);
GO

/* Check the distribution of possible values for o_orderpriority */
SELECT	DISTINCT
		o_orderpriority
FROM	demo.orders;
GO

SET STATISTICS IO, TIME ON;
GO

SELECT	[o_orderdate],
		[o_orderkey],
		[o_custkey],
		[o_orderpriority],
		[o_shippriority],
		[o_clerk],
		[o_orderstatus],
		[o_totalprice],
		[o_comment],
		[o_storekey]
FROM	demo.orders
WHERE	o_orderpriority = 1;
GO

SELECT	[o_orderdate],
		[o_orderkey],
		[o_custkey],
		[o_orderpriority],
		[o_shippriority],
		[o_clerk],
		[o_orderstatus],
		[o_totalprice],
		[o_comment],
		[o_storekey]
FROM	demo.orders
WHERE	o_orderpriority = 5;
GO

SELECT	[o_orderdate],
		[o_orderkey],
		[o_custkey],
		[o_orderpriority],
		[o_shippriority],
		[o_clerk],
		[o_orderstatus],
		[o_totalprice],
		[o_comment],
		[o_storekey]
FROM	demo.orders
WHERE	o_orderpriority = 5;
GO

/*
	Let's assume we can only have 3 valid values foro o_orderpriority
*/
ALTER TABLE demo.orders
ADD CONSTRAINT chk_demo_orders_o_orderpriority CHECK (o_orderpriority <= 3);
GO

/* Run the query and and be surprised! */
SELECT	*
FROM	demo.orders
WHERE	o_orderpriority = 2
GO

SELECT	*
FROM	demo.orders
WHERE	o_orderpriority = 5
GO

/* To avoid the behavior (TRIVAL PLAN) and Simple Parameterization */
SELECT	*
FROM	demo.orders
WHERE	o_orderpriority = 2
OPTION	(RECOMPILE);
GO

SELECT	*
FROM	demo.orders
WHERE	o_orderpriority = 5
OPTION	(RECOMPILE);
GO