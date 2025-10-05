/*
	============================================================================
	File:		02 - when will statistics objects be created.sql

	Summary:	This script demonstrates the situation(s) when new statistics
				objects will be created

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

/* what statistics do we have in an initial table? */
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

/*
    If a column of a table does not have an index a statistics object
    will be created automatically if the option "AUTO_CREATE_STATISTICS" 
    is set to ON.
*/
BEGIN
    SELECT  o_orderdate,
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

    /*
        A new statistics object _WA_Sys_... has been created for the column
        [o_custkey]
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
END
GO

BEGIN
    SELECT  o_orderdate,
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
    WHERE	o_orderdate = '2010-01-01';

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
END
GO

/*
    If there is an existing auto created statistics object in the 
    database it will NOT be deleted if you create an index afterwards!
*/
BEGIN
    CREATE NONCLUSTERED INDEX nix_orders_o_custkey
    ON dbo.orders (o_custkey);

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
END
GO

/* See the actual properties of the statistics */
SELECT	s.stats_id,
		s.name,
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

/*
    The histogram will be used by the query optimizer when he sniffs
    the value of the literal / variable for a query
*/
SELECT  s.stats_id,
        s.name,
        sh.step_number,
        sh.range_high_key,
        sh.range_rows,
        sh.equal_rows,
        sh.distinct_range_rows,
        sh.average_range_rows
FROM    sys.stats AS s
        CROSS APPLY sys.dm_db_stats_histogram
        (
            s.object_id,
            s.stats_id
        ) AS sh
WHERE	s.object_id = OBJECT_ID(N'dbo.orders', N'U')
        AND s.stats_id = 3  /* o_orderdate */;
GO

SELECT  s.stats_id,
        s.name,
        sh.step_number,
        sh.range_high_key,
        sh.range_rows,
        sh.equal_rows,
        sh.distinct_range_rows,
        sh.average_range_rows
FROM    sys.stats AS s
        CROSS APPLY sys.dm_db_stats_histogram
        (
            s.object_id,
            s.stats_id
        ) AS sh
WHERE	s.object_id = OBJECT_ID(N'dbo.orders', N'U')
        AND s.stats_id = 2
        /*
            2: o_custkey    auto stats
            4: o_custkey    INDEX
        */;
GO

/*
    Let's remove all auto stats objects from the table
*/
BEGIN
    DECLARE @sql_cmd NVARCHAR(MAX);

    DECLARE c CURSOR LOCAL READ_ONLY FORWARD_ONLY
    FOR
        SELECT  N'DROP STATISTICS dbo.orders.' + QUOTENAME(name)
        FROM    sys.stats AS s
        WHERE	s.object_id = OBJECT_ID(N'dbo.orders', N'U')
                AND s.auto_created = 1;

    OPEN c;
    FETCH NEXT FROM c INTO @sql_cmd;
    WHILE @@FETCH_STATUS <> -1
    BEGIN
        EXEC sp_executesql @sql_cmd;
        FETCH NEXT FROM c INTO @sql_cmd;
    END

    CLOSE c;
    DEALLOCATE c;

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
END
GO
