SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[MetricValuesWithStats] (
	@StartDate date, @EndDate date,
	@ServerID int = null, 
	@MetricSetID int = null, @MetricID int = null, 
	@GrHours tinyint = 0
)
/*
Valid @GrHours values: 0, 1, 2, 4, 6, 8, 12
	@GrHours = 0 means that data will be grouped by date.
	@GrHours = 2 means that data will be grouped by every 12 hours (24 / 2).
	Default value is 0

select * from dbo.MetricValuesWithStats('5/8/2018', '5/9/2018', null, null, null, 12)
order by ServerID, MetricSetID, MetricID, TheDate, TimeStart
*/
RETURNS TABLE
AS
RETURN
(	
	with d as (
		select ID, TheDate, DayInYear, DayInWeek
		from Dates
		where TheDate between @StartDate and @EndDate
	),
	t as (
		select TimeID_min, TimeID_max, Time_min, Time_max
		from TimesGrouped where GrHours = @GrHours
	),
	mv as (
		select top(2147483647)
			m.ServerID,
			m.MetricSetID,
			m.MetricID,
			m.DateID,
			m.TimeID,
			m.Value,
			TheDate = d.TheDate,
			DayInWeek = d.DayInWeek
		from MetricValues m
			join d on m.DayInYear = d.DayInYear	-- required for proper partitions usage
				and m.DateID = d.ID 
		where (@ServerID is null or m.ServerID = @ServerID)
			and (@MetricSetID is null or m.MetricSetID = @MetricSetID)
			and (@MetricID is null or m.MetricID = @MetricID)
	),
	mv_grouped as (
		select
			mv.ServerID,
			mv.MetricSetID,
			mv.MetricID,
			DateID = mv.DateID,
			DayInWeek = mv.DayInWeek,
			TheDate = mv.TheDate,
			TimeStart = t.Time_min,
			TimeEnd = t.Time_max,
			TimeIDStart = t.TimeID_min,
			TimeIDEnd = t.TimeID_max,
			Value_Lo = min(mv.Value),
			Value_Hi = max(mv.Value),
			Value_Avg = avg(mv.Value)
		from mv
			join t on mv.TimeID between t.TimeID_min and t.TimeID_max
		group by mv.ServerID, mv.MetricSetID, mv.MetricID, 
			mv.DateID, mv.DayInWeek, mv.TheDate, 
			t.TimeID_min, t.TimeID_max, t.Time_min, t.Time_max
	)
	select
		res.ServerID, res.MetricSetID, res.MetricID,
		TheDate = res.TheDate,
		TimeStart = res.TimeStart,
		TimeEnd = res.TimeEnd,
		Value_Lo = res.Value_Lo,
		Value_Hi = res.Value_Hi,
		Value_Avg = res.Value_Avg,
		StatValue_Lo = stat.Value_Lo,
		StatValue_Hi = stat.Value_Hi,
		StatValue_Avg = stat.Value_Avg,
		StatValue_Std = stat.Value_Std,
		StatRatio = case 
			when stat.Value_Avg is null then null
			when stat.Value_Avg is not null and isnull(stat.Value_Std,0) != 0 then
				(res.Value_Avg - stat.Value_Avg) / stat.Value_Std
			else 0	-- STD == 0
		end
	from mv_grouped res
		left join MetricValueStats stat on stat.GrHours = @GrHours
			and stat.DayInWeek = res.DayInWeek
			and stat.ServerID = res.ServerID
			and stat.MetricSetID = res.MetricSetID 
			and stat.MetricID = res.MetricID
			and stat.StartTimeID = res.TimeIDStart
);
GO
GRANT SELECT ON [dbo].[MetricValuesWithStats] TO [reporter] AS [dbo]
GO
