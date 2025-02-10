/*
	============================================================================
	File:		03 - scenario 06 - avoid recompiles.sql

	Summary:	Before we start with the optimization 1 we must understand the
				problem with executions of DDL after a temporary object has been
				created.

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

/*
	Let's create a stored procedure with a typical dev implementation of
	temporary objects
*/
CREATE OR ALTER PROCEDURE dbo.proc_recompile
AS
BEGIN
	SET NOCOUNT ON;

	CREATE TABLE #x (c_custkey BIGINT NOT NULL);
	ALTER TABLE #x ADD PRIMARY KEY CLUSTERED (c_custkey);
	
	INSERT INTO #x (c_custkey)
	SELECT TOP (1) c_custkey FROM dbo.customers;

	SELECT * FROM #x
	WHERE	c_custkey <= 0;
END
GO

/*
	Implement the extended event "XEvent - procedure recompiles.sql"
	NOTE:
	- the script must run in SQLCMD mode!
	- Change the value of the variable session_id to the current SPID!

	Open "Watch Live Data" from the new extended event
*/
EXEC proc_recompile;
GO

/*
	Load the template "Workshop - scenario 06.json in Windows Admin Center
	Load the template "Workshop - scenario 06 - recompile demo.json" in SQLQueryStress
	Execute the command(s) in SQLQueryStress and watch the metrics in Windows Admin Center
*/
CREATE OR ALTER PROCEDURE dbo.proc_recompile
AS
BEGIN
	SET NOCOUNT ON;

	CREATE TABLE #x (c_custkey BIGINT NOT NULL PRIMARY KEY CLUSTERED);
	
	INSERT INTO #x (c_custkey)
	SELECT TOP (1) c_custkey FROM dbo.customers;

	SELECT * FROM #x
	WHERE	c_custkey <= 0;
END
GO

EXEC proc_recompile;
GO

/*
	Temporary Tables have statistics which must be updated.
	That causes additional recompiles!
*/
CREATE OR ALTER PROCEDURE dbo.proc_recompile
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @T TABLE (c_custkey BIGINT NOT NULL PRIMARY KEY CLUSTERED);
	
	INSERT INTO @T (c_custkey)
	SELECT TOP (1) c_custkey FROM dbo.customers;

	SELECT * FROM @T
	WHERE	c_custkey <= 0;
END
GO

EXEC dbo.proc_recompile;
GO

/* Clear the enviroment */
IF EXISTS (SELECT * FROM sys.dm_xe_sessions WHERE name = N'Track procedure recompiles')
BEGIN
	RAISERROR (N'Dropping XEvent-Session: [Track procedure recompiles]', 0, 1) WITH NOWAIT;
	DROP EVENT SESSION [Track procedure recompiles] ON SERVER;
END
GO
