/*
	============================================================================
	File:		07 - temporary table.sql

	Summary:	This script demonstrates the usage of temporary tables to fight
				parameter sniffing.
				
				THIS SCRIPT IS PART OF THE TRACK:
					"Workshop - Improve your DBA Skills"

	Version:	1.00.000

	Date:		October 2025
	Revion:		October 2025

	SQL Server Version: >= 2016
	============================================================================
*/
USE demo_db;
GO

CREATE OR ALTER PROCEDURE dbo.get_customers_by_nation
	@n_nationkey INT
AS
BEGIN
	SET NOCOUNT ON;

	CREATE TABLE #t (c_custkey BIGINT PRIMARY KEY CLUSTERED);

	INSERT INTO #t (c_custkey)
	SELECT	c_custkey
	FROM	dbo.customers
	WHERE	c_nationkey = @n_nationkey;

	SELECT	c.c_custkey,
			c.c_name,
			n.n_name
	FROM	#t AS t
			INNER JOIN dbo.customers AS c
			ON (t.c_custkey = c.c_custkey)
			INNER JOIN dbo.nations AS n
			ON (c.c_nationkey = n.n_nationkey)
	WHERE	n.n_nationkey = @n_nationkey
	ORDER BY
			c.c_name
	OPTION	(RECOMPILE);
END
GO

/*
	See this solution in action and have a look to the different
	execution plans!
*/
EXEC dbo.get_customers_by_nation @n_nationkey = 44;
GO

EXEC dbo.get_customers_by_nation @n_nationkey = 6;
GO

ALTER DATABASE demo_db SET QUERY_STORE CLEAR;
GO
