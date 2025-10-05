/*
	============================================================================
	File:		02 - demo of Windows Admin Center - optimization.sql

	Summary:	This script walks through all optimization phases of the query.
				All optimizations can be seen in the Windows Admin Center!
				
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
	After the first execution round we add an additional index
	on dbo.customers for better performance!
*/
EXEC dbo.sp_create_indexes_customers;
EXEC dbo.sp_create_indexes_nations;
EXEC dbo.sp_create_indexes_regions;
GO

/* Will an optimized index on dbo.orders improve my performance? */
CREATE NONCLUSTERED INDEX nix_orders_o_custkey_o_orderdate
ON dbo.orders
(o_custkey)
INCLUDE (o_orderdate)
WITH
(
	DATA_COMPRESSION = PAGE,
	SORT_IN_TEMPDB = ON,
	ONLINE = ON
);
GO

/*
	Finally we try to optimize the procedure to reduce IO on the storage
*/
CREATE OR ALTER PROCEDURE dbo.get_customer_info
	@c_custkey BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DROP TABLE IF EXISTS #result;

	CREATE TABLE #result
	(
		customer_number		BIGINT			NOT NULL	PRIMARY KEY CLUSTERED,
		customer_name		VARCHAR(128)	NOT NULL,
		customer_nation		VARCHAR(128)	NOT NULL,
		first_order_date	DATE			NULL,
		last_order_date		DATE			NULL,
		num_orders_total	INT				NULL	DEFAULT (0)
	);

	/*
		Get a record for the given customer which contains
		the number of orders and the information of:
		- first order date
		- last order date
	*/
	INSERT INTO #result
	(customer_number, customer_name, customer_nation, first_order_date, last_order_date, num_orders_total)
	SELECT	c.c_custkey			AS	customer_number,
			c.c_name			AS	customer_name,
			n.n_name			AS	customer_nation,
			MIN(o.o_orderdate)	AS	first_order_date,
			MAX(o.o_orderdate)	AS	last_order_date,
			COUNT_BIG(*)		AS	num_orders_total
	FROM	dbo.regions AS r
			INNER JOIN dbo.nations AS n
			ON (n.n_regionkey = r.r_regionkey)
			INNER JOIN dbo.customers AS c
			ON (n.n_nationkey = c.c_nationkey)
			INNER JOIN dbo.orders AS o
			ON (c.c_custkey = o.o_custkey)
	WHERE	c.c_custkey = @c_custkey
	GROUP BY
			c.c_custkey,
			c.c_name,
			n.n_name;
END
GO