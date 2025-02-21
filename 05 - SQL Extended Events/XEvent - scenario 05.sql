/*
	============================================================================
	File:		    XEvent - scenario 05.sql

	Description:    This script creates an extended event which tracks all sql- and
					sp starting commands and - if happens - the recompile of a statement.

				    THIS SCRIPT IS PART OF THE WORKSHOP:
					    "Workshop - Spped Up Your SQL Code"

	Date:		    October 2024
	Revion:		    January 2025

	SQL Server Version: >= 2016
	============================================================================
*/
USE master;
GO

:SETVAR	session_id	55

IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = N'Scenario 05 - Recompiliations')
	DROP EVENT SESSION [Scenario 05 - Recompiliations] ON SERVER;
	GO

CREATE EVENT SESSION [Scenario 05 - Recompiliations] ON SERVER 
ADD EVENT sqlserver.auto_stats,
ADD EVENT sqlserver.sp_statement_starting (WHERE sqlserver.session_id = $(session_id)),
ADD EVENT sqlserver.sql_statement_recompile (WHERE sqlserver.session_id = $(session_id)),
ADD EVENT sqlserver.sql_statement_starting (WHERE sqlserver.session_id = $(session_id))
WITH
(
	MAX_MEMORY=4096 KB,
	EVENT_RETENTION_MODE=NO_EVENT_LOSS,
	MAX_DISPATCH_LATENCY= 1 SECONDS,
	MAX_EVENT_SIZE=0 KB,
	MEMORY_PARTITION_MODE=NONE,
	TRACK_CAUSALITY=OFF,
	STARTUP_STATE=OFF
)
GO

ALTER EVENT SESSION [Scenario 05 - Recompiliations] ON SERVER STATE = START;
GO