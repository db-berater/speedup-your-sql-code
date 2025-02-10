/*
	============================================================================
	File:		0001 - Preparation of demo databases.sql

	Summary:	This script restores the database ERP_Demo from
				the backup medium for distribution of data.
				
				THIS SCRIPT IS PART OF THE TRACK: "Workshop - Making Bad Codes better"

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
USE master;
GO

/*
	Make sure you've executed the script 0000 - sp_restore_erp_demo.sql
	before you run this code!
*/
EXEC dbo.sp_restore_ERP_demo @query_store = 1;
GO

/* reset the sql server default settings for the demos */
EXEC ERP_Demo.dbo.sp_set_sql_server_defaults;
GO

SELECT * FROM ERP_Demo.dbo.get_database_help_info();
SELECT * FROM ERP_Demo.dbo.get_object_help_info(NULL);
GO
