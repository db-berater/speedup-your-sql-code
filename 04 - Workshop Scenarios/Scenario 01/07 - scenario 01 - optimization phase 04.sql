/*
	============================================================================
	File:		07 - scenario 01 - optimization phase 04.sql

	Summary:	This script optimize the table valued function that way
				that we make the Multiline-Function an Inline-Function for
				a better execution plan.
				
				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Workshop - Accelerate your SQL Code"

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
	Function Name:	dbo.calculate_customer_category
	Parameters:		@c_custkey		=>	customer key from dbo.customers
					@int_orderyear	=>	year of the status earned
					@calling_level	=>	the function is called recursive!

	Description:	This user definied function calculates the number of
					orders a customer has placed for a specific year
*/
DROP FUNCTION IF EXISTS dbo.calculate_customer_category;
GO

CREATE OR ALTER FUNCTION dbo.calculate_customer_category
(
	@c_custkey		BIGINT,
	@int_orderyear	INT,
	@calling_level	INT = 0
)
RETURNS TABLE
AS
RETURN
(
	/* Return the  information from actual and previous year */
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
);
GO

/*
	We are clearing the query store to focus on the last problem - indexing!
*/
ALTER DATABASE ERP_Demo SET QUERY_STORE CLEAR;
GO
