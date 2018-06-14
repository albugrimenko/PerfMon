SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[srv_ComputeStats]
	@StartDate date = null,
	@EndDate date = null

--
-- Computes basic stats of MetricValues.
--
-- When dates are not populated, default date stats range will be used:
--		4 weeks, starting 1 week prior to the current week
--

/*
exec srv_ComputeStats @StartDate='5/1/2018', @EndDate='5/10/2018'
*/

AS
set nocount on;

-- Valid @GrHours values: 0, 1, 2, 4, 6, 8, 12
declare @GrHours tinyint = 0,
		@res int = 0

-- default date stats range is 4 weeks, starting 1 week prior to the current week
--	just to make sure we did not catch any recent days irregularity
if @StartDate is null or @EndDate is null begin
	select @StartDate = dateadd(week,-1-4,getdate()),
		   @EndDate = dateadd(week,-1,getdate())
	-- extra check for data availability to avoid empty stats
	declare @sd date, @ed date
	; with r as (
		select 
			MinDateID = min(v.DateID),
			MaxDateID = max(v.DateID)
		from MetricValues v
	)
	select 
		@sd = dmin.TheDate,
		@ed = dmax.TheDate
	from r
		join Dates dmin on r.MinDateID = dmin.ID
		join Dates dmax on r.MaxDateID = dmax.ID
	if @EndDate < @sd
		select @StartDate = @sd, @EndDate=@ed
end

truncate table MetricValueStats

while @GrHours <= 12 begin
	print '-- Group by # hours: '  + cast(@GrHours as varchar(20))

	-- compute and save stats
	; with d as (
		select ID, TheDate, DayInYear, DayInWeek
		from Dates
		where TheDate between @StartDate and @EndDate
	), mv as (
		select top(2147483647)
			m.ServerID,
			m.MetricSetID,
			m.MetricID,
			DateID = d.ID,
			DayInWeek = d.DayInWeek,
			TimeID = m.TimeID,
			Value = m.Value
		from MetricValues m
			join d on m.DayInYear = d.DayInYear	-- required for proper partitions usage
				and m.DateID = d.ID 
	)
	insert into MetricValueStats (ServerID, MetricSetID, MetricID,
		GrHours, GrNumber, DayInWeek, StartTimeID, EndTimeID, 
		Value_Lo, Value_Hi, Value_Avg, Value_Std)
	select 
		ServerID = mv.ServerID,
		MetricSetID = mv.MetricSetID,
		MetricID = mv.MetricID,
		GrHours = @GrHours,
		GrNumber = t.GrNumber,
		DayInWeek = mv.DayInWeek, 
		StartTimeID = t.TimeID_min,
		EndTimeID = t.TimeID_max,
		Value_Lo = min(mv.Value),
		Value_Hi = max(mv.Value),
		Value_Avg = avg(mv.Value),
		Value_Std = isnull(stdev(mv.Value), 0)
	from mv
		--join #times t on mv.TimeID between t.ID_min and t.ID_max
		join (select * from TimesGrouped where GrHours = @GrHours) t on 
			mv.TimeID between t.TimeID_min and t.TimeID_max
	group by mv.ServerID, mv.MetricSetID, mv.MetricID, t.GrNumber, mv.DayInWeek, t.TimeID_min, t.TimeID_max
	--order by mv.ServerID, mv.MetricSetID, mv.MetricID, t.GrNumber, mv.DayInWeek, t.ID_min, t.ID_max
	set @res = @@rowcount
	print '-+ # rows inserted: '  + cast(@res as varchar(20))

	if @GrHours < 2
		set @GrHours += 1
	else if @GrHours < 8
		set @GrHours += 2
	else
		set @GrHours += 4
end

print '--- DONE ---'

RETURN 1
GO
