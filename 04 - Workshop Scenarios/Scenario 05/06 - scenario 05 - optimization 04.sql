/*
	============================================================================
	File:		06 - scenario 05 - optimization 04.sql

	Summary:	Try to avoid multiple SELECT when you can achieve the result(s)
				with one SELECT statment!

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

	DECLARE	c CURSOR
	FOR
		SELECT	c_custkey
		FROM	#customer_stats;

	OPEN c;

	FETCH NEXT FROM c INTO @c_custkey;
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT	@c_num_orders = COUNT_BIG(DISTINCT o.o_orderkey),
				@c_val_orders = ISNULL(SUM(l.l_extendedprice * (1.0 - l_discount)), 0)
		FROM	dbo.lineitems AS l
				INNER JOIN
				(
					SELECT	TOP (3)
							o_orderkey
					FROM	dbo.orders AS o
					WHERE	o.o_custkey = @c_custkey
							AND o_orderdate BETWEEN @date_from AND @date_to
					ORDER BY
							o_orderdate DESC
				) AS o
				ON (o.o_orderkey = l.l_orderkey);

		UPDATE	#customer_stats
		SET		c_num_orders = @c_num_orders,
				c_val_orders = @c_val_orders
		WHERE	c_custkey = @c_custkey;

		FETCH NEXT FROM c INTO @c_custkey;
	END

	CLOSE c;
	DEALLOCATE c;

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