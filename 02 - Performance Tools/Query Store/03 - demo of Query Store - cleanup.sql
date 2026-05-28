/*
	Clean the environment before we are starting the journey.
*/
EXEC dbo.sp_drop_foreign_keys
	@table_name = N'ALL';
GO

EXEC dbo.sp_drop_indexes
	@table_name = N'ALL',
    @check_only = 0;
GO

EXEC dbo.sp_clear_query_store;
GO