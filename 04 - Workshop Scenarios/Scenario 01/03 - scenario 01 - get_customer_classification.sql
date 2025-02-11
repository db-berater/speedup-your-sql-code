/*
	============================================================================
	File:		03 - scenario 01 - sp_stress_test.sql

	Summary:	This script creates a stored procedure which should be run by
				- ostress OR
				- SQLQueryStress

				The procedure will simulate a typical workload which should be
				executed ~100.000 times by 50 simultanious processes
				
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
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

USE ERP_Demo;
GO

CREATE OR ALTER PROCEDURE dbo.get_customer_classification
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE	@c_custkey	BIGINT = (RAND() * 1600000) + 1;

	SELECT	c.c_custkey,
			c.c_mktsegment,
			c.c_nationkey,
			c.c_name,
			ccc.num_of_orders,
			ccc.classification
	FROM	dbo.customers AS c
			CROSS APPLY dbo.calculate_customer_category(c.c_custkey, 2019, 0) AS ccc
	WHERE	c.c_custkey = @c_custkey;
END
GO

/* Test */
EXEC dbo.get_customer_classification;
GO