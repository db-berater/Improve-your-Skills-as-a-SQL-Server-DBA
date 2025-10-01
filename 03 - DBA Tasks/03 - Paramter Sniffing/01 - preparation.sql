/*
	============================================================================
	File:		01 - preparation.sql

	Summary:	This script prepares the environment for a parameter sniffing
				problem
				
				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Improve your Skills as a SQL Server DBA"

	Date:		October 2025
	Revion:		October 2025

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

EXEC master..sp_create_demo_db
	@num_of_files = 1,
    @initial_size_MB = 1024,
    @use_filegroups = 0;
GO

USE demo_db;
GO

/*
	Create the tables dbo.customers and dbo.nations for the demo
*/
RAISERROR ('creating table [dbo].[customers]...', 0, 1) WITH NOWAIT;
GO

SELECT	*
INTO	dbo.customers
FROM	ERP_Demo.dbo.customers;
GO

RAISERROR ('creating table [dbo].[nations]...', 0, 1) WITH NOWAIT;
GO

SELECT	*
INTO	dbo.nations
FROM	ERP_Demo.dbo.nations;
GO

RAISERROR ('creating indexes on table [dbo].[customers]...', 0, 1) WITH NOWAIT;
GO

ALTER TABLE dbo.customers
ADD CONSTRAINT pk_customers PRIMARY KEY CLUSTERED (c_custkey);
GO

CREATE NONCLUSTERED INDEX nix_customers_c_nationkey
ON dbo.customers (c_nationkey);
GO

RAISERROR ('creating indexes on table [dbo].[nations]...', 0, 1) WITH NOWAIT;
GO

ALTER TABLE dbo.nations
ADD CONSTRAINT pk_nations PRIMARY KEY CLUSTERED (n_nationkey);
GO

RAISERROR ('creating referencial integrity between [dbo].[customers] and [dbo].[nations]...', 0, 1) WITH NOWAIT;
GO

ALTER TABLE dbo.customers
ADD CONSTRAINT fk_customers_nations 
FOREIGN KEY (c_nationkey)
REFERENCES dbo.nations (n_nationkey);
GO

RAISERROR ('creating wrapper object as stored procedure...', 0, 1) WITH NOWAIT;
GO

CREATE OR ALTER PROCEDURE dbo.get_customers_by_nation
	@n_nationkey INT
AS
BEGIN
	SET NOCOUNT ON;

	SELECT	c.c_custkey,
			c.c_name,
			n.n_name
	FROM	dbo.customers AS c
			INNER JOIN dbo.nations AS n
			ON (c.c_nationkey = n.n_nationkey)
	WHERE	n.n_nationkey = @n_nationkey
	ORDER BY
			c.c_name;
END
GO

ALTER DATABASE demo_db SET QUERY_STORE CLEAR;
GO
