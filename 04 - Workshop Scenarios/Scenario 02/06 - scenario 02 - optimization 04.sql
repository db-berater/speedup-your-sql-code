/*
	============================================================================
	File:		06 - scenario 02 - optimization 04.sql

	Summary:	The deletion process covers lots of indexes.
				It is important to check how the indexes get used.
				It might be useful to delete unnecessary indexes!
				
				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Workshop - Accelerate your SQL Code"

	Date:		October 2024
	Revion:		November 2024

	SQL Server Version: >= 2016
	============================================================================
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

USE ERP_Demo;
GO

/*
	Let's check the indexes in the table dbo.jobqueue!
*/
SELECT	i.index_id,
		i.name,
		i.type_desc,
		i.is_unique,
		i.is_primary_key,
		i.is_unique_constraint,
        ddius.user_seeks,
        ddius.user_scans,
        ddius.user_lookups,
        ddius.user_updates,
        ddius.last_user_seek,
        ddius.last_user_scan,
        ddius.last_user_lookup,
        ddius.last_user_update
FROM	sys.indexes AS i
		INNER JOIN sys.dm_db_index_usage_stats AS ddius
		ON	(
				i.index_id = ddius.index_id
				AND i.object_id = ddius.object_id
			)
WHERE	ddius.database_id = DB_ID()
		AND i.object_id = OBJECT_ID(N'dbo.jobqueue', N'U')
ORDER BY
		i.index_id ASC;
GO

/*
	Let's remove indexes which are not used in the table.

	NOTE:	this is only for demo purposes and fits to this specific scenario
			Don't delete vendor indexes without permissions
			Do not rely on these statistics only but check Query Store or your
			Execution plans whether other indexes on the table are used!!!
*/
IF EXISTS (SELECT * FROM sys.indexes WHERE name = N'nix_jobqueue_sortorder' AND OBJECT_ID = OBJECT_ID(N'dbo.jobqueue', N'U'))
	DROP INDEX nix_jobqueue_sortorder	ON dbo.jobqueue;
IF EXISTS (SELECT * FROM sys.indexes WHERE name = N'nix_jobqueue_genprocid' AND OBJECT_ID = OBJECT_ID(N'dbo.jobqueue', N'U'))
	DROP INDEX nix_jobqueue_genprocid	ON dbo.jobqueue;
IF EXISTS (SELECT * FROM sys.indexes WHERE name = N'nix_jobqueue_uid_task' AND OBJECT_ID = OBJECT_ID(N'dbo.jobqueue', N'U'))
	DROP INDEX nix_jobqueue_uid_task	ON dbo.jobqueue;
IF EXISTS (SELECT * FROM sys.indexes WHERE name = N'nix_jobqueue_objectname' AND OBJECT_ID = OBJECT_ID(N'dbo.jobqueue', N'U'))
	DROP INDEX nix_jobqueue_objectname	ON dbo.jobqueue;

/*
	Let's check the indexes in the table dbo.jobqueue!
*/
SELECT	i.index_id,
		i.name,
		i.type_desc,
		i.is_unique,
		i.is_primary_key,
		i.is_unique_constraint,
        ddius.user_seeks,
        ddius.user_scans,
        ddius.user_lookups,
        ddius.user_updates,
        ddius.last_user_seek,
        ddius.last_user_scan,
        ddius.last_user_lookup,
        ddius.last_user_update
FROM	sys.indexes AS i
		INNER JOIN sys.dm_db_index_usage_stats AS ddius
		ON	(
				i.index_id = ddius.index_id
				AND i.object_id = ddius.object_id
			)
WHERE	ddius.database_id = DB_ID()
		AND i.object_id = OBJECT_ID(N'dbo.jobqueue', N'U')
ORDER BY
		i.index_id ASC;
GO

ALTER TABLE dbo.jobqueue
DROP CONSTRAINT pk_jobqueue;
GO

ALTER TABLE dbo.jobqueue
ADD CONSTRAINT pk_jobqueue PRIMARY KEY CLUSTERED (uid_jobqueue)
WITH
(
	DATA_COMPRESSION = PAGE,
	SORT_IN_TEMPDB = ON
);
GO
