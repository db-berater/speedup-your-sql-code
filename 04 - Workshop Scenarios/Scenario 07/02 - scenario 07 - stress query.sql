/*
	============================================================================
	File:		02 - scenario 01 - stress query.sql

	Summary:	This script creates a stored procedure which should be run by
				- ostress OR
				- SQLQueryStress

				The procedure returns the total number of products and it's sales volume
				for each supplier
				
				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Performance optimization by identifying and correcting bad SQL code"

	Date:		October 2024
	Revion:		November 2024

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
USE ERP_Demo;
GO

--CREATE NONCLUSTERED INDEX nix_lineitems_l_partkey 
--ON dbo.lineitems (l_partkey)
--WITH (SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE);
--GO

DECLARE	@date_from	DATE	=	'2023-01-01';
DECLARE	@date_to	DATE	=	'2023-01-31';

SELECT	l.*,
		ps.*
FROM	dbo.orders AS o
		INNER JOIN dbo.lineitems AS l
		ON (o.o_orderkey = l.l_orderkey)
		CROSS APPLY
		(
			SELECT	ps_supplycost
			FROM	dbo.partsuppliers AS ps
			WHERE	ps.ps_suppkey = l.l_suppkey
					AND ps.ps_partkey = l.l_partkey
		) AS ps
WHERE	o.o_orderdate BETWEEN @date_from AND @date_to
ORDER BY
		l.l_partkey
OPTION	(RECOMPILE);