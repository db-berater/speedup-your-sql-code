/*
	============================================================================
	File:		02 - scenario 05 - optimization 01.sql

	Problem / Description:

	The first optimization will prevent recompilations when the temporary table
	object does not have an meta data change outside of the table definition!

	This procedure is called >100.000 / hr and is causing lots of CPU and
	IO overload.

				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Accelerate your SQL Code"

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
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

USE ERP_Demo;
GO

EXEC sp_create_indexes_customers;
GO

/* Create all necessary indexes on the tables! */
CREATE OR ALTER PROCEDURE dbo.proc_recompile
AS
BEGIN
    SET NOCOUNT ON;
 
	/* Create a temporary table for the storage of data */
    CREATE TABLE #x (c_custkey BIGINT NOT NULL PRIMARY KEY CLUSTERED);
     
    INSERT INTO #x (c_custkey)
    SELECT TOP (10) c_custkey FROM dbo.customers;
 
    /* Do the rest of the stuff */
    SELECT * FROM #x
    WHERE   c_custkey <= 10;
END
GO