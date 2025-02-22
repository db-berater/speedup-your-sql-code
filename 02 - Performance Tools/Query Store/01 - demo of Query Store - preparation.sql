/*
	============================================================================
	File:		01 - demo of Query Store - preparation.sql

	Summary:	This script prepares tables in the database ERP_Demo
				for the chapter
				- Working with Query Store
				
				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Workshop - Accelerate your SQL Code"

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
EXEC dbo.sp_activate_query_store;
GO

/*
	We create a stored procedure which creates a stored procedure
	for the execution in SQLQueryStress
*/
CREATE OR ALTER PROCEDURE dbo.get_customer_info
	@c_custkey BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	/*
		Get a record for the given customer which contains
		the number of orders and the information of:
		- first order date
		- last order date
	*/

	SELECT	c.c_custkey			AS	customer_number,
			c.c_name			AS	customer_name,
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
			n.n_name;
END
GO

CREATE OR ALTER VIEW dbo.list_customer_info
AS
	SELECT	c_custkey
	FROM	(
				VALUES	(1),
						(10),
						(100),
						(1000),
						(10000)
			) AS x (c_custkey);
GO