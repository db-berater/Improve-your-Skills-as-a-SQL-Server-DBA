/*
	============================================================================
	File:		08 - scenario 01 - clean the environment.sql

	Summary:	This script removes all custom objects from the database which 
				have been used for the demos!

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

DROP PROCEDURE IF EXISTS dbo.get_customer_classification;
DROP FUNCTION IF EXISTS dbo.calculate_customer_category;
GO

/* Remove all indexes */
EXEC dbo.sp_drop_foreign_keys @table_name = N'ALL';
GO

EXEC dbo.sp_drop_indexes @table_name = N'dbo.orders',		@check_only = 0;
EXEC dbo.sp_drop_indexes @table_name = N'dbo.customers',	@check_only = 0;
GO

/* Remove extended events used for this demo */
IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = N'Track Scalar Functions')
	DROP EVENT SESSION [Track Scalar Functions] ON SERVER;
GO
