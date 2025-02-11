/*
	============================================================================
	File:		05 - scenario 02 - optimization 03.sql

	Summary:	This script is the final version of an optimized processing for
				batch operations in a big table.

				We can completely ignore the work with table objects and run the
				DELETE within a LOOP and after the deletion we check the number
				of affected rows!

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

CREATE OR ALTER PROCEDURE dbo.jobqueue_delete
	@rowlimit	INT	=	1000,
	@maxlimit	INT =	50000
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	/* Declaration of variables for the execution */
	DECLARE	@rows_deleted_actual	INT = 1;
	DECLARE @rows_deleted_total		INT = 0;

	DECLARE	@error_message		NVARCHAR(2024);
	DECLARE	@error_number		INT;
	DECLARE	@error_line			INT;

	BEGIN TRY
		/*
			The exact number of rows is not mandatory for the process.
			The @rows_total is only for checking IF data are available
			in the table.
		*/
		WHILE (@rows_deleted_actual) > 0 AND @rows_deleted_total < @maxlimit
		BEGIN
			DELETE	TOP (@rowlimit)
			FROM	dbo.jobqueue
			WHERE	Generation = -1;

			SET	@rows_deleted_actual = @@ROWCOUNT;
			SET	@rows_deleted_total += @rows_deleted_actual;

			IF (@maxlimit - @rows_deleted_total) < @rowlimit
				SET	@rowlimit =  (@maxlimit - @rows_deleted_total);
		END
	END TRY
	BEGIN CATCH
		SET	@error_message = ERROR_MESSAGE();
		SET	@error_number = ERROR_NUMBER();
		SET	@error_line = ERROR_LINE();
		SELECT	@error_message	AS	error_message,
				@error_number	AS error_number,
				@error_line		AS	error_ine;
	END CATCH

	RETURN @rows_deleted_total;
END
GO