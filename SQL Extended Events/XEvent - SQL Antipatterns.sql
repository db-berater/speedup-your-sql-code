IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = N'Query Antipatterns')
    DROP EVENT SESSION [Query Antipatterns] ON SERVER 
    GO

CREATE EVENT SESSION [Query Antipatterns] ON SERVER 
ADD EVENT sqlserver.plan_affecting_convert
(
    ACTION
    (
        sqlserver.session_id,
        sqlserver.sql_text,
        sqlserver.is_system
    )
    WHERE   sqlserver.is_system = 0
            AND sqlserver.database_name = N'ERP_Demo'
),
ADD EVENT sqlserver.query_antipattern
(
    ACTION
    (
        sqlserver.session_id,
        sqlserver.sql_text,
        sqlserver.is_system
    )
    WHERE   sqlserver.is_system = 0
            AND sqlserver.database_name = N'ERP_Demo'
)
WITH
(
    MAX_MEMORY=4096 KB,
    EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,
    MAX_DISPATCH_LATENCY=30 SECONDS,
    MAX_EVENT_SIZE=0 KB,
    MEMORY_PARTITION_MODE=NONE,
    TRACK_CAUSALITY=OFF,
    STARTUP_STATE=OFF
)
GO

ALTER EVENT SESSION [Query Antipatterns] ON SERVER STATE = START;
GO