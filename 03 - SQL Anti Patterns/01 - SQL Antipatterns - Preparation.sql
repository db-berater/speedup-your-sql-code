/*
	============================================================================
	File:		01 - SQL Anti Paterns - preparation.sql

	Description:

	This script demonstrates some typical SQL Antipatterns which should be avoid.

	Summary:	This script prepares tables in the database ERP_Demo
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

RAISERROR ('Dropping existing model for SQL Antipatterns', 0, 1) WITH NOWAIT;
DROP TABLE IF EXISTS demo.nations;
DROP TABLE IF EXISTS demo.regions;
DROP TABLE IF EXISTS demo.orders;
DROP TABLE IF EXISTS demo.customers;
GO

/*
	Create a new schema [demo] and additional tables for the demonstration
*/
IF SCHEMA_ID(N'demo') IS NULL
BEGIN
	RAISERROR ('Creating schema [demo] for SQL Antipatterns', 0, 1) WITH NOWAIT;
	EXEC sp_executesql N'CREATE SCHEMA [demo] AUTHORIZATION dbo;';
END
GO

RAISERROR ('Creating table demo.customers...', 0, 1) WITH NOWAIT;
SELECT	CAST(c_custkey AS VARCHAR(10))	AS	c_custkey,
		CAST(c_mktsegment AS NCHAR(10))	AS	c_mktsegment,
		c_nationkey,
		c_name,
		c_address,
		CASE WHEN c_custkey % 100000 = 0
			 THEN NULL
			 ELSE c_phone
		END								AS	c_phone,
		c_acctbal,
		c_comment
INTO	demo.customers
FROM	dbo.customers;
GO

RAISERROR ('Creating table demo.nations...', 0, 1) WITH NOWAIT;
SELECT	[n_nationkey],
		[n_name],
		[n_regionkey],
		[n_comment]
INTO	demo.nations
FROM	dbo.nations;
GO

RAISERROR ('Creating table demo.regions...', 0, 1) WITH NOWAIT;
SELECT	[r_regionkey],
		[r_name],
		[r_comment]
INTO	demo.regions
FROM	dbo.regions;
GO

RAISERROR ('Creating table demo.orders...', 0, 1) WITH NOWAIT;
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
INTO	demo.orders
FROM	dbo.orders
WHERE	o_orderdate >= '2015-01-01'
		AND o_orderdate < '2020-01-01';
GO

/* create required indexes for the new tables */
RAISERROR ('Creating primary key on [demo].[customers]...', 0, 1) WITH NOWAIT;
BEGIN TRANSACTION
	ALTER TABLE demo.customers
	ALTER COLUMN c_custkey VARCHAR(10) NOT NULL;
	GO

	ALTER TABLE demo.customers
	ADD CONSTRAINT pk_demo_customers
	PRIMARY KEY CLUSTERED (c_custkey)
	WITH (SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE);
	GO
COMMIT TRANSACTION;
GO

RAISERROR ('Creating primary key on [demo].[nations]...', 0, 1) WITH NOWAIT;
ALTER TABLE demo.nations
ADD CONSTRAINT pk_demo_nations
PRIMARY KEY CLUSTERED (n_nationkey)
WITH (SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE);
GO

RAISERROR ('Creating primary key on [demo].[regions]...', 0, 1) WITH NOWAIT;
ALTER TABLE demo.regions
ADD CONSTRAINT pk_demo_regions
PRIMARY KEY CLUSTERED (r_regionkey)
WITH (SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE);
GO

RAISERROR ('Creating primary key on [demo].[orders]...', 0, 1) WITH NOWAIT;
ALTER TABLE demo.orders
ADD CONSTRAINT pk_demo_orders PRIMARY KEY CLUSTERED (o_orderkey)
WITH (SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE);
GO

ALTER DATABASE ERP_Demo SET QUERY_STORE CLEAR;
GO
