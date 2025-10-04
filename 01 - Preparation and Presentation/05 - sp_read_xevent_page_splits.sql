/*
	============================================================================
	File:		04 - sp_analyse_page_splits.sql

	Summary:	This script creates a stored procedure inside ERP_Demo for 
				the analysis of the XEvent which tracks page splits

				THIS SCRIPT IS PART OF THE TRACK:
					"Index Rebuild vs Index Reorganize"

	Date:		June 2025

	SQL Server Version: 2016 / 2017 / 2019
	============================================================================
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

USE master;
GO

CREATE OR ALTER PROCEDURE dbo.sp_read_xevent_page_splits
	@xevent_name		NVARCHAR(128)
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DROP TABLE IF EXISTS #event_data;

	RAISERROR ('Catching the data from the ring_buffer for extended event [%s]', 0, 1, @xevent_name) WITH NOWAIT;

	SELECT	CAST(target_data AS XML) AS target_data
	INTO	#event_data
	FROM	sys.dm_xe_session_targets AS t
			INNER JOIN sys.dm_xe_sessions AS s
			ON (t.event_session_address = s.address)
	WHERE	s.name = N'monitor_page_splits'
			AND t.target_name = N'ring_buffer';

	RAISERROR ('Analyzing the data from the ring buffer', 0, 1) WITH NOWAIT;

	WITH XE
	AS
	(
		SELECT	x.event_data.value('(@timestamp)[1]','datetime')								AS	[time],
				x.event_data.value('(@name)[1]', 'VARCHAR(128)')								AS	[Event_name],
				x.event_data.value('(data[@name="file_id"]/value)[1]','int')					AS	[file_id],
				x.event_data.value('(data[@name="page_id"]/value)[1]','int')					AS	[page_id],
				x.event_data.value('(data[@name="new_page_page_id"]/value)[1]','int')			AS	[new_page_id],
				x.event_data.value('(data[@name="database_id"]/value)[1]','int')				AS	[database_id],
				x.event_data.value('(data[@name="splitOperation"]/text)[1]','varchar(128)')	AS	[split_operation]
		FROM	#event_data AS ed
				CROSS APPLY ed.target_data.nodes('//RingBufferTarget/event') AS x (event_data)
	)
	SELECT	DISTINCT
			XE.Event_name,
			XE.split_operation,
			XE.page_id,
			XE.new_page_id,
			XE.new_page_id - XE.page_id	AS	split_jump
	FROM	XE
	WHERE	(XE.new_page_id - XE.page_id) > 1
			AND XE.Event_name = 'page_split';
END
GO

EXEC master..sp_ms_marksystemobject N'dbo.sp_read_xevent_page_splits';
GO