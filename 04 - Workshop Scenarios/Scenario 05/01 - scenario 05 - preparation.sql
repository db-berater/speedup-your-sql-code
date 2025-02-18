/*
	============================================================================
	File:		01 - scenario 05 - preparation.sql

	Problem / Description:

	The management board wants to have on a daily basis a report by region for
	the last three orders from any customer placed in a given time range.

	The development team created a stored procedure with two parameters:
		@date_from	DATE
		@date_to	DATE

	For that time range an analysis about the last 3 orders of each customer
	was made.

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

/* Create all necessary indexes on the tables! */
EXEC dbo.sp_create_indexes_regions;
GO

EXEC dbo.sp_create_indexes_nations;
GO

EXEC dbo.sp_create_indexes_customers;
GO

EXEC dbo.sp_create_indexes_orders @column_list = N'o_orderkey';
GO

EXEC dbo.sp_create_indexes_lineitems;
GO
