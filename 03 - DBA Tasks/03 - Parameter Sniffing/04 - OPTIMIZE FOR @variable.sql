/*
	============================================================================
	File:		03 - OPTIMIZE FOR @variable.sql

	Summary:	This script demonstrates the option OPTIMIZE FOR @variable
				to generate more stable execution plans
				
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

	SELECT	c.c_custkey,
			c.c_name,
			n.n_name
	FROM	dbo.customers AS c
			INNER JOIN dbo.nations AS n
			ON (c.c_nationkey = n.n_nationkey)
	WHERE	n.n_nationkey = @n_nationkey
	ORDER BY
			c.c_name
	OPTION	(OPTIMIZE FOR (@n_nationkey = 44));
END
GO

ALTER DATABASE demo_db SET QUERY_STORE CLEAR;
GO

/* Check the execution plan with a small data set */
EXEC dbo.get_customers_by_nation @n_nationkey = 44;
GO

/* Check the execution plan with a big data set */
EXEC dbo.get_customers_by_nation @n_nationkey = 6;
GO

/* Where does the estimates come from? */
SELECT	p.object_id,
        p.stats_id,
        p.rows,
        p.steps,
        p.unfiltered_rows,
		1.0 / p.steps		AS	avg_distribution,
		CAST
		(
			1.0 / p.steps * p.rows
			AS INT
		)					AS	avg_rows
FROM	sys.stats AS s
		CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) AS p
WHERE	s.object_id = OBJECT_ID(N'dbo.customers', N'U')
		AND s.stats_id > 1;
GO
