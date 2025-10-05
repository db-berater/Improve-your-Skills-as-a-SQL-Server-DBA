/*
	============================================================================
	File:		05 - Dynamic SQL.sql

	Summary:	This script demonstrates the usage of dynamic SQL to fight
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

	DECLARE	@sql_cmd	NVARCHAR(MAX) = N'SELECT	c.c_custkey,
			c.c_name,
			n.n_name
	FROM	dbo.customers AS c
			INNER JOIN dbo.nations AS n
			ON (c.c_nationkey = n.n_nationkey)
	WHERE	n.n_nationkey = ' + CAST(@n_nationkey AS NVARCHAR(2)) + N'
	ORDER BY
			c.c_name;';

	EXEC sp_executesql @sql_cmd;
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

/*
	We clear the query store and load the SQLQueryStress template
	"80 - SQL Query Stress\01 - Parameter Sniffing.json" for the
	execution in SQLQueryStress
*/
ALTER DATABASE demo_db SET QUERY_STORE CLEAR;
GO

/*
	While SQL Query Stress is running we check the plan cache
*/

SELECT	ps.database_id,
        ps.cached_time,
        ps.last_execution_time,
        ps.execution_count,
        ps.total_worker_time,
        ps.last_worker_time,
        ps.min_worker_time,
        ps.max_worker_time
FROM	sys.dm_exec_procedure_stats AS ps
WHERE	ps.object_id = OBJECT_ID(N'dbo.get_customers_by_nation', N'P');
GO

/*
	What execution plans do we have in the plan cache
*/
SELECT	cp.cacheobjtype,
		cp.objtype,
		cp.usecounts,
		cp.size_in_bytes,
		qt.text				AS	sql_text
FROM	sys.dm_exec_cached_plans AS cp
		INNER JOIN sys.dm_exec_query_stats AS qs
		ON (cp.plan_handle = qs.plan_handle)
		CROSS APPLY sys.dm_exec_sql_text
		(
			qs.sql_handle
		) AS qt
WHERE	qt.text LIKE '%customers%'
		AND qt.text NOT LIKE '%sys.dm_exec_sql_text%'
ORDER BY
		cp.usecounts DESC
GO

/* We run the same workload again but using FORCED Parameterization for the database */
ALTER DATABASE [demo_db] SET PARAMETERIZATION FORCED WITH NO_WAIT
GO

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

ALTER DATABASE [demo_db] SET QUERY_STORE CLEAR;
GO

EXEC dbo.get_customers_by_nation @n_nationkey = 44;
GO

EXEC dbo.get_customers_by_nation @n_nationkey = 6;
GO

/*
	Screw it back to the default settings for the database
*/
ALTER DATABASE [demo_db] SET PARAMETERIZATION SIMPLE WITH NO_WAIT
GO
