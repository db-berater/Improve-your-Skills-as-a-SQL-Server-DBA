/*
	============================================================================
	File:		04 - ASYNC_NETWORK_IO.sql

	Summary:	This script demonstrates the wait stat ASYNC_NETWORK_IO

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

/* We want to make sure we have default instance values */
EXEC sys.sp_configure N'cost threshold for parallelism', 5;
RECONFIGURE WITH OVERRIDE;
GO

EXEC sys.sp_configure N'max degree of parallelism', 0;
RECONFIGURE WITH OVERRIDE;
GO

/* Let's reset all counters on the demo machine */
EXEC dbo.sp_reset_counters
        @clear_wait_stats = 1,
        @clear_user_counters = 1;
GO

/*
	After the counters have been reset we can start with the
	bad coding example.

	This is a powershell script in the folder "99 - Poershell Scripts"

	Open the script in PS and execute it.
	While the script is executing run the code below which refreshes
	every 1 second(s) the user counter for the Windows Admin Center

	user counter 4:		Number of Waits
	user counter 5:		average wait time
*/
SET NOCOUNT ON;
DECLARE	@num_of_waits	INT;
DECLARE	@avg_waittime	INT;

WHILE (1 = 1)
BEGIN
	BEGIN TRY
		SELECT	@avg_waittime = ISNULL([Avg Waittime (seconds)], 0) * 1000,
				@num_of_waits = ISNULL([Total number of waits], 0)
		FROM	ERP_Demo.dbo.get_wait_stats_info(N'ASYNC_NETWORK_IO');

		DBCC SETINSTANCE('SQLServer:User Settable', 'Query', 'User counter 4', @num_of_waits);
		DBCC SETINSTANCE('SQLServer:User Settable', 'Query', 'User counter 5', @avg_waittime);
	END TRY
	BEGIN CATCH
		SET	@num_of_waits = 0;
		SET	@avg_waittime = 0
	END CATCH

	WAITFOR DELAY '00:00:01';
END
GO
