/****************************************************************************/
/*                Module: Transact-SQL Performance Tips                     */
/*                        Author: Miloš Radivojević                         */
/*                                                                          */
/****************************************************************************/
/*                     UNION vs. UNION ALL                                  */
/*                                                                          */
/****************************************************************************/

--------------------------------------------
--UNION vs. UNION ALL
--------------------------------------------

use xSQLPASS2022;
GO
select orderid,CustomerId, cols  from Orders where OrderId <= 100000
union
select orderid,CustomerId, cols  from Orders where OrderId > 117683400
go

select orderid,CustomerId, cols  from Orders where OrderId <= 100000
union all
select orderid,CustomerId, cols from Orders where OrderId > 117683400

select orderid,CustomerId, cols  from Orders where CustomerId <= 100000
union
select orderid,CustomerId, cols  from Orders where OrderId > 117683400
go
select orderid,CustomerId, cols  from Orders where CustomerId <= 100000
union all
select orderid,CustomerId, cols from Orders where OrderId > 117683400
 
