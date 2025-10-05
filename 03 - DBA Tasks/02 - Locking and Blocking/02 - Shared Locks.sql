/*
	============================================================================
	File:		02 - Shared Locks.sql

	Summary:	This script demonstrates the usage of shared locks in HEAPS
				and/or CLUSTERED INDEXES
				
				THIS SCRIPT IS PART OF THE TRACK:
					"Workshop - Improve your DBA Skills"

	Version:	1.00.000

	Date:		October 2025
	Revion:		October 2025

	SQL Server Version: >= 2016
	============================================================================
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

USE demo_db;
GO

BEGIN TRANSACTION;
GO
	SELECT	[c_custkey],
			[c_mktsegment],
			[c_nationkey],
			[c_name],
			[c_address],
			[c_phone],
			[c_acctbal],
			[c_comment]
	FROM	dbo.customers
	WHERE	c_custkey = 10
	OPTION	(MAXDOP 1);
	GO
	
	SELECT	DISTINCT
			request_session_id,
			resource_type,
			resource_description,
			request_mode,
			request_type,
			request_status
	FROM	ERP_Demo.dbo.get_locking_status(@@SPID)
	WHERE	resource_description <> N'get_locking_status';
	GO
COMMIT TRANSACTION;
GO

/*
	Before you run this query execute the implementation of an extended event

	RUN:	[80 Extended Events]/[02 - 02 - read shared locks.sql]

	which covers all locks while the SELECT is running.
	You must change the session_id to the session_id of this tab!
*/
SELECT	c_custkey,
        c_mktsegment,
        c_nationkey,
        c_name,
        c_address,
        c_phone,
        c_acctbal,
        c_comment
FROM	dbo.customers
WHERE	c_custkey = 10;
GO

/*
	Stop the recording by dropping both events for tracking the locks
	Notice that the table is a HEAP Table!
*/
ALTER EVENT SESSION [locking_shared_locks] ON SERVER
	DROP EVENT sqlserver.lock_acquired,
	DROP EVENT sqlserver.lock_released;
GO

/* ... and read the data from the ring buffer */
EXEC master.dbo.sp_read_xevent_locks
	@xevent_name = N'locking_shared_locks';
GO

IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = N'read_committed_locks')
BEGIN
	RAISERROR (N'dropping existing extended event session [read_committed_locks]...', 0, 1) WITH NOWAIT;
	DROP EVENT SESSION [read_committed_locks] ON SERVER;
END
GO

/*
	Now we select a specific o_orderky from dbo.orders
	Notice:	The table dbo.orders has a CLUSTERED INDEX!

	Rerun the creation of the extend event before we start the demo!
*/
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
FROM	dbo.orders
WHERE	o_orderkey = 3877;
GO

/*
	Stop the recording by dropping both events for tracking the locks
	Notice that the table is a HEAP Table!
*/
ALTER EVENT SESSION [locking_shared_locks] ON SERVER
	DROP EVENT sqlserver.lock_acquired,
	DROP EVENT sqlserver.lock_released;
GO

/* ... and read the data from the ring buffer */
EXEC master.dbo.sp_read_xevent_locks
	@xevent_name = N'locking_shared_locks';
GO

/*
	When another process hold an U / X Lock on a specific row than
	the locking is working different

	Take the following code and execute it in another query window

BEGIN TRANSACTION
GO
	UPDATE	dbo.orders
	SET		o_orderdate = GETDATE()
	WHERE	o_orderkey = 3877;

	Rerun the creation of the extend event before we start the demo!
*/
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
FROM	dbo.orders
WHERE	o_orderkey = 3877;
GO

/*
	Stop the recording by dropping both events for tracking the locks
	Notice that the table is a HEAP Table!
*/
ALTER EVENT SESSION [locking_shared_locks] ON SERVER
	DROP EVENT sqlserver.lock_acquired,
	DROP EVENT sqlserver.lock_released;
GO

/* ... and read the data from the ring buffer */
EXEC master.dbo.sp_read_xevent_locks
	@xevent_name = N'locking_shared_locks';
GO

/*
	Clean the environment!
*/
IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = N'locking_shared_locks')
BEGIN
	RAISERROR (N'dropping existing extended event session [locking_shared_locks]...', 0, 1) WITH NOWAIT;
	DROP EVENT SESSION [locking_shared_locks] ON SERVER;
END
GO
