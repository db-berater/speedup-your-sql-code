/*
	============================================================================
	File:		06 - SQL Anti Paterns - Large In.sql

	Description:

	This script demonstrates the drawback of large number of values in an IN-Statement

				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Workshop - Spped Up Your SQL Code"

	Date:		October 2024
	Revion:		January 2025

	SQL Server Version: >= 2016
	------------------------------------------------------------------------------
	Written by Uwe Ricken, db Berater GmbH

	This script is intended only as a supplement to demos and lectures
	given by Uwe Ricken.  
  
	THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
	ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
	TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
	PARTICULAR PURPOSE.
	============================================================================
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

USE ERP_Demo;
GO

SELECT * FROM demo.Orders WHERE o_orderkey IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100);
GO
SELECT * FROM demo.Orders WHERE o_orderkey BETWEEN 1 AND 100;
GO

WITH r
AS
(
	SELECT	CAST (1 AS BIGINT) AS o_orderkey

	UNION ALL

	SELECT	o_orderkey + 1
	FROM	r
	WHERE	o_orderkey < 100
)
SELECT	o.*
FROM	demo.orders AS o
		INNER JOIN r
		ON (o.o_orderkey = r.o_orderkey)
OPTION	(MAXRECURSION 0);
GO

WITH r
AS
(
	SELECT	CAST (1 AS BIGINT) AS o_orderkey

	UNION ALL

	SELECT	o_orderkey + 1
	FROM	r
	WHERE	o_orderkey < 100
)
SELECT	o.*
FROM	demo.orders AS o
WHERE	o_orderkey IN (SELECT o_orderkey FROM r)
OPTION	(MAXRECURSION 0);
GO