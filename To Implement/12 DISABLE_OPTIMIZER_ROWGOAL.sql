/****************************************************************************/
/*                Module: Transact-SQL Performance Tips                     */
/*                        Author: Miloš Radivojević                         */
/*                                                                          */
/****************************************************************************/
/*                        DISABLE_OPTIMIZER_ROWGOAL                         */
/*                                                                          */
/****************************************************************************/
USE TransactSQLTips;
GO
---------------------------------------------------------------------------
-- DISABLE_OPTIMIZER_ROWGOAL
---------------------------------------------------------------------------

SELECT TOP (10) o.DeliveryDate  
FROM Orders AS o
    INNER JOIN Events AS e
        ON o.ID = e.ID
WHERE o.OrderDate > '20220602'
ORDER BY 1
GO
SELECT TOP (10) o.DeliveryDate  
FROM Orders AS o
    INNER JOIN Events AS e
        ON o.ID = e.ID
WHERE o.OrderDate > '20220602'
ORDER BY 1
OPTION(USE HINT('DISABLE_OPTIMIZER_ROWGOAL'));