CREATE USER [perfmon] FOR LOGIN [perfmon] WITH DEFAULT_SCHEMA=[dbo]
GO
ALTER ROLE [reporter] ADD MEMBER [perfmon]
GO
ALTER ROLE [importer] ADD MEMBER [perfmon]
GO
ALTER ROLE [db_datareader] ADD MEMBER [perfmon]
GO
ALTER ROLE [db_datawriter] ADD MEMBER [perfmon]
GO
