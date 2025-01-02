/*
	============================================================================
	File:		02 - scenario 03 - new indexes.sql

	Summary:	This script creates the original query which should be fired
				10.000 times in a minute!
				
				Use https://statisticsparser.com to analyze the usage of resources!

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

/*
	The JOIN Operation is on centralsapaccount and on ccc_aliasname!
	What could be more obvious than indexing these two attributes?
*/
IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.persons') AND name = N'nix_persons_centralsapaccount')
	DROP INDEX nix_persons_centralsapaccount ON dbo.persons;
	GO

IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.persons') AND name = N'nix_persons_ccc_aliasname')
	DROP INDEX nix_persons_ccc_aliasname ON dbo.persons;
	GO

CREATE NONCLUSTERED INDEX nix_persons_centralsapaccount
ON dbo.persons (centralsapaccount)
WITH (DATA_COMPRESSION = PAGE);
GO

CREATE NONCLUSTERED INDEX nix_persons_ccc_aliasname
ON dbo.persons (ccc_aliasname)
WITH (DATA_COMPRESSION = PAGE);
GO

/* We check it out! */
SET STATISTICS IO, TIME ON;
GO

/* Get the uid_sapuser first for the execution of the stored procedure */
DECLARE @uid_sapuser VARCHAR(38) = (SELECT uid_sapuser FROM dbo.sapusers WHERE uid_person = '00002332-5324-4B66-AFE7-EA2024C9CD9A');

EXEC dbo.stress_query @uid_sapuser = @uid_sapuser;
GO

SET STATISTICS IO, TIME OFF;
GO