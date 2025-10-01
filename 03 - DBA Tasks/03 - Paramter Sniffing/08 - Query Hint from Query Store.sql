/*
	============================================================================
	File:		08 - Query Hint from Query Store.sql

	Summary:	This script demonstrates the usage of Query Hints in Query Store
				NOTE: This feature is only available with SQL Server 2022
				
				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Improve your Skills as a SQL Server DBA"

	Date:		October 2025
	Revion:		October 2025

	SQL Server Version: >= 2022
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

CREATE OR ALTER PROCEDURE dbo.get_customers_by_nation
	@n_nationkey INT
AS
BEGIN
	SET NOCOUNT ON;

	SELECT	c.c_custkey,
			c.c_name,
			n.n_name
	FROM	dbo.customers AS c
			INNER JOIN dbo.nations AS n
			ON (c.c_nationkey = n.n_nationkey)
	WHERE	n.n_nationkey = @n_nationkey
	ORDER BY
			c.c_name;
END
GO
ALTER DATABASE demo_db SET QUERY_STORE CLEAR;
GO

/*
	See this solution in action and have a look to the different
	execution plans!
*/
EXEC dbo.get_customers_by_nation @n_nationkey = 44;
GO 5

EXEC dbo.get_customers_by_nation @n_nationkey = 6;
GO 5

/* Now we clear our plan cache to get fresh query plans! */
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

EXEC dbo.get_customers_by_nation @n_nationkey = 6;
GO 5


/* Now we search for the query_id of the affected statement */
SELECT	qsq.query_id,
		qsq.query_text_id,
		qt.query_sql_text,
		qsp.plan_id,
		qsp.query_plan,
		qsp.is_forced_plan
FROM	sys.query_store_query AS qsq
		INNER JOIN sys.query_store_query_text AS qt
		ON qsq.query_text_id = qt.query_text_id
		INNER JOIN sys.query_store_plan AS qsp
		ON qsq.query_id = qsp.query_id
WHERE	qt.query_sql_text LIKE '%dbo.customers%'
ORDER BY
		qsq.query_id;
GO

/* Now we can apply the query hint to the affected query (query_id) */
EXEC sys.sp_query_store_set_hints
	@query_id = 3,
	@query_hints = N'OPTION (RECOMPILE)';
GO

/* Check the applied query hint */
SELECT * FROM sys.query_store_query_hints
GO

/* We remove the query hint before we go into the last optimization */
EXEC sys.sp_query_store_clear_hints
	@query_id = 3;
GO
