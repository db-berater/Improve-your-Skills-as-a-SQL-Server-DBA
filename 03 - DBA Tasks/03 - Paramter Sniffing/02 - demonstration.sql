/*
	============================================================================
	File:		02 - demonstration.sql

	Summary:	This script demonstrates the problems / side effects of 
				parameter sniffing
				
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
USE demo_db;
GO

/*
	Before we start the demos we clear the procedure cache for the demo_db
*/
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

/* run the next query with actual execution plan and watch the parameters */
SET STATISTICS IO, TIME ON;
GO

EXEC dbo.get_customers_by_nation
	@n_nationkey = 44;
GO

EXEC dbo.get_customers_by_nation
	@n_nationkey = 6;
GO

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

EXEC dbo.get_customers_by_nation
	@n_nationkey = 6;
GO

EXEC dbo.get_customers_by_nation
	@n_nationkey = 44;
GO