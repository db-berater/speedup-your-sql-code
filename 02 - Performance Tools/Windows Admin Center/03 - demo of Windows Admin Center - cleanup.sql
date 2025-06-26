/*
	============================================================================
	File:		03 - demo of Windows Admin Center - cleanup.sql

	Summary:	This script walks through all optimization phases of the query.
				All optimizations can be seen in the Windows Admin Center!
				
				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Workshop - Making Bad Codes better"

	Date:		October 2024
	Revion:		November 2024

	SQL Server Version: >= 2016
	============================================================================
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

USE ERP_Demo;
GO

/*
	Clean the environment before we are starting the journey.
*/
EXEC dbo.sp_drop_foreign_keys
	@table_name = N'ALL';
GO

EXEC dbo.sp_drop_indexes
	@table_name = N'dbo.nations',
    @check_only = 0;
GO

EXEC dbo.sp_drop_indexes
	@table_name = N'dbo.regions',
    @check_only = 0;
GO

EXEC dbo.sp_drop_indexes
	@table_name = N'dbo.customers',
    @check_only = 0;
GO

DROP PROCEDURE IF EXISTS dbo.get_customer_info;
GO

EXEC dbo.sp_clear_query_store;
GO