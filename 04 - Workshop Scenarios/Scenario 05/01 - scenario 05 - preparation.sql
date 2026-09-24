/*
	============================================================================
	File:		01 - scenario 05 - preparation.sql

	Problem / Description:

	The development team created a stored procedure for any evaluation.
	Due to performance issues they decided to work with temporary tables
	to store data for further steps.

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
    CREATE TABLE #x (c_custkey BIGINT NOT NULL);

	/* Add a primary key to the table */
	ALTER TABLE #x ADD PRIMARY KEY CLUSTERED (c_custkey);
     
    INSERT INTO #x (c_custkey)
    SELECT TOP (10) c_custkey FROM dbo.customers;
 
    /* Do the rest of the stuff */
    SELECT * FROM #x
    WHERE   c_custkey <= 10;
END
GO