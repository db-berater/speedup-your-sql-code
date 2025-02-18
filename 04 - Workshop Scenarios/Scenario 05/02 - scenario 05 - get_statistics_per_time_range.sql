/*
	============================================================================
	File:		02 - scenario 05 - dbo.get_statistics_per_time_range.sql

	Summary:	This script creates the stored procedure for the daily statistics
				for the management board.

				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Performance optimization by identifying and correcting bad SQL code"

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

	/* remove the temporary table if exist */
	DROP TABLE IF EXISTS #customer_stats;

	CREATE TABLE #customer_stats
	(
		c_custkey		BIGINT			NOT NULL,
		c_nationkey		INT				NOT NULL,
		c_num_orders	INT				NOT NULL	DEFAULT (0),
		c_val_orders	NUMERIC(10, 2)	NOT NULL	DEFAULT (0)
	);

	ALTER TABLE #customer_stats ADD PRIMARY KEY CLUSTERED (c_custkey);

	/*
		we insert all customers into the temporary table which have placed
		an order in the given timeframe
	*/
	INSERT INTO #customer_stats
	(c_custkey, c_nationkey, c_num_orders)
	SELECT	c.c_custkey,
			c.c_nationkey,
			COUNT_BIG(*)	AS	c_num_orders
	FROM	dbo.customers AS c
			CROSS APPLY
			(
				SELECT	TOP (3)
						o_orderkey
				FROM	dbo.orders AS o
				WHERE	o.o_custkey = c.c_custkey
						AND o.o_orderdate BETWEEN @date_from AND @date_to
			) AS o
	GROUP BY
			c.c_custkey,
			c.c_nationkey;

	DECLARE	c CURSOR
	FOR
		SELECT	c_custkey
		FROM	#customer_stats;

	OPEN c;

	FETCH NEXT FROM c INTO @c_custkey;
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT	@c_num_orders = COUNT(*)
		FROM	(
					SELECT	TOP (3)
							o_custkey,
							o_orderkey
					FROM	dbo.orders
					WHERE	o_custkey = @c_custkey
							AND o_orderdate BETWEEN @date_from AND @date_to
					ORDER BY
							o_orderdate DESC
				) AS t;

		UPDATE	#customer_stats
		SET		c_num_orders = @c_num_orders
		WHERE	c_custkey = @c_custkey

		SELECT	@c_val_orders = ISNULL(SUM(l.l_extendedprice * (1.0 - l_discount)), 0)
		FROM	dbo.lineitems AS l
				INNER JOIN
				(
					SELECT	TOP (3)
							o_orderkey
					FROM	dbo.orders AS o
					WHERE	o.o_custkey = @c_custkey
							AND o_orderdate BETWEEN @date_from AND @date_to
					ORDER BY
							o_orderdate DESC,
							o.o_orderkey DESC
				) AS o
				ON (o.o_orderkey = l.l_orderkey);

		UPDATE	#customer_stats
		SET		c_val_orders = @c_val_orders
		WHERE	c_custkey = @c_custkey;

		FETCH NEXT FROM c INTO @c_custkey;
	END

	CLOSE c;
	DEALLOCATE c;

	SELECT	r.r_name								AS	region_name,
			COUNT(*)								AS	num_customers,
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

	DROP TABLE #customer_stats;
END
GO

ALTER DATABASE ERP_Demo SET QUERY_STORE CLEAR;
GO