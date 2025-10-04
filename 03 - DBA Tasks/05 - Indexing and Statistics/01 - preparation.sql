/*
	============================================================================
	File:		01 - preparation.sql

	Summary:	This script prepares the environment for a the index maintenance topic
				
				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Improve your Skills as a SQL Server DBA"

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

SET NOCOUNT ON;
GO

BEGIN
	RAISERROR ('Creating table dbo.orders without data', 0, 1) WITH NOWAIT
	SELECT	NEWID()		AS	o_orderkey,
			o_orderdate,
            o_custkey,
            o_orderpriority,
            o_shippriority,
            o_clerk,
            o_orderstatus,
            o_totalprice,
            o_comment,
            o_storekey
	INTO	dbo.orders
	FROM	ERP_Demo.dbo.orders
	WHERE	1 = 0;

	ALTER TABLE dbo.orders ALTER COLUMN o_orderkey UNIQUEIDENTIFIER NOT NULL;

	RAISERROR ('Inserting 10,000 rows into the empty table', 0, 1) WITH NOWAIT;

	;WITH l (o_orderkey, o_orderdate, o_custkey, o_orderpriority, o_shippriority, o_clerk, o_orderstatus, o_totalprice, o_comment, o_storekey)
	AS
	(
		SELECT	TOP (10000)
				NEWID()			AS	o_orderkey,
				o_orderdate,
                o_custkey,
                o_orderpriority,
                o_shippriority,
                o_clerk,
                o_orderstatus,
                o_totalprice,
                o_comment,
                o_storekey
		FROM	ERP_Demo.dbo.orders
		ORDER BY
				o_orderkey
	)
	INSERT INTO dbo.orders WITH (TABLOCK)
	SELECT	*
	FROM	l
	ORDER BY
			l.o_orderkey;

	RAISERROR ('Creating a clustered index on dbo.orders', 0, 1) WITH NOWAIT;
	ALTER TABLE dbo.orders
	ADD CONSTRAINT pk_orders PRIMARY KEY CLUSTERED (o_orderkey)
	WITH
	(
		DATA_COMPRESSION = PAGE,
		SORT_IN_TEMPDB = ON
	);

	RAISERROR ('Creating an additional index on o_orderdate', 0, 1) WITH NOWAIT;
	CREATE NONCLUSTERED INDEX nix_orders_o_orderdate
	ON dbo.orders (o_orderdate)
	WITH
	(
		DATA_COMPRESSION = PAGE,
		SORT_IN_TEMPDB = ON
	);
END
GO

RAISERROR ('Creating stored procedure dbo.fill_orders for demonstration purposes', 0, 1) WITH NOWAIT;
GO

CREATE OR ALTER PROCEDURE dbo.fill_orders
	@num_records INT = 1000,
	@where_stmt	NVARCHAR(MAX) = NULL,
	@order_key NVARCHAR(128) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE	@avg_page_space_used	INT;
	DECLARE	@num_pages				INT;

	DECLARE	@num_rows INT;
	DECLARE	@sql_stmt NVARCHAR(MAX) = N'INSERT INTO dbo.orders WITH (TABLOCK)
SELECT	TOP (' + CAST(@num_records AS NVARCHAR(16)) + N')
		NEWID()	AS	o_orderkey,
		o_orderdate,
		o_custkey,
		o_orderpriority,
		o_shippriority,
		o_clerk,
		o_orderstatus,
		o_totalprice,
		o_comment,
		o_storekey
FROM    ERP_Demo.dbo.orders
' +
	CASE WHEN @where_stmt IS NOT NULL
		 THEN 'WHERE   ' + @where_stmt
		 ELSE ''
	END +N'
' +
	CASE WHEN @order_key IS NOT NULL
		 THEN N'ORDER BY ' + QUOTENAME(@order_key) + N';'
		 ELSE N''
	END

	BEGIN TRY
		PRINT @sql_stmt;
		EXEC sp_executesql @sql_stmt;
		SET	@num_rows = @@ROWCOUNT;

		SELECT	@avg_page_space_used = CAST(avg_page_space_used_in_percent AS INT),
				@num_pages = CAST(page_count AS INT) / 100
		FROM	sys.dm_db_index_physical_stats
				(
					DB_ID(),
					OBJECT_ID(N'dbo.orders', N'U'),
					1,
					0,
					N'DETAILED'
				)
		WHERE	index_level = 0;

		DBCC SETINSTANCE('SQLServer:User Settable', 'Query', 'User counter 1', @num_pages);
		DBCC SETINSTANCE('SQLServer:User Settable', 'Query', 'User counter 2', @avg_page_space_used);

		RAISERROR ('%i rows have been inserted into [dbo].[orders]', 0, 1, @num_rows) WITH NOWAIT;
	END TRY
	BEGIN CATCH
		PRINT ERROR_MESSAGE();
	END CATCH
END
GO