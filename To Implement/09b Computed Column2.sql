/****************************************************************************/
/*                Module: Transact-SQL Performance Tips                     */
/*                        Author: Miloš Radivojević                         */
/*                                                                          */
/****************************************************************************/
/*                             Computed columns                             */
/*                                                                          */
/****************************************************************************/
USE TransactSQLTips;
GO
---------------------------------------------------------------------------
-- Using an index on computed column to resolve data type conversion issue
---------------------------------------------------------------------------
SELECT * FROM Orders 
WHERE CustId = 248131;
/*
 SQL Server Execution Times:
   CPU time = 7690 ms,  elapsed time = 5336 ms.
*/

--adding a computed column (non-persistent)
ALTER TABLE Orders ADD CustId2 AS CAST(CustId AS INT);
GO

--repeat the query
SELECT * FROM Orders 
WHERE CustId = 248131;
/*
 SQL Server Execution Times:
   CPU time = 1565 ms,  elapsed time = 281 ms.
*/
/*
already better! computed column helped even without an index
*/

--adding an index on the computed column
CREATE INDEX ixc2 ON Orders(CustId2);
GO

--repeat the query
SELECT * FROM Orders 
WHERE CustId = 248131;
/*
 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 20 ms.
*/
/*
instantly executed!
*/


---------------------------------------------------------------------------
-- Limitations
---------------------------------------------------------------------------
/*
ANSI_NULLS = ON
ANSI_PADDING = ON
ANSI_WARNINGS = ON
ARITHABORT = ON
CONCAT_NULL_YIELDS_NULL = ON
QUOTED_IDENTIFIER = ON
NUMERIC_ROUNDABORT = OFF
*/

SET NUMERIC_ROUNDABORT OFF;
SELECT * FROM Orders 
WHERE CustId = 248131;
/*
index on computed column is used
*/
SET NUMERIC_ROUNDABORT ON;
SELECT * FROM Orders 
WHERE CustId = 248131;
/*
index on computed column is not used
*/

SET NUMERIC_ROUNDABORT OFF;
UPDATE Orders SET CustId = 248133 WHERE CustId = 248132;
/*
update works
*/
SET NUMERIC_ROUNDABORT ON;
UPDATE Orders SET CustId = 248134 WHERE CustId = 248133;
/*
Msg 1934, Level 16, State 1, Line 41
UPDATE failed because the following SET options have incorrect settings: 'NUMERIC_ROUNDABORT'. Verify that SET options are correct for use with indexed views and/or indexes on computed columns and/or filtered indexes and/or query notifications and/or XML data type methods and/or spatial index operations.

*/

---------------------------------------------------------------------------
-- Cleanup
---------------------------------------------------------------------------
DROP INDEX ixc2 ON Orders;
ALTER TABLE Orders DROP COLUMN CustId2;
GO