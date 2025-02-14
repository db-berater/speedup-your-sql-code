/*
	============================================================================
	File:		03 - scenario 04 - optimizatino dbo.total_orders.sql

	Summary:	The user defined function dbo.total_orders is using a
				table variable which causes IO on tempdb!

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

CREATE OR ALTER FUNCTION webshop.total_orders(@o_custkey BIGINT, @o_orderyear INT)
RETURNS INT
AS
BEGIN
	DECLARE	@return_value	INT;

	/*
		COUNT_BIG		=	we don't need to convert to INT
		DATEFROMPARTS	=	instead of YEAR the function DATEFROMPARTS
							makes the attribute (index) sargable!
	*/
	SELECT	@return_value = COUNT_BIG(*)
	FROM	webshop.orders
	WHERE	o_custkey = @o_custkey
			AND o_orderdate >= DATEFROMPARTS(@o_orderyear, 1, 1)
			AND o_orderdate < DATEFROMPARTS(@o_orderyear + 1, 1, 1)

	RETURN	ISNULL(@return_value, 0);
END
GO

/*
	Remove all lineitems and orders from the webshop table
*/
DELETE	webshop.lineitems WITH (TABLOCK);
DELETE	webshop.orders WITH (TABLOCK);
GO

/*
	Let's create an index for the evaluation of the number of orders by customer
*/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'webshop.orders', N'U') AND name = N'nix_webshop_orders_o_custkey_o_orderdate')
	CREATE NONCLUSTERED INDEX nix_webshop_orders_o_custkey_o_orderdate
	ON webshop.orders
	(
		o_custkey,
		o_orderdate
	)
	WITH
	(
		DATA_COMPRESSION = PAGE,
		SORT_IN_TEMPDB = ON
	);
GO

ALTER DATABASE ERP_Demo SET QUERY_STORE CLEAR;
GO