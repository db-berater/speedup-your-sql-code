/*
	============================================================================
	File:		0023 - Windows Admin Server - Writing Workload.sql

	Summary:	This script will in a loop generate a writing workload.
				
				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Performance optimization by identifying and correcting bad SQL code"

	Date:		October 2024
	Revion:		November 2024

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

DROP TABLE IF EXISTS dbo.demo_table;
GO

SELECT	*
INTO	dbo.demo_table
FROM	dbo.orders
WHERE	1 = 1;
GO

DECLARE	@i INT = 1
WHILE @i <= 3
BEGIN
	INSERT INTO dbo.demo_table
	(o_orderdate, o_orderkey, o_custkey, o_orderpriority, o_shippriority, o_clerk, o_orderstatus, o_totalprice, o_comment)
	SELECT	TOP (1000000)
			o_orderdate,
			o_orderkey,
			o_custkey,
			o_orderpriority,
			o_shippriority,
			o_clerk,
			o_orderstatus,
			o_totalprice,
			o_comment
	FROM	dbo.orders;
	
	DELETE	dbo.demo_table;

	SET @i += 1;
END
GO

DECLARE	@i INT = 1
WHILE @i <= 3
BEGIN
	INSERT INTO dbo.demo_table WITH (TABLOCK)
	(o_orderdate, o_orderkey, o_custkey, o_orderpriority, o_shippriority, o_clerk, o_orderstatus, o_totalprice, o_comment)
	SELECT	TOP (1000000)
			o_orderdate,
			o_orderkey,
			o_custkey,
			o_orderpriority,
			o_shippriority,
			o_clerk,
			o_orderstatus,
			o_totalprice,
			o_comment
	FROM	dbo.orders;
	
	TRUNCATE TABLE dbo.demo_table;

	SET @i += 1;
END
GO