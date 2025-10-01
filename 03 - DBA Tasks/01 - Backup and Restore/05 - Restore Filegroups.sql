/*============================================================================
	File:		05 - Restore Filegroups.sql

	Summary:	This demo shows how to restore a VLDB with filegroup restore

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

IF DB_ID(N'demo_db') IS NOT NULL
BEGIN
	ALTER DATABASE demo_db SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE demo_db;
END
GO

/*
	Most important with restores is that the PRIMARY filegroup must
	ALWAYS be restored first!
*/
RESTORE DATABASE demo_db READ_WRITE_FILEGROUPS
FROM DISK = N'S:\Backup\demo_db_full.bak'
WITH
	STATS = 10;
GO

/*
	Let's check it out. Can we access data from the last year?
*/
SELECT * FROM demo_db.dbo.orders
WHERE	o_orderdate = '2022-01-01';
GO

SELECT * FROM demo_db.dbo.orders
WHERE	o_orderdate = '2021-01-01';
GO

SELECT * FROM demo_db.dbo.orders
WHERE	o_orderdate = '2020-01-01';
GO

RESTORE FILELISTONLY FROM DISK = N'S:\Backup\demo_db_full.bak'
GO

/*
	Now the business can work again and we can relax.
	Let's restore the other filegroups!
*/
SELECT	fg.name,
        fg.type,
        fg.is_read_only,
        mf.name,
        mf.physical_name,
        mf.state,
        mf.state_desc,
        mf.size
FROM	demo_db.sys.filegroups AS fg
CROSS APPLY
(
	SELECT * FROM sys.master_files
	WHERE database_id = DB_ID(N'demo_db')
	AND data_space_id = fg.data_space_id
) AS mf
WHERE   fg.is_read_only = 1
		AND mf.state = 3 /* recovery pending */;
GO

/*
	This will not work because the read only filegroups
	are stored in different backup files!
*/
RESTORE DATABASE demo_db
FILEGROUP = 'filegroup_06'
FROM DISK = N'S:\backup\demo_db_full.bak'
GO

RESTORE DATABASE demo_db
FILEGROUP = 'filegroup_06'
FROM DISK = N'S:\backup\fg_01_2020.bak'
GO

RESTORE DATABASE demo_db
FILEGROUP = 'filegroup_05'
FROM DISK = N'S:\backup\fg_01_2019.bak'
GO

RESTORE DATABASE demo_db
FILEGROUP = 'filegroup_04'
FROM DISK = N'S:\backup\fg_01_2018.bak'
GO

RESTORE DATABASE demo_db
FILEGROUP = 'filegroup_03'
FROM DISK = N'S:\backup\fg_01_2017.bak'
GO

RESTORE DATABASE demo_db
FILEGROUP = 'filegroup_02'
FROM DISK = N'S:\backup\fg_01_2016.bak'
GO

RESTORE DATABASE demo_db
FILEGROUP = 'filegroup_01'
FROM DISK = N'S:\backup\fg_01_2015.bak'
GO

SELECT	fg.name,
        fg.type,
        fg.is_read_only,
        mf.name,
        mf.physical_name,
        mf.state,
        mf.state_desc,
        mf.size
FROM	demo_db.sys.filegroups AS fg
CROSS APPLY
(
	SELECT * FROM sys.master_files
	WHERE database_id = DB_ID(N'demo_db')
	AND data_space_id = fg.data_space_id
) AS mf
WHERE   fg.is_read_only = 1
		AND mf.state = 3 /* recovery pending */;
GO
