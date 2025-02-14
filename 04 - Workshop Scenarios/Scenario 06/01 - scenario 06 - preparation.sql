/*
	============================================================================
	File:		06 - scenario 01 - preparation.sql

	Problemdescription:

	The management board wants to have on a daily basis a report by region for
	the last three orders from any customer placed in a given time range.

	The development team created a stored procedure with two paramters:
		@date_from	DATE
		@date_to	DATE

	For that time range an analysis about the last 3 orders of each customer
	was made.

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

/* Create all necessary indexes on the tables! */
EXEC dbo.sp_create_indexes_customers;
GO

EXEC dbo.sp_create_indexes_orders;
GO

EXEC dbo.sp_create_indexes_lineitems;
GO

EXEC dbo.sp_create_indexes_nations;
GO

EXEC dbo.sp_create_indexes_regions;
GO