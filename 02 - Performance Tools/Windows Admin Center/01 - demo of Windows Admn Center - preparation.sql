/*
	============================================================================
	File:		01 - demo of Windows Admin Center - preparation.sql

	Summary:	This script prepares tables in the database ERP_Demo
				for the chapter
				- Working with Windows Admin Center
				
				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Workshop - Making Bad Codes better"

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
USE ERP_Demo;
GO

/*
	We make sure that no indexes are present for the affected tables.

	NOTE:	The stored procedures are part of the ERP_Demo Database Framework!
*/
EXEC dbo.sp_drop_foreign_keys @table_name = N'ALL';
EXEC dbo.sp_drop_indexes @table_name = N'ALL', @check_only = 0;
GO

/* we deactivate the query store because we don't need it here */
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
		- number of orders
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