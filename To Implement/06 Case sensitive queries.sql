/****************************************************************************/
/*                Module: Transact-SQL Performance Tips                     */
/*                        Author: Miloš Radivojević                         */
/*                                                                          */
/****************************************************************************/
/*                     Case sensitive queries                               */
/*                                                                          */
/****************************************************************************/

USE TransactSQLTips;
GO
--show only those rows where the value of the Other column is abc (lowercase)
SELECT * FROM dbo.Orders
WHERE Other COLLATE SQL_Latin1_General_CP1_CS_AS = 'abc';

--solution 
WITH cte AS(
SELECT * FROM dbo.Orders
WHERE Other = 'abc'
)
SELECT * FROM cte WHERE 
Other COLLATE SQL_Latin1_General_CP1_CS_AS = 'abc';

