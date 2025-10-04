/*
	============================================================================
	File:		03 - logical index fragmentation.sql

	Summary:	This script prepares the environment for a the index maintenance topic
				
				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Improve your Skills as a SQL Server DBA"

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

BEGIN
	DROP TABLE IF EXISTS dbo.orders;

	SELECT	TOP (500)
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
	INTO	dbo.orders
	FROM	ERP_Demo.dbo.orders AS o
	WHERE	o_orderkey % 2 = 0
	ORDER BY
			o.o_orderkey

	ALTER TABLE dbo.orders ADD CONSTRAINT
	pk_orders PRIMARY KEY CLUSTERED (o_orderkey);
END
GO

/*
	Let's recieve a few more information about the data pages of dbo.orders
*/
BEGIN
	DROP TABLE IF EXISTS #t;

	CREATE TABLE #t
	(
		previous_page_id	BIGINT	NULL,
		allocaged_page_id	BIGINT	NOT NULL,
		next_page_id		BIGINT	NULL,
		num_rows_page		INT		NULL,
		free_bytes			INT		NULL
	);

	INSERT INTO #t
	(previous_page_id, allocaged_page_id, next_page_id, num_rows_page, free_bytes)
	SELECT	p_a.previous_page_page_id,
			p_a.allocated_page_page_id,
			p_a.next_page_page_id,
			p_i.slot_count,
			p_i.free_bytes
	FROM	sys.dm_db_database_page_allocations
			(
				DB_ID(),
				OBJECT_ID(N'dbo.orders', N'U'),
				1,
				NULL,
				N'DETAILED'
			) AS p_a
			CROSS APPLY sys.dm_db_page_info
			(
				p_a.database_id,
				p_a.allocated_page_file_id,
				p_a.allocated_page_page_id,
				N'DETAILED'
			) p_i
	WHERE	p_a.is_iam_page = 0
			AND p_a.page_type = 1

	;WITH l
	AS
	(
		SELECT	1						AS	page_order,
				t.previous_page_id,
				t.allocaged_page_id,
				t.next_page_id,
				t.num_rows_page,
				t.free_bytes
		FROM	#t AS t
		WHERE	previous_page_id IS NULL

		UNION ALL

		SELECT	l.page_order + 1		AS	page_order,
				t.previous_page_id,
				t.allocaged_page_id,
				t.next_page_id,
				t.num_rows_page,
				t.free_bytes
		FROM	#t AS t INNER JOIN l
				ON (t.allocaged_page_id = l.next_page_id)
	)
	SELECT	l.page_order,
			l.previous_page_id,
			l.allocaged_page_id,
			l.next_page_id,
			CASE WHEN l.next_page_id - l.allocaged_page_id > 1
				 THEN 'true'
				 ELSE 'false'
			END					AS	is_logical_fragmentation,
			l.num_rows_page,
			l.free_bytes
	FROM	l
	ORDER BY
		page_order ASC;
END
GO

/*
	Now we insert another 500 records into the table
*/
INSERT INTO dbo.orders WITH (TABLOCK)
(
	o_orderdate, o_orderkey, o_custkey, o_orderpriority, o_shippriority, 
	o_clerk, o_orderstatus, o_totalprice, o_comment, o_storekey
)
SELECT	TOP (500)
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
FROM	ERP_Demo.dbo.orders AS o
WHERE	o_orderkey % 2 = 1
ORDER BY
		o.o_orderkey;
GO

BEGIN
	DROP TABLE IF EXISTS #t;

	CREATE TABLE #t
	(
		previous_page_id	BIGINT	NULL,
		allocaged_page_id	BIGINT	NOT NULL,
		next_page_id		BIGINT	NULL,
		num_rows_page		INT		NULL,
		free_bytes			INT		NULL
	);

	INSERT INTO #t
	(previous_page_id, allocaged_page_id, next_page_id, num_rows_page, free_bytes)
	SELECT	p_a.previous_page_page_id,
			p_a.allocated_page_page_id,
			p_a.next_page_page_id,
			p_i.slot_count,
			p_i.free_bytes
	FROM	sys.dm_db_database_page_allocations
			(
				DB_ID(),
				OBJECT_ID(N'dbo.orders', N'U'),
				1,
				NULL,
				N'DETAILED'
			) AS p_a
			CROSS APPLY sys.dm_db_page_info
			(
				p_a.database_id,
				p_a.allocated_page_file_id,
				p_a.allocated_page_page_id,
				N'DETAILED'
			) p_i
	WHERE	p_a.is_iam_page = 0
			AND p_a.page_type = 1

	;WITH l
	AS
	(
		SELECT	1						AS	page_order,
				t.previous_page_id,
				t.allocaged_page_id,
				t.next_page_id,
				t.num_rows_page,
				t.free_bytes
		FROM	#t AS t
		WHERE	previous_page_id IS NULL

		UNION ALL

		SELECT	l.page_order + 1		AS	page_order,
				t.previous_page_id,
				t.allocaged_page_id,
				t.next_page_id,
				t.num_rows_page,
				t.free_bytes
		FROM	#t AS t INNER JOIN l
				ON (t.allocaged_page_id = l.next_page_id)
	)
	SELECT	l.page_order,
			l.previous_page_id,
			l.allocaged_page_id,
			l.next_page_id,
			CASE WHEN l.next_page_id - l.allocaged_page_id > 1
				 THEN 'true'
				 ELSE 'false'
			END					AS	is_logical_fragmentation,
			l.num_rows_page,
			l.free_bytes
	FROM	l
	ORDER BY
		page_order ASC;
END
GO
