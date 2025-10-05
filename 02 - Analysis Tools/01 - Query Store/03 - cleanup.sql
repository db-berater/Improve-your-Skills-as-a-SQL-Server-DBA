USE ERP_Demo;
GO

/*
	Clean the environment before we are starting the journey.
*/
EXEC dbo.sp_drop_foreign_keys
	@table_name = N'ALL';
GO

BEGIN
	EXEC dbo.sp_drop_indexes
		@table_name = N'dbo.nations',
		@check_only = 0;

	EXEC dbo.sp_drop_indexes
		@table_name = N'dbo.regions',
		@check_only = 0;

	EXEC dbo.sp_drop_indexes
		@table_name = N'dbo.orders',
		@check_only = 0;
END
GO

EXEC dbo.sp_clear_query_store;
GO