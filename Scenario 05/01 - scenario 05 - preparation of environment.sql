/*
	============================================================================
	File:		01 - scenario 05 - preparation of environment.sql

	Summary:	This script creates one table which is used heavily in the environment.
                The table has 1.6 mio records and a query (procedure dbo.stress_query)
                gets executed 600.000 / hr.

				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Performance optimization by identifying and correcting bad SQL code"

	Date:		October 2024
	Revion:		December 2024

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

DROP TABLE IF EXISTS dbo.AttestationCase;
GO

CREATE TABLE dbo.attestationcase
(
    uid_attestationcase     VARCHAR(38)     NOT NULL,
    uid_attestationpolicy   VARCHAR(38)     NOT NULL,
    uid_attestationrun      VARCHAR(38)     NOT NULL,
    objectkeybase           VARCHAR(139)    NULL
);
GO

INSERT INTO dbo.attestationcase WITH (TABLOCK)
(uid_attestationcase, uid_attestationpolicy, uid_attestationrun, objectkeybase)
SELECT  NEWID(), 'A', 'B', c_comment
FROM    dbo.customers;
GO

ALTER TABLE dbo.attestationcase
ADD CONSTRAINT pk_attestationcase PRIMARY KEY CLUSTERED
(uid_attestationcase)
WITH (SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE);
GO

/*
    Distribution of uid_attestationpolicy
*/
DECLARE @newid VARCHAR(38) = CAST(NEWID() AS VARCHAR(38));
UPDATE  TOP (450000) dbo.attestationcase
SET     uid_attestationpolicy = @newid
WHERE   uid_attestationpolicy = 'A'

SET @newid = CAST(NEWID() AS VARCHAR(38));
UPDATE  TOP (400000) dbo.attestationcase
SET     uid_attestationpolicy = @newid
WHERE   uid_attestationpolicy = 'A'

SET @newid = CAST(NEWID() AS VARCHAR(38));
UPDATE  TOP (100000) dbo.attestationcase
SET     uid_attestationpolicy = @newid
WHERE   uid_attestationpolicy = 'A'

SET @newid = CAST(NEWID() AS VARCHAR(38));
UPDATE  TOP (85000) dbo.attestationcase
SET     uid_attestationpolicy = @newid
WHERE   uid_attestationpolicy = 'A'

SET @newid = CAST(NEWID() AS VARCHAR(38));
UPDATE  TOP (70000) dbo.attestationcase
SET     uid_attestationpolicy = @newid
WHERE   uid_attestationpolicy = 'A'

SET @newid = CAST(NEWID() AS VARCHAR(38));
UPDATE  TOP (60000) dbo.attestationcase
SET     uid_attestationpolicy = @newid
WHERE   uid_attestationpolicy = 'A'

SET @newid = CAST(NEWID() AS VARCHAR(38));
UPDATE  TOP (40000) dbo.attestationcase
SET     uid_attestationpolicy = @newid
WHERE   uid_attestationpolicy = 'A'

SET @newid = CAST(NEWID() AS VARCHAR(38));
UPDATE  TOP (38000) dbo.attestationcase
SET     uid_attestationpolicy = @newid
WHERE   uid_attestationpolicy = 'A'

SET @newid = CAST(NEWID() AS VARCHAR(38))
UPDATE  ac
SET     uid_attestationpolicy = @newid
FROM    dbo.attestationcase AS ac
WHERE   uid_attestationpolicy = 'A'

SET @newid = CAST(NEWID() AS VARCHAR(38))
UPDATE  TOP (105000) ac
SET     uid_attestationrun = @newid
FROM    dbo.attestationcase AS ac
WHERE   uid_attestationrun = 'B'


SET @newid = CAST(NEWID() AS VARCHAR(38))
UPDATE  TOP (38000) ac
SET     uid_attestationrun = @newid
FROM    dbo.attestationcase AS ac
WHERE   uid_attestationrun = 'B'

SET @newid = CAST(NEWID() AS VARCHAR(38))
UPDATE  TOP (30000) ac
SET     uid_attestationrun = @newid
FROM    dbo.attestationcase AS ac
WHERE   uid_attestationrun = 'B'

SET @newid = CAST(NEWID() AS VARCHAR(38))
UPDATE  TOP (25000) ac
SET     uid_attestationrun = @newid
FROM    dbo.attestationcase AS ac
WHERE   uid_attestationrun = 'B'

SET @newid = CAST(NEWID() AS VARCHAR(38))
UPDATE  TOP (22000) ac
SET     uid_attestationrun = @newid
FROM    dbo.attestationcase AS ac
WHERE   uid_attestationrun = 'B'

--DECLARE @num_records INT = 500000;
--WHILE @num_records > 0
--BEGIN
--    SET @newid = CAST(NEWID() AS VARCHAR(38))
--    UPDATE  TOP (@num_records) ac
--    SET     uid_attestationrun = @newid
--    FROM    dbo.attestationcase AS ac
--    WHERE   uid_attestationrun = 'B'

--    SET @num_records = @num_records - (@num_records * 0.25);

--    IF @num_records <= 10
--        BREAK;
--END
--GO

SELECT COUNT_BIG(*)
FROM    dbo.attestationcase;
GO

SELECT  uid_attestationpolicy,
        COUNT_BIG(*)
FROM    dbo.attestationcase
GROUP BY
        uid_attestationpolicy
ORDER BY
        COUNT_BIG(*) DESC;
GO

SELECT  uid_attestationrun,
        COUNT_BIG(*)
FROM    dbo.attestationcase
GROUP BY
        uid_attestationrun
ORDER BY
        COUNT_BIG(*) DESC;
GO

SELECT TOP (1) uid_attestationcase
FROM    dbo.attestationcase