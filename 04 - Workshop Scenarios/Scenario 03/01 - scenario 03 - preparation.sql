/*
	============================================================================
	File:		01 - scenario 03 - preparation of environment.sql

	Summary:	This script creates the environment for the scenario.
				- table:	dbo.persons		(~1.6 Mio records)
				- table:	dbo.sapusers	(~6.5 Mio records)
				- create all necessary indexes
				- create a stored procedure to be executed

				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Accelerate your SQL Code"

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

DROP TABLE IF EXISTS dbo.sapusers;
DROP TABLE IF EXISTS dbo.persons;
GO

RAISERROR ('Creating table [dbo].[persons]...', 0, 1) WITH NOWAIT;
CREATE TABLE dbo.persons
(
	uid_person					VARCHAR(38)		NOT NULL,
	internalname				NVARCHAR(128)	NULL,
	centralaccount				NVARCHAR(110)	NULL,
	xmarkedfordeletion			INT				NULL,
	centralsapaccount			NVARCHAR(12)	NULL,
	ccc_aliasname				NVARCHAR(256)	NULL,
	c1_filler					CHAR(512)		NOT NULL	DEFAULT ('shit')
);
GO

RAISERROR ('filling table [dbo].[persons] with 1.607.958 rows...', 0, 1) WITH NOWAIT;
INSERT INTO dbo.persons WITH (TABLOCK)
(uid_person, internalname, centralaccount, xmarkedfordeletion, centralsapaccount, ccc_aliasname)
SELECT	'00002332-5324-4b66-afe7-ea2024c9cd9a'	AS	uid_person,
		N'uricken'								AS	internalname,
		N'QM2Q177'								AS	centralaccount,
		0										AS	xmarkedfordeletion,
		N'QM2Q177'								AS	centralsapaccount,
		NULL									AS	ccc_aliasname

UNION ALL

SELECT	NEWID()							AS	uid_person,
		REVERSE(RIGHT(c_name, 8))		AS	internalname,
		LEFT(c_comment, 8)				AS	centralaccount,
		CAST(RAND() * 100 AS INT) % 2	AS	xmarkedfordeletion,
		REVERSE(RIGHT(c_name, 8))		AS	centralsapaccount,
		NULL
FROM	dbo.customers;
GO

RAISERROR ('creating primary key and non clustered indexe(s) on [dbo].[persons]...', 0, 1) WITH NOWAIT;
ALTER TABLE dbo.persons
ADD CONSTRAINT pk_persons PRIMARY KEY CLUSTERED (uid_person);
GO


RAISERROR ('Creating table [dbo].[sapusers]...', 0, 1) WITH NOWAIT;
CREATE TABLE dbo.sapusers
(
	uid_sapuser	VARCHAR(38)		NOT NULL,
	uid_person	VARCHAR(38)		NULL,
	accnt		NVARCHAR(38)	NULL,
	c1_filler	NCHAR(1024)		NOT NULL DEFAULT (N'test')
);
GO

RAISERROR ('filling table [dbo].[sapusers] with 6.607.958 Mio rows...', 0, 1) WITH NOWAIT;
INSERT INTO dbo.sapusers WITH (TABLOCK)
(uid_sapuser, uid_person, accnt)
SELECT	CAST(NEWID() AS VARCHAR(38))	AS	uid_sapuser,
		p.uid_person,
		p.uid_person
FROM	dbo.persons AS p
GO

INSERT INTO dbo.sapusers WITH (TABLOCK)
(uid_sapuser, uid_person, accnt)
SELECT	TOP (5000000)
		NEWID()		AS	uid_sapuser,
		NULL,
		NULL
FROM	dbo.orders;
GO

RAISERROR ('updating a few rows in [dbo].[sapusers]...', 0, 1) WITH NOWAIT;
UPDATE	s WITH (TABLOCKX)
SET		s.accnt = p.centralsapaccount
		FROM dbo.persons AS p
		INNER JOIN dbo.sapusers AS s
		ON (p.uid_person = s.uid_person)
GO

RAISERROR ('creating primary key on [dbo].[sapusers]...', 0, 1) WITH NOWAIT;
ALTER TABLE dbo.sapusers
ADD CONSTRAINT pk_sapuser_uid_sapuser PRIMARY KEY CLUSTERED (uid_sapuser)
WITH (DATA_COMPRESSION = PAGE);
GO

ALTER DATABASE ERP_Demo SET QUERY_STORE CLEAR;
GO
