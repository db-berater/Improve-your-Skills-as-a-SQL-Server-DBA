

USE ERP_Demo;
GO

IF EXISTS (SELECT * FROM sys.dm_xe_sessions WHERE name = N'Track Scalar Functions')
BEGIN
	RAISERROR (N'Dropping XEvent-Session: [Track Scalar Functions]', 0, 1) WITH NOWAIT;
	DROP EVENT SESSION [Track Scalar Functions] ON SERVER;
END
GO