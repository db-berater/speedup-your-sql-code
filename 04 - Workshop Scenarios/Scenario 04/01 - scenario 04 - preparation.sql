/*
	============================================================================
	File:		01 - scenario 04 - preparation.sql

	Summary:	A customer's webshop runs without any complaints from customers during "normal" days.
				As soon as special sales promotions are started (e.g. Black Friday, fire sale, ...),
				the system's performance collapses and customers complain that it takes
				a long time for an order to be saved in the system.
	
				This script creates the environment for the scenario.
				- new table webshop.customers
				- new table webshop.orders
				- new function for the calculation of num of orders
				- triggers for
					- INSERT
					- UPDATE
					- DELETE

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

SET NOCOUNT ON;
GO

EXEC dbo.sp_create_indexes_customers;
EXEC dbo.sp_create_indexes_orders @column_list = N'o_orderkey, o_orderdate, o_custkey';
EXEC dbo.sp_create_indexes_lineitems;
GO

/* let's create the required tables first */
DROP TABLE IF EXISTS webshop.lineitems;
DROP TABLE IF EXISTS webshop.orders;
DROP TABLE IF EXISTS webshop.customers;
GO

/* let's create the new schema if it not exists */
IF SCHEMA_ID(N'webshop') IS NULL
	EXEC sp_executesql N'CREATE SCHEMA [webshop] AUTHORIZATION dbo;';
GO

/* create the table webshop.customers with 1.6 Mio customers */
RAISERROR ('Creating table webshop.customers...', 0, 1) WITH NOWAIT;
SELECT	[c_custkey],
		[c_mktsegment],
		[c_nationkey],
		[c_name],
		[c_address],
		[c_phone],
		[c_acctbal],
		[c_comment],
		CAST(0 AS INT)	AS [num_orders]
INTO	webshop.customers
FROM	dbo.customers;
GO

ALTER TABLE webshop.customers
ADD CONSTRAINT pk_webshop_customers
PRIMARY KEY CLUSTERED (c_custkey)
WITH (SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE);
GO

/* create the empty table webshop.orders with no records */
RAISERROR ('Creating table webshop.orders...', 0, 1) WITH NOWAIT;
SELECT	[o_orderdate],
		[o_orderkey],
		[o_custkey],
		[o_orderpriority],
		[o_shippriority],
		[o_clerk],
		[o_orderstatus],
		[o_totalprice],
		[o_comment],
		[o_storekey]
INTO	webshop.orders
FROM	dbo.orders
WHERE	1 = 0;
GO

ALTER TABLE webshop.orders
ADD CONSTRAINT pk_webshop_orders PRIMARY KEY CLUSTERED (o_orderkey)
WITH (SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE);
GO

CREATE NONCLUSTERED INDEX nix_webshop_orders_o_orderdate
ON webshop.orders (o_orderdate)
WITH (SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE);
GO

CREATE NONCLUSTERED INDEX nix_webwhop_orders_o_custkey
ON webshop.orders (o_custkey)
WITH (SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE);
GO

ALTER TABLE webshop.orders
ADD CONSTRAINT fk_webshop_customers FOREIGN KEY (o_custkey)
REFERENCES webshop.customers (c_custkey);
GO

RAISERROR ('Creating table webshop.lineitems...', 0, 1) WITH NOWAIT;
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
INTO	webshop.lineitems
FROM	dbo.lineitems
WHERE	1 = 0;
GO

ALTER TABLE webshop.lineitems
ADD CONSTRAINT pk_webshop_lineitems PRIMARY KEY CLUSTERED
(
	l_orderkey,
	l_linenumber
)
WITH (SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE);
GO

ALTER TABLE webshop.lineitems
ADD CONSTRAINT fk_webshop_orders FOREIGN KEY (l_orderkey)
REFERENCES webshop.orders (o_orderkey);
GO

/* A function is needed for the evaluation of the total num of orders for a customer */
RAISERROR ('Creating function webshop.total_orders...', 0, 1) WITH NOWAIT;
GO
CREATE OR ALTER FUNCTION webshop.total_orders(@o_custkey BIGINT, @o_orderyear INT)
RETURNS INT
AS
BEGIN
	DECLARE	@return_value	INT;
	DECLARE	@t TABLE (o_orderkey BIGINT);

	INSERT INTO @t (o_orderkey)
	SELECT	o_orderkey
	FROM	webshop.orders
	WHERE	o_custkey = @o_custkey
			AND YEAR(o_orderdate) = @o_orderyear;

	SELECT	@return_value = COUNT(*)
	FROM	@t;

	RETURN	ISNULL(@return_value, 0);
END
GO

