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
