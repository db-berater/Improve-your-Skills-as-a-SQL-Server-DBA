/*
	============================================================================
	File:		04 - Lock Escalation.sql

	Summary:	This script demonstrates situations where Lock Escalation happens.
				
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

/*
	Let's create a demo database with a partitioned table first
*/
USE master;
GO

EXEC master.dbo.sp_create_demo_db
	@num_of_files = 1,
	@initial_size_mb = 1024,
	@use_filegroups = 0;
GO

USE demo_db;
GO

CREATE TABLE dbo.orders
(
	o_orderdate date NOT NULL,
	o_orderkey bigint NOT NULL,
	o_custkey bigint NOT NULL,
	o_orderpriority char(15) NULL,
	o_shippriority int NULL,
	o_clerk char(15) NULL,
	o_orderstatus char(1) NULL,
	o_totalprice money NULL,
	o_comment varchar(79) NULL,
	o_storekey bigint NOT NULL,

	CONSTRAINT pk_orders PRIMARY KEY CLUSTERED
	(o_orderkey)
	WITH (DATA_COMPRESSION = PAGE)
);
GO

INSERT INTO dbo.orders WITH (TABLOCK)
(
	o_orderdate,
    o_orderkey,
    o_custkey,
    o_orderpriority,
    o_shippriority,
    o_clerk,
    o_orderstatus,
    o_totalprice,
    o_comment,
    o_storekey
)
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
FROM	ERP_Demo.dbo.orders
WHERE	o_orderdate >= '2018-01-01'
		AND o_orderdate <= '2018-06-30';
GO


/*
	After the extended event "monitor_lock_escalation" has been
	implemented we can start with the demo!
*/
DECLARE	@num_rows	INT = 1250;
WHILE @num_rows <= 10000
BEGIN
	BEGIN TRANSACTION
		;WITH l
		AS
		(
			SELECT	TOP (@num_rows)
					o_orderkey
			FROM	dbo.orders
		)
		UPDATE	o
		SET		o.o_orderdate = GETDATE()
		FROM	dbo.orders AS o
				INNER JOIN l
				ON (o.o_orderkey = l.o_orderkey)

		SELECT	DISTINCT
				@num_rows		AS	num_rows,
				resource_type,
				OBJECT_NAME(resource_associated_entity_id)	AS	object_name,
				request_mode,
				request_status
		FROM	sys.dm_tran_locks
		WHERE	request_session_id = @@SPID
				AND resource_type = N'OBJECT';
	ROLLBACK

	SET	@num_rows += 1250;
END
GO

/*
	afterwards we clear the kitchen
*/
DROP TABLE IF EXISTS dbo.orders;
GO

IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = N'monitor_lock_escalation')
BEGIN
	RAISERROR (N'dropping existing extended event session [monitor_lock_escalation]...', 0, 1) WITH NOWAIT;
	DROP EVENT SESSION [monitor_lock_escalation] ON SERVER;
END
GO

