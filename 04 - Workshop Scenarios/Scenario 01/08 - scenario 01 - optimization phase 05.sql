/*
	============================================================================
	File:		08 - scenario 01 - optimization phase 05.sql

	Summary:	The final optimization is the implementation of a missing index
				to improve the general performance
				
				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Workshop - Accelerate your SQL Code"

	Date:		October 2024
	Revion:		November 2024

	SQL Server Version: >= 2016
	============================================================================
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

USE ERP_Demo;
GO

/*
	First let's analyse the generic query inside the function
*/
DECLARE	@c_custkey		BIGINT	=	1483396;
DECLARE	@int_orderyear	INT		=	2019;

WITH l
AS
(
	SELECT	ROW_NUMBER() OVER (ORDER BY YEAR(o_orderdate) DESC)	AS	rn,
			o.o_custkey			AS	c_custkey,
			COUNT_BIG(*)		AS	num_of_orders,
			CASE WHEN YEAR(o_orderdate) = @int_orderyear
					THEN CASE
						WHEN COUNT_BIG(*) >= 20	THEN 'A'
						WHEN COUNT_BIG(*) >= 10	THEN 'B'
						WHEN COUNT_BIG(*) >= 5	THEN 'C'
						WHEN COUNT_BIG(*) >= 1	THEN 'D'
						ELSE 'Z'
						END
					ELSE CASE
						WHEN COUNT_BIG(*) >= 20	THEN 'B'
						WHEN COUNT_BIG(*) >= 10	THEN 'C'
						WHEN COUNT_BIG(*) >= 5	THEN 'D'
						ELSE 'Z'
						END
			END			AS	classification
	FROM	dbo.orders AS o
	WHERE	o.o_custkey = @c_custkey
			AND	o.o_orderdate >= DATEFROMPARTS(@int_orderyear - 1, 1, 1)
			AND	o.o_orderdate <= DATEFROMPARTS(@int_orderyear, 12, 31)
	GROUP BY
			o.o_custkey,
			YEAR(o_orderdate)
)
SELECT	c_custkey,
		num_of_orders,
		classification
FROM	l
WHERE	rn = 1
OPTION (RECOMPILE);
GO

/*
	The analysis of the execution plan reveals a missing index on the dbo.orders table
*/
CREATE NONCLUSTERED INDEX nix_orders_o_custkey_o_orderdate
ON dbo.orders
(
	o_custkey,
	o_orderdate
)
WITH
(
	SORT_IN_TEMPDB = ON,
	DATA_COMPRESSION = PAGE
);
GO

/*
	... and see the optimization potential after the implementation of the index!
*/
DECLARE	@c_custkey		BIGINT	=	1483396;
DECLARE	@int_orderyear	INT		=	2019;

WITH l
AS
(
	SELECT	ROW_NUMBER() OVER (ORDER BY YEAR(o_orderdate) DESC)	AS	rn,
			o.o_custkey			AS	c_custkey,
			COUNT_BIG(*)		AS	num_of_orders,
			CASE WHEN YEAR(o_orderdate) = @int_orderyear
					THEN CASE
						WHEN COUNT_BIG(*) >= 20	THEN 'A'
						WHEN COUNT_BIG(*) >= 10	THEN 'B'
						WHEN COUNT_BIG(*) >= 5	THEN 'C'
						WHEN COUNT_BIG(*) >= 1	THEN 'D'
						ELSE 'Z'
						END
					ELSE CASE
						WHEN COUNT_BIG(*) >= 20	THEN 'B'
						WHEN COUNT_BIG(*) >= 10	THEN 'C'
						WHEN COUNT_BIG(*) >= 5	THEN 'D'
						ELSE 'Z'
						END
			END			AS	classification
	FROM	dbo.orders AS o
	WHERE	o.o_custkey = @c_custkey
			AND	o.o_orderdate >= DATEFROMPARTS(@int_orderyear - 1, 1, 1)
			AND	o.o_orderdate <= DATEFROMPARTS(@int_orderyear, 12, 31)
	GROUP BY
			o.o_custkey,
			YEAR(o_orderdate)
)
SELECT	c_custkey,
		num_of_orders,
		classification
FROM	l
WHERE	rn = 1
OPTION (RECOMPILE);
GO
