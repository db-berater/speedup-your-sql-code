/*
	============================================================================
	File:		01 - scenario 01 - preparation.sql

	Problemdescription:

	The development team love to work with user defined functions (UDF).
	So they decided to create an UDF which calculates the status of any customer by year.
	The calculation is a simple math:

	+ A customer: More or equal than 20 orders in a given year
	+ B customer: 10 - 19 orders for a given year
	+ C customer: 05 - 09 orders for a given year
	+ D customer: 01 - 04 orders for a given year
	+ Z customer: no orders for a given year

	Summary:	This script prepares tables in the database ERP_Demo
				for the chapter
				- bad code - usage of functions
				
				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Workshop - Making Bad Codes better"

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
	Make sure we don't have any objects from previous exercises
*/


/* Create all necessary indexes on the tables! */
EXEC dbo.sp_create_indexes_customers;
EXEC dbo.sp_create_indexes_orders @column_list = N'o_orderkey, @o_orderdate';
GO

EXEC dbo.sp_create_foreign_keys
	@master_table = 'dbo.customers',
    @detail_table = N'dbo.orders';
GO

/*
	We are making sure that Query Store is activated!
*/
EXEC dbo.sp_activate_query_store;
GO