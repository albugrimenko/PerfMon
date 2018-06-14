SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetMetricValuesDet]
	@StartDate date, @EndDate date,

	@ServerID int = null, @ServerName nvarchar(200) = null, 
	@MetricSetID int = null, @MetricSetName nvarchar(200) = null,
	@MetricID int = null, @MetricName nvarchar(200) = null,
	@GrHours tinyint = null

/* Gets all recorded values for a particular server/metric for specified date range
	with a corresponding statistics.

exec GetMetricValuesDet @StartDate = '5/8/2018', @EndDate = '5/9/2018',
	@ServerID=1, @MetricSetName='Processor(_Total)', 
	@MetricName='% Processor Time',
	@GrHours=2
*/
--with recompile

AS
set nocount on;
set transaction isolation level snapshot;

---- params 
if @EndDate is NULL
	set @EndDate = getdate()
if @StartDate is NULL
	set @StartDate = dateadd(week, -1, @EndDate)

if @GrHours is null begin
	if dateadd(day, 14, @StartDate) > @EndDate	-- 2 weeks and more - every 12 hrs ~ 14 * (24/12) = 28 points
		set @GrHours = 12
	else if dateadd(day, 7, @StartDate) > @EndDate	-- 1 week - every 6 hrs ~ 7 * (24/6) = 28 points
		set @GrHours = 6
	else if dateadd(day, 5, @StartDate) > @EndDate	-- 5 days - every 4 hrs ~ 5 * (24/4) = 30 points
		set @GrHours = 4
	else if dateadd(day, 3, @StartDate) > @EndDate	-- 3 days - every 2 hrs ~ 3 * (24/12) = 36 points
		set @GrHours = 4
	else
		set @GrHours = 1	-- every 1 hour
end

if @ServerID is null and len(isnull(@ServerName,'')) > 0
	exec @ServerID=GetLookupID @ObjectName='servers', @ObjectValue=@ServerName, @IsAutoAdd=0

if @MetricSetID is null and len(isnull(@MetricSetName,'')) > 0
	exec @MetricSetID=GetLookupID @ObjectName='metricsets', @ObjectValue=@MetricSetName, @IsAutoAdd=0

if @MetricID is null and len(isnull(@MetricName,'')) > 0
	exec @MetricID=GetLookupID @ObjectName='metrics', @ObjectValue=@MetricName, @IsAutoAdd=0

if (@ServerID is NULL) begin
	raiserror('ServerID or ServerName is required.', 16, 1)
	RETURN -1
end
if (@MetricSetID is NULL) begin
	raiserror('MetricSetID or MetricSetName is required.', 16, 1)
	RETURN -1
end
if (@MetricID is NULL) begin
	raiserror('MetricID or MetricName is required.', 16, 1)
	RETURN -1
end

---- get data
-- MetricValuesWithStats (@StartDate date, @EndDate date,@ServerID int = null, 
--		@MetricSetID int = null, @MetricID int = null, @GrHours)
select
	TheDate,
	TimeStart,
	TimeEnd,
	Value_Lo,
	Value_Hi,
	Value_Avg,
	StatValue_Lo,
	StatValue_Hi,
	StatValue_Avg,
	StatValue_Std,
	StatRatio = cast(StatRatio as money),
	StatRatioDescr = dbo.GetStatRatioDescr(StatRatio)
from dbo.MetricValuesWithStats(@StartDate, @EndDate, @ServerID, @MetricSetID, @MetricID, @GrHours) mv
order by TheDate, TimeStart


/*
; with d as (
	select ID, TheDate, DayInYear, DayInWeek
	from Dates
	where TheDate between @StartDate and @EndDate
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
	where m.ServerID = @ServerID
		and m.MetricSetID = @MetricSetID
		and m.MetricID = @MetricID
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
		join (select * from TimesGrouped where GrHours = @GrHours) t on 
			mv.TimeID between t.TimeID_min and t.TimeID_max
	group by mv.ServerID, mv.MetricSetID, mv.MetricID, 
		mv.DateID, mv.DayInWeek, mv.TheDate, 
		t.TimeID_min, t.TimeID_max, t.Time_min, t.Time_max
)
select
	[Date] = res.TheDate,
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
		when stat.Value_Avg is not null and res.Value_Hi <= stat.Value_Lo then -100
		when stat.Value_Avg is not null and res.Value_Lo >= stat.Value_Hi then +100
		when stat.Value_Std is not null and stat.Value_Std != 0 then
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
order by res.DateID, res.TimeIDStart
*/

RETURN 1
GO
GRANT EXECUTE ON [dbo].[GetMetricValuesDet] TO [reporter] AS [dbo]
GO
