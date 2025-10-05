/*
	============================================================================
	File:		01 - preparation.sql

	Summary:	This script prepares the environment for a parameter sniffing
				problem
				
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

/*
	Let's create the demo tables for the demonstration of locking/blocking
*/
BEGIN
	RAISERROR ('Creating demo environment for the topic "Locking/Blocking"', 0, 1) WITH NOWAIT;

	SELECT	c_custkey,
			c_mktsegment,
			c_nationkey,
			c_name,
			c_address,
			c_phone,
			c_acctbal,
			c_comment
	INTO	dbo.customers
	FROM	ERP_Demo.dbo.customers AS c
	WHERE	c_custkey <= 10000;

	SELECT	TOP(1000000)
			*
	INTO	dbo.orders
	FROM	ERP_Demo.dbo.orders AS o
	WHERE	o_custkey IN
			(
				SELECT	c_custkey
				FROM	dbo.customers
			);
END
GO

BEGIN
	RAISERROR ('Optimizing tables for the demos', 0, 1) WITH NOWAIT;

	ALTER TABLE dbo.orders
	ADD CONSTRAINT pk_orders PRIMARY KEY CLUSTERED (o_orderkey)
	WITH
	(
		DATA_COMPRESSION = PAGE,
		SORT_IN_TEMPDB = ON
	);
END
GO
