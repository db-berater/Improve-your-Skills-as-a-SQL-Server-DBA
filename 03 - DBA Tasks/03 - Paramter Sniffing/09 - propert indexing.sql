/*
	============================================================================
	File:		09 - proper indexing.sql

	Summary:	Most parameter sniffing problems (IO) are coming from not proper
				indexing (Key/Rid Lookups).
				To avoid these costs just cover the attributes in the index
				
				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Improve your Skills as a SQL Server DBA"

	Date:		October 2025
	Revion:		October 2025

	SQL Server Version: >= 2022
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
USE demo_db;
GO

EXEC dbo.get_customers_by_nation @n_nationkey = 44;
GO

EXEC dbo.get_customers_by_nation @n_nationkey = 6;
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

/*
	See this solution in action and have a look to the different
	execution plans!
*/
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
EXEC dbo.get_customers_by_nation @n_nationkey = 44;
GO

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
EXEC dbo.get_customers_by_nation @n_nationkey = 6;
GO

/* Let's apply a proper index to dbo.customers to avoid the key lookups */
CREATE NONCLUSTERED INDEX nix_customers_c_nationkey
ON dbo.customers (c_nationkey)
INCLUDE (c_name)
WITH
(
	DROP_EXISTING = ON,
	SORT_IN_TEMPDB = ON,
	DATA_COMPRESSION = PAGE
);
GO

