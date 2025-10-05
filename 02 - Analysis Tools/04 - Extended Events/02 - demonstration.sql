/*
	============================================================================
	File:		03 - run demo script.sql

	Summary:	This script creates an environment for the demo of Extended Events
	
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
	80 - Extended Events\01 - extended events demo.sql
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
