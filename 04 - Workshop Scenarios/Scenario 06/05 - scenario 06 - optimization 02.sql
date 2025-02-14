/*
	============================================================================
	File:		05 - scenario 06 - optimization 02.sql

	Summary:	Additional indexes may help to optimize the process.
				Check the Query Store of ERP_Demo to identify bad or 
				non useful index usage.

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

/*
	The first index will cover o_custkey and o_orderdate to avoid key lookups
*/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.orders', N'U') AND name = N'nix_orders_o_custkey_o_orderdate')
	CREATE NONCLUSTERED INDEX nix_orders_o_custkey_o_orderdate
	ON dbo.orders (o_custkey, o_orderdate)
	WITH (SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE, ONLINE = ON);
	GO

/*
	The second index is for the last improvement!
	Do not implement it before the optimization phase 06!
*/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.orders', N'U') AND name = N'nix_orders_o_o_orderdate_custkey')
	CREATE NONCLUSTERED INDEX nix_orders_o_orderdate_o_custkey
	ON dbo.orders (o_orderdate, o_custkey)
	WITH (SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE, ONLINE = ON);
	GO
