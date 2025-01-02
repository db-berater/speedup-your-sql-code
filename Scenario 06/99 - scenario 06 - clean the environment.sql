/*
	============================================================================
	File:		02 - scenario 06 - clean the environment.sql

	Summary:	drop all objects which have been created for scenario 06

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
USE ERP_Demo;
GO

/* Drop the extended event */
IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = N'Track procedure recompiles')
	DROP EVENT SESSION [Track procedure recompiles] ON SERVER;
	GO

/* Drop the demo stored proc for recompilations */
DROP PROCEDURE IF EXISTS dbo.proc_recompile;
GO

DROP PROCEDURE IF EXISTS dbo.get_statistics_per_time_range;
GO

EXEC sp_drop_indexes
	@table_name = N'dbo.regions',
	@check_only = 0;
GO

EXEC sp_drop_indexes
	@table_name = N'dbo.nations',
	@check_only = 0;
GO

EXEC sp_drop_indexes
	@table_name = N'dbo.orders',
	@check_only = 0;
GO

EXEC sp_drop_indexes
	@table_name = N'dbo.lineitems',
	@check_only = 0;
GO

EXEC sp_drop_indexes
	@table_name = N'dbo.customers',
	@check_only = 0;
GO
