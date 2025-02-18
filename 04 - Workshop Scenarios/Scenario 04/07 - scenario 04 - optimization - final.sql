/*
	============================================================================
	File:		07 - scenario 04 - optimization - final.sql

	Summary:	The problems cannot be solved sufficently by optimizing the triggers.
				Instead of triggers the implementation of a user definied function
				seems to be the better way.

				It is not better when we query the data but will speed up the 
				DML processes.

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

/*
	Best practice is to avoid triggers when writing performance is essential
	Instead of triggers it is recommended to use calculated attributes.
	If the calculated properties are accessing remote tables it is mandatory
	to have good indexes on the tables covering the use case!
*/

/*
	Drop the column num_orders from webshop.customers
*/
IF EXISTS (SELECT * FROM sys.columns WHERE name = N'num_orders' AND object_id = OBJECT_ID(N'webshop.customers', N'U'))
BEGIN TRY
	ALTER TABLE webshop.customers
	DROP COLUMN num_orders;
END TRY
BEGIN CATCH
	RETURN;
END CATCH
GO


/*
	Step 1:	Create a Scalar User Defined Function to evaluate the number of orders
*/
CREATE OR ALTER FUNCTION webshop.num_orders
(
	@c_custkey		BIGINT,
	@o_orderdate	INT
)
RETURNS INT
AS
BEGIN
	DECLARE	@return_value	INT;

	SELECT	@return_value = COUNT_BIG(*)
	FROM	webshop.orders
	WHERE	o_custkey = @c_custkey
			AND o_orderdate = DATEFROMPARTS(@o_orderdate, 1, 1)
			AND o_orderdate <= DATEFROMPARTS(@o_orderdate, 12, 31)

	RETURN	ISNULL(@return_value, 0)
END
GO


BEGIN TRY
	ALTER TABLE webshop.customers
	ADD [num_orders] AS webshop.num_orders (c_custkey, 2023)
END TRY
BEGIN CATCH
	RETURN;
END CATCH
GO

/*
	Now we can deactivate all triggers on webshop.orders
*/
DECLARE	@sql_stmt	NVARCHAR(4000);
DECLARE	c CURSOR LOCAL FORWARD_ONLY READ_ONLY
FOR
	SELECT	N'DISABLE TRIGGER ' + QUOTENAME(name) + N' ON webshop.orders;'
	FROM	sys.triggers
	WHERE	parent_id = OBJECT_ID(N'webshop.orders', N'U')
			AND is_disabled = 0;

OPEN c;

FETCH NEXT FROM c INTO @sql_stmt;
WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC sp_executesql @sql_stmt;
	FETCH NEXT FROM c INTO @sql_stmt;
END

CLOSE c;
DEALLOCATE c;
GO

SELECT * FROM webshop.customers
WHERE	c_custkey IN (SELECT o_custkey FROM webshop.orders)
AND		num_orders > 0;
GO