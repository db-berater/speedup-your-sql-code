USE ERP_Demo;
GO

/* Remove all objects, indexes and Foreign Keys */
EXEC dbo.sp_drop_foreign_keys @table_name = N'ALL';
EXEC dbo.sp_drop_indexes @table_name = N'ALL';
EXEC dbo.sp_drop_statistics @table_name = N'ALL';
GO

DECLARE	@sql_stmt	NVARCHAR(MAX);

DECLARE c CURSOR LOCAL FORWARD_ONLY READ_ONLY
FOR
	SELECT	N'DROP TABLE IF EXISTS ' + QUOTENAME(SCHEMA_NAME(schema_id)) + N'.' + QUOTENAME (name)
	FROM	sys.objects
	WHERE	schema_id = SCHEMA_ID(N'demo')
			AND type = N'U';

OPEN c;

FETCH NEXT FROM c INTO @sql_stmt;
WHILE @@FETCH_STATUS = 0
BEGIN
	PRINT @sql_stmt;
	EXEC sp_executesql @sql_stmt;
	FETCH NEXT FROM c INTO @sql_stmt;
END

CLOSE c;
DEALLOCATE c;
GO

IF SCHEMA_ID(N'demo') IS NOT NULL
	EXEC sp_executesql N'DROP SCHEMA [demo];';
	GO