/****************************************************************************/
/*                Module: Transact-SQL Performance Tips                     */
/*                        Author: Miloš Radivojević                         */
/*                                                                          */
/****************************************************************************/
/*                       SELECT * as bad practice                           */
/*                                                                          */
/****************************************************************************/
USE TransactSQLTips;
GO
DECLARE @now DATETIME = GETDATE();
SELECT * FROM dbo.Events e
WHERE EventDate >= @now 
ORDER BY e.Price;
/*
memory grant: 614MB
*/

ALTER TABLE dbo.Events ADD col1 VARCHAR(4000) NULL;
GO

DECLARE @now DATETIME = GETDATE();
SELECT * FROM dbo.Events e
WHERE EventDate >= @now 
ORDER BY e.Price;
/*
memory grant: 2,76GB
*/

ALTER TABLE dbo.Events ADD col2 VARCHAR(MAX) NULL;
GO

DECLARE @now DATETIME = GETDATE();
SELECT * FROM dbo.Events e
WHERE EventDate >= @now 
ORDER BY e.Price;
/*
memory grant: 7,07GB
*/

--cleanup
ALTER TABLE dbo.Events DROP COLUMN col1;
ALTER TABLE dbo.Events DROP COLUMN col2;
GO
