/*
	============================================================================
	File:		03 - run demo script.sql

	Summary:	This script creates an environment for the demo of Extended Events
	
				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Workshop - Improve your Skills as a SQL Server DBA"

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
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

USE ERP_Demo;
GO

/* We run the procedure without any measures */
EXEC dbo.get_customer_classification;
GO

/* For a better understanding you should activate IO, TIME statistics */
SET STATISTICS IO, TIME ON;
GO

EXEC dbo.get_customer_classification;
GO

/*
	Get more clearance when you run the stored procedure with a monitoring
	by an extended event!

	Implement the extened event *** by executing the script
	08 - Extended Events\01 - scalar functions.sql
*/
EXEC dbo.get_customer_classification;
GO

/*
	After evaluation of the function we detect lots of exec calls.
	The developer sends a new script for the optimization

	Implement the script 04 - Extended Events\03 - optmization.sql
	and run the query again. Watch the extended event results!
*/
EXEC dbo.get_customer_classification;
GO
