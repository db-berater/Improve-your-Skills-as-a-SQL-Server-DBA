/*
	============================================================================
	File:		01 - preparation.sql

	Summary:	This script prepares the environment for a the WAIT STATS analysis
				
				THIS SCRIPT IS PART OF THE TRACK:
					"Workshop - Improve your DBA Skills"

	Version:	1.00.000

	Date:		October 2025
	Revion:		October 2025

	SQL Server Version: >= 2016
	============================================================================
*/
USE master;
GO

/*
	Let's create a database first for the storage of data

	Note:	The code for the stored procedure can be found in
			[01 - Preparation an Presentation]\[02 - dbo.sp_create_demo_db.sql]
*/
EXEC master..sp_create_demo_db
	@num_of_files = 1,
    @initial_size_MB = 1024,
    @use_filegroups = 0;
GO

USE demo_db;
GO

RAISERROR ('create table [dbo].[orders] as a heap...', 0, 1) WITH NOWAIT;
SELECT	o_orderdate,
        o_orderkey,
        o_custkey,
        o_orderpriority,
        o_shippriority,
        o_clerk,
        o_orderstatus,
        o_totalprice,
        o_comment,
        o_storekey
INTO	dbo.orders
FROM	ERP_Demo.dbo.orders;
GO

RAISERROR ('create table [dbo].[customers] as a heap...', 0, 1) WITH NOWAIT;
SELECT	c_custkey,
        c_mktsegment,
        c_nationkey,
        c_name,
        c_address,
        c_phone,
        c_acctbal,
        c_comment
INTO	dbo.customers
FROM	ERP_Demo.dbo.customers;
GO

/* Stored Procedure for the workload demonstration */
CREATE OR ALTER PROCEDURE dbo.get_customer_analysis
	@c_custkey				BIGINT,
	@cxpacket				SMALLINT = 0,
	@sos_scheduler_yield	SMALLINT = 0,
	@async_network_io		SMALLINT = 0,
	@threadpool				SMALLINT = 0,
	@writelog				SMALLINT = 0
AS
BEGIN
	SET NOCOUNT ON;

	SELECT	c.c_custkey,
            c.c_mktsegment,
            c.c_nationkey,
            c.c_name,
            c.c_address,
            c.c_phone,
            c.c_acctbal,
            c.c_comment,
            o.o_orderdate,
            o.o_orderkey,
            o.o_custkey,
            o.o_orderpriority,
            o.o_shippriority,
            o.o_clerk,
            o.o_orderstatus,
            o.o_totalprice,
            o.o_comment,
            o.o_storekey
	FROM	dbo.customers AS c
			INNER JOIN dbo.orders AS o
			ON (c.c_custkey = o.o_custkey)
	WHERE	c.c_custkey <= 100
	ORDER BY
			c.c_mktsegment;

	SELECT	p.order_year,
			[Jan],
			[Feb],
			[Mar],
			[Apr],
			[May],
			[Jun],
			[Jul],
			[Aug],
			[Sep],
			[Oct],
			[Nov],
			[Dec]
	FROM
	(
		SELECT	o_custkey,
				YEAR(o.o_orderdate)	AS	order_year,
				CHOOSE(MONTH(o.o_orderdate), 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec')	AS	order_month,
				o.o_orderkey
		FROM	dbo.orders AS o
		WHERE	o.o_custkey = @c_custkey
	) AS s
	PIVOT
	(
		COUNT(o_orderkey) FOR order_month IN
		([Jan], [Feb], [Mar], [Apr], [May], [Jun], [Jul], [Aug], [Sep], [Oct], [Nov], [Dec])
	) AS p;

	/* Now we set the user counter 1 to the avg wait stats of CXPACKET*/
	DECLARE	@cxpacket_sec				INT = 0;
	DECLARE	@sos_scheduler_yield_sec	INT = 0;
	DECLARE	@async_network_io_sec		INT = 0;
	DECLARE	@threadpool_sec				INT = 0;
	DECLARE	@writelog_sec				INT = 0;

	BEGIN TRY
		SELECT	@cxpacket_sec = ISNULL([Avg Waittime (seconds)], 0) * 1000
		FROM	ERP_Demo.dbo.get_wait_stats_info(N'CXPACKET')
		WHERE	@cxpacket = 1;
	END TRY
	BEGIN CATCH
		SET	@cxpacket_sec = 0
	END CATCH

	BEGIN TRY
		SELECT	@sos_scheduler_yield_sec = ISNULL([Avg Waittime (seconds)], 0) * 1000
		FROM	ERP_Demo.dbo.get_wait_stats_info(N'SOS_SCHEDULER_YIELD')
		WHERE	@sos_scheduler_yield = 1;
	END TRY
	BEGIN CATCH
		SET	@sos_scheduler_yield_sec = 0
	END CATCH

	BEGIN TRY
		SELECT	@async_network_io_sec = ISNULL([Avg Waittime (seconds)], 0) * 1000
		FROM	ERP_Demo.dbo.get_wait_stats_info(N'ASYNC_NETWORK_IO')
		WHERE	@async_network_io = 1;
	END TRY
	BEGIN CATCH
		SET	@async_network_io_sec = 0
	END CATCH

	BEGIN TRY
		SELECT	@threadpool_sec = ISNULL([Total number of waits], 0)
		FROM	ERP_Demo.dbo.get_wait_stats_info(N'THREADPOOL')
		WHERE	@threadpool = 1;
	END TRY
	BEGIN CATCH
		SET	@threadpool_sec = 0
	END CATCH

	DBCC SETINSTANCE('SQLServer:User Settable', 'Query', 'User counter 1', @cxpacket_sec);
	DBCC SETINSTANCE('SQLServer:User Settable', 'Query', 'User counter 2', @sos_scheduler_yield_sec);
	DBCC SETINSTANCE('SQLServer:User Settable', 'Query', 'User counter 3', @async_network_io_sec);
	DBCC SETINSTANCE('SQLServer:User Settable', 'Query', 'User counter 4', @threadpool_sec);
	DBCC SETINSTANCE('SQLServer:User Settable', 'Query', 'User counter 5', @writelog_sec);
END
GO

CREATE OR ALTER VIEW dbo.year_list
AS
	SELECT	TOP (100000)
			c.c_custkey
	FROM	ERP_Demo.dbo.customers AS c
GO