USE demo_db;
GO

DROP TABLE IF EXISTS dbo.orders;
GO

IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = N'monitor_page_splits')
BEGIN
	RAISERROR (N'dropping existing extended event session monitor_page_splits...', 0, 1) WITH NOWAIT;
	DROP EVENT SESSION [monitor_page_splits] ON SERVER;
END
GO