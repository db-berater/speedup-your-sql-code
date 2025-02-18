/*
	============================================================================
	File:		08 - scenario 04 - clean the environment.sql

	Summary:	This script removes all custom objects from the database which 
				have been used for the demos!

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
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

USE ERP_Demo;
GO

/*
	Remove all indexes and foreign keys from the source tables
*/
EXEC dbo.sp_drop_foreign_keys @table_name = N'ALL';
EXEC dbo.sp_drop_indexes @table_name = N'ALL';
EXEC dbo.sp_drop_statistics @table_name = N'ALL';
GO

/*
	Remove all objects from the webshop schema
*/
DECLARE	@sql_stmt NVARCHAR(4000);

DECLARE c CURSOR LOCAL FORWARD_ONLY READ_ONLY
FOR
SELECT N'DROP ' +
		CASE 
			WHEN type = N'U' THEN 'TABLE'
			WHEN type = N'P' THEN 'PROCEDURE'
			WHEN type = N'FN' THEN 'FUNCTION'
			WHEN type = N'IF' THEN 'FUNCTION'
		END + ' '
		+ N'webshop.' + QUOTENAME(name)
FROM sys.all_objects WHERE schema_id = SCHEMA_ID(N'webshop')
AND type IN (N'U', N'P', 'IF', 'FN', 'MF')
ORDER BY
	type DESC;

OPEN c;
FETCH NEXT FROM c INTO @sql_stmt;
WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC sp_executesql @sql_stmt;
	FETCH NEXT FROM c INTO @sql_stmt;
END

CLOSE c;
DEALLOCATE c;
GO
