/*
	============================================================================
	File:		02 - scenario 01 - verify function.sql

	Summary:	This script shows a few examples how the UDF will be implemented.
				Follow the execution plan to see, how the queries are processed.
				
				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Workshop - Making Bad Codes better"

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

/* Test of user definied function with different customers */
SELECT	c.c_custkey,
        c.c_mktsegment,
        c.c_nationkey,
        c.c_name,
		ccc.num_of_orders,
		ccc.classification
FROM	dbo.customers AS c
		CROSS APPLY dbo.calculate_customer_category(c.c_custkey, 2019, 0) AS ccc
WHERE	c.c_custkey = 1483396;	/* A-customer */
GO

SELECT	c.c_custkey,
        c.c_mktsegment,
        c.c_nationkey,
        c.c_name,
		ccc.num_of_orders,
		ccc.classification
FROM	dbo.customers AS c
		CROSS APPLY dbo.calculate_customer_category(c.c_custkey, 2019, 0) AS ccc
WHERE	c.c_custkey = 746111;		/* B-customer */
GO

SELECT	c.c_custkey,
        c.c_mktsegment,
        c.c_nationkey,
        c.c_name,
		ccc.num_of_orders,
		ccc.classification
FROM	dbo.customers AS c
		CROSS APPLY dbo.calculate_customer_category(c.c_custkey, 2019, 0) AS ccc
WHERE	c.c_custkey = 149134;		/* C-customer */
GO

SELECT	c.c_custkey,
        c.c_mktsegment,
        c.c_nationkey,
        c.c_name,
		ccc.num_of_orders,
		ccc.classification
FROM	dbo.customers AS c
		CROSS APPLY dbo.calculate_customer_category(c.c_custkey, 2019, 0) AS ccc
WHERE	c.c_custkey = 696764;		/* D-customer */
GO

SELECT	c.c_custkey,
        c.c_mktsegment,
        c.c_nationkey,
        c.c_name,
		ccc.num_of_orders,
		ccc.classification
FROM	dbo.customers AS c
		CROSS APPLY dbo.calculate_customer_category(c.c_custkey, 2019, 0) AS ccc
WHERE	c.c_custkey = 10;		/* Z-customer */
GO