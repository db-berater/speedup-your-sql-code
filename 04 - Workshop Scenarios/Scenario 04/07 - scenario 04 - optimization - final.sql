/*
	============================================================================
	File:		07 - scenario 04 - optimization - final.sql

	Summary:	The problems cannot be solved sufficently by optimizing the triggers.
				Instead of triggers the implementation of a user definied function
				seems to be the better way.

				It is not better when we query the data but will speed up the 
				DML processes.

				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Accelerate your SQL Code"

	Date:		October 2024
	Revion:		February 2025

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