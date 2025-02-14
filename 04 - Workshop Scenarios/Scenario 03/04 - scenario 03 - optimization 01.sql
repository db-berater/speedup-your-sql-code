/*
	============================================================================
	File:		04 - scenario 03 - stress query - optimization 01.sql

	Summary:	This script creates the original query which should be fired
				10.000 times in a minute!
				
				Use https://statisticsparser.com to analyze the usage of resources!

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
SET	NOCOUNT ON;
SET XACT_ABORT ON;
GO

USE ERP_Demo;
GO

CREATE OR ALTER PROCEDURE dbo.stress_query
	@uid_sapuser	VARCHAR(38)
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	SELECT	internalname,
			uid_person,
			centralaccount,
			xmarkedfordeletion
	FROM	dbo.persons
	WHERE	(
				uid_person IN
				(
					SELECT	p.uid_person
					FROM	dbo.persons AS p
							INNER JOIN dbo.sapusers AS a
							ON
							(
								p.CentralSAPAccount = a.accnt
								OR p.CCC_AliasName = a.accnt
							)
					WHERE	a.uid_sapuser = @uid_sapuser
				)
			)
	ORDER BY
		   internalname,
		   centralaccount;
END
GO