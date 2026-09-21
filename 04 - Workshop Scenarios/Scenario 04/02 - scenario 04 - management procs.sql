/*
	============================================================================
	File:		02 - scenario 04 - management procs.sql

	Summary:	This script creates the wrapper procedures for the simulation of
				the daily web shop activities

				- wrapper stored proc for the tests

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

RAISERROR ('Creating stored procedure webshop.insert_order_record...', 0, 1) WITH NOWAIT;
GO

CREATE OR ALTER PROCEDURE webshop.insert_order_record
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	/* Let's grab a random o_orderkey and insert the data into the webshop */
	DECLARE	@o_orderkey	BIGINT = 1 + ABS(CHECKSUM(NEWID())) % 27725897;

	IF NOT EXISTS (SELECT * FROM webshop.orders WHERE o_orderkey = @o_orderkey)
	BEGIN
		BEGIN TRY
			INSERT INTO webshop.orders
			(
				o_orderdate, o_orderkey, o_custkey, o_orderpriority, o_shippriority,
				o_clerk, o_orderstatus, o_totalprice, o_comment, o_storekey
			)
			SELECT	o.o_orderdate, o.o_orderkey, o.o_custkey, o.o_orderpriority, o.o_shippriority,
					o.o_clerk, 'N', o.o_totalprice, o.o_comment, o.o_storekey
			FROM		dbo.orders AS o
					LEFT JOIN webshop.orders AS t
					ON (o.o_orderkey = t.o_orderkey)
			WHERE	o.o_orderkey = @o_orderkey
					AND t.o_orderkey IS NULL;

			INSERT INTO webshop.lineitems
			SELECT	[l_orderkey],
					[l_linenumber],
					[l_shipdate],
					[l_discount],
					[l_extendedprice],
					[l_suppkey],
					[l_quantity],
					[l_returnflag],
					[l_partkey],
					[l_linestatus],
					[l_tax],
					[l_commitdate],
					[l_receiptdate],
					[l_shipmode],
					[l_shipinstruct],
					[l_comment]
			FROM		dbo.lineitems
			WHERE	l_orderkey = @o_orderkey
					AND EXISTS
					(
						SELECT	*
						FROM		webshop.orders AS o
						WHERE	o.o_orderkey = @o_orderkey
					);
		END TRY
		BEGIN CATCH
			INSERT INTO webshop.error_manager
			(error_number, error_message, session_id, o_orderkey)
			SELECT	ERROR_NUMBER(),
					ERROR_MESSAGE(),
					@@SPID,
					@o_orderkey;
		END CATCH
	END
END
GO

RAISERROR ('Creating stored procedure webshop.update_order_record...', 0, 1) WITH NOWAIT;
GO

CREATE OR ALTER PROCEDURE webshop.update_order_record
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE	@num_records		INT	=	(SELECT COUNT_BIG(*) FROM webshop.orders);
	DECLARE	@o_orderkey		BIGINT = (1 + ABS(CHECKSUM(NEWID())) % @num_records);
	DECLARE	@to_custkey		BIGINT = (1 + ABS(CHECKSUM(NEWID())) % @num_records);

	BEGIN TRY
		UPDATE	webshop.orders
		SET		o_custkey = @to_custkey,
				o_orderstatus = 'M'
		WHERE	o_orderkey = @o_orderkey;
	END TRY
	BEGIN CATCH
		INSERT INTO webshop.error_manager
		(error_number, error_message, session_id, o_orderkey)
		SELECT	ERROR_NUMBER(),
				ERROR_MESSAGE(),
				@@SPID,
				@o_orderkey;
	END CATCH
END
GO

RAISERROR ('Creating stored procedure webshop.delete_order_record...', 0, 1) WITH NOWAIT;
GO

CREATE OR ALTER PROCEDURE [webshop].[delete_order_record]
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE	@max_orders	BIGINT	= (SELECT COUNT_BIG(*) FROM webshop.orders);
	DECLARE	@o_orderkey BIGINT = 1 + ABS(CHECKSUM(NEWID())) % 27725897;

	BEGIN TRY
		DELETE	webshop.lineitems
		WHERE	l_orderkey = @o_orderkey;

		DELETE	webshop.orders
		WHERE	o_orderkey = @o_orderkey;
	END TRY
	BEGIN CATCH
		INSERT INTO webshop.error_manager
		(error_number, error_message, session_id, o_orderkey)
		SELECT	ERROR_NUMBER(),
				ERROR_MESSAGE(),
				@@SPID,
				@o_orderkey;
	END CATCH
END
GO

/* Reset of the query store */
ALTER DATABASE ERP_Demo SET QUERY_STORE CLEAR;
GO
