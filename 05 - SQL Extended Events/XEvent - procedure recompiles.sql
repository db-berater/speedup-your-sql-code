USE ERP_Demo;
GO

/*
    Run this statement in SQLCMD Modus and replace the value of the variable
    session_id with the session_id of your query tab!
*/
:SETVAR session_id  55

IF EXISTS (SELECT * FROM sys.dm_xe_sessions WHERE name = N'Track procedure recompiles')
BEGIN
	RAISERROR (N'Dropping XEvent-Session: [Track procedure recompiles]', 0, 1) WITH NOWAIT;
	DROP EVENT SESSION [Track procedure recompiles] ON SERVER;
END

RAISERROR (N'Createing XEvent-Session: [Track procedure recompiles]', 0, 1) WITH NOWAIT;

CREATE EVENT SESSION [Track procedure recompiles] ON SERVER 
ADD EVENT sqlserver.auto_stats
(
    ACTION
    (
        sqlserver.database_id,
        sqlserver.session_id,
        sqlserver.sql_text
    )
    WHERE   sqlserver.session_id = $(session_id)
),
ADD EVENT sqlserver.sp_statement_starting
(
    ACTION
    (
        sqlserver.database_id,
        sqlserver.session_id,
        sqlserver.sql_text
    )
    WHERE   sqlserver.session_id = $(session_id)
),
ADD EVENT sqlserver.sql_statement_recompile
(
    ACTION
    (
        sqlserver.database_id,
        sqlserver.session_id,
        sqlserver.sql_text
    )
    WHERE   sqlserver.session_id = $(session_id)
)
WITH
(
    MAX_MEMORY=4096 KB,
    EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,
    MAX_DISPATCH_LATENCY=30 SECONDS,
    MAX_EVENT_SIZE=0 KB,
    MEMORY_PARTITION_MODE=NONE,
    TRACK_CAUSALITY=ON,
    STARTUP_STATE=OFF
)
GO

RAISERROR (N'Starting XEvent-Session: [Track procedure recompiles]', 0, 1) WITH NOWAIT;
ALTER EVENT SESSION [Track procedure recompiles] ON SERVER STATE = START;
GO