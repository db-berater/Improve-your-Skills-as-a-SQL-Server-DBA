/*
	============================================================================
	File:		02 - CONVERT_IMPLICIT.sql

	Summary:	This script demonstrates the impact of CONVERT_IMPLICIT by
				using wrong data types
				- SQL Antipatterns
				
				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Workshop - Improve your skills as a DBA"

	Date:		October 2025
	Revion:		November 2025

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
USE demo_db;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET STATISTICS IO, TIME ON;
GO

/*
	The very first SIMPLE query is searching for a customer with the
	c_custkey = 1

	NOTE:	The additional Predicate is obsolete to avoid simple paramerization!
*/
SELECT * FROM dbo.customers
WHERE	c_Custkey = 1
		AND 1 = (SELECT 1);
GO

/*
	The second query is using the correct data type for the c_mktsegment
	for the search.
*/
SELECT	c_custkey,
		c_mktsegment
FROM	dbo.customers
WHERE	c_mktsegment = 'FURNITURE '
GO

/*
	... but what happens if the data type is not correct?
	It's smart and correct the data type IF it belongs to
	the same group of data types (e.g. strings).
*/
SELECT	c_custkey,
		c_mktsegment
FROM	dbo.customers
WHERE	c_mktsegment = N'FURNITURE '
GO

/*
	Different data types can prevent optimized JOIN predicates
*/
SELECT	c.c_custkey,
		c.c_name,
		YEAR(o.o_orderdate)	AS	order_year,
		COUNT_BIG(*)		AS	order_quantity
FROM	dbo.customers AS c
		INNER JOIN dbo.orders AS o
		ON (c.c_custkey = o.o_custkey)
WHERE	c.c_custkey <= 100
GROUP BY
		c.c_custkey,
		c.c_name,
		YEAR(o.o_orderdate)
ORDER BY
		c.c_custkey,
		YEAR(o.o_orderdate);
GO

/*
	Let's rewrite the query without changing the data types
*/
;WITH c
AS
(
	SELECT	c_custkey,
			c_name
	FROM	dbo.customers
	WHERE	c_custkey <= 100
)
SELECT	c.c_custkey,
		c.c_name,
		YEAR(o.o_orderdate)	AS	order_year,
		COUNT_BIG(*)		AS	order_quantity
FROM	c INNER JOIN dbo.orders AS o
		ON (CAST(c.c_custkey AS VARCHAR(16)) = o.o_custkey)
GROUP BY
		c.c_custkey,
		c.c_name,
		YEAR(o.o_orderdate)
ORDER BY
		c.c_custkey,
		YEAR(o.o_orderdate);
GO