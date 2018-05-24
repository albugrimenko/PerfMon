USE PerfmonE
GO
print '--- Partitions and tables ---'
GO
-- 30 days per partition
CREATE PARTITION FUNCTION [pfMetricValues](smallint) AS RANGE LEFT 
	FOR VALUES (30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330)
GO
CREATE PARTITION SCHEME [psMetricValues] AS PARTITION [pfMetricValues] 
TO ([MetricValues], [MetricValues], [MetricValues], [MetricValues], [MetricValues], [MetricValues], [MetricValues], [MetricValues], [MetricValues], [MetricValues], [MetricValues], [MetricValues], [MetricValues])
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Dates](
	[ID] [smallint] IDENTITY(1,1) NOT NULL,
	[TheDate] [date] NOT NULL,
	[TheYear] [smallint] NOT NULL,
	[MonthInYear] [tinyint] NOT NULL,
	[QuarterInYear] [tinyint] NOT NULL,
	[WeekInYear] [tinyint] NOT NULL,
	[WeekInMonth] [tinyint] NOT NULL,
	[WeekInQuarter] [tinyint] NOT NULL,
	[DayInYear] [smallint] NOT NULL,
	[DayInMonth] [tinyint] NOT NULL,
	[DayInWeek] [tinyint] NOT NULL,
	[NameOfMonth] [varchar](50) NOT NULL,
	[NameOfDay] [varchar](50) NOT NULL,
 CONSTRAINT [PK_Dates] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MetricSets](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](200) NOT NULL,
 CONSTRAINT [PK_MetricSets] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_MetricSets] UNIQUE NONCLUSTERED 
