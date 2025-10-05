/*
	============================================================================
	File:		01 - demo of Windows Admin Center - preparation.sql

	Summary:	This script prepares tables in the database ERP_Demo
				for the chapter
				- Working with Windows Admin Center
				
				THIS SCRIPT IS PART OF THE TRACK:
					"Workshop - Improve your DBA Skills"

	Version:	1.00.000

	Date:		October 2025
	Revion:		October 2025

	SQL Server Version: >= 2016
	============================================================================
*/
USE ERP_Demo;
GO

/*
	We make sure that no indexes are present for the affected tables.

	NOTE:	The stored procedures are part of the ERP_Demo Database Framework!
*/
EXEC dbo.sp_drop_foreign_keys @table_name = N'ALL';
EXEC dbo.sp_drop_indexes @table_name = N'ALL', @check_only = 0;
GO

/*
	We create a stored procedure which creates a stored procedure
	for the execution in SQLQueryStress
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
		customer_number		BIGINT			NOT NULL,
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
	(customer_number, customer_name, customer_nation)
	SELECT	c.c_custkey			AS	customer_number,
			c.c_name			AS	customer_name,
			n.n_name			AS	customer_nation
	FROM	dbo.regions AS r
			INNER JOIN dbo.nations AS n
			ON (n.n_regionkey = r.r_regionkey)
			INNER JOIN dbo.customers AS c
			ON (n.n_nationkey = c.c_nationkey)
	WHERE	c.c_custkey = @c_custkey

	ALTER TABLE #result ADD PRIMARY KEY CLUSTERED (customer_number);
	
	/* Now we collect the missing infos for the customer */
	BEGIN
		UPDATE	#result
		SET		first_order_date = (SELECT MIN(o_orderdate) FROM dbo.orders WHERE o_custkey = @c_custkey);

		UPDATE	#result
		SET		last_order_date = (SELECT MAX(o_orderdate) FROM	dbo.orders WHERE o_custkey = @c_custkey);

		UPDATE	#result
		SET		num_orders_total = (SELECT COUNT_BIG(*) FROM dbo.orders WHERE o_custkey = @c_custkey);
	END
END
GO

CREATE OR ALTER VIEW dbo.list_customer_info
AS
	SELECT	c_custkey
	FROM	(
				VALUES	(1),
						(10),
						(100),
						(1000),
						(10000)
			) AS x (c_custkey);
GO

RAISERROR ('Now open Windows Admin Center and load the settings of [01 - Windows Admin Server Demo.json]', 0, 1) WITH NOWAIT;
RAISERROR ('Start the process the first time and watch the metrics.', 0, 1) WITH NOWAIT;
GO