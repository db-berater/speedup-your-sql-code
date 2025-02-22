/*
	============================================================================
	File:		01 - scenario 02 - maintenance procedure.sql

	Summary:	This procedure creates the maintenance stored procedure
				dbo.jobqueue_delete.
				The code is - nearby - exactly the same as the vendor code
				and only modifified for better reading / understanding.
					
				The stored procedure uses two variables which control the behavior
				@rowlimit	=>	batch size of rows to be deleted
				@maxlimit	=>	number of rows to delete from dbo.jobqueue

				THIS SCRIPT IS PART OF THE WORKSHOP:
					"Workshop - Accelerate your SQL Code"

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
		/* Check the number of rows in the dbo.jobqueue table */
		SELECT	@rows_total = COUNT(*) FROM	dbo.jobqueue;

		IF @rows_total > 0
			GOTO normal

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
				WAITFOR DELAY '00:00:02';
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