/*
	============================================================================
	File:		01 - preparation.sql

	Summary:	This script creates an environment for the demo of Resource Monitor
	
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

USE master;
GO

EXEC master..sp_create_demo_db
	@num_of_files = 4,
    @initial_size_MB = 1024,
	@use_filegroups = 1;
GO

USE demo_db;
GO


/*
	We create a partition function for 4 years
*/
DROP TABLE IF EXISTS dbo.orders;
GO

IF EXISTS (SELECT * FROM sys.partition_schemes WHERE name = N'ps_order')
	DROP PARTITION SCHEME ps_orders;
GO

IF EXISTS (SELECT * FROM sys.partition_functions WHERE name = N'pf_orders')
	DROP PARTITION FUNCTION pf_orders;
GO

CREATE PARTITION FUNCTION pf_orders (DATE)
AS RANGE RIGHT FOR VALUES 
(
	'2010-01-01',
	'2011-01-01',
	'2012-01-01',
	'2013-01-01'
);
GO

CREATE PARTITION SCHEME ps_orders
AS PARTITION pf_orders TO
(
	[PRIMARY], 
	[Filegroup_01], 
	[Filegroup_02], 
	[Filegroup_03],
	[Filegroup_04]
);
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
	(
		o_orderkey,
		o_orderdate
	)
	WITH (DATA_COMPRESSION = PAGE)
	ON ps_orders(o_orderdate)
);
GO

ALTER TABLE dbo.orders SET (LOCK_ESCALATION = AUTO);
GO

/* Wrapper procedure for the execution of 4 parallel threads */
CREATE OR ALTER PROCEDURE dbo.load_orders
	@order_year INT,
	@truncate_table INT = 0
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	IF @truncate_table = 1
	BEGIN
		DECLARE	@partition_id INT = $PARTITION.pf_orders(DATEFROMPARTS(@order_year, 1, 1));
		TRUNCATE TABLE dbo.orders WITH (PARTITIONS(@partition_id));
	END

	INSERT INTO dbo.orders
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
	SELECT	*
	FROM	ERP_Demo.dbo.orders
	WHERE	o_orderdate >= DATEFROMPARTS(@order_year, 1, 1)
			AND o_orderdate < DATEFROMPARTS(@order_year + 1, 1, 1);
END
GO


/*
EXEC sp_whoisactive;


BEGIN TRANSACTION;
GO
	TRUNCATE TABLE dbo.orders WITH (PARTITIONS (2));

	SELECT	resource_type,
            resource_subtype,
            resource_description,
            resource_associated_entity_id,
            resource_lock_partition,
            request_mode,
            request_type,
            request_status
	FROM	sys.dm_tran_locks WHERE request_session_id = @@SPID
            AND resource_type = N'OBJECT';
ROLLBACK


SELECT * INTO dbo.switch FROM dbo.orders WHERE 1 = 0;

ALTER TABLE dbo.switch DROP CONSTRAINT pk_switch;
GO

ALTER TABLE dbo.switch ADD CONSTRAINT pk_switch PRIMARY KEY CLUSTERED
(
    o_orderkey,
    o_orderdate
)
WITH (DATA_COMPRESSION = PAGE)
ON ps_orders (o_orderdate);
GO

*
ALTER TABLE dbo.orders SWITCH PARTITION (2) TO dbo.switch PARTITION (2);
TRUNCATE TABLE dbo.switch WITH (PARTITIONS(2));
ALTER TABLE dbo.switch SWITCH PARTITION (2) TO dbo.orders PARTITION (2);
GO

*/