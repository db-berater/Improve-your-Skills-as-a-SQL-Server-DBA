/*
	============================================================================
	File:		01 - Backing up databases.sql

	Summary:	This demo shows the correlation between recovery models and
				the importance of sufficient backup strategies

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
	Let's create a database first for the storage of data

	Note:	The code for the stored procedure can be found in
			[01 - Preparation an Presentation]\[02 - dbo.sp_create_demo_db.sql]
*/
EXEC dbo.sp_create_demo_db
	@num_of_files = 1,
	@initial_size_MB = 1024;
GO

/*
	The default recovery model for the demo_db database is SIMPLE
*/
SELECT	name,
		recovery_model_desc,
		log_reuse_wait_desc
FROM	sys.databases
WHERE	name = N'demo_db';
GO

/*
	Because no previous backups have been done there is no
	backup entry in the msdb backup history table.
*/
SELECT	BMF.physical_device_name,
		BS.type,
		BS.backup_start_date,
		BS.first_lsn,
		BS.last_lsn,
		BS.checkpoint_lsn,
		BS.database_backup_lsn
FROM	msdb.dbo.backupmediafamily AS BMF
		INNER JOIN msdb.dbo.backupset AS BS
		ON (BMF.media_set_id = BS.media_set_id)
WHERE	BS.database_name =  N'demo_db'
ORDER BY
		BS.backup_start_date ASC
GO

/*
	Now we let the database go into production and fill it with data
*/
USE demo_db;
GO

SELECT	file_id,
        vlf_begin_offset,
        vlf_size_mb,
        vlf_sequence_number,
        vlf_active,
        vlf_status,
        vlf_parity,
        vlf_first_lsn,
        vlf_create_lsn
FROM	sys.dm_db_log_info(DB_ID());
GO

SELECT	message_id,
        language_id,
        severity,
        is_event_logged,
        text
INTO	dbo.messages
FROM	sys.messages
WHERE	language_id = 1028;
GO

/*
	Every transaction must be stored in the LOG-File.
*/
SELECT	file_id,
        vlf_begin_offset,
        vlf_size_mb,
        vlf_sequence_number,
        vlf_active,
        vlf_status,
        vlf_parity,
        vlf_first_lsn,
        vlf_create_lsn
FROM	sys.dm_db_log_info(DB_ID());
GO

CHECKPOINT;
GO

/*
	Because the database is running in SIMPLE recovery model
	the LOG will be truncated after the transaction is done
*/
SELECT	name,
		recovery_model_desc,
		log_reuse_wait,
		log_reuse_wait_desc
FROM	sys.databases
WHERE	name = N'demo_db';
GO

/* SIMPLE recovery model cannot do LOG backups! */
BACKUP LOG demo_db TO DISK = N'NUL';
GO

/*
	Now we set the recovery model of the demo_db database
	to FULL.

	Note: The database will behave like SIMPLE until the
			first FULL Backup was initiated!
*/
ALTER DATABASE demo_db SET RECOVERY FULL;
GO

SELECT	name,
		recovery_model_desc,
		log_reuse_wait,
		log_reuse_wait_desc
FROM	sys.databases
WHERE	name = N'demo_db';
GO

-- add more records to the table
INSERT INTO dbo.messages
(message_id, language_id, severity, is_event_logged, text)
SELECT	message_id,
        language_id,
        severity,
        is_event_logged,
        text
FROM	sys.messages
WHERE	language_id = 1029;
GO

-- what has happend to the log_reuse_wait_desc info?
SELECT	name,
		recovery_model_desc,
		log_reuse_wait,
		log_reuse_wait_desc
FROM	sys.databases
WHERE	name = N'demo_db';
GO

SELECT * FROM sys.fn_dblog(NULL, NULL);
GO

CHECKPOINT;
GO

SELECT * FROM sys.fn_dblog(NULL, NULL)
ORDER BY
		[Current LSN];
GO

/*
	OK - let's do the first FULL backup of the database
*/
BACKUP DATABASE demo_db TO DISK = N'S:\Backup\demo_db_full_backup.bak'
WITH
	STATS,
	INIT,
	FORMAT,
	COMPRESSION;
GO

-- Check the backup history which is stored in msdb database
SELECT	BMF.physical_device_name,
		BS.type,
		BS.backup_start_date,
		BS.first_lsn,
		BS.last_lsn,
		BS.checkpoint_lsn,
		BS.database_backup_lsn
FROM	msdb.dbo.backupmediafamily AS BMF
		INNER JOIN msdb.dbo.backupset AS BS
		ON (BMF.media_set_id = BS.media_set_id)
WHERE	BS.database_name =  N'demo_db'
ORDER BY
		BS.backup_start_date ASC
GO

-- add new records into the table
INSERT INTO dbo.messages
(message_id, language_id, severity, is_event_logged, text)
SELECT	message_id,
        language_id,
        severity,
        is_event_logged,
        text
