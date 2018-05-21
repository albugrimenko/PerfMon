print '--- Registering roles and schemas ---'
GO
USE [master]
GO
CREATE LOGIN [perfmon] WITH PASSWORD=N'perfmon', DEFAULT_DATABASE=[PerfmonE], 
	CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
USE [PerfmonE]
GO
CREATE USER [perfmon] FOR LOGIN [perfmon] WITH DEFAULT_SCHEMA=[dbo]
GO
GRANT CONNECT TO [perfmon] AS [dbo]
GO
CREATE ROLE [reporter]
GO
CREATE ROLE [importer]
GO
EXEC sp_addrolemember N'reporter', N'perfmon'
GO
EXEC sp_addrolemember N'importer', N'perfmon'
GO
EXEC sp_addrolemember N'db_datareader', N'perfmon'
GO
EXEC sp_addrolemember N'db_datawriter', N'perfmon'
GO
CREATE SCHEMA [stage]
GO
GRANT EXECUTE ON SCHEMA::[stage] TO [perfmon] AS [dbo]
GO
GRANT INSERT ON SCHEMA::[stage] TO [perfmon] AS [dbo]
GO
GRANT SELECT ON SCHEMA::[stage] TO [perfmon] AS [dbo]
GO
GRANT UPDATE ON SCHEMA::[stage] TO [perfmon] AS [dbo]
GO
print '--- Registering roles and schemas: done. ---'
GO
