/*
	============================================================================
	File:		0081 - scenario 04 - preparation of environment.sql

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

				- wrapper stored proc for the tests

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

SET NOCOUNT ON;
GO

EXEC dbo.sp_create_indexes_customers;
EXEC dbo.sp_create_indexes_orders;
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
SELECT	*
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

/*
	Let's create stored procedures for a better handling / demonstration of the process
	each stord procedure will cover one event (INSERT, UPDATE, DELETE)
*/
RAISERROR ('Creating stored procedures for webshop.orders...', 0, 1) WITH NOWAIT;
GO

CREATE OR ALTER PROCEDURE webshop.insert_order_record
	@c_custkey		BIGINT,
	@num_records	INT	=	1
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	BEGIN TRANSACTION
		;WITH d
		AS
		(
			SELECT	CAST(GETDATE() AS DATE)	AS	o_orderdate,
					o_orderkey,
					o_custkey,
					o_orderpriority,
					o_shippriority,
					o_clerk,
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
					o_totalprice,
					o_comment
			FROM	webshop.orders
			WHERE	o_custkey = @c_custkey
		)
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
			o_comment
		)
		SELECT	TOP (@num_records)
				d.o_orderdate,
				d.o_orderkey,
				d.o_custkey,
				d.o_orderpriority,
				d.o_shippriority,
				d.o_clerk,
				'N'				AS	o_orderstatus,
				d.o_totalprice,
				d.o_comment
		FROM d;

		/* We insert a few lineitems to the order */

	SELECT	c_custkey,
            c_mktsegment,
            c_name,
            c_acctbal,
            num_orders
	FROM	webshop.customers 
	WHERE	c_custkey = @c_custkey;

	SELECT	o_orderdate,
            o_orderkey,
            o_custkey,
            o_totalprice
	FROM	webshop.orders
	WHERE	o_custkey = @c_custkey;
END
GO

CREATE OR ALTER PROCEDURE webshop.move_order_record
	@from_custkey	BIGINT,
	@to_custkey		BIGINT,
	@num_records	INT	=	1
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	WITH d
	AS
	(
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
		FROM	webshop.orders
		WHERE	o_custkey = @from_custkey
	)
	UPDATE	d
	SET		d.o_custkey = @to_custkey;

	SELECT	c_custkey,
            c_mktsegment,
            c_name,
            c_acctbal,
            num_orders
	FROM	webshop.customers
	WHERE	c_custkey IN (@from_custkey, @to_custkey);

	SELECT	o_orderdate,
            o_orderkey,
            o_custkey,
            o_totalprice
	FROM	webshop.orders
	WHERE	o_custkey IN (@from_custkey, @to_custkey)
	ORDER BY
			o_custkey;
END
GO

CREATE OR ALTER PROCEDURE webshop.delete_order_record
	@c_custkey		BIGINT,
	@num_records	INT	= 1
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DELETE	TOP (@num_records)
	FROM	webshop.orders
	WHERE	o_custkey = @c_custkey;

	SELECT	c_custkey,
            c_mktsegment,
            c_name,
            c_acctbal,
            num_orders
	FROM	webshop.customers
	WHERE	c_custkey = @c_custkey;

	SELECT	o_orderdate,
            o_orderkey,
            o_custkey,
            o_totalprice
	FROM	webshop.orders
	WHERE	o_custkey = @c_custkey;
END
GO

CREATE OR ALTER PROCEDURE webshop.update_order_record
	@delay VARCHAR(10) = '00:00:05'
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE	@o_orderkey BIGINT = (SELECT TOP (1) o_orderkey FROM webshop.orders WHERE o_orderstatus = 'N');

	BEGIN TRANSACTION
		UPDATE	webshop.orders
		SET		o_orderstatus = 'P'
		WHERE	o_orderkey = @o_orderkey;

		/* The delay simulates a process done by the application */
		WAITFOR DELAY @delay;
	COMMIT TRANSACTION
END
GO


/*
	These stored procedures are for the stress test scenarios only
	The functionality is primitive because it grabs a random customer_id
	and insert/update/delete an order.
*/
RAISERROR ('Creating wrapper procedures for webshop.orders...', 0, 1) WITH NOWAIT;
GO

CREATE OR ALTER PROCEDURE webshop.insert_order
	@num_records	INT = 1
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE	@c_custkey	BIGINT = (
									SELECT	TOP (1)
											c_custkey
									FROM	webshop.customers
									ORDER BY
											NEWID()
								 );
	
	/* Insert an order for this customer */
	EXEC webshop.insert_order_record
		@c_custkey = @c_custkey,
	    @num_records = @num_records;
END
GO

CREATE OR ALTER PROCEDURE webshop.move_order
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE	@from_c_custkey		BIGINT = (
											SELECT	TOP (1)
													c_custkey
											FROM	webshop.customers
											ORDER BY
													NEWID()
										 );
	DECLARE	@to_c_custkey		BIGINT = (
											SELECT	TOP (1)
													c_custkey
											FROM	webshop.customers
											ORDER BY
													NEWID()
										 );

	/* Insert an order for this customer */
	EXEC webshop.move_order_record
		@from_custkey = @from_c_custkey,
	    @to_custkey = @to_c_custkey,
	    @num_records = 1;	
END
GO

CREATE OR ALTER PROCEDURE webshop.update_order
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

END
GO

CREATE OR ALTER PROCEDURE webshop.delete_order
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE	@c_custkey	BIGINT = (
									SELECT	TOP (1)
											c_custkey
									FROM	webshop.customers
									ORDER BY
											NEWID()
								 );
	
	/* Insert an order for this customer */
	EXEC webshop.delete_order_record
		@c_custkey = @c_custkey,
	    @num_records = 1;	
END
GO

ALTER DATABASE ERP_Demo SET QUERY_STORE CLEAR;
GO