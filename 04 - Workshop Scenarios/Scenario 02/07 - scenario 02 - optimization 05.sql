/*
	============================================================================
	File:		07 - scenario 02 - optimization 05.sql

	Summary:	The process cannot scale when the process will work with multiple
				threads. To avoid this we use the following technics:
				- partitioning	(1 partition for each process / max 10)
					- dbo.used_partition:	session stores the aquired partition
					- dbo.session_values:	uid_jobqueue values for deletion / partition

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
USE ERP_Demo;
GO

/* repopulate the 5 million rows again! */
DROP TABLE IF EXISTS dbo.jobqueue;
DROP TABLE IF EXISTS dbo.used_partition;
DROP TABLE IF EXISTS dbo.session_values;
GO

/* With the exact number of partitions to the simultanious threads we can spread the workload */
IF EXISTS (SELECT * FROM sys.partition_schemes WHERE name = N'ps_session_divisor')
BEGIN
	RAISERROR ('Dropping partition schema ps_session_divisor', 0, 1) WITH NOWAIT
	DROP PARTITION SCHEME ps_session_divisor;
END
GO

IF EXISTS (SELECT * FROM sys.partition_functions WHERE name = N'pf_session_divisor')
BEGIN
	RAISERROR ('Dropping partition function pf_session_divisor', 0, 1) WITH NOWAIT;
	DROP PARTITION FUNCTION pf_session_divisor;
END
GO

RAISERROR ('Creating partition function pf_session_divisor', 0, 1) WITH NOWAIT;
CREATE PARTITION FUNCTION pf_session_divisor (SMALLINT)
AS RANGE LEFT
FOR VALUES(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
GO

RAISERROR ('Creating partition scheme ps_session_divisor', 0, 1) WITH NOWAIT;
CREATE PARTITION SCHEME ps_session_divisor
AS PARTITION pf_session_divisor
ALL TO ([PRIMARY]);
GO

RAISERROR ('Creating the table dbo.jobqueue on the partition scheme', 0, 1) WITH NOWAIT;
CREATE TABLE dbo.jobqueue
(
	uid_jobqueue	VARCHAR(38) NOT NULL,
	uid_task		VARCHAR(38) NULL,
	objectname		VARCHAR(38) NULL,
	subobjectname	VARCHAR(38) NULL,
	sortorder		INT			NOT NULL	CONSTRAINT df_jobqueue_sortorder DEFAULT (0),
	istouched		NCHAR(1)	NULL,
	genprocid		VARCHAR(38) NOT NULL,
	generation		INT			NULL		CONSTRAINT df_jobqueue_generation DEFAULT (0),
	session_partition	AS	CAST(ABS(CHECKSUM(uid_jobqueue)) % 10 + 1 AS SMALLINT) PERSISTED,

	CONSTRAINT pk_jobqueue PRIMARY KEY CLUSTERED 
	(
		uid_jobqueue ASC,
		session_partition
	)
	ON ps_session_divisor (session_partition)
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

/* Check the distribution of data in the partitioned dbo.jobqueue table */
SELECT	[schema.table],
		[Index ID],
		rows,
		[partition #]
FROM	dbo.get_partition_layout_info(N'dbo.jobqueue', 1);
GO

/*
	Let's create an infrastructure for parallel delete operations
*/
DROP TABLE IF EXISTS dbo.used_partition;
GO

CREATE TABLE dbo.used_partition
(
	session_uid		UNIQUEIDENTIFIER	NOT NULL,
	partition_key	SMALLINT			NOT NULL,

	CONSTRAINT pk_used_partition PRIMARY KEY CLUSTERED
	(partition_key),

	CONSTRAINT uq_session_id UNIQUE (session_uid)
);
GO

/* Stored procedure changed for mulitple processes at the same time */
CREATE OR ALTER PROCEDURE dbo.jobqueue_delete
	@rowlimit	INT	=	1000,
	@maxlimit	INT =	50000
AS
BEGIN
	SET NOCOUNT ON;

	/* Declaration of variables for the execution */
	DECLARE	@session_uid			UNIQUEIDENTIFIER = NEWID();
	DECLARE	@partition_key			INT;

	DECLARE	@rows_deleted_actual	INT = 1;
	DECLARE @rows_deleted_total		INT = 0;

	DECLARE	@error_message		NVARCHAR(2024);
	DECLARE	@error_number		INT;
	DECLARE	@error_line			INT;

	/*
		With the first step we reserve a partition for our process
		Keep in mind that we have a @session_uid defined at the
		beginning of the procedure!

		The list (PK) covers partitions from 1 to 10!
	*/
	WITH pk
	AS
	(
		SELECT	*
		FROM	(VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10)) AS x (partition_key)
	)
	INSERT INTO dbo.used_partition WITH (TABLOCKX)
	(session_uid, partition_key)
	SELECT	TOP (1)
			@session_uid,
			pk.partition_key
	FROM	pk
			LEFT JOIN dbo.used_partition AS up
			ON (pk.partition_key = up.partition_key)
	WHERE	up.session_uid IS NULL;

	/* If we cannot get a slot we quit the process! */
	IF @@ROWCOUNT = 0
		RETURN 0;

	/* Now we get our personal partition key for the process */
	SELECT	@partition_key = partition_key
	FROM	dbo.used_partition
	WHERE	session_uid = @session_uid;

	IF @partition_key IS NULL
		RETURN 0;

	BEGIN TRY
		/*
			The exact number of rows is not mandatory for the process.
			The @rows_total is only for checking IF data are available
			in the table.
		*/
		WHILE (@rows_deleted_actual) > 0 AND @rows_deleted_total < @maxlimit
		BEGIN
			DELETE	TOP (@rowlimit)
					jq
			FROM	dbo.jobqueue AS jq
			WHERE	generation = -1
					AND $PARTITION.pf_session_divisor(sv.partition_key) = @partition_key;

			SET	@rows_deleted_actual = @@ROWCOUNT;
			SET	@rows_deleted_total += @rows_deleted_actual;

			IF (@maxlimit - @rows_deleted_total) < @rowlimit
				SET	@rowlimit =  (@maxlimit - @rows_deleted_total);
		END
	END TRY
	BEGIN CATCH
		SET	@error_message = ERROR_MESSAGE();
		SET	@error_number = ERROR_NUMBER();
		SET	@error_line = ERROR_LINE();
		SELECT	@error_message	AS	error_message,
				@error_number	AS error_number,
				@error_line		AS	error_ine;
	END CATCH

	/* Now we clean the environment */
	DELETE	dbo.used_partition
	WHERE	session_uid = @session_uid;

	RETURN @rows_deleted_total;
END
GO