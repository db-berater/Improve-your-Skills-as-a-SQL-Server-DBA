# Workshop - Improve your Skills as a SQL Server DBA
This repository contains all codes for my workshop "Improve your Skills as a SQL Server DBA"
All scripts are created for the use of Microsoft SQL Server (Version 2016 or higher)
To work with the scripts it is required to have the workshop database ERP_Demo installed on your SQL Server Instance.
The last version of the demo database can be downloaded here:

**https://www.db-berater.de/downloads/ERP_DEMO_2012.BAK**

> Written by
>	[Uwe Ricken](https://www.db-berater.de/uwe-ricken/), 
>	[db Berater GmbH](https://db-berater.de)
> 
> All scripts are intended only as a supplement to demos and lectures
> given by Uwe Ricken.  
>   
> **THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
> ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
> TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
> PARTICULAR PURPOSE.**

**Note**
The database contains a framework for all workshops / sessions from db Berater GmbH
+ Stored Procedures
+ User Definied Inline Functions

Workshop Scripts for SQL Server Workshop "Improve your Skills as a SQL Server DBA"\
Version:	1.00.500\
Date:		2025-10-04

**Tip for json scripts for OSTRESS and/or SQLQueryStress**
All templates reference to a machine called "SQLServer". If you don't want to change the names to your instance name I recommend to create a SQL Alias on your local machine.
[For details see the offical Microsoft documentation](https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/create-or-delete-a-server-alias-for-use-by-a-client?view=sql-server-ver17).

# Folder structure
+ Each topic has a dedicated scenario which deals with examples concerning the topic
+ All scripts have numbers and basically the script with the prefix 01 is for the preparation of the environment
   
+ The folder **Windows Admin Center** contains json files with the configuration of performance counter. These files can only be used with Windows Admin Center
  - [Windows Admin Center](https://www.microsoft.com/en-us/windows-server/windows-admin-center)
  - Before you can use the JSON templates make sure you replace the Machine Name / Instance Name with your Machine Name / Instance Name
+ The folder **SQL Query Stress** contains prepared configuration settings for each scenario which produce load test with SQLQueryStress from Adam Machanic
  - [SQLQueryStress](https://github.com/ErikEJ/SqlQueryStress)
  - Before you can use the JSON templates make sure you replace the Machine Name / Instance Name with your Machine Name / Instance Name.
  - If you are using an ALIAS "SQLServer", you don't have to change anything on the templates. 
+ The folder **SQL Extended Events** contains scripts for the implementation of extended events for the different scenarios
  All extended events are written for "LIVE WATCHING" and will have no target file for saving the results.

# 01 - Preparation and Presentation
This folder contains all Powerpoint Presentations required for this workshop
+ Powerpoint Slides
+ Powershell Script for the creation of an SQL Alias: SQLServer
+ Stored Procedure for the restore of ERP_Demo Database (must be executed before the script [01 - Preparation of demo databases]!)
+ Preparation of demo database
+ Stored Procedure for the creation of a demo_db Database for dedicated scenarios
  The stored procedure will be created in the master database and marked as system object!
+ Stored Procedure for the reset of User Counters and Wait Stats Analysis
+ Stored Procedures for reading data from the Ring Buffer and display it as table

NOTE: All Stored Procedures will automatically be created when you restore the ERP_Demo Database by script "[01 - Preparation of demo database]."

# 02 - Analysis Tools
This folder contains workloads/demos to demonstrate the following Analysis Tools
+ Query Store
+ Windows Admin Center
+ Resource Monitor
+ Extended Events

# 3 - DBA Tasks
This folder contains a separate folder for each DBA task, containing all scripts that have a "Preparation" -> "Demo" and a "Cleanup" for the corresponding topic.
Depending on the scope, several demo scripts may be present in the folder.
## 01 - Backup and Restore
Demos for Backup Scenarios
## 02 - Locking and Blocking
Demos for Locking and Blocking of processes
## 03 - Parameter Sniffing
Demos for Problems with Parameter Sniffing and possible solutions
## 04 - Wait Stats Analysis
Demos for different wait types
+ CXPACKET
+ SOS_SCHEDULER_YIELD
+ THREADPOOL
+ ASYNC_NETWORK_IO
## 05 - Indexes and Statistics
This folder contains a complex demos about the internal structure of indexes and problems with PAGE_SPLIT and fragmentation. Two different fragmentation types are covered:
+ Logical Fragmentation
+ Physical Fragmentation
# 60 - Windows Admin Center
During the workshop, various scenarios will be examined for performance bottlenecks. We will use the Windows Admin Center for this purpose. The folder contains dedicated monitoring templates for all demonstrations.
**Note**
The author performed the configuration using a German operating system. Not all templates have been modified for English operating systems.

# 70 - SQL Query Stress
Templates for using SQLQueryStress to perform load testing on Microsoft SQL Server. The templates use the names of the DBA tasks (see structure above).
All templates reference a SQL Server Instance named "SQLServer". It is recommended to create a SQL Alias with this name.
This prevents you from changing all templates with the name of your Microsoft SQL Server Instance.

**Example**
```json
{
	"MainDbConnectionInfo":
	{
		"IntegratedAuth":true,
		"Login":"",
		"MaxPoolSize":2,
		"Password":"",
		"Server":"SQLServer",
		"TrustServerCertificate":true
	}
}
```
# 80 - Extended Events
Scripts for the implementation of Extended Events for the different scenarios.
All extended events are written for "LIVE WATCHING" and will have no target file for saving the results.
Some Extended Events are using the Ring Buffer Object to read data from.
In this case you can use the stored procedures master..sp_read_xevent_...
These stored procedures will be implemented in the preparation phase from script
[01 - Preparation and Presentation]\[01 - Preparation of demo databases.sql]

# 90 - Tools and Scripts
+ Maintenance Solution from [Ola Hallengren](https://ola.hallengren.com/)
+ sp_whoisactive from [Adam Machanic](https://github.com/amachanic/sp_whoisactive)