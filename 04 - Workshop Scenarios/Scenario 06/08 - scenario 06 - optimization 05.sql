/*
	============================================================================
	File:		08 - scenario 06 - optimization 05.sql

	Summary:	The best approach to deal with lots of rows is to avoid cursors!
				Try to cover your goal in a set based operation instead of a row
				based operation!

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

CREATE OR ALTER PROCEDURE dbo.get_statistics_per_time_range
	@date_from	DATE,
	@date_to	DATE
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE	@c_custkey		BIGINT;
	DECLARE	@c_num_orders	INT;
	DECLARE	@c_val_orders	NUMERIC(10, 2);

	CREATE TABLE #customer_stats
	(
		c_custkey		BIGINT			NOT NULL,
		c_nationkey		INT				NOT NULL,
		c_num_orders	INT				NOT NULL	DEFAULT (0),
		c_val_orders	NUMERIC(10, 2)	NOT NULL	DEFAULT (0),

		/* 
			To avoid a recompile of temporary objects we must make sure
			that NO DDL commands are executed outside of the table
			definition!
		*/
		PRIMARY KEY CLUSTERED (c_custkey)
	);

	/*
		we insert all customers into the temporary table which have placed
		an order in the given timeframe
	*/
	INSERT INTO #customer_stats
	(c_custkey, c_nationkey)
	SELECT	DISTINCT
			c.c_custkey,
			c.c_nationkey
	FROM	dbo.customers AS c
			INNER JOIN dbo.orders AS o
			ON (c.c_custkey = o.o_custkey)
	WHERE	o.o_orderdate BETWEEN @date_from AND @date_to;

	;WITH cl
	AS
	(
		SELECT	cs.c_custkey,
				COUNT_BIG(DISTINCT o.o_orderkey)						AS	c_num_orders,
				ISNULL(SUM(l.l_extendedprice * (1.0 - l_discount)), 0)	AS	c_val_orders
		FROM	#customer_stats AS cs
				OUTER APPLY
				(
					dbo.lineitems AS l
					INNER JOIN
					(
						SELECT	TOP (3)
								o_orderkey
						FROM	dbo.orders AS o
						WHERE	o.o_custkey = cs.c_custkey
								AND o_orderdate BETWEEN @date_from AND @date_to
						ORDER BY
								o_orderdate DESC
					) AS o
					ON (o.o_orderkey = l.l_orderkey)
				)
		GROUP BY
				cs.c_custkey
	)
	UPDATE	cs
	SET		cs.c_num_orders = cl.c_num_orders,
			cs.c_val_orders = cl.c_val_orders
	FROM	#customer_stats AS cs
			INNER JOIN cl
			ON (cs.c_custkey = cl.c_custkey);

	SELECT	r.r_name								AS	region_name,
			COUNT_BIG(*)							AS	num_customers,
			SUM(c_num_orders)						AS	num_orders,
			FORMAT
			(
				SUM(c_val_orders),
				'#,##0.00',
				'en-us'
			)										AS	val_orders
	FROM	#customer_stats AS cs
			INNER JOIN dbo.nations AS n
			ON (cs.c_nationkey = n.n_nationkey)
			INNER JOIN dbo.regions AS r
			ON (n.n_regionkey = r.r_regionkey)
	GROUP BY
			r.r_name
	ORDER BY
			r.r_name;
END
GO