FROM	sys.messages
WHERE	language_id = 1030;
GO

/*
	Check the LOG file for the active part of the log file!
*/
SELECT	file_id,
		vlf_size_mb				AS	FileSize,
		vlf_begin_offset		AS	StartOffset,
		vlf_sequence_number		AS	FSeqNo,
		vlf_status				AS	Status,
		vlf_parity,
		vlf_create_lsn			AS	CreateLSN,
		vlf_first_lsn			AS	FirstLSN,
		vlf_active
FROM	sys.dm_db_log_info(DB_ID());
GO

CHECKPOINT;
GO

-- what has happend to the log_reuse_wait_desc info?
SELECT	name,
		recovery_model_desc,
		log_reuse_wait_desc
FROM	sys.databases WHERE name = N'demo_db';
GO

/* We add more data to the database to fill the LOG file */
INSERT INTO dbo.messages
(message_id, language_id, severity, is_event_logged, text)
SELECT	message_id,
        language_id,
        severity,
        is_event_logged,
        text
FROM	sys.messages
WHERE	language_id = 1030;
GO

SELECT	file_id,
		vlf_size_mb				AS	FileSize,
		vlf_begin_offset		AS	StartOffset,
		vlf_sequence_number		AS	FSeqNo,
		vlf_status				AS	Status,
		vlf_parity,
		vlf_create_lsn			AS	CreateLSN,
		vlf_first_lsn			AS	FirstLSN,
		vlf_active
FROM	sys.dm_db_log_info(DB_ID());
GO

-- what has happend to the log_reuse_wait_desc info?
SELECT	name,
		recovery_model_desc,
		log_reuse_wait_desc
FROM	sys.databases WHERE name = N'demo_db';
GO


-- Make a first log backup of the changes
BACKUP LOG demo_db TO DISK = N'S:\Backup\demo_db_log_backup_01.bak'
WITH
	STATS,
	INIT,
	FORMAT,
	COMPRESSION;
GO

-- Check the backup history which is stored in msdb database
SELECT	BMF.physical_device_name,
		BS.type,
		BS.backup_start_date,
		BS.first_lsn,
		BS.last_lsn,
		BS.checkpoint_lsn,
		BS.database_backup_lsn
FROM	msdb.dbo.backupmediafamily AS BMF
		INNER JOIN msdb.dbo.backupset AS BS
		ON (BMF.media_set_id = BS.media_set_id)
WHERE	BS.database_name =  N'demo_db'
ORDER BY
		BS.backup_start_date ASC
GO

SELECT	file_id,
		vlf_size_mb				AS	FileSize,
		vlf_begin_offset		AS	StartOffset,
		vlf_sequence_number		AS	FSeqNo,
		vlf_status				AS	Status,
		vlf_parity,
		vlf_create_lsn			AS	CreateLSN,
		vlf_first_lsn			AS	FirstLSN,
		vlf_active
FROM	sys.dm_db_log_info(DB_ID());
GO

-- what has happend to the log_reuse_wait_desc info?
SELECT	name,
		recovery_model_desc,
		log_reuse_wait_desc
FROM	sys.databases WHERE name = N'demo_db';
GO

INSERT INTO dbo.messages
(message_id, language_id, severity, is_event_logged, text)
SELECT	message_id,
        language_id,
        severity,
        is_event_logged,
        text
FROM	sys.messages
WHERE	language_id = 1030;
GO

SELECT	file_id,
		vlf_size_mb				AS	FileSize,
		vlf_begin_offset		AS	StartOffset,
		vlf_sequence_number		AS	FSeqNo,
		vlf_status				AS	Status,
		vlf_parity,
		vlf_create_lsn			AS	CreateLSN,
		vlf_first_lsn			AS	FirstLSN,
		vlf_active
FROM	sys.dm_db_log_info(DB_ID());
GO

SELECT	name,
		recovery_model_desc,
		log_reuse_wait_desc
FROM	sys.databases WHERE name = N'demo_db';
GO

-- we make the second backup
BACKUP LOG demo_db TO DISK = N'S:\Backup\demo_db_log_backup_02.bak'
WITH STATS, INIT, FORMAT, COMPRESSION;
GO

-- Check the backup history which is stored in msdb database
SELECT	BMF.physical_device_name,
		BS.type,
		BS.backup_start_date,
		BS.first_lsn,
		BS.last_lsn,
		BS.checkpoint_lsn,
		BS.database_backup_lsn
FROM	msdb.dbo.backupmediafamily AS BMF
		INNER JOIN msdb.dbo.backupset AS BS
		ON (BMF.media_set_id = BS.media_set_id)
WHERE	BS.database_name =  N'demo_db'
ORDER BY
		BS.backup_start_date ASC
GO

