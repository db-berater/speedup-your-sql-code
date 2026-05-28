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
    The used function is part of the framework of the demo database ERP_Demo.
    Download: https://www.db-berater.de/downloads/ERP_DEMO.BAK

	we activate the query store to see the changes in our process
*/
EXEC dbo.sp_drop_foreign_keys @table_name = N'ALL';
EXEC dbo.sp_drop_indexes
	@table_name = N'ALL',
    @check_only = 0;

EXEC dbo.sp_clear_query_store;
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

RAISERROR ('Now open Windows Admin Center and load the settings of [Windows Admin Server Demo.json]', 0, 1) WITH NOWAIT;
RAISERROR ('Start the process the first time and watch the metrics.', 0, 1) WITH NOWAIT;
GO