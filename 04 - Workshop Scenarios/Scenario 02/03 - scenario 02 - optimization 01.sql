/*
	============================================================================
	File:		03 - scenario 02 - optimization 01.sql

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
	DECLARE @run_delete			INT = 0;
	DECLARE @num_deletes		INT;
	DECLARE @num_deletes_total	INT = 0;
	DECLARE @start_time			DATETIME;
	DECLARE @end_time			DATETIME;
	DECLARE @diff				INT;
	DECLARE @expected_runtime	FLOAT = 1000.0;
	DECLARE @rows_total			INT;

	DECLARE	@error_message		NVARCHAR(2024);
	DECLARE	@error_number		INT;
	DECLARE	@error_line			INT;

BEGIN TRY
	/* Code change for optimization 01 */
	IF EXISTS (SELECT * FROM dbo.jobqueue)
		SET	@rows_total = 1
	ELSE
		IF @rows_total > 0

	IF @rows_total = 0	AND @@TRANCOUNT = 0
	BEGIN
		BEGIN TRANSACTION;
		BEGIN TRY
			UPDATE	dbo.jobqueue
			SET		Generation = q.Generation
			FROM	dbo.jobqueue AS q WITH (TABLOCKX);
		END TRY
		BEGIN CATCH
			SET	@rows_total = 1;
		END CATCH

		/* Step 1: We replace the second count by the previous value */
		IF (SELECT COUNT(*) FROM dbo.jobqueue) = 0 AND @rows_total = 0
		BEGIN
			BEGIN TRY
				TRUNCATE TABLE dbo.jobqueue;
				COMMIT;
				
				SET	@run_delete = 1;
			END TRY
			BEGIN CATCH
				ROLLBACK;
			END CATCH
		END
		ELSE
		BEGIN
			ROLLBACK;
		END
	END

	IF @run_delete = 1
	BEGIN
		GOTO endLabel;
	END

normal:
	INSERT INTO @Items (singleguid)
	SELECT	TOP (@maxlimit)
			qt.uid_jobqueue
	FROM	dbo.jobqueue AS qt WITH (READPAST)
	WHERE	generation = -1;

	SET	@run_delete = 1;
	SET	@rows_per_batch = @RowLimit;

	WHILE @run_delete > 0
	BEGIN
		SET		@start_time = GETUTCDATE()

		DELETE	@ItemPortion;

		INSERT INTO @ItemPortion (singleguid)
		SELECT TOP (@rows_per_batch)
				t.singleguid
		FROM	@Items t
		WHERE	t.BitProperty = 0;

		SET		@run_delete = @@ROWCOUNT;

		IF @run_delete = 0
			CONTINUE;

		UPDATE	@Items
		SET		BitProperty = 1
		FROM	@Items AS t
				INNER JOIN @ItemPortion AS p
				ON (t.singleguid = p.singleguid)

		BEGIN TRY
			DELETE	dbo.jobqueue
			WHERE	uid_jobqueue IN
					(
						SELECT t.singleguid
						FROM @ItemPortion t
					);

			SET		@num_deletes = @@ROWCOUNT;
		END TRY
		BEGIN CATCH
			SELECT	@num_deletes = 0;
			WAITFOR DELAY '00:00:05';
		END CATCH

		SET @num_deletes_total += @num_deletes;
		SET	@end_time = GETUTCDATE();
		SET	@diff = DATEDIFF(ms, @start_time, @end_time)

		SELECT @rows_per_batch =
			CASE
				WHEN @diff = 0 THEN @RowLimit
				WHEN @num_deletes = 0 THEN @RowLimit
				WHEN @diff > @expected_runtime THEN @RowLimit
				ELSE CONVERT(INT, @expected_runtime * CONVERT(float, @rows_per_batch) / CONVERT(float, @diff))
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
	RETURN (@num_deletes_total);
END
GO