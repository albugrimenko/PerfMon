SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TimesGrouped](
	[GrHours] [tinyint] NOT NULL,
	[TimeID_min] [smallint] NOT NULL,
	[TimeID_max] [smallint] NOT NULL,
	[Time_min] [time](0) NOT NULL,
	[Time_max] [time](0) NOT NULL,
	[GrNumber] [tinyint] NOT NULL,
 CONSTRAINT [PK_TimesGrouped] PRIMARY KEY CLUSTERED 
(
	[GrHours] ASC,
	[TimeID_min] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
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
