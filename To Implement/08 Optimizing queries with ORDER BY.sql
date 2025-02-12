/****************************************************************************/
/*                Module: Transact-SQL Performance Tips                     */
/*                        Author: Miloš Radivojević                         */
/*                                                                          */
/****************************************************************************/
/*                     Optimizing queries with ORDER BY                     */
/*                                                                          */
/****************************************************************************/
USE TransactSQLTips;
GO
SELECT * FROM dbo.Orders
WHERE DATEDIFF(day, OrderDate, DeliveryDate) > 30
ORDER BY OrderDate;
/*
memory grant: 1 593MB
*/

--simply remove ORDER BY
SELECT * FROM dbo.Orders
WHERE DATEDIFF(day, OrderDate, DeliveryDate) > 30; 
/*
memory grant: 0, but serial plan
*/
SELECT * FROM dbo.Orders
WHERE DATEDIFF(day, OrderDate, DeliveryDate) > 30
OPTION(QUERYTRACEON 8649);
/*
memory grant: 0, parallel plan
*/

--rewrite the query by using a temp table
DROP TABLE IF EXISTS #t;
SELECT * INTO #t FROM dbo.Orders
WHERE DATEDIFF(day, OrderDate, DeliveryDate) > 30
SELECT * FROM #t ORDER BY OrderDate;
/*
memory grant: 1MB
*/

--do not use CTE, it will create the same plan as the initial one
;WITH cte AS(
SELECT * FROM dbo.Orders
WHERE DATEDIFF(day, OrderDate, DeliveryDate) > 30
)
SELECT * FROM cte ORDER BY OrderDate;
/*
memory grant: 1 593MB
*/

--do not use table variable, insert into table variable is parallelism inhibitor
DECLARE @t TABLE(
	[Id] [int] NOT NULL,
	[CustomerId] [int] NOT NULL,
	[OrderDate] [datetime] NOT NULL,
	[Amount] [int] NOT NULL,
	[Other] [char](500) NOT NULL,
	[Status] [tinyint] NOT NULL,
	[CustId] [varchar](20) NULL,
	[DeliveryDate] [datetime] NULL
)
INSERT INTO @t
SELECT * FROM dbo.Orders
WHERE DATEDIFF(day, OrderDate, DeliveryDate) > 30
SELECT * FROM @t ORDER BY OrderDate;
/*
memory grant: 1MB, but serial plan
*/