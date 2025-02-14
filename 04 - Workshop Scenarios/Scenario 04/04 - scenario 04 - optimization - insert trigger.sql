/*
	============================================================================
	File:		04 - scenario 04 - optimization - insert trigger.sql

	Summary:	this script demonstrates the bad behavior of the trigger.
				The trigger uses a cursor for a "row by row" processing.
				Furthermore the trigger cannot use indexes efficently because
				it is using functions to transform attributes!

				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Accelerate your SQL Code"

	Date:		October 2024
	Revion:		February 2025

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

/*
	Let's run the insert of 10,000 rows and check the IO and CPU
*/
SET STATISTICS IO, TIME ON;
GO

WITH i
AS
(
	SELECT	TOP (10000) o_orderkey FROM dbo.orders
	EXCEPT
	SELECT	o_orderkey FROM webshop.orders
)
INSERT INTO webshop.orders WITH (TABLOCK)
SELECT	o.*
FROM	dbo.orders AS o
		INNER JOIN i
		ON (o.o_orderkey = i.o_orderkey);
GO

SET STATISTICS IO, TIME OFF;
GO


USE ERP_Demo;
GO

CREATE OR ALTER TRIGGER webshop.trg_orders_insert
ON webshop.orders
FOR INSERT
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	/*
		Orders have an ascending key for the o_orderdate.
		There will be no orders inserted for the past!
	*/
	WITH s
	AS
	(
		SELECT	o.o_custkey,
				COUNT_BIG(*)	AS	num_of_orders
		FROM	webshop.orders AS o
				INNER JOIN inserted AS i
				ON (o.o_custkey = i.o_custkey)
		WHERE	o.o_orderdate >= DATEFROMPARTS(YEAR(i.o_orderdate), 1, 1)
				AND o.o_orderdate < DATEFROMPARTS(YEAR(i.o_orderdate) + 1, 1, 1)
	)
	UPDATE	c
	SET		num_orders = s.num_of_orders
	FROM	webshop.customers AS c
			INNER JOIN s
			ON (c.c_custkey = s.o_custkey);
END
GO

/*
	We rerun the test with 10.000 records...
*/
SET STATISTICS IO, TIME ON;
GO

WITH i
AS
(
	SELECT	TOP (10000) o_orderkey FROM dbo.orders
	EXCEPT
	SELECT	o_orderkey FROM webshop.orders
)
INSERT INTO webshop.orders WITH (TABLOCK)
SELECT	o.*
FROM	dbo.orders AS o
		INNER JOIN i
		ON (o.o_orderkey = i.o_orderkey);
GO

SET STATISTICS IO, TIME OFF;
GO

/* Reset of the query store */
ALTER DATABASE ERP_Demo SET QUERY_STORE CLEAR;
GO