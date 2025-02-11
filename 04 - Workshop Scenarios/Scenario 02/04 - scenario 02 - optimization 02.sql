/*
	============================================================================
	File:		04 - scenario 02 - optimization 02.sql

	Summary:	This script is the first step to optimize the workload for the
				deletion of data from a job queue table!

				The developer is using SELECT COUNT for checking if records exists.
				This requires a FULL scan of a given index.
				Replace it with IF EXISTS!

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
	SET	LOCK_TIMEOUT 50;

	/* Declaration of variables for the execution */
	DECLARE	@items			AS	dbo.helpertable;
	DECLARE	@itemportion	AS	dbo.helpertable;

	DECLARE @rows_per_batch		INT;
	DECLARE @LaufDelete			INT = 0;
	DECLARE @AnzahlLoeschGesamt	INT = 0;

	DECLARE	@error_message		NVARCHAR(2024);
	DECLARE	@error_number		INT;
	DECLARE	@error_line			INT;

BEGIN TRY
	/*
		The exact number of rows is not mandatory for the process.
		The @rows_total is only for checking IF data are available
		in the table.
	*/
	IF EXISTS (SELECT * FROM dbo.jobqueue)
	BEGIN
		/*
			We insert the max rows which should be deleted
			into a table variable!
		*/
		INSERT INTO @Items (singleguid)
		SELECT TOP (@maxlimit)
				qt.uid_jobqueue
		FROM	dbo.jobqueue AS qt WITH (READPAST)
		WHERE	Generation = -1;

		/* Than we record the number of records we've inserted */
		SET	@LaufDelete = @@ROWCOUNT;
		SET	@rows_per_batch = @RowLimit;

		/* Now we move in a loop through the affected rows */
		WHILE @LaufDelete > 0
		BEGIN
			/* Remove all data from the second table variable! */
			DELETE	@ItemPortion;

			/* ... to insert the next package of rows to be deleted */
			INSERT INTO @ItemPortion(singleguid)
			SELECT TOP (@rows_per_batch)
					t.singleguid
			FROM	@Items t
			WHERE	t.BitProperty = 0;

			SET		@LaufDelete = @@ROWCOUNT;

			IF @LaufDelete = 0
				CONTINUE;

			/* now we mark processed records */
			UPDATE	@Items
			SET		BitProperty = 1
			FROM	@Items AS t
					INNER JOIN @ItemPortion AS p
					ON (t.singleguid = p.singleguid)

			/* And delete the rows from the target table */
			BEGIN TRY
				DELETE	dbo.jobqueue
				WHERE	uid_jobqueue IN
						(
							SELECT t.singleguid
							FROM @ItemPortion t
						);

				SET	@AnzahlLoeschGesamt += @@ROWCOUNT;

			END TRY
			BEGIN CATCH
				WAITFOR DELAY '00:00:05';
			END CATCH
		END
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

endLabel:
	RETURN @AnzahlLoeschGesamt;
END
GO