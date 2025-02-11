/*
	============================================================================
	File:		01 - scenario 02 - preparation.sql

	Problemdescription:

	A software uses a table to queue jobs. Whenever a new job is to be queued,
	its details are written into a table. The table grows very quickly, as up to
	100,000 jobs can be scheduled in one hour.

	- Sometimes the table is growing very fast
	- The maintenance job cannot scale.
	- The table is growing
	- The system suffers from performance problems

	Summary:	This script creates the environment for the scenario.
				- create the table dbo.jobqueue with indexes
				- create a table dbo.runtime_statistics to measure the improvements
				
				- create data types for handling the deletion process
					- dbo.helpertable (table variable!)

				- create the stored procedure to clean the jobqueue-table
					- dbo.jobqueue_delete
					
				The stored procedure uses two variables which control the behavior
				@rowlimit	=>	batch size of rows to be deleted
				@maxlimit	=>	number of rows to delete from dbo.jobqueue

				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Performance optimization by identifying and correcting bad SQL code"

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

/*
	If the table aready exists we make sure it gets deleted first!
*/
DROP TABLE IF EXISTS dbo.jobqueue;
DROP TABLE IF EXISTS dbo.runtime_statistics;
GO

RAISERROR ('Creating table dbo.runtime_statistics', 0, 1) WITH NOWAIT;
CREATE TABLE dbo.runtime_statistics
(
	id			INT				NOT NULL	IDENTITY (1, 1)	PRIMARY KEY CLUSTERED,
	action_name	VARCHAR(64)		NOT NULL,
	num_rows	BIGINT			NOT NULL,
	start_date	DATETIME2(7)	NOT NULL,
	finish_date	DATETIME2(7)	NOT NULL,
	diff_ms	AS	DATEDIFF(MILLISECOND, start_date, finish_date)
);
GO

RAISERROR ('Creating table dbo.jobqueue', 0, 1) WITH NOWAIT;
CREATE TABLE dbo.jobqueue
(
	uid_jobqueue	VARCHAR(38) NOT NULL,
	uid_task		VARCHAR(38) NULL,
	objectname		VARCHAR(38) NULL,
	subobjectname	VARCHAR(38) NULL,
	sortorder		INT			NOT NULL	CONSTRAINT df_jobqueue_sortorder DEFAULT (0),
	istouched		NCHAR(1)	NULL,
	genprocid		VARCHAR(38) NOT NULL,
	generation		INT NULL				CONSTRAINT df_jobqueue_generation DEFAULT (0),

	CONSTRAINT pk_jobqueue PRIMARY KEY NONCLUSTERED 
	(uid_jobqueue ASC)
);
GO

/* Now we fill ~5.000.000 rows into the table */
RAISERROR ('Filling dbo.jobqueue with 5,000,000 rows', 0, 1) WITH NOWAIT;
INSERT INTO dbo.jobqueue WITH (TABLOCK)
(uid_jobqueue, sortorder, istouched, genprocid, generation)
SELECT	TOP (5000000)
		CAST(NEWID() AS VARCHAR(38))	AS	uid_jobqueue,
		CAST(1 AS INT)					AS	sortorder,
		N'1'							AS	istouched,
		CAST(NEWID() AS VARCHAR(38))	AS	genprocid,
		-1								AS	generation
FROM	dbo.orders;
GO

RAISERROR ('creating additional indexes on dbo.jobqueue', 0, 1) WITH NOWAIT;
CREATE NONCLUSTERED INDEX nix_jobqueue_sortorder ON dbo.jobqueue (sortorder)
INCLUDE
(
	generation,
	uid_task,
	genprocid
);
GO

CREATE NONCLUSTERED INDEX nix_jobqueue_genprocid ON dbo.jobqueue (genprocid)
INCLUDE
(
	generation,
	uid_task,
	sortorder
);
GO

CREATE NONCLUSTERED INDEX nix_jobqueue_uid_task ON dbo.jobqueue
(
       uid_task		ASC,
       sortorder	ASC,
       genprocid	ASC,
       generation	ASC
)
INCLUDE
(
	uid_jobqueue,
	objectname
);
GO

CREATE NONCLUSTERED INDEX nix_jobqueue_objectname ON dbo.jobqueue
(
       objectname	ASC,
       UID_Task		ASC
)
INCLUDE
(
	Generation,
	GenProcID,
	subobjectname
);
GO

RAISERROR ('Creating table data types for the stored procedure', 0, 1) WITH NOWAIT;
DROP TYPE IF EXISTS dbo.helpertable;
GO

CREATE TYPE dbo.helpertable AS TABLE
(
	singleguid	VARCHAR(38)	NOT NULL	PRIMARY KEY NONCLUSTERED,
	bitproperty	BIT			NULL		DEFAULT (0),
	intproperty	INT			NULL		DEFAULT (0)
);
GO