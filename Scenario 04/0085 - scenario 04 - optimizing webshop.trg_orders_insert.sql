/*
	============================================================================
	File:		0084 - scenario 04 - optimizing webshop.trg_orders_insert.sql

	Summary:	The stored proc has two problems:
				- the EXCEPT clause in the statement can lead to un unstable plan
					if statistics are not updated!
				- there is an unnecessary output which does not help with the
					insert statement!

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

CREATE OR ALTER TRIGGER [webshop].[trg_orders_insert]
ON [webshop].[orders]
FOR INSERT
AS
BEGIN
	/* Start every batch with NOCOUNT ON! */
	SET NOCOUNT ON;

	/*
		When we insert a record into webshop.orders we can
		update the customers table within ONE statement!
	*/
	UPDATE	c
	SET		num_orders = x.total_orders
	FROM	webshop.customers AS c
			INNER JOIN inserted AS i
			ON (c.c_custkey = i.o_custkey)
			CROSS APPLY
			(
				SELECT	COUNT_BIG(*)	AS	total_orders
				FROM	webshop.orders AS wo
				WHERE	wo.o_custkey = c.c_custkey
						AND wo.o_orderdate >= DATEFROMPARTS(YEAR(GETDATE()), 1, 1)
						AND wo.o_orderdate < DATEFROMPARTS(YEAR(GETDATE()) + 1 , 1, 1)
			) AS x(total_orders)
END
GO

/*
	Testing the trigger!
*/
TRUNCATE TABLE webshop.orders;
GO

SELECT	c_custkey,
        c_mktsegment,
        c_name,
        c_acctbal,
        num_orders
FROM	webshop.customers
WHERE	c_custkey <= 10;
GO

/* No rows in webhop.orders! */
SELECT	o_orderdate,
        o_orderkey,
        o_custkey,
        o_totalprice,
        o_comment
FROM	webshop.orders;
GO


/* Insert a few new records into webshop.orders for customer 1 */
EXEC webshop.insert_order_record @c_custkey = 1, @num_records = 1;
GO
EXEC webshop.insert_order_record @c_custkey = 1, @num_records = 50;
GO

/* we do it again with another customer before we check UPDATE(s) */
EXEC webshop.insert_order_record @c_custkey = 10, @num_records = 100;
GO

TRUNCATE TABLE webshop.orders;
GO

ALTER DATABASE ERP_Demo SET QUERY_STORE CLEAR;
GO