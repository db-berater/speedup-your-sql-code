/*
	============================================================================
	File:		02 - scenario 02 - stress query.sql

	Summary:	This script execute the given stored procedure and tracks the runtime
				of the execution.

				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Workshop - Accelerate your SQL Code"

	Date:		October 2024
	Revion:		November 2024

	SQL Server Version: >= 2016
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
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

USE ERP_Demo;
GO

DECLARE	@return_value	INT;
DECLARE	@finish_time	DATETIME2(7);
DECLARE	@time_diff_ms	INT;
DECLARE	@start_time		DATETIME2(7) = SYSDATETIME();

EXEC @return_value = dbo.jobqueue_delete
	@rowlimit = 3000,
	@maxlimit = 50000;

SET	@finish_time = SYSDATETIME();
SET	@time_diff_ms = DATEDIFF(MILLISECOND, @start_time, @finish_time);

/*
	Update the user counters (monitoring with Windows Admin Manager or PerfMon!
	User counter 1:	runtime in ms
	User counter 2:	number of rows deleted
*/
DBCC setinstance('SQLServer:User Settable', 'Query', 'User counter 1', @time_diff_ms);
dbcc setinstance('SQLServer:User Settable', 'Query', 'User counter 2', @return_value);

INSERT INTO dbo.runtime_statistics
(action_name, num_rows, start_date, finish_date)
SELECT	'runtime of process'	AS	action_name,
		@return_value			AS	num_rows,
		@start_time				AS	start_time,
		@finish_time			AS	finish_time;
GO

SELECT * FROM dbo.runtime_statistics;
