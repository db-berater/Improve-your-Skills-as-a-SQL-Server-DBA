/*
	============================================================================
		File:		02 - CXPACKET.sql

		Summary:	This script demonstrates the wait stat: CXPACKET

				THIS SCRIPT IS PART OF THE TRACK:
					"Workshop - Improve your DBA Skills"

	Version:	1.00.000

	Date:		October 2025
	Revion:		October 2025

	SQL Server Version: >= 2016
	============================================================================
*/
SET NOCOUNT ON;
GO

/*
	reconfigure the threshold for parallelism to default value!
*/
EXEC sys.sp_configure N'cost threshold for parallelism', 5;
RECONFIGURE WITH OVERRIDE;
GO

EXEC sys.sp_configure N'max degree of parallelism', 0;
RECONFIGURE WITH OVERRIDE;
GO

EXEC dbo.sp_reset_counters
	@clear_wait_stats = 1,
	@clear_user_counters = 1;
GO

ALTER DATABASE demo_db SET QUERY_STORE CLEAR;
GO

USE demo_db;
GO

/*
	Now we load the workload 02 - Wait Stats - CXPACKET.json
	into SQLQueryStress to put pressure on our system!

	You can watch the situation with the Windows Admin Center
	Template:	03 - SQL Server - User Counter.json

	CXPACKET:	User Counter 1
*/

/*
	To fight high CXPACKET Latencies you can increase the
	COSTTHRESHOLD FOR PARLLELISM
*/
BEGIN
	EXEC sys.sp_configure N'cost threshold for parallelism', 500;
	RECONFIGURE WITH OVERRIDE;

EXEC dbo.sp_reset_counters
	@clear_wait_stats = 1,
	@clear_user_counters = 1;
END
GO

/*
	Another option to improve the CX.. Performance might be the reduction
	of parallelism, isn't it?
*/
BEGIN
	EXEC sys.sp_configure N'cost threshold for parallelism', 5;
	RECONFIGURE WITH OVERRIDE;

	EXEC sys.sp_configure N'max degree of parallelism', 4;
	RECONFIGURE WITH OVERRIDE;

	EXEC dbo.sp_reset_counters
		@clear_wait_stats = 1,
		@clear_user_counters = 1;
END
GO

/*
	If you are not allowed to improve performance by server settings you can
	control MAXDOP on database level!
*/
BEGIN
	EXEC sys.sp_configure N'cost threshold for parallelism', 5;
	RECONFIGURE WITH OVERRIDE;

	EXEC sys.sp_configure N'max degree of parallelism', 0;
	RECONFIGURE WITH OVERRIDE;

	ALTER DATABASE SCOPED CONFIGURATION SET MAXDOP = 1;

	EXEC dbo.sp_reset_counters
		@clear_wait_stats = 1,
		@clear_user_counters = 1;
END
GO

/*
	If only individual queries are behaving erratically, you can use query hints implemented using the query store.
	This feature is available starting with SQL Server 2022!
*/
BEGIN
	/* Reset all back to the default values */
	EXEC sys.sp_configure N'cost threshold for parallelism', 5;
	RECONFIGURE WITH OVERRIDE;

	EXEC sys.sp_configure N'max degree of parallelism', 0;
	RECONFIGURE WITH OVERRIDE;

	ALTER DATABASE SCOPED CONFIGURATION SET MAXDOP = 0;
	ALTER DATABASE demo_db SET QUERY_STORE CLEAR;

	EXEC dbo.sp_reset_counters
		@clear_wait_stats = 1,
		@clear_user_counters = 1;
END
GO

/*
	Find queries with the specific text pattern you are looking for
*/
BEGIN
	SELECT	qt.query_text_id,
			qt.query_sql_text,
			q.query_id
	FROM	sys.query_store_query_text AS qt
			INNER JOIN sys.query_store_query AS q
			ON (qt.query_text_id = q.query_text_id)
	WHERE	qt.query_sql_text LIKE N'%dbo.customers%';

	/* If you have SQL 2022 you can use a query hint */
	EXEC sys.sp_query_store_set_hints
		@query_id = 1,
		@query_hint = N'OPTION (MAXDOP 1)';

	EXEC dbo.sp_reset_counters
		@clear_wait_stats = 1,
		@clear_user_counters = 1;
END
GO

/* We reset the query hint after the demo */
EXEC sys.sp_query_store_clear_hints
	@query_id = 1;
GO

/*
	The best solution is using indexes to reduce the costs for the affected queries
*/
BEGIN
	ALTER TABLE dbo.customers ADD CONSTRAINT pk_customers
	PRIMARY KEY CLUSTERED (c_custkey)
	WITH
	(
		DATA_COMPRESSION = PAGE,
		SORT_IN_TEMPDB = ON
		/* only with ENTERPRISE or DEVELOPER Edition*/
		, ONLINE = ON
	);

	EXEC dbo.sp_reset_counters
		@clear_wait_stats = 1,
		@clear_user_counters = 1;
END
GO

BEGIN
	CREATE NONCLUSTERED INDEX nix_orders_o_custkey
	ON dbo.orders (o_custkey)
	WITH
	(
		DATA_COMPRESSION = PAGE,
		SORT_IN_TEMPDB = ON
		/* only with ENTERPRISE or DEVELOPER Edition*/
		, ONLINE = ON
	);

	EXEC dbo.sp_reset_counters
		@clear_wait_stats = 1,
		@clear_user_counters = 1;
END
GO

/*
	We reset the demo environment to the original settings for the next demo
*/
BEGIN
	DROP INDEX nix_orders_o_custkey ON dbo.orders;
	ALTER TABLE dbo.customers DROP CONSTRAINT pk_customers;

	EXEC sys.sp_configure N'cost threshold for parallelism', 5;
	RECONFIGURE WITH OVERRIDE;

	EXEC sys.sp_configure N'max degree of parallelism', 0;
	RECONFIGURE WITH OVERRIDE;

	ALTER DATABASE SCOPED CONFIGURATION SET MAXDOP = 0;
	ALTER DATABASE demo_db SET QUERY_STORE CLEAR;

	EXEC dbo.sp_reset_counters
		@clear_wait_stats = 1,
		@clear_user_counters = 1;
END
GO