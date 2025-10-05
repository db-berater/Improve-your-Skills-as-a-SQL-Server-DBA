/*
	============================================================================
	File:		01 - extended events demo.sql

	Summary:	creates an Extended Event for the demonstration of powerful analysis
				with extended events.
				
				THIS SCRIPT IS PART OF THE TRACK:
					"Workshop - Improve your DBA Skills"

	Version:	1.00.000

	Date:		October 2025
	Revion:		October 2025

	SQL Server Version: >= 2016
	============================================================================
*/
USE master;
GO

/*
	NOTE:		RUN THIS SCRIPT IN SQLCMD MODUS!!!

	Explanation of variables:
	EventName:	Name of the Extended Event session

	session_id:		session_id to track
*/
:SETVAR EventName				extended_events_demo
:SETVAR	session_id				52

:SETVAR	show_execution_plan		0
:SETVAR show_start_statement	0

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

CREATE EVENT SESSION [$(EventName)]
	ON SERVER
	ADD EVENT sqlserver.sp_statement_completed
	(
		ACTION (package0.event_sequence)
		WHERE sqlserver.session_id = $(session_id)
	),
	ADD EVENT sqlserver.sql_statement_completed
	(
		ACTION (package0.event_sequence)
		WHERE
		sqlserver.session_id = $(session_id)
	)
	WITH
	(
		MAX_MEMORY = 4096KB,
		EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS,
		MAX_DISPATCH_LATENCY = 5 SECONDS,
		MAX_EVENT_SIZE = 0KB,
		MEMORY_PARTITION_MODE = NONE,
		TRACK_CAUSALITY = OFF,
		STARTUP_STATE = OFF
	);

IF $(show_execution_plan) = 1
BEGIN
	RAISERROR (N'adding events for execution plans: [$(EventName)]', 0, 1) WITH NOWAIT;

	ALTER EVENT SESSION [$(EventName)] ON SERVER
	ADD EVENT sqlserver.query_post_compilation_showplan
	(ACTION (package0.event_sequence)),
	ADD EVENT sqlserver.query_post_execution_showplan
	(ACTION (package0.event_sequence));
END

IF $(show_start_statement) = 1
BEGIN
	RAISERROR (N'adding events for starting statements: [$(EventName)]', 0, 1) WITH NOWAIT;

	ALTER EVENT SESSION [$(EventName)] ON SERVER
	ADD EVENT sqlserver.sp_statement_starting
	(
		ACTION (package0.event_sequence)
		WHERE sqlserver.session_id = $(session_id)
	),
	ADD EVENT sqlserver.sql_statement_starting
	(
		ACTION (package0.event_sequence)
		WHERE sqlserver.session_id = $(session_id)
	)
END
GO

RAISERROR (N'Starting XEvent-Session: [$(EventName)]', 0, 1) WITH NOWAIT;
ALTER EVENT SESSION [$(EventName)] ON SERVER STATE = START;
GO