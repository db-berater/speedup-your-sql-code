/*
	============================================================================
	File:		0083 - scenario 04 - optimizing dbo.insert_order_record.sql

	Summary:	The stored proc has two problems:
				- there is an unnecessary output which does not help with the
					insert statement!

				- the EXCEPT clause in the statement can lead to un unstable plan
					if statistics are not updated!

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
	Let's create stored procedures for a better handling / demonstration of the process
	each stord procedure will cover one event (INSERT, UPDATE, DELETE)
*/
CREATE OR ALTER PROCEDURE webshop.insert_order_record
	@c_custkey		BIGINT,
	@num_records	INT
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	;WITH d
	AS
	(
		SELECT	CAST(GETDATE() AS DATE)	AS	o_orderdate,
				o_orderkey,
				o_custkey,
				o_orderpriority,
				o_shippriority,
				o_clerk,
				o_orderstatus,
				o_totalprice,
				o_comment
		FROM	dbo.orders
		WHERE	o_custkey = @c_custkey

		EXCEPT

		SELECT	CAST(GETDATE() AS DATE)	AS	o_orderdate,
				o_orderkey,
				o_custkey,
				o_orderpriority,
				o_shippriority,
				o_clerk,
				o_orderstatus,
				o_totalprice,
				o_comment
		FROM	webshop.orders
		WHERE	o_custkey = @c_custkey
	)
	INSERT INTO webshop.orders
	(o_orderdate, o_orderkey, o_custkey, o_orderpriority, o_shippriority, o_clerk, o_orderstatus, o_totalprice, o_comment)
	SELECT	TOP (@num_records)
	d.o_orderdate, d.o_orderkey, d.o_custkey, d.o_orderpriority, d.o_shippriority, d.o_clerk, d.o_orderstatus, d.o_totalprice, d.o_comment
	FROM d;

	/* unnecessary output removed */
END
GO

/* Truncate webshop.orders and clear the Query Store */
TRUNCATE TABLE webshop.orders;
ALTER DATABASE ERP_Demo SET QUERY_STORE CLEAR;
GO


CREATE OR ALTER PROCEDURE webshop.insert_order_record
	@c_custkey		BIGINT,
	@num_records	INT
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	INSERT INTO webshop.orders
	(o_orderdate, o_orderkey, o_custkey, o_orderpriority, o_shippriority, o_clerk, o_orderstatus, o_totalprice, o_comment)
	SELECT	TOP (@num_records)
			o_orderdate,
			o_orderkey,
			o_custkey,
			o_orderpriority,
			o_shippriority,
			o_clerk,
			o_orderstatus,
			o_totalprice,
			o_comment
	FROM	dbo.orders AS o
	WHERE	o_custkey = @c_custkey
			AND NOT EXISTS
			(
				SELECT	o_orderkey,
						o_custkey,
						o_orderpriority,
						o_shippriority,
						o_clerk,
						o_orderstatus,
						o_totalprice,
						o_comment
				FROM	webshop.orders AS wo
				WHERE	wo.o_custkey = o.o_custkey
						AND wo.o_orderkey = o.o_orderkey
			);
END
GO

TRUNCATE TABLE webshop.orders;
ALTER DATABASE ERP_Demo SET QUERY_STORE CLEAR;
GO
