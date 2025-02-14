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

CREATE OR ALTER PROCEDURE webshop.insert_order_record
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	/* Let's grab a random o_orderkey and insert the data into the webshop */
	DECLARE	@o_orderkey	BIGINT = RAND() * 30000000 + 1

	IF NOT EXISTS (SELECT * FROM webshop.orders WHERE o_orderkey = @o_orderkey)
	BEGIN
		BEGIN TRANSACTION
			INSERT INTO webshop.orders
			(
				o_orderdate,
				o_orderkey,
				o_custkey,
				o_orderpriority,
				o_shippriority,
				o_clerk,
				o_orderstatus,
				o_totalprice,
				o_comment,
				o_storekey
			)
			SELECT	s.o_orderdate,
					s.o_orderkey,
					s.o_custkey,
					s.o_orderpriority,
					s.o_shippriority,
					s.o_clerk,
					'N'				AS	o_orderstatus,
					s.o_totalprice,
					s.o_comment,
					s.o_storekey
			FROM	dbo.orders AS s
					LEFT JOIN webshop.orders AS t
					ON
					(s.o_orderkey = t.o_orderkey)
			WHERE	s.o_orderkey = @o_orderkey
					AND t.o_orderkey IS NULL;

			INSERT INTO webshop.lineitems
			(
				[l_orderkey],
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
			)
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
			FROM	dbo.lineitems
			WHERE	l_orderkey = @o_orderkey;
		COMMIT TRANSACTION;
	END
END
GO