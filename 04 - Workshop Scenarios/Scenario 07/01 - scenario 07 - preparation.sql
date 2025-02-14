/*
	============================================================================
	File:		01 - scenario 07 - preparation.sql

	Problemdescription:

	The purchasing department needs a list of products sold and the manufacturer every morning.
	This list is used to make calculations to determine the quantity that needs to be ordered
	from each manufacturer for the next few days.

	Summary:	This script prepares tables in the database ERP_Demo
				
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

EXEC sp_create_indexes_orders;
GO

EXEC sp_create_indexes_lineitems;
GO

EXEC sp_create_indexes_suppliers;
GO

EXEC sp_create_indexes_parts;
GO

EXEC sp_create_indexes_partsuppliers;
GO