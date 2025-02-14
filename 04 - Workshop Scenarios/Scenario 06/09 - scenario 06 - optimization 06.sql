/*
	============================================================================
	File:		09 - scenario 06 - optimization 06.sql

	Summary:	Try to avoid temporary objects if you can handle the result in
				one - set based - operation.

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

	SELECT	r.r_name,
			COUNT_BIG(DISTINCT c.c_custkey)	AS	num_customers,
			COUNT_BIG(DISTINCT o.o_orderkey)	AS	num_orders,
			FORMAT
			(
				SUM(val_orders),
				'#,##0.00',
				'en-us'
			)				AS	c_val_orders
	FROM	dbo.regions AS r
			INNER JOIN dbo.nations AS n
			ON (r.r_regionkey = n.n_regionkey)
			INNER JOIN dbo.customers AS c
			ON (n.n_nationkey = c.c_nationkey)
			INNER JOIN
			(
				SELECT	ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC, o.o_orderkey DESC)	AS	rn,
						o.o_custkey,
						o.o_orderkey,
						ISNULL(SUM(l.l_extendedprice * (1.0 - l.l_discount)), 0)	AS	val_orders
				FROM	dbo.orders AS o
						LEFT JOIN dbo.lineitems AS l
						ON (o.o_orderkey = l.l_orderkey)
				WHERE	o.o_orderdate BETWEEN '2023-01-01' AND '2023-01-31'
				GROUP BY
						o.o_custkey,
						o.o_orderdate,
						o.o_orderkey
			) AS o
			ON
			(
				c.c_custkey = o.o_custkey
				AND o.rn <= 3
			)
	GROUP BY
			r.r_name
	ORDER BY
			r.r_name;
END
GO