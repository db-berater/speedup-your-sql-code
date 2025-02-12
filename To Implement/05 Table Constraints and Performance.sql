/****************************************************************************/
/*                Module: Transact-SQL Performance Tips                     */
/*                        Author: Miloš Radivojević                         */
/*                                                                          */
/****************************************************************************/
/*                    Table Constraints and Performance                     */
/*                                                                          */
/****************************************************************************/

SET STATISTICS IO, TIME ON;
GO
------------------------------------------------------------------------------
--CHECK Constraint
------------------------------------------------------------------------------
USE AdventureWorks2022;
SELECT DISTINCT Status FROM Sales.SalesOrderHeader;
--Result: 5 (the status 5 is set for all orders, no rows with Status <> 5)

--Check for rows with the status 4 or 6
SELECT * FROM Sales.SalesOrderHeader WHERE Status = 4;
SELECT * FROM Sales.SalesOrderHeader WHERE Status = 6;
/*
Result: 50% : 50%
the same plans - Clustered Index Scan with 689 logical reads
*/
/*
Let's assume that Status cannot be greather than 5
and let's create a CHECK constraint ensuring this rule
*/
ALTER TABLE Sales.SalesOrderHeader WITH CHECK 
	ADD CONSTRAINT chkStatus CHECK (Status <= 5);

--Check again for rows with the status 4 or 6
SELECT * FROM Sales.SalesOrderHeader WHERE Status = 4;
SELECT * FROM Sales.SalesOrderHeader WHERE Status = 6;
/*
Result: 100% : 0%
in the first case Clustered Index Scan is used,
for the second query the table was not touched at all!
SQL Server knew that this is not possible, because of CHECK constraint 
*/
--Clean-Up
ALTER TABLE Sales.SalesOrderHeader DROP CONSTRAINT chkStatus;
GO

------------------------------------------------------------------------------
--UNIQUE Constraint
------------------------------------------------------------------------------
USE TransactSQLTips;
--create and populate a lookup table
DROP TABLE IF EXISTS dbo.StatusLookup;
GO
CREATE TABLE dbo.StatusLookup(id TINYINT NOT NULL, Descr VARCHAR(10));
INSERT INTO dbo.StatusLookup VALUES(1, 'open'), (2, 'closed'), (3, 'cancelled');
GO

--create a report showing the status text and number of orders and amount summe
--for 1M orders
;WITH cte AS(
SELECT *, 
	(SELECT descr FROM dbo.StatusLookup sl WHERE o.Status=sl.id) orderstatus
FROM dbo.Orders o
WHERE id <= 1000000
)
SELECT orderstatus, COUNT_BIG(*) Cnt, SUM(Amount*1.0) Sm
FROM cte
GROUP BY orderstatus;
/*
Table 'Orders'. Scan count 9, logical reads 130222, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'StatusLookup'. Scan count 1000000, logical reads 1000000, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 29169 ms,  elapsed time = 4337 ms. 
*/

--create and populate a lookup table with primary key
DROP TABLE IF EXISTS dbo.StatusLookup2;
GO
CREATE TABLE dbo.StatusLookup2(id TINYINT NOT NULL PRIMARY KEY, Descr VARCHAR(10));
INSERT INTO dbo.StatusLookup2 VALUES(1, 'open'), (2, 'closed'), (3, 'cancelled');
GO

--repeat the query, but this time use new lookup table
;WITH cte AS(
SELECT *, 
	(SELECT descr FROM dbo.StatusLookup2 sl WHERE o.Status=sl.id) orderstatus
FROM dbo.Orders o
WHERE id <= 1000000
)
SELECT orderstatus, COUNT_BIG(*) Cnt, SUM(Amount*1.0) Sm
FROM cte
GROUP BY orderstatus;
/*
Table 'Orders'. Scan count 9, logical reads 135694, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'StatusLookup2'. Scan count 3, logical reads 4, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 625 ms,  elapsed time = 136 ms.
*/
/*
let's compare the times
 CPU time = 29169 ms,  elapsed time = 4337 ms. 
 CPU time =   625 ms,  elapsed time =  136 ms.
 A huge difference because of extra work SQL Server has to perform to get the text
 for the status in the first query. Without a PK or unique constraint, it is possible
 to have the following entries in the StatusLookupTable
 id   Descr
---- ----------
1    open
2    closed
3    cancelled
1    xxx
If this would be a case, SQL Server would send the following error message:
Msg 512, Level 16, State 1, Line 59
Subquery returned more than 1 value. This is not permitted when the subquery follows =, !=, <, <= , >, >= or when the subquery is used as an expression.

Even if this won't happen in the application, it COULD happen in the table and SQL Server
has to check this for all rows (therefore, you can see Stream Aggregate and Assert
operators in the first plan) and this takes some time, as you can see when you compare
both executions. Conclusion: Always add constraints to tables! 
*/
 

/****************************************************************************/
/*                               Takeaways                                  */
/****************************************************************************/

/*

* Always add constraints to tables, especially CHECK and UNIQUE constraints.

* Constraints do not provide only data integrity but the could also improve performance 

* CHECK constraints, UNIQUE constrains and FOREIGN KEYs 
*/
