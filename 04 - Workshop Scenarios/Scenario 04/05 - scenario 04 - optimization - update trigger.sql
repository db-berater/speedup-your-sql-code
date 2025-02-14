/*
	============================================================================
	File:		05 - scenario 04 - optimization - update trigger.sql

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
	Let's run one demo move from only 1 record!
*/
SET STATISTICS IO, TIME ON;
GO

EXEC	webshop.move_order_record;
GO

SET STATISTICS IO, TIME OFF;
GO


CREATE OR ALTER TRIGGER webshop.trg_orders_update
ON webshop.orders
FOR UPDATE
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
		GROUP BY
				o.o_custkey
	)
	UPDATE	c
	SET		num_orders = s.num_of_orders
	FROM	webshop.customers AS c
			INNER JOIN s
			ON (c.c_custkey = s.o_custkey);
END
GO


/*
	Let's run one demo move from only 1 record again!
*/
SET STATISTICS IO, TIME ON;
GO

EXEC	webshop.move_order_record;
GO

SET STATISTICS IO, TIME OFF;
GO
