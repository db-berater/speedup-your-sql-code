/*
	============================================================================
	File:		08 - scenario 01 - clean the environment.sql

	Summary:	This script removes all custom objects from the database which 
				have been used for the demos!

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

DROP PROCEDURE IF EXISTS dbo.get_customer_classification;
DROP FUNCTION IF EXISTS dbo.calculate_customer_category;
GO

/* Remove all indexes */
EXEC dbo.sp_drop_foreign_keys @table_name = N'ALL';

EXEC dbo.sp_drop_indexes @table_name = N'dbo.orders',		@check_only = 0;
EXEC dbo.sp_drop_indexes @table_name = N'dbo.customers',	@check_only = 0;
EXEC dbo.sp_drop_indexes @table_name = N'dbo.nations',		@check_only = 0;
GO
