/****************************************************************************/
/*                Module: Transact-SQL Performance Tips                     */
/*                        Author: Miloš Radivojević                         */
/*                                                                          */
/****************************************************************************/
/*          Mitigating issues for queries using the OR statement            */
/*                                                                          */
/****************************************************************************/
USE WideWorldImporters;
GO
SET NOCOUNT ON;
SET STATISTICS TIME ON;

--a slow query using the OR statement
SELECT DISTINCT p.StockItemID, p.StockItemName
FROM Warehouse.StockItems  p
INNER JOIN Sales.OrderLines o
ON
	(
		p.StockItemID = o.StockItemID
		OR p.StockItemName = o.Description
	);
GO

/*
 SQL Server Execution Times:
   CPU time = 14812 ms,  elapsed time = 2108 ms.
*/
/*
a very bad plan with Table Spool operator and almost 15 seconds of CPU time
Table Spool is an operator that should optimize execution and this was not
case in this plan, it rather made it worst. How to mitigate this?
You can try to rewrite the query by usin UNION instead of OR
*/
SELECT DISTINCT p.StockItemID, p.StockItemName
FROM Warehouse.StockItems  p
INNER JOIN Sales.OrderLines o ON p.StockItemID = o.StockItemID 
UNION
SELECT DISTINCT p.StockItemID, p.StockItemName
FROM Warehouse.StockItems  p
INNER JOIN Sales.OrderLines o ON p.StockItemName = o.Description;
GO
/*
 SQL Server Execution Times:
   CPU time = 93 ms,  elapsed time = 183 ms.
*/
/*
Result: 11x faster, 150x less CPU usage, a serial plan, no spool operators
withiut going to details, you were able to improve performance significantly
by using UNION instead of OR command
*/

--another example
USE TransactSQLTips;
GO
--
SELECT DISTINCT Status FROM Orders;
/*
Status
------
1
*/
/*
all rows in this table have value 1 in the Status column
there is no single row where status <> 1
*/

--this query returns 0 rows and there is an index on the Status column
SELECT * FROM Orders WHERE Status IN (0, 3);
GO
/*
Table 'Orders'. Scan count 1, logical reads 1270343, physical reads 3, page server reads 0, read-ahead reads 1270331, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 4703 ms,  elapsed time = 6412 ms.
*/
/*
the execution is very slow, SQL Server scanned the table and here is its estimation
Estimated Number od Rows: 10 000 000
Actual Number od Rows: 0
it expects all rows, 0 rows were returned - it cannot be worse
This is again an issue with OR because SQL Server internally rewrites the initial query to
SELECT * FROM Orders WHERE Status = 0 OR Status = 3
How to mitigate this? By using UNION operator!
*/

SELECT * FROM Orders WHERE Status = 0
UNION ALL
SELECT * FROM Orders WHERE Status = 3;
/*
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Orders'. Scan count 2, logical reads 8, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 1 ms,  elapsed time = 18 ms.
*/
/*
here we used the UNION ALL operator since a row cannot have different values
in the Status column at the same time
The plan looks better (Index Seek + Key Lookup), it is done twice, but it is 
significantly faster than the initial solution 350x faster 4000x less CPU
*/

/*
you can also try to force SQL Server to use rules for the old Cardinality Estimator
this might help for some queries, it won't always work, but it's worth a try
*/
--QUERY_OPTIMIZER_COMPATIBILITY_LEVEL_110 HINT
SELECT * FROM Orders WHERE Status IN (0,3)
OPTION(USE HINT('QUERY_OPTIMIZER_COMPATIBILITY_LEVEL_110'));
/*
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Orders'. Scan count 2, logical reads 6, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 13 ms.
*/

SELECT * FROM Orders WHERE Status IN (0,3)
OPTION(USE HINT('FORCE_LEGACY_CARDINALITY_ESTIMATION'))
/*
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Orders'. Scan count 2, logical reads 6, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 11 ms.
*/

USE WideWorldImporters;
GO
SELECT DISTINCT p.StockItemID, p.StockItemName
FROM Warehouse.StockItems  p
INNER JOIN Sales.OrderLines o ON p.StockItemID = o.StockItemID OR p.StockItemName = o.Description;
GO
SELECT DISTINCT p.StockItemID, p.StockItemName
FROM Warehouse.StockItems  p
INNER JOIN Sales.OrderLines o ON p.StockItemID = o.StockItemID OR p.StockItemName = o.Description 
OPTION(NO_PERFORMANCE_SPOOL)