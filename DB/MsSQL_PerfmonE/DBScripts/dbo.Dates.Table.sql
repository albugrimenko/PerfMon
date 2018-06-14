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
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Dates] ON [dbo].[Dates]
(
	[TheDate] ASC
)
INCLUDE ( 	[DayInYear],
	[DayInWeek]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
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
 