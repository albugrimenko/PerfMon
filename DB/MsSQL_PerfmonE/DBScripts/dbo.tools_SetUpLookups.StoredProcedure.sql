SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[tools_SetUpLookups]
-- 
-- Populates basic lookup tables.
-- 

AS
set nocount on;

-- MetricSetGroups
if exists(select * from MetricSetGroups)
	truncate table MetricSetGroups

insert into MetricSetGroups
values ('Memory', 'Memory'),
	('Network Interface', 'Network'),
	('PhysicalDisk', 'Disk'),
	('Processor', 'Processor'),
	('SQLServer', 'SQLServer')


RETURN 1
GO
