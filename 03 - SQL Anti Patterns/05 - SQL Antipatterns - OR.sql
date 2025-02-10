/*
	============================================================================
	File:			05 - SQL Anti Paterns - OR.sql

	Description:	This script demonstrates some typical SQL Antipatterns which should be avoid.

	Summary:		This demonstration shows the side effects/pro & con of OR
				
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

IF SCHEMA_ID(N'demo') IS NULL
	EXEC sp_executesql N'CREATE SCHEMA [demo] AUTHORIZATION dbo;';
	GO

DROP TABLE IF EXISTS demo.lineitems;
DROP TABLE IF EXISTS demo.parts;
GO

SELECT	TOP (200000)
		p_partkey,
		p_type,
		p_size,
		p_brand,
		p_container,
		p_retailprice
INTO	demo.parts
FROM	dbo.parts AS p
GO

SELECT	TOP (1000000)
		l.l_orderkey,
		l.l_linenumber,
		l.l_extendedprice,
		l.l_partkey,
		p.p_brand			AS	l_brand,
		l.l_linestatus
INTO	demo.lineitems
FROM	dbo.parts AS p
		INNER JOIN dbo.lineitems AS l
		ON (p.p_partkey = l.l_partkey)
GO

/*
	Create additional indexes for the performance
*/
ALTER TABLE demo.parts
ADD CONSTRAINT pk_demo_parts PRIMARY KEY CLUSTERED (p_partkey)
WITH (SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE);
GO

CREATE NONCLUSTERED INDEX nix_demo_lineitems_l_partkey_l_brand
ON demo.lineitems (l_partkey, l_brand)
WITH (SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE);
GO

CREATE NONCLUSTERED INDEX nix_demo_lineitems_l_l_brand_partkey
ON demo.lineitems (l_brand, l_partkey)
WITH (SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE);
GO

/*
	See the performance of the query
*/
SELECT	DISTINCT
		p.p_partkey,
		p.p_brand
FROM	demo.parts AS  p
		INNER JOIN demo.lineitems AS l
		ON
		(
			p.p_partkey = l.l_partkey
			OR p.p_brand = l.l_brand
		);
GO

/*
	Optimize the query by using a UNION instead of an OR
*/
SELECT	DISTINCT
		p.p_partkey,
		p.p_brand
FROM	demo.parts AS  p
		INNER JOIN demo.lineitems AS l
		ON(p.p_partkey = l.l_partkey)

UNION 

SELECT	DISTINCT
		p.p_partkey,
		p.p_brand
FROM	demo.parts AS  p
		INNER JOIN demo.lineitems AS l
		ON(p.p_brand = l.l_brand)
GO
