IF EXISTS (SELECT * FROM sys.dm_xe_sessions WHERE name = N'scenario 04 - tracking single process')
	DROP EVENT SESSION [scenario 04 - tracking single process] ON SERVER;
	GO

CREATE EVENT SESSION [scenario 04 - tracking single process]
ON SERVER 
	ADD EVENT sqlserver.sp_statement_completed
	(
		WHERE	sqlserver.is_system = 0
				AND sqlserver.database_name = N'ERP_Demo'
	),
	ADD EVENT sqlserver.sql_statement_completed
	(
		WHERE	sqlserver.is_system = 0
				AND sqlserver.database_name = N'ERP_Demo'
	),
	ADD EVENT sqlserver.database_xml_deadlock_report
	(
		WHERE database_name=N'ERP_Demo'
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
);
GO

ALTER EVENT SESSION [scenario 04 - tracking single process] ON SERVER STATE = START;
GO
