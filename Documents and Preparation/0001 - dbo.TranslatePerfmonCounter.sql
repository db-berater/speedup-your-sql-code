/*
	This script creates a stored procedure with a translation of
	all german perfmon counter names to corresponding english names!
*/

CREATE OR ALTER PROCEDURE dbo.TranslatePerfmonCounter
	@scenario	INT,
	@json_file	NVARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE	@retrieve_sql	NVARCHAR(1024);
	DECLARE	@json_input	TABLE (json_text NVARCHAR(MAX));

	DECLARE	@translation_list TABLE
	(
		german_object	NVARCHAR(128)	NOT NULL	PRIMARY KEY CLUSTERED,
		english_object	NVARCHAR(128)	NOT NULL
	);

	INSERT INTO @translation_list(german_object, english_object)
	SELECT *
	FROM	(
				VALUES
					(N'Bytes geschrieben/s', N'Write Bytes/Sec')
		    ) AS list(german_object, english_object);

	/* OPENROWSET cannot handle variables so we must use it in a weired way! */
	SET	@retrieve_sql = N'SELECT *
	FROM OPENROWSET 
		(
			BULK
			' + QUOTENAME(@json_file, '''') + ',
			SINGLE_CLOB
		) AS jf;'

	PRINT @retrieve_sql;
	INSERT INTO @json_input(json_text)
	EXEC sp_executesql @retrieve_sql;

	SELECT * FROM @json_input;
END
GO

--EXEC dbo.TranslatePerfmonCounter
--	@scenario = 1,
--	@json_file = 'S:\Windows Admin Server\PerfMon Counter - scenario 01.json';
--GO
