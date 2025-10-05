/*
	============================================================================
	File:		0020 - Restore a databases.sql

	Summary:	This script demonstrates different ways to restore databases!
								
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

IF DB_ID(N'demo_db') IS NOT NULL
BEGIN
	ALTER DATABASE demo_db SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE [demo_db];
END
GO

/*
	Before we can do a restore of LOG / DIFF we need the FULL backup!
*/
RESTORE DATABASE demo_db
FROM DISK = N'S:\Backup\demo_db_full_backup.bak'
WITH
	REPLACE,
	STATS = 10;
GO

SELECT	name,
		SUSER_SNAME(owner_sid) AS dbOwner,
		state_desc,
		recovery_model_desc
FROM	sys.databases
WHERE	database_id = DB_ID(N'demo_db');
GO

-- can we apply another backup file?
RESTORE LOG demo_db
FROM DISK = N'S:\Backup\demo_db_log_backup_01.bak'
WITH
	STATS = 10;
GO

RESTORE DATABASE demo_db
FROM DISK = N'S:\Backup\demo_db_full_backup.bak'
WITH
	STATS = 10,
	REPLACE,
	-- WHETHER
	STANDBY = N'C:\Temp\demo_db.stby';
	-- OR
	--NORECOVERY
GO

SELECT	language_id,
		COUNT_BIG(*)	AS	num_records
FROM	demo_db.dbo.messages
GROUP BY
		language_id
GO

/* can we apply another backup file? */
RESTORE LOG demo_db
FROM DISK = N'S:\Backup\demo_db_log_backup_01.bak'
WITH
	STATS = 10,
	--NORECOVERY
	STANDBY = N'C:\Temp\demo_db.stby';
GO

SELECT	language_id,
		COUNT_BIG(*)	AS	num_records
FROM	demo_db.dbo.messages
GROUP BY
		language_id
GO

RESTORE LOG demo_db FROM DISK = N'S:\Backup\demo_db_log_backup_02.bak'
WITH
	STATS = 10,
	NORECOVERY;
	--STANDBY = N'C:\Temp\demo_db.stby';
GO

SELECT	language_id,
		COUNT_BIG(*)	AS	num_records
FROM	demo_db.dbo.messages
GROUP BY
		language_id
GO

RESTORE LOG demo_db
FROM DISK = N'S:\Backup\demo_db_log_backup_02.bak'
WITH
	STATS = 10,
	-- NORECOVERY;
	STANDBY = N'C:\Temp\demo_db.stby';
GO

SELECT	language_id,
		COUNT_BIG(*)	AS	num_records
FROM	demo_db.dbo.messages
GROUP BY
		language_id
GO

RESTORE DATABASE demo_db
FROM DISK = N'S:\Backup\demo_db_diff_backup_01.bak'
WITH
	STATS = 10,
	STANDBY = N'C:\Temp\demo_db.stby';
GO

SELECT	language_id,
		COUNT_BIG(*)	AS	num_records
FROM	demo_db.dbo.messages
GROUP BY
		language_id
GO

RESTORE LOG demo_db FROM DISK = N'S:\Backup\demo_db_log_backup_03.bak'
WITH
	STATS = 10,
	NORECOVERY;
	--STANDBY = N'C:\Temp\demo_db.stby';
GO

RESTORE LOG demo_db FROM DISK = N'S:\Backup\demo_db_log_backup_04.bak'
WITH
	STATS = 10,
	NORECOVERY;
	--STANDBY = N'C:\Temp\demo_db.stby';
GO

RESTORE DATABASE demo_db WITH RECOVERY;
GO

/* change the owner!!! */
ALTER AUTHORIZATION ON DATABASE::demo_db TO sa;
GO

SELECT	language_id,
		COUNT_BIG(*)	AS	num_records
FROM	demo_db.dbo.messages
GROUP BY
		language_id
GO