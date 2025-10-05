/*
	============================================================================
	File:		03 - when will statistics objects be updated.sql

	Summary:	This script demonstrates the situation(s) existing statistics
				objects will be updated

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

/*
	Demonstration of problems with update of stats in the past and now
*/
;WITH l	(rows)
AS
(
	SELECT	CAST(10000 AS BIGINT)		AS	rows

	UNION ALL

	SELECT	rows * 10	AS	rows
	FROM	l
	WHERE	l.rows <= 10000000000
)
SELECT	rows,
		CAST((500 + (rows * 0.2)) AS BIGINT)	AS	[SQL_2014],
		CAST (SQRT(1000 * rows) AS BIGINT)		AS	[SQL_2016],
		CASE WHEN CAST((500 + (rows * 0.2)) AS BIGINT) <CAST (SQRT(1000 * rows) AS BIGINT)
			 THEN N'SQL Server 2014'
			 ELSE N'SQL Server 2016'
		END										AS	UpdateRule
FROM	l;
GO

/*
	We check the actual modification counter of all statistics
	in [dbo].[orders]
*/
SELECT	s.stats_id,
		s.name,
		p.last_updated,
		p.rows,
		p.rows_sampled,
		p.modification_counter		AS	mods,
		CAST
		(
			SQRT(1000 * p.rows)
			AS BIGINT
		)			AS	next_modification
FROM	sys.stats AS s
		CROSS APPLY sys.dm_db_stats_properties
		(
			s.object_id,
			s.stats_id
		) AS p
WHERE	s.object_id = OBJECT_ID(N'dbo.orders', N'U');
GO

/*
	Let's add another day of orders into the table and check the
	statistics afterwards
*/
BEGIN
	INSERT INTO dbo.orders WITH (TABLOCK)
	(
		o_orderdate, o_orderkey, o_custkey, o_orderpriority, o_shippriority, 
		o_clerk, o_orderstatus, o_totalprice, o_comment, o_storekey
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
	WHERE	o_orderdate = '2010-01-02';

	SELECT	s.stats_id,
			s.name,
			p.last_updated,
			p.rows,
			p.rows_sampled,
			p.modification_counter		AS	mods,
			CAST
			(
				SQRT(1000 * p.rows)
				AS BIGINT
			)			AS	next_modification
	FROM	sys.stats AS s
			CROSS APPLY sys.dm_db_stats_properties
			(
				s.object_id,
				s.stats_id
			) AS p
	WHERE	s.object_id = OBJECT_ID(N'dbo.orders', N'U');
END
GO

/*
	Statistics will be updated when the query optimizer hits the next
	time a query which requires the stats for a good plan!
*/
BEGIN
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
	WHERE	o_custkey = 746440;

	SELECT	s.stats_id,
			s.name,
			p.last_updated,
			p.rows,
			p.rows_sampled,
			p.modification_counter		AS	mods,
			CAST
			(
				SQRT(1000 * p.rows)
				AS BIGINT
			)			AS	next_modification
	FROM	sys.stats AS s
			CROSS APPLY sys.dm_db_stats_properties
			(
				s.object_id,
				s.stats_id
			) AS p
	WHERE	s.object_id = OBJECT_ID(N'dbo.orders', N'U');
END
GO

BEGIN
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
	WHERE	o_orderkey = 11315604;

	SELECT	s.stats_id,
			s.name,
			p.last_updated,
			p.rows,
			p.rows_sampled,
			p.modification_counter		AS	mods,
			CAST
			(
				SQRT(1000 * p.rows)
				AS BIGINT
			)			AS	next_modification
	FROM	sys.stats AS s
			CROSS APPLY sys.dm_db_stats_properties
			(
				s.object_id,
				s.stats_id
			) AS p
	WHERE	s.object_id = OBJECT_ID(N'dbo.orders', N'U');
END
GO