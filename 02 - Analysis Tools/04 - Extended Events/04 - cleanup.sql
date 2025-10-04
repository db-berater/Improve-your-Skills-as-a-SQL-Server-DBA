USE ERP_Demo;
GO

EXEC dbo.sp_drop_foreign_keys @table_name = N'ALL';
EXEC dbo.sp_drop_indexes @table_name = N'ALL', @check_only = 0;
EXEC dbo.sp_drop_statistics @table_name = N'ALL', @check_only = 0;
GO

IF EXISTS (SELECT * FROM sys.dm_xe_sessions WHERE name = N'extended_events_demo')
BEGIN
	RAISERROR (N'Dropping XEvent-Session: [extended_events_demo]', 0, 1) WITH NOWAIT;
	DROP EVENT SESSION [extended_events_demo] ON SERVER;
END
GO