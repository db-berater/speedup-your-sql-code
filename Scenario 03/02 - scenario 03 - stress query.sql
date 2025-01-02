/*
	============================================================================
	File:		02 - scenario 03 - proc stress_test_03 - original.sql

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
/*
	If you want to check the resources:
	SET LANGUAGE us_english

	This setting is for https://statisticsparser.com only!
*/
USE ERP_Demo;
GO


CREATE OR ALTER PROCEDURE dbo.stress_query
	@uid_sapuser	VARCHAR(38)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT	internalname,
			uid_person,
			centralaccount,
			xmarkedfordeletion
	FROM	dbo.persons
	WHERE	(
				uid_person IN
				(
					SELECT	p.uid_person
					FROM	(
								SELECT	a.accnt AS c1,
										a.accnt AS c2
								FROM	dbo.sapusers AS a
								WHERE	uid_sapuser = @uid_sapuser
							) AS x
							INNER JOIN dbo.persons AS p
							ON
							(
								p.CentralSAPAccount = x.c1
								OR p.CCC_AliasName = x.c2
							)
				)
			)
	ORDER BY
		   internalname,
		   centralaccount;
END
GO

ALTER DATABASE ERP_demo SET QUERY_STORE CLEAR;
GO

/*
	Activate the runtime execution plan before you execute the procedure!
*/
SET STATISTICS IO, TIME ON;
GO

/* Get the uid_sapuser first for the execution of the stored procedure */
DECLARE @uid_sapuser VARCHAR(38) = (SELECT uid_sapuser FROM dbo.sapusers WHERE uid_person = '00002332-5324-4B66-AFE7-EA2024C9CD9A');

EXEC dbo.stress_query @uid_sapuser = @uid_sapuser;
GO

SET STATISTICS IO, TIME OFF;
GO