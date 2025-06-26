/*
	============================================================================
	File:		02 - SQL Anti Paterns - High CPU.sql

	Description:

	This script demonstrates some typical SQL Antipatterns which should be avoid.

	Summary:	This demo shows the high usage of CPU concerning the usage of
				anti pattern design of the query.
				
				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Workshop - Spped Up Your SQL Code"

	Date:		October 2024
	Revion:		January 2025

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
SET STATISTICS IO, TIME ON;
GO

USE ERP_Demo;
GO


/* Now we create a stored procedure which access the data by the c_custkey */
CREATE OR ALTER PROCEDURE demo.get_customer_by_c_custkey
	@c_custkey BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	SELECT	c_custkey,
            c_mktsegment,
            c_nationkey,
            c_name,
            c_address,
            c_phone,
            c_acctbal,
            c_comment
	FROM	demo.customers
	WHERE	c_custkey = @c_custkey;
END
GO

ALTER DATABASE ERP_DEMO SET QUERY_STORE CLEAR;
GO

/*
	One test run to check the execution plan for the stored procedure
*/
EXEC demo.get_customer_by_c_custkey @c_custkey = 10;
GO
