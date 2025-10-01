USE ERP_Demo;
GO

:SETVAR event_name      "db SQL Antipatterns"
:SETVAR session_id      75
:SETVAR session_name    "db SQL Antipatterns"
:SETVAR db_name         db_demo

IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = N'$(event_name)')
BEGIN
	RAISERROR (N'Dropping XEvent-Session: [$(event_name)]', 0, 1) WITH NOWAIT;
	DROP EVENT SESSION [$(event_name)] ON SERVER;
END

CREATE EVENT SESSION [$(event_name)] ON SERVER 
ADD EVENT sqlserver.plan_affecting_convert
(
    ACTION
        (
            sqlserver.client_app_name,
            sqlserver.client_hostname,
            sqlserver.session_id,
            sqlserver.sql_text
        )
    WHERE   sqlserver.session_id = $(session_id)
),
ADD EVENT sqlserver.query_antipattern
(
    ACTION
    (
        sqlserver.client_app_name,
        sqlserver.client_hostname,
        sqlserver.session_id,
        sqlserver.sql_text
    )
    WHERE   sqlserver.session_id = $(session_id)
)
ADD TARGET package0.ring_buffer
GO

ALTER EVENT SESSION [$(event_name)] ON SERVER STATE = START;
GO