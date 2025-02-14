/*
	============================================================================
	File:		05 - scenario 04 - optimization - delete trigger.sql

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

CREATE OR ALTER TRIGGER webshop.trg_orders_deleted
ON webshop.orders
FOR DELETE
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	WITH cl
	AS
	(
		SELECT	DISTINCT
				o_custkey
		FROM	deleted
	)
	UPDATE	c
	SET		c.num_orders = x.num_orders
	FROM	cl INNER JOIN webshop.customers AS c
			ON (cl.o_custkey = c.c_custkey)
			CROSS APPLY
			(
				SELECT	COUNT_BIG(*)	AS	num_orders
				FROM	webshop.orders
				WHERE	o_custkey = c.c_custkey
						AND o_orderdate >= DATEFROMPARTS(YEAR(GETDATE()), 1, 1)
						AND o_orderdate <= DATEFROMPARTS(YEAR(GETDATE()), 12, 31)
			) AS x (num_orders);
END
GO