/*
	============================================================================
	File:		02 - physical index fragmentation.sql

	Summary:	This script prepares the environment for a the index maintenance topic
				
				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Improve your Skills as a SQL Server DBA"

	Date:		October 2025
	Revion:		October 2025

	SQL Server Version: >= 2016
	============================================================================
*/
USE demo_db;
GO

/*
	Let's have a look to the physical fragmentation of the data
*/
SELECT	index_id,
        index_type_desc,
        alloc_unit_type_desc,
        index_level,
        page_count,
        avg_page_space_used_in_percent
FROM	sys.dm_db_index_physical_stats
		(
			DB_ID(),
			OBJECT_ID(N'dbo.orders', N'U'),
			1,
			0,
			N'DETAILED'
		)
ORDER BY
        index_id,
        index_level DESC;
GO

/*
	Now we insert 1,000 new records into the table
*/
EXEC dbo.fill_orders
	@num_records = 1000,
    @where_stmt = NULL,
    @order_key = NULL;
GO

SELECT	index_id,
        index_type_desc,
        alloc_unit_type_desc,
        index_level,
        page_count,
        avg_page_space_used_in_percent
FROM	sys.dm_db_index_physical_stats
		(
			DB_ID(),
			OBJECT_ID(N'dbo.orders', N'U'),
			1,
			0,
			N'DETAILED'
		)
ORDER BY
        index_id,
        index_level DESC;
GO

EXEC dbo.fill_orders
	@num_records = 10000,
    @where_stmt = NULL,
    @order_key = NULL;
GO

SELECT	index_id,
        index_type_desc,
        alloc_unit_type_desc,
        index_level,
        page_count,
        avg_page_space_used_in_percent
FROM	sys.dm_db_index_physical_stats
		(
			DB_ID(),
			OBJECT_ID(N'dbo.orders', N'U'),
			1,
			0,
			N'DETAILED'
		)
ORDER BY
        index_id,
        index_level DESC;
GO


BEGIN TRANSACTION fill_orders
GO
	EXEC dbo.fill_orders
		@num_records = 10000,
		@where_stmt = NULL,
		@order_key = NULL;
	GO

EXEC master..sp_read_xevent_page_splits
	@xevent_name = N'monitor_page_splits';
GO

SELECT	index_id,
        index_type_desc,
        alloc_unit_type_desc,
        index_level,
        page_count,
        avg_page_space_used_in_percent
FROM	sys.dm_db_index_physical_stats
		(
			DB_ID(),
			OBJECT_ID(N'dbo.orders', N'U'),
			1,
			0,
			N'DETAILED'
		)
ORDER BY
        index_id,
        index_level DESC;
GO

/*
	For the next demo please open SQLQueryStress and load the template
	In Windows Admin Center load the template ? and watch the "user counter 1"

	This counter shows the number of page splits within one single transaction!
*/
EXEC dbo.sp_reset_counters
	@clear_wait_stats = 0,
	@clear_user_counters = 1;
GO

SELECT	index_id,
        index_type_desc,
        alloc_unit_type_desc,
        index_level,
        page_count,
        avg_page_space_used_in_percent
FROM	sys.dm_db_index_physical_stats
		(
			DB_ID(),
			OBJECT_ID(N'dbo.orders', N'U'),
			1,
			0,
			N'DETAILED'
		)
ORDER BY
        index_id,
        index_level DESC;
GO

/*
	Let's drop the data from dbo.orders
*/
TRUNCATE TABLE dbo.orders;
GO

SELECT	index_id,
        index_type_desc,
        alloc_unit_type_desc,
        index_level,
        page_count,
        avg_page_space_used_in_percent
FROM	sys.dm_db_index_physical_stats
		(
			DB_ID(),
			OBJECT_ID(N'dbo.orders', N'U'),
			1,
			0,
			N'DETAILED'
		)
ORDER BY
        index_id,
        index_level DESC;
GO

EXEC dbo.sp_reset_counters
	@clear_wait_stats = 0,
	@clear_user_counters = 1;
GO

/*
	Let's rebuild the clustered index on dbo.orders
*/
ALTER INDEX pk_orders ON dbo.orders REBUILD
WITH
(
	FILLFACTOR = 70,
	DATA_COMPRESSION = NONE,
	SORT_IN_TEMPDB = ON
);
GO