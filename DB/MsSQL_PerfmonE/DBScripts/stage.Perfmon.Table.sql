SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [stage].[Perfmon](
	[ServerName] [varchar](50) NULL,
	[DateTimeStamp] [datetime] NULL,
	[CounterInstance] [nvarchar](200) NULL,
	[CounterValue] [float] NULL
) ON [stage]
GO
GRANT ALTER ON [stage].[Perfmon] TO [importer] AS [dbo]
GO
GRANT DELETE ON [stage].[Perfmon] TO [importer] AS [dbo]
GO
GRANT INSERT ON [stage].[Perfmon] TO [importer] AS [dbo]
GO
GRANT SELECT ON [stage].[Perfmon] TO [importer] AS [dbo]
GO
GRANT UPDATE ON [stage].[Perfmon] TO [importer] AS [dbo]
GO
SET ANSI_PADDING ON
GO
CREATE NONCLUSTERED INDEX [IX_stage_PerfMon_CounterName] ON [stage].[Perfmon]
(
	[CounterInstance] ASC
)
INCLUDE ( 	[ServerName],
	[DateTimeStamp],
	[CounterValue]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [stage]
GO
SET ANSI_PADDING ON
GO
CREATE NONCLUSTERED INDEX [IX_stage_PerfMon_ServerName] ON [stage].[Perfmon]
(
	[ServerName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [stage]
GO
