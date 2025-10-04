/*
	============================================================================
	File:		02 - read shared locks.sql

	Summary:	creates an Extended Event to track all locks from a SELECT
				against a resource in READ COMMITTED isolation level
				
				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Improve your Skills as a SQL Server DBA"

	Date:		January 2025

	SQL Server Version: >= 2016
	============================================================================
*/
USE master;
GO

/*
	NOTE:		RUN THIS SCRIPT IN SQLCMD MODUS!!!

	Explanation of variables:

	EventName:	Name of the Extended Event session
	db_name:	Name of the database
*/
:SETVAR EventName	monitor_page_splits
:SETVAR	db_name		demo_db

PRINT N'-------------------------------------------------------------';
PRINT N'| Installation script by db Berater GmbH                     |';
PRINT N'| https://www.db-berater.de                                  |';
PRINT N'| Uwe Ricken - uwe.ricken@db-berater.de                      |';
PRINT N'-------------------------------------------------------------';
GO

IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = N'$(EventName)')
BEGIN
	RAISERROR (N'dropping existing extended event session $(EventName)...', 0, 1) WITH NOWAIT;
	DROP EVENT SESSION [$(EventName)] ON SERVER;
END
GO

RAISERROR (N'creating extended event session $(EventName)...', 0, 1) WITH NOWAIT;
CREATE EVENT SESSION [$(EventName)] ON SERVER 
ADD EVENT sqlserver.page_split
(
    WHERE [database_name] = N'$(db_name)'
)
ADD TARGET package0.histogram
(
	SET filtering_event_name = N'sqlserver.page_split',
		source = N'splitOperation',
		source_type = 0
),
ADD TARGET package0.ring_buffer
WITH
(
	MAX_MEMORY=4096 
	KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,
	MAX_DISPATCH_LATENCY=5 SECONDS,
	MAX_EVENT_SIZE=0 KB,
	MEMORY_PARTITION_MODE = NONE,
	TRACK_CAUSALITY = OFF,
	STARTUP_STATE = OFF
);
GO

ALTER EVENT SESSION [$(EventName)] ON SERVER STATE = START;
GO