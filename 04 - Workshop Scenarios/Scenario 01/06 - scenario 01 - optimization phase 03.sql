/*
	============================================================================
	File:		06 - scenario 01 - optimization phase 03.sql

	Summary:	This script optimize the table valued function that way
				that we remove residual predicates in the NONSargable section
				of the query.
				
				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Workshop - Accelerate your SQL Code"

	Date:		October 2024
	Revion:		November 2024

	SQL Server Version: >= 2016
	============================================================================
*/
USE ERP_Demo;
GO

/*
	Function Name:	dbo.calculate_customer_category
	Parameters:		@c_custkey		=>	customer key from dbo.customers
					@int_orderyear	=>	year of the status earned
					@calling_level	=>	the function is called recursive!

	Description:	This user definied function calculates the number of
					orders a customer has placed for a specific year
*/

/*
	YEAR(o_orderdate) is a NONSARGable predicate and will be replaced
	by a SARGable expression.
	Furthermore we create an additional index which covers o_custkey and o_orderdate!
*/
CREATE OR ALTER FUNCTION dbo.calculate_customer_category
(
	@c_custkey		BIGINT,
	@int_orderyear	INT,
	@calling_level	INT = 0
)
RETURNS @t TABLE
(
	c_custkey		BIGINT	NOT NULL	PRIMARY KEY CLUSTERED,
	num_of_orders	INT		NOT NULL	DEFAULT (0),
	classification	CHAR(1)	NOT NULL	DEFAULT ('Z')
)
BEGIN

	/*
		if the customer does not have any orders in the specific year
		we return the value "Z"
	*/
	DECLARE	@num_of_orders				INT;

	/*
		IMPROVEMENT 03!
		Remove of NONSARGable expression and exchange by a SARGable expression!
	*/
	SELECT	@num_of_orders = COUNT(*)
	FROM	dbo.orders
	WHERE	o_custkey = @c_custkey
			AND o_orderdate >= DATEFROMPARTS(@int_orderyear, 1, 1)
			AND o_orderdate <= DATEFROMPARTS(@int_orderyear, 12, 31);

	/* How many orders has the customer for the specific year */
	INSERT INTO @t (c_custkey, num_of_orders, classification)
	SELECT	@c_custkey,
			@num_of_orders,
			CASE
				WHEN @num_of_orders >= 20	THEN 'A'
				WHEN @num_of_orders >= 10	THEN 'B'
				WHEN @num_of_orders >= 5	THEN 'C'
				WHEN @num_of_orders >= 1	THEN 'D'
				ELSE 'Z'
			END		AS	classification;

	/*
		Depending on the number of orders we define what category the customer is
		If the category for the given year is "Z" we take the classification from
		the last year and reduce it by one classification
	*/
	IF @num_of_orders = 0
	BEGIN
		IF @calling_level = 0
		BEGIN
			DELETE	@t;

			INSERT INTO @t
			(c_custkey, num_of_orders, classification)
			SELECT	c_custkey, @num_of_orders, classification
			FROM	dbo.calculate_customer_category(@c_custkey, @int_orderyear - 1, @calling_level + 1);

			UPDATE	@t
			SET		classification = CASE WHEN classification = N'D'
										  THEN 'Z'
										  ELSE CHAR(ASCII(classification) + 1)
									 END
			WHERE	c_custkey = @c_custkey
					AND classification <> 'Z'
		END
		RETURN;
	END

	RETURN;
END
GO