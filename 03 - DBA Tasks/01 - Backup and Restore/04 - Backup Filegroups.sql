/*============================================================================
	File:		04 - Backup Filegroups.sql

	Summary:	This demo shows how to optimize the backup of a VLDB
				with multiple filegroups

	Date:		May 2025

	SQL Server Version: >= 2016
------------------------------------------------------------------------------

	THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
	ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
	TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
	PARTICULAR PURPOSE.
============================================================================*/
USE master;
GO

/*
	Let's have a look to the size of the database before we start 
	different backup strategies
*/
SELECT	file_id,
        type_desc,
        name,
        physical_name,
        size / 128	AS	size_mb
FROM	sys.master_files
WHERE	database_id = DB_ID(N'demo_db');
GO

/*
	Let's try a FULL backup of all data and check the time
	for the backup and the backup size!
*/
DECLARE	@start_time	DATETIME = GETDATE();
DECLARE	@time_diff	INT = 0;

BACKUP DATABASE demo_db
TO DISK = N'S:\backup\demo_db_full.bak'
WITH
	STATS = 10,
	INIT,
	FORMAT,
	COMPRESSION;

SET	@time_diff = DATEDIFF(SECOND, @start_time, GETDATE());
RAISERROR ('Backup time in seconds: %i', 0, 1, @time_diff) WITH NOWAIT;
GO

/* We check the file size of the backup .... */
RESTORE FILELISTONLY FROM DISK = N'S:\backup\demo_db_full.bak';
GO

/*
	If you don't want to have a full backup you can do backups on filegroups
*/
BACKUP DATABASE demo_db
FILEGROUP = N'filegroup_01'
TO DISK = N'NUL'
WITH
	FORMAT,
	INIT,
	STATS = 10;
GO

/*
	The business only wants to have the last two filegroups as readable
	and immediately available data source in case of a desaster.

	All other filegroups can be changed to read only.
*/
ALTER DATABASE demo_db MODIFY FILEGROUP filegroup_01 READONLY;
ALTER DATABASE demo_db MODIFY FILEGROUP filegroup_02 READONLY;
ALTER DATABASE demo_db MODIFY FILEGROUP filegroup_03 READONLY;
ALTER DATABASE demo_db MODIFY FILEGROUP filegroup_04 READONLY;
ALTER DATABASE demo_db MODIFY FILEGROUP filegroup_05 READONLY;
ALTER DATABASE demo_db MODIFY FILEGROUP filegroup_06 READONLY;
GO

SELECT	fg.name,
        fg.type_desc,
        fg.is_read_only,
        f.type_desc,
        f.size_mb
FROM	demo_db.sys.filegroups AS fg
		CROSS APPLY
		(
			SELECT	mf.file_id,
                    mf.type_desc,
                    mf.name,
                    mf.physical_name,
                    mf.size / 128		AS	size_mb,
                    mf.max_size / 128	AS	max_size_mb,
                    mf.growth / 128	AS	growth_mb
			FROM	sys.master_files AS mf
			WHERE	mf.database_id = DB_ID(N'demo_db')
					AND data_space_id = fg.data_space_id
		) AS f;
GO

BACKUP DATABASE demo_db
FILEGROUP = N'filegroup_01'
TO DISK = N'S:\Backup\fg_01_2015.bak'
WITH
	FORMAT,
	INIT,
	STATS = 10,
	NAME = N'dbo.orders from 2015',
	COMPRESSION;
GO

BACKUP DATABASE demo_db
FILEGROUP = N'filegroup_02'
TO DISK = N'S:\Backup\fg_01_2016.bak'
WITH
	FORMAT,
	INIT,
	STATS = 10,
	NAME = N'dbo.orders from 2016',
	COMPRESSION;
GO

BACKUP DATABASE demo_db
FILEGROUP = N'filegroup_03'
TO DISK = N'S:\Backup\fg_01_2017.bak'
WITH
	FORMAT,
	INIT,
	STATS = 10,
	NAME = N'dbo.orders from 2017',
	COMPRESSION;
GO

BACKUP DATABASE demo_db
FILEGROUP = N'filegroup_04'
TO DISK = N'S:\Backup\fg_01_2018.bak'
WITH
	FORMAT,
	INIT,
	STATS = 10,
	NAME = N'dbo.orders from 2018',
	COMPRESSION;
GO

BACKUP DATABASE demo_db
FILEGROUP = N'filegroup_05'
TO DISK = N'S:\Backup\fg_01_2019.bak'
WITH
	FORMAT,
	INIT,
	STATS = 10,
	NAME = N'dbo.orders from 2019',
	COMPRESSION;
GO

BACKUP DATABASE demo_db
FILEGROUP = N'filegroup_06'
TO DISK = N'S:\Backup\fg_01_2020.bak'
WITH
	FORMAT,
	INIT,
	STATS = 10,
	NAME = N'dbo.orders from 2020',
	COMPRESSION;
GO

/*
	Your daily backup concerns only filegroups which are read/writeable
*/
BACKUP DATABASE demo_db READ_WRITE_FILEGROUPS
TO DISK = N'S:\Backup\demo_db_full.bak'
WITH
	INIT,
	FORMAT,
	STATS = 10,
	NAME = N'all read/write filegroups of demo_db',
	COMPRESSION;
GO