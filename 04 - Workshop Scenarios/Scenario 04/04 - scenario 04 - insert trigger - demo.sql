/*
	============================================================================
	File:		04 - scenario 04 - insert trigger - demo.sql

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


USE ERP_Demo;
GO

CREATE OR ALTER TRIGGER webshop.trg_orders_insert
ON webshop.orders
FOR INSERT
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;


END