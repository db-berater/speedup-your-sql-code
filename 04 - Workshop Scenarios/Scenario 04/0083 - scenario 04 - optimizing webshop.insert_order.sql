/*
	============================================================================
	File:		0083 - scenario 04 - optimizing webshop.insert_order.sql

	Summary:	The stored proc has one problems:
				It grabs a random customer by using a SORT over all rows in the
				table webshop.customers.
				The better way is to avoid the STOP Operator by using OFFSET instead
				of ordering by a random key value!

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
USE [ERP_Demo]
GO

/*
	These stored procedures are for the stress test scenarios only
	The functionality is primitive because it grabs a random customer_id
	and insert/update/delete an order.
*/
ALTER   PROCEDURE [webshop].[insert_order]
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	/* Grab one number for the position of the row in the table */
	DECLARE	@row_offset BIGINT = (RAND() * 1600000) + 1;

	/* Now we jump to that row and pick it up! */
	DECLARE	@c_custkey	BIGINT = (
									SELECT	c_custkey
									FROM	webshop.customers
									ORDER BY
											c_custkey
									OFFSET @row_offset ROWS FETCH NEXT 1 ROWS ONLY
								 );
	
	/* Insert an order for this customer */
	EXEC webshop.insert_order_record
		@c_custkey = @c_custkey,
	    @num_records = 1;
END
GO

/* Clean the webshop.orders table and the Query Store before we start a new test */
TRUNCATE TABLE webshop.orders;
GO

ALTER DATABASE ERP_Demo SET QUERY_STORE CLEAR;
GO