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
ALTER TABLE dbo.Orders ADD [Offset] AS DATEDIFF(day, OrderDate, DeliveryDate);
GO
CREATE INDEX ixcompcol ON dbo.Orders([Offset]);
GO
SELECT * FROM dbo.Orders
WHERE DATEDIFF(day, OrderDate, DeliveryDate) > 30
ORDER BY OrderDate;
GO
DROP INDEX ixcompcol ON dbo.Orders
GO
ALTER TABLE dbo.Orders DROP COLUMN [Offset];
GO