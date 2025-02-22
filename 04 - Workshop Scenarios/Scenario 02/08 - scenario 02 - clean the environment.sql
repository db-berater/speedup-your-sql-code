/*
	============================================================================
	File:		08 - scenario 02 - clean the environment.sql

	Summary:	This script removes all custom objects from the database which 
				have been used for the demos!

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
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

USE ERP_Demo;
GO

EXEC sp_drop_foreign_keys @table_name = N'ALL';
EXEC sp_drop_indexes @table_name = N'ALL';
EXEC sp_drop_statistics @table_name = N'ALL';
GO

ALTER DATABASE ERP_Demo SET READ_COMMITTED_SNAPSHOT OFF WITH ROLLBACK IMMEDIATE;
GO

/* Remove partitioning infrastructure */
DROP TABLE IF EXISTS dbo.jobqueue;
DROP TABLE IF EXISTS dbo.used_partition;
DROP TABLE IF EXISTS dbo.session_values;
GO

IF EXISTS (SELECT * FROM sys.partition_schemes WHERE name = N'ps_session_divisor')
	DROP PARTITION SCHEME ps_session_divisor;
GO

IF EXISTS (SELECT * FROM sys.partition_functions WHERE name = N'pf_session_divisor')
	DROP PARTITION FUNCTION pf_session_divisor;
GO

DROP TABLE IF EXISTS dbo.runtime_statistics;
DROP PROCEDURE IF EXISTS dbo.jobqueue_delete;
DROP TABLE IF EXISTS dbo.jobqueue;
DROP TYPE IF EXISTS dbo.helpertable;
GO

ALTER DATABASE ERP_Demo SET QUERY_STORE CLEAR;
GO
