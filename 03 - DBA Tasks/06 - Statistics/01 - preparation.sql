/*
	============================================================================
	File:		01 - preparation.sql

	Summary:	This script prepares the environment for a the statistics topic
				
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

/*
	Create a table with ~6.500 rows
*/
USE demo_db;
GO

;WITH l
AS
(
	SELECT	MIN(o_orderdate)	AS	o_orderdate
	FROM	ERP_Demo.dbo.orders
)
SELECT	o.o_orderdate,
        o.o_orderkey,
        o.o_custkey,
        o.o_orderpriority,
        o.o_shippriority,
        o.o_clerk,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_comment,
        o.o_storekey
INTO	dbo.orders
FROM	ERP_Demo.dbo.orders AS o
		INNER JOIN l
		ON (o.o_orderdate = l.o_orderdate)
GO

ALTER TABLE dbo.orders
ADD CONSTRAINT pk_orders
PRIMARY KEY CLUSTERED (o_orderkey);
GO

/*
	Show the first analysis of available statistics and
	the properties of the statistics
*/
SELECT	s.stats_id,
		s.name,
        s.auto_created,
        s.user_created,
        s.no_recompute,
        s.has_filter,
        s.filter_definition,
        s.has_persisted_sample,
        s.auto_drop
FROM	sys.stats AS s
WHERE	s.object_id = OBJECT_ID(N'dbo.orders', N'U');
GO

/* See the actual properties of the statistics */
SELECT	s.stats_id,
		s.name,
		sp.object_id,
        sp.stats_id,
        sp.last_updated,
        sp.rows,
        sp.rows_sampled,
        sp.steps,
        sp.unfiltered_rows,
        sp.modification_counter
FROM	sys.stats AS s
		CROSS APPLY sys.dm_db_stats_properties
		(
			s.object_id,
			s.stats_id
		) AS sp
WHERE	s.object_id = OBJECT_ID(N'dbo.orders', N'U');
GO