SELECT	file_id,
		vlf_size_mb				AS	FileSize,
		vlf_begin_offset		AS	StartOffset,
		vlf_sequence_number		AS	FSeqNo,
		vlf_status				AS	Status,
		vlf_parity,
		vlf_create_lsn			AS	CreateLSN,
		vlf_first_lsn			AS	FirstLSN,
		vlf_active
FROM	sys.dm_db_log_info(DB_ID());
GO

-- add new records into the table
INSERT INTO dbo.messages
(message_id, language_id, severity, is_event_logged, text)
SELECT	message_id,
        language_id,
        severity,
        is_event_logged,
        text
FROM	sys.messages
WHERE	language_id = 1031;
GO

SELECT	file_id,
		vlf_size_mb				AS	FileSize,
		vlf_begin_offset		AS	StartOffset,
		vlf_sequence_number		AS	FSeqNo,
		vlf_status				AS	Status,
		vlf_parity,
		vlf_create_lsn			AS	CreateLSN,
		vlf_first_lsn			AS	FirstLSN,
		vlf_active
FROM	sys.dm_db_log_info(DB_ID());
GO

SELECT	name,
		recovery_model_desc,
		log_reuse_wait_desc
FROM	sys.databases WHERE name = N'demo_db';
GO

-- and make a DIFF backup at the end of the day
BACKUP DATABASE demo_db TO DISK = N'S:\Backup\demo_db_diff_backup_01.bak'
WITH
	STATS, 
	INIT, 
	FORMAT, 
	COMPRESSION, 
	DIFFERENTIAL;
GO

SELECT	BMF.physical_device_name,
		BS.type,
		BS.backup_start_date,
		BS.first_lsn,
		BS.last_lsn,
		BS.checkpoint_lsn,
		BS.database_backup_lsn
FROM	msdb.dbo.backupmediafamily AS BMF
		INNER JOIN msdb.dbo.backupset AS BS
		ON (BMF.media_set_id = BS.media_set_id)
WHERE	BS.database_name =  N'demo_db'
ORDER BY
		BS.backup_start_date ASC
GO

SELECT	file_id,
		vlf_size_mb				AS	FileSize,
		vlf_begin_offset		AS	StartOffset,
		vlf_sequence_number		AS	FSeqNo,
		vlf_status				AS	Status,
		vlf_parity,
		vlf_create_lsn			AS	CreateLSN,
		vlf_first_lsn			AS	FirstLSN,
		vlf_active
FROM	sys.dm_db_log_info(DB_ID());
GO

SELECT	name,
		recovery_model_desc,
		log_reuse_wait_desc
FROM	sys.databases WHERE name = N'demo_db';
GO

-- we make the third LOG backup
BACKUP LOG demo_db TO DISK = N'S:\Backup\demo_db_log_backup_03.bak'
WITH
	STATS, 
	INIT, 
	FORMAT, 
	COMPRESSION;
GO

SELECT	file_id,
		vlf_size_mb				AS	FileSize,
		vlf_begin_offset		AS	StartOffset,
		vlf_sequence_number		AS	FSeqNo,
		vlf_status				AS	Status,
		vlf_parity,
		vlf_create_lsn			AS	CreateLSN,
		vlf_first_lsn			AS	FirstLSN,
		vlf_active
FROM	sys.dm_db_log_info(DB_ID());
GO

SELECT	name,
		recovery_model_desc,
		log_reuse_wait_desc
FROM	sys.databases WHERE name = N'demo_db';
GO


-- add new records into the table
INSERT INTO dbo.messages
(message_id, language_id, severity, is_event_logged, text)
SELECT	message_id,
        language_id,
        severity,
        is_event_logged,
        text
FROM	sys.messages
WHERE	language_id = 1032;
GO

SELECT	file_id,
		vlf_size_mb				AS	FileSize,
		vlf_begin_offset		AS	StartOffset,
		vlf_sequence_number		AS	FSeqNo,
		vlf_status				AS	Status,
		vlf_parity,
		vlf_create_lsn			AS	CreateLSN,
		vlf_first_lsn			AS	FirstLSN,
		vlf_active
FROM	sys.dm_db_log_info(DB_ID());
GO

SELECT	name,
		recovery_model_desc,
		log_reuse_wait_desc
FROM	sys.databases WHERE name = N'demo_db';
GO

-- we make the third LOG backup
BACKUP LOG demo_db TO DISK = N'S:\Backup\demo_db_log_backup_04.bak'
WITH STATS, INIT, FORMAT, COMPRESSION;
GO

SELECT	BMF.physical_device_name,
		BS.type,
		BS.backup_start_date,
		BS.first_lsn,
		BS.last_lsn,
		BS.checkpoint_lsn,
		BS.database_backup_lsn
FROM	msdb.dbo.backupmediafamily AS BMF
		INNER JOIN msdb.dbo.backupset AS BS
		ON (BMF.media_set_id = BS.media_set_id)
WHERE	BS.database_name =  N'demo_db'
ORDER BY
		BS.backup_start_date ASC
GO
