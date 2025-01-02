/*
	============================================================================
	File:		0002 - demo of Windows Admin Center.sql

	Summary:	This script prepares tables in the database ERP_Demo
				for the chapter
				- Working with Windows Admin Center
				
				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Workshop - Making Bad Codes better"

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

/*
	We make sure that no indexes are present for the affected tables.

	NOTE:	The stored procedures are part of the ERP_Demo Database Framework!
*/
EXEC dbo.sp_drop_foreign_keys;
GO

EXEC dbo.sp_drop_indexes
	@table_name = N'ALL',
	@check_only = 0;
GO

/* we activate the query store to see the changes in our process */
EXEC dbo.sp_deactivate_query_store;
GO

/*
	We create a stored procedure which creates a stored procedure
	for the checks in Windows Admin Center
*/
CREATE OR ALTER PROCEDURE dbo.get_customer_info
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE	@c_custkey BIGINT = CAST((RAND() * 1600000) + 1 AS BIGINT);
	/*
		Get a record for the given customer which contains
		the number of orders and the information of:
		- first order date
		- last order date
	*/

	SELECT	c.c_custkey			AS	customer_number,
			c.c_name			AS	customer_name,
			c.c_comment			AS	customer_comment,
			n.n_name			AS	customer_nation,
			MIN(o.o_orderdate)	AS	first_order_date,
			MAX(o.o_orderdate)	AS	last_order_date,
			COUNT_BIG(*)		AS	num_orders_total
	FROM	dbo.regions AS r
			INNER JOIN dbo.nations AS n
			ON (n.n_regionkey = r.r_regionkey)
			INNER JOIN dbo.customers AS c
			ON (n.n_nationkey = c.c_nationkey)
			INNER JOIN dbo.orders AS o
			ON (c.c_custkey = o.o_custkey)
	WHERE	c.c_custkey = @c_custkey
	GROUP BY
			c.c_custkey,
			c.c_name,
			c.c_comment,
			n.n_name;
END
GO


/*
	Now open Windows Admin Center and import the "Windows Admin Server Demo.json
	from the "Windows Admin Center" folder
*/
EXEC dbo.get_customer_info;
GO

/*
	After the first execution round we add an additional index
	on dbo.customers for better performance!
*/
EXEC dbo.sp_create_indexes_customers;
GO

EXEC dbo.get_customer_info;
GO

/*
	After the second execution round we add an additional index
	on dbo.nations for better performance!
*/
EXEC dbo.sp_create_indexes_nations;
GO

EXEC dbo.get_customer_info;
GO

/*
	After the third execution round we add an additional index
	on dbo.regions for better performance!
*/
EXEC dbo.sp_create_indexes_regions;
GO

EXEC dbo.get_customer_info;
GO

/*
	After the third execution round we add an additional index
	on dbo.orders for better performance!
*/
EXEC dbo.sp_create_indexes_orders;
GO

EXEC dbo.get_customer_info;
GO

/*
	Clean the environment before we are starting the journey.
*/
EXEC dbo.sp_drop_indexes
	@table_name = N'ALL',
    @check_only = 0;
GO

EXEC dbo.sp_clear_query_store;
GO
