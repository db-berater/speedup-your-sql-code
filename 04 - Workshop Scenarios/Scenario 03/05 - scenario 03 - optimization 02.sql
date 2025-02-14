/*
	============================================================================
	File:		05 - scenario 03 - optimization 02.sql

	Summary:	After we implemented the fix from the vendor we had the same
				issue as before. So we must change the query by ourself!
				
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
							(p.CentralSAPAccount = a.accnt)
					WHERE	a.uid_sapuser = @uid_sapuser

					UNION ALL

					SELECT	p.uid_person
					FROM	dbo.persons AS p
							INNER JOIN dbo.sapusers AS a
							ON
							(p.CCC_AliasName = a.accnt)
					WHERE	a.uid_sapuser = @uid_sapuser
				)
			)
	ORDER BY
		   internalname,
		   centralaccount;
END
GO