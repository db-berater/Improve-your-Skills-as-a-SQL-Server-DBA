/*
	============================================================================
	File:		03 -  THREADPOOL.sql

	Summary:	This script demonstrates the wait stat THREADPOOL

				THIS SCRIPT IS PART OF THE TRACK:
					"Workshop - Improve Your Skills as a SQL Server DBA"

	NOTE:		You must run the script "03 - sp_reset_counters.sql" first
				to use the stored procedure for clearing of counters!

	Date:		March 2024

	SQL Server Version: >=2016
    ============================================================================
*/
USE master;
GO

/* We want to make sure we have default instance values */
EXEC sys.sp_configure N'cost threshold for parallelism', 5;
RECONFIGURE WITH OVERRIDE;
GO

EXEC sys.sp_configure N'max degree of parallelism', 0;
RECONFIGURE WITH OVERRIDE;
GO

/* How much worker threads do we have in the machine? */
SELECT	DOSI.cpu_count,
		DOSI.max_workers_count
FROM	sys.dm_os_sys_info AS DOSI;
GO

/* Let's check the current wait stats analysis */
SELECT	WaitType,
        [Total Waittime (seconds)],
        [Total Ressource Waittime (seconds)],
        [Total Signal Waittime (seconds)],
        [Total number of waits],
        [Percentage of Total Waittime],
        [Avg Waittime (seconds)],
        [Avg Resource Waittime (seconds)],
        [Avg Signal Waittime (seconds)]
FROM	ERP_Demo.dbo.get_wait_stats_info(NULL);
GO

/*
    Now we prepare our system for the demos.
    Therefore we reduce the maximum numbers of workers to 196!

    NOTE: DO NOT DO THAT IN PRODUCTION SYSTEMS!
*/
BEGIN
	EXEC sp_configure N'show advanced options', 1;
	RECONFIGURE WITH OVERRIDE;

	EXEC sp_configure N'max worker threads', 196;
	RECONFIGURE WITH OVERRIDE;

	/* How much worker threads do we have in the machine? */
	SELECT	DOSI.cpu_count,
			DOSI.max_workers_count
	FROM	sys.dm_os_sys_info AS DOSI;
END
GO

/*
	Check the "Counter 2" for CPU and "Counter 4" in Windows Admin Center
	or Perfmon to monitor the occurence of THREADPOOL starvation.

	Run the workload "04 - Wait Stats - THREADPOOL.json" in SQLQueryStress
*/
EXEC dbo.sp_reset_counters
        @clear_wait_stats = 1,
        @clear_user_counters = 1;
GO

SELECT  s.cpu_id,
		COUNT_BIG(w.worker_address)	AS thread_count,
		s.current_tasks_count,
		s.runnable_tasks_count,
		s.pending_disk_io_count
FROM	sys.dm_os_schedulers AS s
		LEFT JOIN sys.dm_os_workers AS w
		ON s.scheduler_address = w.scheduler_address
WHERE	s.scheduler_id < 255  -- exclude hidden/system schedulers
GROUP BY 
		s.scheduler_id,
		s.cpu_id,
		s.current_tasks_count,
		s.runnable_tasks_count,
		s.pending_disk_io_count
ORDER BY s.cpu_id;

SELECT * FROM sys.dm_os_wait_stats
WHERE   wait_type = N'THREADPOOL';
GO

/*
	Let's try it by reducing the number of cores for each process!
*/
EXEC sys.sp_configure N'max degree of parallelism', 4;
RECONFIGURE WITH OVERRIDE;
GO

EXEC dbo.sp_reset_counters
        @clear_wait_stats = 1,
        @clear_user_counters = 1;
GO

EXEC sys.sp_configure N'max degree of parallelism', 1;
RECONFIGURE WITH OVERRIDE;
GO

EXEC dbo.sp_reset_counters
        @clear_wait_stats = 1,
        @clear_user_counters = 1;
GO

ALTER DATABASE demo_db SET QUERY_STORE CLEAR;
GO

