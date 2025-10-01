/*
	============================================================================
	File:		01 - Preparation.sql

	Summary:	This script prepare the environment for the topic
				- SQL Antipatterns
				
				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Workshop - Improve your skills as a DBA"

	Date:		October 2025
	Revion:		November 2025

	SQL Server Version: >= 2016
	------------------------------------------------------------------------------
	Written by Uwe Ricken, db Berater GmbH

	This script is intended only as a supplement to demos and lectures
	given by Uwe Ricken.  
  
	THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
	ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
	TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
	PARTICULAR PURPOSE.
	============================================================================
*/
USE master;
GO

RAISERROR ('creating the demo database with one database file', 0, 1) WITH NOWAIT;
GO

DECLARE	@return_value INT = 0;

EXEC	@return_value = master..sp_create_demo_db
							@num_of_files = 1,
							@initial_size_MB = 1024;
GO

RAISERROR ('Creating the schema for the demos "SQL Antipatterns"', 0, 1) WITH NOWAIT;
GO

USE demo_db;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

RAISERROR ('Creating the table dbo.customers', 0, 1) WITH NOWAIT;
SELECT * INTO dbo.customers FROM ERP_Demo.dbo.customers;
GO

RAISERROR ('Creating indexes for table dbo.customers', 0, 1) WITH NOWAIT;
GO

ALTER TABLE dbo.customers
ALTER COLUMN c_custkey BIGINT NOT NULL;
GO

ALTER TABLE dbo.customers
ADD CONSTRAINT pk_customers PRIMARY KEY CLUSTERED (c_custkey)
WITH
(
	DATA_COMPRESSION = PAGE,
	SORT_IN_TEMPDB = ON
);
GO

CREATE NONCLUSTERED INDEX nix_customers_c_mktsegment
ON dbo.customers (c_mktsegment)
WITH
(
	DATA_COMPRESSION = PAGE,
	SORT_IN_TEMPDB = ON
);
GO

RAISERROR ('Creating the table dbo.orders', 0, 1) WITH NOWAIT;
GO

SELECT	[o_orderdate]
		, [o_orderkey]
		, CAST([o_custkey]			AS VARCHAR(16))	AS	o_custkey
		, CAST([o_orderpriority]	AS NCHAR(1))	AS	o_orderpriority
		, [o_shippriority]
		, [o_clerk]
		, [o_orderstatus]
		, [o_totalprice]
		, [o_comment]
		, [o_storekey]
INTO	dbo.orders
FROM	ERP_Demo.dbo.orders AS o
WHERE	o.o_orderdate >= '2020-01-01'
		AND o.o_orderdate < '2024-01-01';
GO

RAISERROR ('Creating indexes for table dbo.orders', 0, 1) WITH NOWAIT;
GO

ALTER TABLE dbo.orders ALTER COLUMN o_orderkey BIGINT NOT NULL;
ALTER TABLE dbo.orders ALTER COLUMN o_custkey VARCHAR(16) NOT NULL;
GO

ALTER TABLE dbo.orders
ADD CONSTRAINT pk_orders PRIMARY KEY CLUSTERED (o_orderkey)
WITH
(
	DATA_COMPRESSION = PAGE,
	SORT_IN_TEMPDB = ON
);
GO

CREATE NONCLUSTERED INDEX nix_orders_o_custkey
ON dbo.orders (o_custkey)
INCLUDE (o_orderdate)
WITH
(
	DATA_COMPRESSION = PAGE,
	SORT_IN_TEMPDB = ON
);
GO

CREATE NONCLUSTERED INDEX nix_orders_o_orderpriority
ON dbo.orders (o_orderpriority)
WITH
(
	DATA_COMPRESSION = PAGE,
	SORT_IN_TEMPDB = ON
);
GO