(
	[Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MetricValueStats](
	[ServerID] [int] NOT NULL,
	[MetricSetID] [int] NOT NULL,
	[MetricID] [int] NOT NULL,
	[GrHours] [tinyint] NOT NULL,
	[GrNumber] [tinyint] NOT NULL,
	[DayInWeek] [tinyint] NOT NULL,
	[StartTimeID] [smallint] NOT NULL,
	[EndTimeID] [smallint] NOT NULL,
	[Value_Lo] [float] NOT NULL,
	[Value_Hi] [float] NOT NULL,
	[Value_Avg] [float] NOT NULL,
	[Value_Std] [float] NOT NULL,
 CONSTRAINT [PK_MetricValueStats] PRIMARY KEY CLUSTERED 
(
	[ServerID] ASC,
	[MetricSetID] ASC,
	[MetricID] ASC,
	[GrHours] ASC,
	[DayInWeek] ASC,
	[StartTimeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [Stats]
) ON [Stats]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MetricValues](
	[DayInYear] [smallint] NOT NULL,
	[ServerID] [int] NOT NULL,
	[MetricSetID] [int] NOT NULL,
	[MetricID] [int] NOT NULL,
	[DateID] [smallint] NOT NULL,
	[TimeID] [smallint] NOT NULL,
	[Value] [float] NOT NULL,
 CONSTRAINT [PK_MetricValues] PRIMARY KEY CLUSTERED 
(
	[DayInYear] ASC,
	[ServerID] ASC,
	[MetricSetID] ASC,
	[MetricID] ASC,
	[DateID] ASC,
	[TimeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [psMetricValues]([DayInYear])
) ON [psMetricValues]([DayInYear])
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Metrics](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](200) NOT NULL,
 CONSTRAINT [PK_Metrics] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_Metrics] UNIQUE NONCLUSTERED 
(
	[Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Server_MetricSets](
	[ServerID] [int] NOT NULL,
	[MetricSetID] [int] NOT NULL,
	[MetricID] [int] NOT NULL,
 CONSTRAINT [PK_Server_MetricSets] PRIMARY KEY CLUSTERED 
(
	[ServerID] ASC,
	[MetricSetID] ASC,
	[MetricID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Servers](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](200) NOT NULL,
 CONSTRAINT [PK_Servers] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_Servers] UNIQUE NONCLUSTERED 
(
	[Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Times](
	[ID] [smallint] IDENTITY(1,1) NOT NULL,
	[TheTime] [time](0) NOT NULL,
	[HourInDay] [tinyint] NOT NULL,
	[MinuteInHour] [tinyint] NOT NULL,
	[EveryHour_2] [tinyint] NOT NULL,
	[EveryHour_4] [tinyint] NOT NULL,
	[EveryHour_6] [tinyint] NOT NULL,
	[EveryHour_8] [tinyint] NOT NULL,
	[EveryHour_12] [tinyint] NOT NULL,
 CONSTRAINT [PK_Times] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_TheTime] UNIQUE NONCLUSTERED 
(
	[TheTime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TimesGrouped](
	[GrHours] [tinyint] NOT NULL,
	[TimeID_min] [smallint] NOT NULL,
	[TimeID_max] [smallint] NOT NULL,
	[Time_min] [time](7) NOT NULL,
	[Time_max] [time](7) NOT NULL,
	[GrNumber] [tinyint] NOT NULL,
 CONSTRAINT [PK_TimesGrouped] PRIMARY KEY CLUSTERED 
(
	[GrHours] ASC,
	[TimeID_min] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
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
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Dates] ON [dbo].[Dates]
(
	[TheDate] ASC
)
INCLUDE ( 	[DayInYear],
	[DayInWeek]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
CREATE NONCLUSTERED INDEX [IX_stage_PerfMon_CounterName] ON [stage].[Perfmon]
(
	[CounterInstance] ASC
)
INCLUDE ( 	
	[ServerName],
	[DateTimeStamp],
	[CounterValue]
)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) 
ON [stage]
GO
SET ANSI_PADDING ON
GO
CREATE NONCLUSTERED INDEX [IX_stage_PerfMon_ServerName] ON [stage].[Perfmon]
(
	[ServerName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [stage]
GO
ALTER TABLE [dbo].[MetricValueStats]  WITH CHECK ADD  CONSTRAINT [FKMetricValueStats_MetricSets] FOREIGN KEY([MetricSetID])
REFERENCES [dbo].[MetricSets] ([ID])
GO
ALTER TABLE [dbo].[MetricValueStats] CHECK CONSTRAINT [FKMetricValueStats_MetricSets]
GO
ALTER TABLE [dbo].[MetricValueStats]  WITH CHECK ADD  CONSTRAINT [FK_MetricValueStats_MetricSets] FOREIGN KEY([MetricSetID])
REFERENCES [dbo].[MetricSets] ([ID])
GO
ALTER TABLE [dbo].[MetricValueStats] CHECK CONSTRAINT [FK_MetricValueStats_MetricSets]
GO
ALTER TABLE [dbo].[MetricValueStats]  WITH CHECK ADD  CONSTRAINT [FK_MetricValueStats_Metrics] FOREIGN KEY([MetricID])
REFERENCES [dbo].[Metrics] ([ID])
GO
ALTER TABLE [dbo].[MetricValueStats] CHECK CONSTRAINT [FK_MetricValueStats_Metrics]
GO
ALTER TABLE [dbo].[MetricValueStats]  WITH CHECK ADD  CONSTRAINT [FK_MetricValueStats_Servers] FOREIGN KEY([ServerID])
REFERENCES [dbo].[Servers] ([ID])
GO
ALTER TABLE [dbo].[MetricValueStats] CHECK CONSTRAINT [FK_MetricValueStats_Servers]
GO
ALTER TABLE [dbo].[MetricValueStats]  WITH CHECK ADD  CONSTRAINT [FK_MetricValueStats_Times] FOREIGN KEY([StartTimeID])
REFERENCES [dbo].[Times] ([ID])
GO
ALTER TABLE [dbo].[MetricValueStats] CHECK CONSTRAINT [FK_MetricValueStats_Times]
GO
ALTER TABLE [dbo].[MetricValueStats]  WITH CHECK ADD  CONSTRAINT [FK_MetricValueStats_TimesEnd] FOREIGN KEY([EndTimeID])
REFERENCES [dbo].[Times] ([ID])
GO
ALTER TABLE [dbo].[MetricValueStats] CHECK CONSTRAINT [FK_MetricValueStats_TimesEnd]
GO
ALTER TABLE [dbo].[MetricValues]  WITH CHECK ADD  CONSTRAINT [FK_MetricValues_Dates] FOREIGN KEY([DateID])
REFERENCES [dbo].[Dates] ([ID])
GO
ALTER TABLE [dbo].[MetricValues] CHECK CONSTRAINT [FK_MetricValues_Dates]
GO
ALTER TABLE [dbo].[MetricValues]  WITH CHECK ADD  CONSTRAINT [FK_MetricValues_MetricSets] FOREIGN KEY([MetricSetID])
REFERENCES [dbo].[MetricSets] ([ID])
GO
ALTER TABLE [dbo].[MetricValues] CHECK CONSTRAINT [FK_MetricValues_MetricSets]
GO
ALTER TABLE [dbo].[MetricValues]  WITH CHECK ADD  CONSTRAINT [FK_MetricValues_Metrics] FOREIGN KEY([MetricID])
REFERENCES [dbo].[Metrics] ([ID])
GO
ALTER TABLE [dbo].[MetricValues] CHECK CONSTRAINT [FK_MetricValues_Metrics]
GO
ALTER TABLE [dbo].[MetricValues]  WITH CHECK ADD  CONSTRAINT [FK_MetricValues_Servers] FOREIGN KEY([ServerID])
REFERENCES [dbo].[Servers] ([ID])
GO
ALTER TABLE [dbo].[MetricValues] CHECK CONSTRAINT [FK_MetricValues_Servers]
GO
ALTER TABLE [dbo].[MetricValues]  WITH CHECK ADD  CONSTRAINT [FK_MetricValues_Times] FOREIGN KEY([TimeID])
REFERENCES [dbo].[Times] ([ID])
GO
ALTER TABLE [dbo].[MetricValues] CHECK CONSTRAINT [FK_MetricValues_Times]
GO
ALTER TABLE [dbo].[Server_MetricSets]  WITH CHECK ADD  CONSTRAINT [FK_Server_MetricSets_MetricSets] FOREIGN KEY([MetricSetID])
REFERENCES [dbo].[MetricSets] ([ID])
GO
ALTER TABLE [dbo].[Server_MetricSets] CHECK CONSTRAINT [FK_Server_MetricSets_MetricSets]
GO
ALTER TABLE [dbo].[Server_MetricSets]  WITH CHECK ADD  CONSTRAINT [FK_Server_MetricSets_Metrics] FOREIGN KEY([MetricID])
REFERENCES [dbo].[Metrics] ([ID])
GO
ALTER TABLE [dbo].[Server_MetricSets] CHECK CONSTRAINT [FK_Server_MetricSets_Metrics]
GO
ALTER TABLE [dbo].[Server_MetricSets]  WITH CHECK ADD  CONSTRAINT [FK_Server_MetricSets_Servers] FOREIGN KEY([ServerID])
REFERENCES [dbo].[Servers] ([ID])
GO
ALTER TABLE [dbo].[Server_MetricSets] CHECK CONSTRAINT [FK_Server_MetricSets_Servers]
GO
ALTER TABLE [dbo].[TimesGrouped]  WITH CHECK ADD  CONSTRAINT [FK_TimesGrouped_Max_Times] FOREIGN KEY([TimeID_max])
REFERENCES [dbo].[Times] ([ID])
GO
ALTER TABLE [dbo].[TimesGrouped] CHECK CONSTRAINT [FK_TimesGrouped_Max_Times]
GO
ALTER TABLE [dbo].[TimesGrouped]  WITH CHECK ADD  CONSTRAINT [FK_TimesGrouped_Min_Times] FOREIGN KEY([TimeID_min])
REFERENCES [dbo].[Times] ([ID])
GO
ALTER TABLE [dbo].[TimesGrouped] CHECK CONSTRAINT [FK_TimesGrouped_Min_Times]
GO
ALTER TABLE [dbo].[Dates]  WITH CHECK ADD  CONSTRAINT [CK_Dates_DayInMonth] CHECK  (([DayInMonth]>=(1) AND [DayInMonth]<=(31)))
GO
ALTER TABLE [dbo].[Dates] CHECK CONSTRAINT [CK_Dates_DayInMonth]
GO
ALTER TABLE [dbo].[Dates]  WITH CHECK ADD  CONSTRAINT [CK_Dates_DayInWeek] CHECK  (([DayInWeek]>=(1) AND [DayInWeek]<=(7)))
GO
ALTER TABLE [dbo].[Dates] CHECK CONSTRAINT [CK_Dates_DayInWeek]
GO
ALTER TABLE [dbo].[Dates]  WITH CHECK ADD  CONSTRAINT [CK_Dates_DayInYear] CHECK  (([DayInYear]>=(1) AND [DayInYear]<=(366)))
GO
ALTER TABLE [dbo].[Dates] CHECK CONSTRAINT [CK_Dates_DayInYear]
GO
ALTER TABLE [dbo].[Dates]  WITH CHECK ADD  CONSTRAINT [CK_Dates_NameOfDay] CHECK  (([NameOfDay]='Saturday' OR [NameOfDay]='Friday' OR [NameOfDay]='Thursday' OR [NameOfDay]='Wednesday' OR [NameOfDay]='Tuesday' OR [NameOfDay]='Monday' OR [NameOfDay]='Sunday'))
GO
ALTER TABLE [dbo].[Dates] CHECK CONSTRAINT [CK_Dates_NameOfDay]
GO
ALTER TABLE [dbo].[Dates]  WITH CHECK ADD  CONSTRAINT [CK_Dates_NameOfMonth] CHECK  (([NameOfMonth]='December' OR [NameOfMonth]='November' OR [NameOfMonth]='October' OR [NameOfMonth]='September' OR [NameOfMonth]='August' OR [NameOfMonth]='July' OR [NameOfMonth]='June' OR [NameOfMonth]='May' OR [NameOfMonth]='April' OR [NameOfMonth]='March' OR [NameOfMonth]='February' OR [NameOfMonth]='January'))
GO
ALTER TABLE [dbo].[Dates] CHECK CONSTRAINT [CK_Dates_NameOfMonth]
GO
ALTER TABLE [dbo].[MetricValueStats]  WITH CHECK ADD  CONSTRAINT [CK_MetricValueStats_DayInWeek] CHECK  (([DayInWeek]>=(1) AND [DayInWeek]<=(7)))
GO
ALTER TABLE [dbo].[MetricValueStats] CHECK CONSTRAINT [CK_MetricValueStats_DayInWeek]
GO
ALTER TABLE [dbo].[MetricValueStats]  WITH CHECK ADD  CONSTRAINT [CK_MetricValueStats_GrHours] CHECK  (([GrHours]=(12) OR [GrHours]=(8) OR [GrHours]=(6) OR [GrHours]=(4) OR [GrHours]=(2) OR [GrHours]=(1) OR [GrHours]=(0)))
GO
ALTER TABLE [dbo].[MetricValueStats] CHECK CONSTRAINT [CK_MetricValueStats_GrHours]
GO
ALTER TABLE [dbo].[MetricValueStats]  WITH CHECK ADD  CONSTRAINT [CK_MetricValueStats_GrNumber] CHECK  (([GrNumber]>=(0) AND [GrNumber]<=(23)))
GO
ALTER TABLE [dbo].[MetricValueStats] CHECK CONSTRAINT [CK_MetricValueStats_GrNumber]
GO
ALTER TABLE [dbo].[Times]  WITH CHECK ADD  CONSTRAINT [CK_Times_TheTime] CHECK  (((0)=datepart(second,[TheTime])%(5)))
GO
ALTER TABLE [dbo].[Times] CHECK CONSTRAINT [CK_Times_TheTime]
GO
print '--- Partitions and tables: done. ---'
GO
