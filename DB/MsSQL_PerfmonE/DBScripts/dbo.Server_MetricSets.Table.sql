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