/*
	No we must react on events in the webshop.orders table

	- when new record(s) are coming in we must update the webshop.customers table
	- if the order will be assigned to another customer we must update
		both customers +n/-n
	- if the order will be deleted we must update the webshop, customers table, too
*/
RAISERROR ('Creating triggers on webshop.orders...', 0, 1) WITH NOWAIT;
GO

CREATE OR ALTER TRIGGER webshop.trg_orders_insert
ON webshop.orders
FOR INSERT
AS
BEGIN
	/* How many orders does a specific customer have? */
	DECLARE	@actual_num_of_orders	INT;

	DECLARE	@o_custkey				BIGINT;
	DECLARE	@o_orderyear			INT;

	/* Now let's loop through the new data and add the orders to the customers */
	DECLARE	c CURSOR LOCAL FAST_FORWARD READ_ONLY
	FOR
		SELECT	o_custkey,
				YEAR(o_orderdate)
		FROM	inserted;

	OPEN	c;

	FETCH NEXT FROM c INTO @o_custkey, @o_orderyear;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET	@actual_num_of_orders = webshop.total_orders(@o_custkey, @o_orderyear);

		UPDATE	webshop.customers
		SET		num_orders = @actual_num_of_orders
		WHERE	c_custkey = @o_custkey;

		FETCH NEXT FROM c INTO @o_custkey, @o_orderyear;
	END

	CLOSE c;
	DEALLOCATE c;
END
GO

CREATE OR ALTER TRIGGER webshop.trg_orders_update
ON webshop.orders
FOR UPDATE
AS
BEGIN
	/* How many orders does a specific customer have? */
	DECLARE	@actual_num_of_orders	INT;

	DECLARE	@new_o_custkey			BIGINT;
	DECLARE	@old_o_custkey			BIGINT
	DECLARE	@new_o_orderyear		INT;
	DECLARE	@old_o_orderyear		INT;

	/* Now let's loop through the new data and add the orders to the customers */
	DECLARE	c CURSOR LOCAL FAST_FORWARD READ_ONLY
	FOR
		SELECT	i.o_custkey				AS	new_o_custkey,
				YEAR(i.o_orderdate)		AS	new_o_orderyear,
				i.o_orderstatus			AS	new_o_orderstatus,
				d.o_custkey				AS	old_o_custkey,
				YEAR(d.o_orderdate)		AS	old_o_orderyear,
				d.o_orderstatus			AS	old_o_orderstatus
		FROM	inserted AS i
				INNER JOIN deleted AS d
				ON (i.o_orderkey = d.o_orderkey);

	OPEN c;

	FETCH NEXT FROM c INTO @new_o_custkey, @new_o_orderyear, @old_o_custkey, @old_o_orderyear;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @new_o_custkey <> @old_o_custkey
		BEGIN
			SET	@actual_num_of_orders = webshop.total_orders(@new_o_custkey, @new_o_orderyear);
		
			UPDATE	webshop.customers
			SET		num_orders = @actual_num_of_orders
			WHERE	c_custkey = @new_o_custkey;

			SET	@actual_num_of_orders = webshop.total_orders(@old_o_custkey, @old_o_orderyear);
		
			UPDATE	webshop.customers
			SET		num_orders = @actual_num_of_orders
			WHERE	c_custkey = @old_o_custkey;
		END

		FETCH NEXT FROM c INTO @new_o_custkey, @new_o_orderyear, @old_o_custkey, @old_o_orderyear;
	END

	CLOSE c;
	DEALLOCATE c;
END
GO

/* DELETE Trigger */
CREATE OR ALTER TRIGGER webshop.trg_orders_deleted
ON webshop.orders
FOR DELETE
AS
BEGIN
	/* How many orders does a specific customer have? */
	DECLARE	@actual_num_of_orders	INT;

	DECLARE	@o_custkey				BIGINT;
	DECLARE	@o_orderyear			INT;

	/* Now let's loop through the new data and add the orders to the customers */
	DECLARE	c CURSOR LOCAL FAST_FORWARD READ_ONLY
	FOR
		SELECT	o_custkey,
				YEAR(o_orderdate)
		FROM	deleted;

	OPEN	c;

	FETCH NEXT FROM c INTO @o_custkey, @o_orderyear;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET	@actual_num_of_orders = webshop.total_orders(@o_custkey, @o_orderyear);
		
		UPDATE	webshop.customers
		SET		num_orders = @actual_num_of_orders
		WHERE	c_custkey = @o_custkey;

		FETCH NEXT FROM c INTO @o_custkey, @o_orderyear;
	END

	CLOSE c;
	DEALLOCATE c;
END
GO