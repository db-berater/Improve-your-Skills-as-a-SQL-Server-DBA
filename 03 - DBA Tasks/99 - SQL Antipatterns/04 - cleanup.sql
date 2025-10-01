USE master;
GO

IF DB_ID(N'demo_db') IS NOT NULL
BEGIN
	RAISERROR (N'Dropping database [demo_db]', 0, 1) WITH NOWAIT;
	ALTER DATABASE demo_db SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE demo_db;
END
GO

IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = N'db SQL Antipatterns')
BEGIN
	RAISERROR (N'Dropping XEvent-Session: [db SQL Antipatterns]', 0, 1) WITH NOWAIT;
	DROP EVENT SESSION [db SQL Antipatterns] ON SERVER;
END