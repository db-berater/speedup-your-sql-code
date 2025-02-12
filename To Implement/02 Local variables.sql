/****************************************************************************/
/*                Module: Transact-SQL Performance Tips                     */
/*                        Author: Miloš Radivojević                         */
/*                                                                          */
/****************************************************************************/
/*                            Local Variables                               */
/*                                                                          */
/****************************************************************************/
USE TransactSQLTips;
GO
SET STATISTICS IO, TIME ON;
GO
DECLARE @now DATETIME =  GETDATE();
SELECT * FROM dbo.Events e
WHERE EventDate >= @now;
GO
SELECT * FROM dbo.Events e
WHERE EventDate >= GETDATE();
GO
USE TransactSQLTips;
GO
DECLARE @now DATETIME =  GETDATE();
SELECT * FROM dbo.Events e
INNER JOIN dbo.Orders o ON o.Id = e.Id
WHERE EventDate >= @now;
GO
SELECT * FROM dbo.Events e
INNER JOIN dbo.Orders o ON o.Id = e.Id
WHERE EventDate >= GETDATE();
GO
 
DECLARE @today DATETIME = '30000101';
SELECT * FROM dbo.Orders WHERE OrderDate >= @today;
GO	
DECLARE @today DATETIME = '19000101';
SELECT * FROM dbo.Orders WHERE OrderDate >= @today;

DECLARE @date DATETIME = '30000101';
SELECT * FROM dbo.Events WHERE EventDate >= @date
UNION ALL
SELECT * FROM dbo.Events WHERE EventDate < @date;

--Local variables and operator BETWEEN
SELECT SUM(Amount) FROM dbo.Orders 
WHERE OrderDate BETWEEN '20210609' AND '20210615';

DECLARE @StartDate DATETIME = '20210609', @EndDate DATETIME = '20210615'; 
SELECT SUM(Amount) FROM dbo.Orders 
WHERE OrderDate BETWEEN @StartDate AND @EndDate;
GO
DECLARE @StartDate DATETIME = '20210609', @EndDate DATETIME = '20210615'; 
SELECT SUM(Amount) FROM dbo.Orders 
WHERE OrderDate BETWEEN @StartDate AND @EndDate
OPTION (USE HINT('QUERY_OPTIMIZER_COMPATIBILITY_LEVEL_110'));


--Solution 1: literal
DECLARE @now DATETIME = GETDATE();
SELECT * FROM dbo.Events WHERE EventDate >= @now;
GO
SELECT * FROM dbo.Events WHERE EventDate >= GETDATE()

--Solution 2: OPTION (RECOMPILE)

DECLARE @now DATETIME = GETDATE();
SELECT * FROM dbo.Events WHERE EventDate >= @now;
SELECT * FROM dbo.Orders WHERE OrderDate >= @now;
GO
SELECT * FROM dbo.Events WHERE EventDate >= GETDATE()
SELECT * FROM dbo.Orders WHERE OrderDate >= GETDATE() 
GO
--these two GETDATE() do not return the same date
DECLARE @now DATETIME = GETDATE();
SELECT * FROM dbo.Events WHERE EventDate >= @now;
SELECT * FROM dbo.Orders WHERE OrderDate >= @now;
GO
DECLARE @now DATETIME = GETDATE();
SELECT * FROM dbo.Events WHERE EventDate >= @now OPTION (RECOMPILE)
SELECT * FROM dbo.Orders WHERE OrderDate >= @now OPTION (RECOMPILE)
GO

--Solution 3: Stored procedure

CREATE OR ALTER PROCEDURE dbo.WrapLocalVar
@date DATETIME
AS
BEGIN
SELECT * FROM dbo.Events WHERE EventDate >= @date
SELECT * FROM dbo.Orders WHERE OrderDate >= @date 

END
GO
DECLARE @now DATETIME = GETDATE();
SELECT * FROM dbo.Events WHERE EventDate >= @now 
SELECT * FROM dbo.Orders WHERE OrderDate >= @now 
GO
DECLARE @now DATETIME = GETDATE();
EXEC dbo.WrapLocalVar @now

EXEC dbo.WrapLocalVar '20240401'



