/*
	============================================================================
	File:		02 - scenario 05 - stress query.sql

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
/* This setting is for statisticsparser only! */
SET LANGUAGE us_english;
GO
USE ERP_Demo;
GO

CREATE OR ALTER PROCEDURE dbo.stress_query
AS
BEGIN
	DECLARE @v0 TABLE
	(
		keyval	VARCHAR(38) COLLATE DATABASE_DEFAULT NOT NULL PRIMARY KEY
	);

	INSERT INTO @v0 (keyval) VALUES ('00000864-E99F-48FA-BAA6-9D9875788414');

    SELECT TOP (1) 1
    WHERE EXISTS
    (
        SELECT  TOP (1) 1
        FROM    dbo.attestationcase as o2  
        INNER JOIN 
        (
            SELECT  ObjectKeyBase,
                    UID_AttestationPolicy,
                    UID_AttestationRun 
            FROM    dbo.attestationcase
            WHERE   UID_AttestationCase in (SELECT keyval FROM @V0)
        ) as o1 
        ON
        (
            (
                o1.ObjectKeyBase is null and o2.ObjectKeyBase is null
            )
            or o1.ObjectKeyBase = o2.ObjectKeyBase
        )
        and o1.UID_AttestationPolicy = o2.UID_AttestationPolicy
        and o1.UID_AttestationRun = o2.UID_AttestationRun
        GROUP BY
            o2.ObjectKeyBase,
            o2.UID_AttestationPolicy,
            o2.UID_AttestationRun
        HAVING COUNT(*) > 1
    );
END
GO

SET STATISTICS IO, TIME ON;
GO

EXEC dbo.stress_query;
GO

SET STATISTICS IO, TIME OFF;
GO