/*
	============================================================================
	File:		03 - SOS_SCHEDULER_YIELD.sql

	Summary:	This script demonstrates the wait stat: SOS_SCHEDULER_YIELD

				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Improve your Skills as a SQL Server DBA"

	Date:		October 2025

	NOTE:		You must run the script "03 - sp_reset_counters.sql" first
				to use the stored procedure for clearing of counters!

	SQL Server Version: >=2016
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

EXEC  dbo.sp_reset_counters
		@clear_wait_stats = 1,
		@clear_user_counters = 1;
GO

ALTER DATABASE demo_db SET QUERY_STORE CLEAR;
GO

USE demo_db;
GO

/*
	Now we load the workload 03 - Wait Stats - SOS_SCHEDULER_YIELD.json
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

	EXEC  dbo.sp_reset_counters
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

	EXEC  dbo.sp_reset_counters
			@clear_wait_stats = 1,
			@clear_user_counters = 1;
END
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

	EXEC  dbo.sp_reset_counters
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

	EXEC  dbo.sp_reset_counters
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

	EXEC  dbo.sp_reset_counters
			@clear_wait_stats = 1,
			@clear_user_counters = 1;
END
GO

/*
	Indexing may help better than all other settings!
*/
EXEC sys.sp_configure N'cost threshold for parallelism', 5;
RECONFIGURE WITH OVERRIDE;
GO

EXEC sys.sp_configure N'max degree of parallelism', 0;
RECONFIGURE WITH OVERRIDE;
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

	CREATE NONCLUSTERED INDEX nix_orders_o_custkey
	ON dbo.orders (o_custkey)
	WITH
	(
		DATA_COMPRESSION = PAGE,
		SORT_IN_TEMPDB = ON
		/* only with ENTERPRISE or DEVELOPER Edition*/
		, ONLINE = ON
	);

	EXEC  dbo.sp_reset_counters
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

	EXEC  dbo.sp_reset_counters
			@clear_wait_stats = 1,
			@clear_user_counters = 1;
END
GO

/*
	Finally one of the most problems related to SOS_SCHEDULER_YIELD is the wrong
	Energy Management on the Host System!
*/