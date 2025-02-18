/*
	============================================================================
	File:		02 - scenario 05 - optimization 02.sql

	Problem / Description:

	The final optimization will prevent recompiles due to stats updates by using
	table variables because they don't have statistics objects!

	This procedure is called >100.000 / hr and is causing lots of CPU and
	IO overload.

				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Accelerate your SQL Code"

	Date:		October 2024
	Revion:		February 2025

	SQL Server Version: >= 2016
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
    DECLARE @x TABLE (c_custkey BIGINT NOT NULL PRIMARY KEY CLUSTERED);
     
    INSERT INTO @x (c_custkey)
    SELECT TOP (10) c_custkey FROM dbo.customers;
 
    /* Do the rest of the stuff */
    SELECT * FROM @x
    WHERE   c_custkey <= 10;
END
GO