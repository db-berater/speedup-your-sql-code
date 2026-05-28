/*
	============================================================================
	File:		02 - demo of Query Store - optimization.sql

	Summary:	This script walks through all optimization phases of the query.
				All optimizations can be seen in the Query Store of the database!
				
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
USE ERP_Demo;
GO


/*
	After the first execution round we add an additional index
	on dbo.customers for better performance!
*/
EXEC dbo.sp_create_indexes_customers;
GO

/*
	After the second execution round we add an additional index
	on dbo.nations for better performance!
*/
EXEC dbo.sp_create_indexes_nations;
GO

/*
	After the third execution round we add an additional index
	on dbo.regions for better performance!
*/
EXEC dbo.sp_create_indexes_regions;
GO

/*
	After the third execution round we add an additional index
	on dbo.orders for better performance!
*/
EXEC dbo.sp_create_indexes_orders
	@column_list = N'o_orderkey, o_custkey';
GO

/*
	To exclude not necessary access to objects we create foreign key relations
	between the tables
*/
EXEC dbo.sp_create_foreign_keys
	@master_table = N'dbo.regions',
	@detail_table = N'dbo.nations';
GO

EXEC dbo.sp_create_foreign_keys
	@master_table = N'dbo.nations',
	@detail_table = N'dbo.customers';
GO

EXEC dbo.sp_create_foreign_keys
	@master_table = N'dbo.customers',
	@detail_table = N'dbo.orders';
GO
