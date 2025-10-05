/*
	============================================================================
	File:		01 - preparation.sql

	Summary:	This script creates an environment for the demo of Extended Events
	
				THIS SCRIPT IS PART OF THE TRACK:
					"Workshop - Improve your DBA Skills"

	Version:	1.00.000

	Date:		October 2025
	Revion:		October 2025

	SQL Server Version: >= 2016
	============================================================================
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

USE ERP_Demo;
GO

/*
	Make sure we don't have any objects from previous exercises
*/


/* Create all necessary indexes on the tables! */
EXEC dbo.sp_create_indexes_customers;
EXEC dbo.sp_create_indexes_orders @column_list = N'o_orderkey, @o_orderdate';
GO

EXEC dbo.sp_create_foreign_keys
	@master_table = 'dbo.customers',
    @detail_table = N'dbo.orders';
GO

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
	DECLARE	@num_of_orders				INT;

	/* Insert the c_custkey into the table variable */
	INSERT INTO @t (c_custkey) VALUES (@c_custkey);

	/* How many orders has the customer for the specific year */
	SELECT	@num_of_orders = COUNT(*)
	FROM	dbo.orders
	WHERE	o_custkey = @c_custkey
			AND YEAR(o_orderdate) = @int_orderyear;

	/* Update the value for num_of_orders in the table variable */
	UPDATE	@t
	SET		num_of_orders = @num_of_orders
	WHERE	c_custkey = @c_custkey;

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

	IF @num_of_orders >= 20
	BEGIN
		UPDATE	@t
		SET		classification = 'A'
		WHERE	c_custkey = @c_custkey;

		RETURN;
	END

	IF @num_of_orders >= 10
	BEGIN
		UPDATE	@t
		SET		classification = 'B'
		WHERE	c_custkey = @c_custkey;
		
		RETURN;
	END

	IF @num_of_orders >= 5
	BEGIN
		UPDATE	@t
		SET		classification = 'C'
		WHERE	c_custkey = @c_custkey;

		RETURN;
	END

	UPDATE	@t
	SET		classification = 'D'
	WHERE	c_custkey = @c_custkey;

	RETURN;
END
GO

CREATE OR ALTER PROCEDURE dbo.get_customer_classification
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE	@c_custkey	BIGINT = (RAND() * 1600000) + 1;

	SELECT	c.c_custkey,
			c.c_mktsegment,
			c.c_nationkey,
			c.c_name,
			ccc.num_of_orders,
			ccc.classification
	FROM	dbo.customers AS c
			CROSS APPLY dbo.calculate_customer_category(c.c_custkey, 2019, 0) AS ccc
	WHERE	c.c_custkey = @c_custkey;
END
GO

/* Test */
SET STATISTICS IO, TIME ON;
GO

EXEC dbo.get_customer_classification;
GO

/*
	We are making sure that Query Store is activated!
*/
EXEC dbo.sp_activate_query_store;
GO