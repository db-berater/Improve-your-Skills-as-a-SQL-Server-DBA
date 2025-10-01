/*
	============================================================================
	File:		0030 - Repair corrupt databases.sql

	Summary:	This script demonstrates different ways to backup databases!
								
				THIS SCRIPT IS PART OF THE TRACK: "SQL Server - Backup and Restore"

	Date:		November 2018

	SQL Server Version: 2016 / 2017
------------------------------------------------------------------------------
	Written by Uwe Ricken, db Berater GmbH

	This script is intended only as a supplement to demos and lectures
	given by Uwe Ricken.  
  
	THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
	ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
	TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
	PARTICULAR PURPOSE.
	============================================================================
*/
USE master;
GO

RESTORE FILELISTONLY FROM DISK = N'S:\Backup\CorruptDatabase.bak';
GO

RESTORE DATABASE demo_db FROM DISK = N'S:\Backup\CorruptDatabase.bak'
WITH
	REPLACE,
	MOVE N'demo_db' TO N'F:\MSSQL16.SQL_2022\MSSQL\DATA\demo_db.mdf',
	MOVE N'demo_db_log' TO N'L:\MSSQL16.SQL_2022\MSSQL\Data\demo_db_log.ldf',
	RECOVERY,
	STATS = 10;
GO

ALTER DATABASE demo_db SET RECOVERY SIMPLE;
GO

USE demo_db;
GO

SELECT * FROM sys.tables;
GO

SELECT	message_id,
        language_id,
        severity,
        is_event_logged,
        text
FROM	dbo.messages
WHERE	severity = 10;
GO

SELECT * FROM dbo.messages
WHERE	message_id = 21
		AND language_id = 1028;
GO

SELECT * FROM dbo.messages
ORDER BY
	message_id, language_id;

SELECT * FROM dbo.messages
ORDER BY
	message_id DESC, language_id DESC;

-- HÄNDE WEG VON TASTATUR!!!
select * from msdb.dbo.suspect_pages


-- Consistency proof!
DBCC CHECKDB(demo_db) WITH NO_INFOMSGS;
GO

-- What table is affected?
SELECT OBJECT_NAME(565577053);
GO

-- What is index 2?
SELECT * FROM sys.indexes WHERE OBJECT_ID = 565577053;
GO

-- can I rebuild the index with Id = 2?
ALTER INDEX nix_messages_severity ON dbo.messages REBUILD;
GO

ALTER INDEX cuix_messages ON dbo.messages REBUILD;
GO

-- We have to repair the database consistency!!!!
DBCC CHECKDB(demo_db, REPAIR_REBUILD);
GO

-- 1st step: Set database to SINGLE_USER
ALTER DATABASE demo_db SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

DBCC CHECKDB(demo_db, REPAIR_REBUILD);
GO

-- last chance: REPAIR the WHOLE database
DBCC CHECKDB(demo_db, REPAIR_ALLOW_DATA_LOSS);
GO

-- can I access the table now?
SELECT * FROM dbo.messages;
GO

SELECT COUNT_BIG(*) FROM sys.messages;

DBCC CHECKDB(demo_db) WITH NO_INFOMSGS;
GO

-- make the database available for the users
ALTER DATABASE demo_db SET MULTI_USER;
GO

-- how many data had we lost?
SELECT	Quelle.*
FROM	CustomerOrders.sys.messages AS Quelle
		LEFT JOIN dbo.messages AS Ziel
		ON
		(
			Quelle.language_id = Ziel.language_id
			AND Quelle.message_id = Ziel.message_id
		)
WHERE	Ziel.message_id IS NULL;
GO

INSERT INTO dbo.messages
SELECT	S.*
FROM	CustomerOrders.sys.messages AS S
		LEFT JOIN dbo.messages AS T
		ON
		(
			S.language_id = T.language_id
			AND S.message_id = T.message_id
		)
WHERE	T.message_id IS NULL;
GO