/*============================================================================
	File:		03 - Backup Restore Filegroups.sql

	Summary:	This demo shows the management of backup / restore strategies
				for VLDB and multiple filegroups

	Date:		May 2025

	SQL Server Version: >= 2016
------------------------------------------------------------------------------

	THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
	ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
	TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
	PARTICULAR PURPOSE.
============================================================================*/
USE master;
GO

/*
	Let's create a database first for the storage of data
	Note:	The database will have 8 different files.
			Every file is in a separate filegroup!
*/
EXEC dbo.sp_create_demo_db
	@num_of_files = 8,
	@initial_size_MB = 1024,
	@use_filegroups = 1;
GO

SELECT	fg.name,
        fg.type_desc,
        fg.is_default,
        fg.is_read_only,
        fg.is_autogrow_all_files,
        f.file_id,
        f.type_desc,
        f.name,
        f.physical_name,
        f.size_mb,
        f.max_size_mb,
        f.growth_mb
FROM	demo_db.sys.filegroups AS fg
		CROSS APPLY
		(
			SELECT	mf.file_id,
                    mf.type_desc,
                    mf.name,
                    mf.physical_name,
                    mf.size / 128		AS	size_mb,
                    mf.max_size / 128	AS	max_size_mb,
                    mf.growth / 128	AS	growth_mb
			FROM	sys.master_files AS mf
			WHERE	mf.database_id = DB_ID(N'demo_db')
					AND data_space_id = fg.data_space_id
		) AS f;
GO

/*
	After the database has been created we can start to create a
	partitioned table for the demo
*/
USE demo_db;
GO

/*
	Let's create a partition function for the last 8 years
	from ERP_Demo.dbo.orders
*/
CREATE PARTITION FUNCTION pf_orders (DATE)
AS RANGE RIGHT FOR VALUES
('2015','2016', '2017', '2018', '2019', '2020', '2021', '2022');
GO

/*
	and we need a partition scheme for the distribution of data
	over all data files
*/
CREATE PARTITION SCHEME ps_orders AS PARTITION pf_orders
TO
(
	[PRIMARY],
	[filegroup_01],filegroup_02,filegroup_03, filegroup_04,
	filegroup_05, filegroup_06, filegroup_07, filegroup_08
);
GO

/*
	Now we create our table dbo.orders on the partition scheme
	before we can add data into it!
*/
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
	o_storekey bigint NOT NULL
) 
ON ps_orders (o_orderdate)
WITH
(DATA_COMPRESSION = PAGE);
GO

CHECKPOINT;
GO

/*
	And now we push the data from 2015 - 2022 into the new table
*/
SET NOCOUNT ON;
GO

DECLARE	@order_year INT = 2015

WHILE @order_year <= 2022
BEGIN
	RAISERROR ('inserting date for the year %i in dbo.orders', 0, 1, @order_year) WITH NOWAIT;

	INSERT INTO dbo.orders WITH (TABLOCK)
	(o_orderdate, o_orderkey, o_custkey, o_orderpriority, o_shippriority, o_clerk, o_orderstatus, o_totalprice, o_storekey)
	SELECT	o_orderdate,
			o_orderkey,
			o_custkey, 
			o_orderpriority, 
			o_shippriority, 
			o_clerk, 
			o_orderstatus, 
			o_totalprice, 
			o_storekey
	FROM	ERP_Demo.dbo.orders
	WHERE	o_orderdate >= DATEFROMPARTS(@order_year, 1, 1)
			AND o_orderdate < DATEFROMPARTS(@order_year + 1, 1, 1);

	SET	@order_year += 1;
	CHECKPOINT;
END
GO

/*
	Now we can check the distribution of data in each partition
*/
SELECT	p.partition_number,
		fg.name			AS	filegroup_name,
		p.rows
        , au.type_desc
FROM	demo_db.sys.partitions AS p
		INNER JOIN demo_db.sys.allocation_units AS au
		ON (p.hobt_id = au.container_id)
		INNER JOIN demo_db.sys.filegroups AS fg
		ON (au.data_space_id = fg.data_space_id)
WHERE	p.object_id = OBJECT_ID(N'dbo.orders', N'U')
		AND p.index_id <= 1;
GO

/*
	The business want to make sure that only the two
	business years are restored in time.

	Older data can be restored within a different SLA agreement!
*/