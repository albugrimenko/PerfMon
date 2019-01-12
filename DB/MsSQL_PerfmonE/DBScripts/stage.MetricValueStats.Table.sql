USE [PerfmonE]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [stage].[MetricValueStats](
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [stage]
) ON [stage]

GO
ALTER TABLE [stage].[MetricValueStats]  WITH CHECK ADD  CONSTRAINT [stFK_MetricValueStats_MetricSets] FOREIGN KEY([MetricSetID])
REFERENCES [dbo].[MetricSets] ([ID])
GO

ALTER TABLE [stage].[MetricValueStats] CHECK CONSTRAINT [stFK_MetricValueStats_MetricSets]
GO

ALTER TABLE [stage].[MetricValueStats]  WITH CHECK ADD  CONSTRAINT [stFK_MetricValueStats_Metrics] FOREIGN KEY([MetricID])
REFERENCES [dbo].[Metrics] ([ID])
GO

ALTER TABLE [stage].[MetricValueStats] CHECK CONSTRAINT [stFK_MetricValueStats_Metrics]
GO

ALTER TABLE [stage].[MetricValueStats]  WITH CHECK ADD  CONSTRAINT [stFK_MetricValueStats_Servers] FOREIGN KEY([ServerID])
REFERENCES [dbo].[Servers] ([ID])
GO

ALTER TABLE [stage].[MetricValueStats] CHECK CONSTRAINT [stFK_MetricValueStats_Servers]
GO

ALTER TABLE [stage].[MetricValueStats]  WITH CHECK ADD  CONSTRAINT [stFK_MetricValueStats_Times] FOREIGN KEY([StartTimeID])
REFERENCES [dbo].[Times] ([ID])
GO

ALTER TABLE [stage].[MetricValueStats] CHECK CONSTRAINT [stFK_MetricValueStats_Times]
GO

ALTER TABLE [stage].[MetricValueStats]  WITH CHECK ADD  CONSTRAINT [stFK_MetricValueStats_TimesEnd] FOREIGN KEY([EndTimeID])
REFERENCES [dbo].[Times] ([ID])
GO

ALTER TABLE [stage].[MetricValueStats] CHECK CONSTRAINT [stFK_MetricValueStats_TimesEnd]
GO

ALTER TABLE [stage].[MetricValueStats]  WITH CHECK ADD  CONSTRAINT [stCK_MetricValueStats_DayInWeek] CHECK  (([DayInWeek]>=(1) AND [DayInWeek]<=(7)))
GO

ALTER TABLE [stage].[MetricValueStats] CHECK CONSTRAINT [stCK_MetricValueStats_DayInWeek]
GO

ALTER TABLE [stage].[MetricValueStats]  WITH CHECK ADD  CONSTRAINT [stCK_MetricValueStats_GrHours] CHECK  (([GrHours]=(12) OR [GrHours]=(8) OR [GrHours]=(6) OR [GrHours]=(4) OR [GrHours]=(2) OR [GrHours]=(1) OR [GrHours]=(0)))
GO

ALTER TABLE [stage].[MetricValueStats] CHECK CONSTRAINT [stCK_MetricValueStats_GrHours]
GO

ALTER TABLE [stage].[MetricValueStats]  WITH CHECK ADD  CONSTRAINT [stCK_MetricValueStats_GrNumber] CHECK  (([GrNumber]>=(0) AND [GrNumber]<=(23)))
GO

ALTER TABLE [stage].[MetricValueStats] CHECK CONSTRAINT [stCK_MetricValueStats_GrNumber]
GO


