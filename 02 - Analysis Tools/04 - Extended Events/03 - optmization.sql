/*
	============================================================================
	File:		03 - optimization.sql

	Summary:	The final optimization is the implementation of a missing index
				to improve the general performance
				
				THIS SCRIPT IS PART OF THE TRACK:
					"Workshop - Improve your DBA Skills"

	Version:	1.00.000

	Date:		October 2025
	Revion:		October 2025

	SQL Server Version: >= 2016
	============================================================================
*//
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

USE ERP_Demo;
GO

/*
	First let's analyse the generic query inside the function
*/
DROP FUNCTION IF EXISTS dbo.calculate_customer_category;
GO

CREATE OR ALTER FUNCTION dbo.calculate_customer_category
(
	@c_custkey		BIGINT,
	@int_orderyear	INT,
	@calling_level	INT = 0
)
RETURNS TABLE
AS
RETURN
(
	WITH l
	AS
	(
		SELECT	ROW_NUMBER() OVER (ORDER BY YEAR(o_orderdate) DESC)	AS	rn,
				o.o_custkey			AS	c_custkey,
				COUNT_BIG(*)		AS	num_of_orders,
				CASE WHEN YEAR(o_orderdate) = @int_orderyear
						THEN CASE
							WHEN COUNT_BIG(*) >= 20	THEN 'A'
							WHEN COUNT_BIG(*) >= 10	THEN 'B'
							WHEN COUNT_BIG(*) >= 5	THEN 'C'
							WHEN COUNT_BIG(*) >= 1	THEN 'D'
							ELSE 'Z'
							END
						ELSE CASE
							WHEN COUNT_BIG(*) >= 20	THEN 'B'
							WHEN COUNT_BIG(*) >= 10	THEN 'C'
							WHEN COUNT_BIG(*) >= 5	THEN 'D'
							ELSE 'Z'
							END
				END			AS	classification
		FROM	dbo.orders AS o
		WHERE	o.o_custkey = @c_custkey
				AND	o.o_orderdate >= DATEFROMPARTS(@int_orderyear - 1, 1, 1)
				AND	o.o_orderdate <= DATEFROMPARTS(@int_orderyear, 12, 31)
		GROUP BY
				o.o_custkey,
				YEAR(o_orderdate)
	)
	SELECT	c_custkey,
			num_of_orders,
			classification
	FROM	l
	WHERE	rn = 1
);
GO

/*
	The analysis of the execution plan reveals a missing index on the dbo.orders table
*/
IF NOT EXISTS
(
	SELECT * FROM sys.indexes WHERE name = N'nix_orders_o_custkey_o_orderdate' AND object_id = OBJECT_ID(N'dbo.orders', N'U')
)
	CREATE NONCLUSTERED INDEX nix_orders_o_custkey_o_orderdate
	ON dbo.orders
	(
		o_custkey,
		o_orderdate
	)
	WITH
	(
		SORT_IN_TEMPDB = ON,
		DATA_COMPRESSION = PAGE
	);
ELSE
	CREATE NONCLUSTERED INDEX nix_orders_o_custkey_o_orderdate
	ON dbo.orders
	(
		o_custkey,
		o_orderdate
	)
	WITH
	(
		SORT_IN_TEMPDB = ON,
		DATA_COMPRESSION = PAGE,
		DROP_EXISTING = ON
	);
GO
