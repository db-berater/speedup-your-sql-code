/*
	============================================================================
	File:		0082 - scenario 04 - testing the environment.sql

	Summary:	This script holds some test units (INSERT, UPDATE, DELETE)
				to test whether the implemented objects are working as expected

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
ALTER DATABASE ERP_Demo SET QUERY_STORE CLEAR;
GO

USE ERP_Demo;
GO

/*
	Check the new tables for the demos
	- webshop.customers
	- webshop.orders
*/
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

/* cross check that we have
	24 orders for customer 1 and
	18 orders for customer 10!
*/
 

/*
	Update action
*/
/* Move one order from customer 10 to customer 1 */
EXEC webshop.move_order_record
	@from_custkey = 10,
    @to_custkey = 1,
    @num_records = 1;
GO

EXEC webshop.move_order_record
	@from_custkey = 1,
    @to_custkey = 10,
    @num_records = 15;
GO
/*
	Delete action
*/
EXEC webshop.delete_order_record
	@c_custkey = 1,
    @num_records = 1;
GO

EXEC webshop.delete_order_record
	@c_custkey = 1,
    @num_records = 100;
GO

EXEC webshop.delete_order_record
	@c_custkey = 10,
    @num_records = 100;
GO