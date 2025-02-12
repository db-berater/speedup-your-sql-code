/****************************************************************************/
/*                Module: Transact-SQL Performance Tips                     */
/*                        Author: Miloš Radivojević                         */
/*                                                                          */
/****************************************************************************/
/*                         Data Type Conversions                            */
/*                                                                          */
/****************************************************************************/

---------------------------------------------------------------------
--INT vs. TEXT
---------------------------------------------------------------------
USE TransactSQLTips;
GO
-- compare two queries: data type of CustId is VARCHAR
SELECT * FROM dbo.Orders WHERE CustId = 688;
SELECT * FROM dbo.Orders WHERE CustId = '688';
 
/*
Table 'Orders'. Scan count 9, logical reads 1338602, physical reads 6922, page server reads 0, read-ahead reads 1312542, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
 SQL Server Execution Times:
   CPU time = 2701 ms,  elapsed time = 33220 ms.

Table 'Orders'. Scan count 1, logical reads 43, physical reads 4, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 1 ms.
*/

--a similar case
SELECT * FROM dbo.Orders WHERE CustomerId = 688;
SELECT * FROM dbo.Orders WHERE CustomerId = '688';
/*
Table 'Orders'. Scan count 1, logical reads 35, physical reads 3, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 22 ms.

Table 'Orders'. Scan count 1, logical reads 35, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 10 ms.
*/

---------------------------------------------------------------------
--Unicode text vs. Non-unicode text
---------------------------------------------------------------------
USE AdventureWorks2022
GO
DROP TABLE IF EXISTS dbo.Contacts
CREATE TABLE dbo.Contacts(
	Id INT NOT NULL PRIMARY KEY IDENTITY (1,1),
	PersonType NCHAR(2) NOT NULL,
	Title NVARCHAR(8) NULL,
	FirstName NVARCHAR(50) NOT NULL,
	LastName NVARCHAR(50) NOT NULL,
	Other CHAR(200) NULL DEFAULT 'aaa',
	ModifiedDate DATETIME NOT NULL
) 
GO
INSERT INTO dbo.Contacts(PersonType, Title, FirstName, LastName, ModifiedDate)
SELECT PersonType, Title, FirstName, LastName, ModifiedDate 
FROM Person.Person;
GO
CREATE INDEX ix1 ON dbo.Contacts(LastName)
GO

 
-- nvarchar column and varchar argument - NOTHING happens
SELECT FirstName, LastName FROM dbo.Contacts WHERE LastName = 'Atkinson';
GO
SELECT FirstName, LastName FROM dbo.Contacts WHERE LastName = N'Atkinson';
/*
Table 'Contacts'. Scan count 1, logical reads 5, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Contacts'. Scan count 1, logical reads 5, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
*/

--Add new column with VARCHAR type, update and index it
ALTER TABLE dbo.Contacts ADD LastName2 VARCHAR(50);
GO
UPDATE dbo.Contacts SET LastName2 = LastName;
GO
CREATE INDEX ix2 ON dbo.Contacts(LastName2);
GO

--VARCHAR column and NVARCHAR argument - CONVERSION needed
SELECT FirstName,LastName2 FROM dbo.Contacts WHERE LastName2 = 'Atkinson';
SELECT FirstName,LastName2 FROM dbo.Contacts WHERE LastName2 = N'Atkinson';
GO
/*
Table 'Contacts'. Scan count 1, logical reads 5, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Contacts'. Scan count 1, logical reads 54, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

*/
--cleanup
DROP TABLE IF EXISTS dbo.Contacts;
GO


---------------------------------------------------------------------
--Implicit data type conversion in JOIN statements
---------------------------------------------------------------------
USE TransactSQLTips;
GO
SELECT c.CustomerId, c.CustomerName, o.Id, o.OrderDate, o.Amount 
FROM dbo.Customers c
INNER JOIN dbo.Orders o ON c.CustomerId = o.CustId
WHERE c.CustomerId = 34;
/*
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 20 ms.
Table 'Orders'. Scan count 9, logical reads 1338972, physical reads 2, page server reads 0, read-ahead reads 1335823, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Customers'. Scan count 0, logical reads 3, physical reads 2, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 3263 ms,  elapsed time = 34182 ms.
*/
SELECT c.CustomerId, c.CustomerName, o.Id, o.OrderDate, o.Amount 
FROM dbo.Customers c
INNER JOIN dbo.Orders o ON CAST(c.CustomerId AS VARCHAR(10)) = o.CustId
WHERE c.CustomerId = 34;
/*
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 5 ms.
Table 'Orders'. Scan count 1, logical reads 51, physical reads 7, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Customers'. Scan count 0, logical reads 3, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 8 ms.
*/
