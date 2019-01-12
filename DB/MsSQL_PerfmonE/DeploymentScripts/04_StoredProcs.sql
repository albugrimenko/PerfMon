USE PerfmonE
GO
print '--- Functions and stored procs ---'
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[CSV2Table] 
(	
	@ItemsStr nvarchar(max), -- comma separated list of values to be returned
	@sep char(1) = ','		-- separator chaacter
)
RETURNS @Items TABLE (Item nvarchar(200))
AS

/*
select * from dbo.CSV2Table('\Network Interface(Intel(R) Ethernet Connection I217-LM)\Bytes Sent/sec', '\')
select * from dbo.CSV2Table('Bytes Sent/sec', '\')
*/

begin
	declare @ItemsList nvarchar(max),
			@Item nvarchar(200), 
			@Pos int;
	--possible separators char(13),char(9)-tab; char(10)(LF) gets removed
	select @ItemsList = LTRIM(RTRIM(
		replace(
			replace(
				replace(@ItemsStr, char(13), @sep)
				, char(9), @sep)
			, char(10), '')
		)) + @sep

	select @Pos = CHARINDEX(@sep, @ItemsList, 1)
	if REPLACE(@ItemsList, @sep, '') <> '' begin
		while @Pos > 0 begin
			select @Item = LTRIM(RTRIM(LEFT(@ItemsList, @Pos - 1)))
			if @Item <> '' begin
				insert into @Items (Item) 
				values (@Item)
			end
			select @ItemsList = RIGHT(@ItemsList, LEN(@ItemsList) - @Pos)
			select @Pos = CHARINDEX(@sep, @ItemsList, 1)
		end
	end	

	return 
end

GO
GRANT SELECT ON [dbo].[CSV2Table] TO [public] AS [dbo]
GO
CREATE FUNCTION [dbo].[GetStatRatioDescr](@StatRatio float)
--
-- Gets stat ratio description (StatRatio is computed in the MetricValuesWithStats)
--
RETURNS nvarchar(15)
AS
BEGIN
	declare @res nvarchar(15) = case
		when @StatRatio is null then 'Unknown'

		when @StatRatio is not null and @StatRatio < -5 then 'Extremely Low'
		when @StatRatio is not null and @StatRatio >= -5 and @StatRatio < -3 then 'Very Low'
		when @StatRatio is not null and @StatRatio >= -3 and @StatRatio < -2 then 'Low'

		when @StatRatio is not null and @StatRatio > 2 and @StatRatio <= 3 then 'High'
		when @StatRatio is not null and @StatRatio > 3 and @StatRatio <= 5 then 'Very High'
		when @StatRatio is not null and @StatRatio > 5 then 'Extremely High'

		else 'OK'
	end

	RETURN @res
END

GO
GRANT EXECUTE ON [dbo].[GetStatRatioDescr] TO [reporter] AS [dbo]
GO
CREATE FUNCTION [dbo].[GetValueFromCSV] 
(	
	@ItemsStr nvarchar(max), -- comma separated list of values to be returned
	@sep char(1) = ',',		-- separator chaacter
	@ItemNumber int = 1		-- item number to get
)
RETURNS nvarchar(200)
AS

/*
select dbo.GetValueFromCSV('\Network Interface(Intel(R) Ethernet Connection I217-LM)\Bytes Sent/sec', '\', 2)
select dbo.GetValueFromCSV('Bytes Sent/sec', '\', 2)
select dbo.GetValueFromCSV('Bytes Sent/sec', '\', 1)
*/

begin
	declare @ItemsList nvarchar(max),
			@Item nvarchar(200), 
			@Pos int;

	declare @Items table (ID int identity(1,1), Item nvarchar(200))

	--possible separators char(13),char(9)-tab; char(10)(LF) gets removed
	select @ItemsList = LTRIM(RTRIM(
		replace(
			replace(
				replace(@ItemsStr, char(13), @sep)
				, char(9), @sep)
			, char(10), '')
		)) + @sep

	select @Pos = CHARINDEX(@sep, @ItemsList, 1)
	if REPLACE(@ItemsList, @sep, '') <> '' begin
		while @Pos > 0 begin
			select @Item = LTRIM(RTRIM(LEFT(@ItemsList, @Pos - 1)))
			if @Item <> '' begin
				insert into @Items (Item) 
				values (@Item)
			end
			select @ItemsList = RIGHT(@ItemsList, LEN(@ItemsList) - @Pos)
			select @Pos = CHARINDEX(@sep, @ItemsList, 1)
		end
	end	

	select @Item = null
	select @Item = Item from @Items where ID = @ItemNumber

	return @Item
end

GO
GRANT EXECUTE ON [dbo].[GetValueFromCSV] TO [public] AS [dbo]
GO
CREATE FUNCTION [dbo].[TimeGrouped](@GrHours tinyint)
/*
Gets times grouped by a particular number of hours.
Valid @GrHours values: 0, 1, 2, 4, 6, 8, 12
Default value of 2 is used for any not valid @GrHours.

select * from dbo.TimeGrouped(3)
*/
RETURNS @t TABLE 
(
	ID_min smallint, 
	ID_max smallint, 
	Time_min time, 
	Time_max time,
	GrNumber tinyint
	)
AS
BEGIN

	; with ftimes as (
		select ID, TheTime,
			GrNumber = case 
				when @GrHours = 1 then HourInDay
				when @GrHours = 2 then EveryHour_2
				when @GrHours = 4 then EveryHour_4
				when @GrHours = 6 then EveryHour_6
				when @GrHours = 8 then EveryHour_8
				when @GrHours = 12 then EveryHour_12
				when @GrHours in (0, 24) then 0
				else EveryHour_2
			end
		from Times
	),
	t as (
		select
			ID_min = min(ID),
			ID_max = max(ID),
			Time_min = min(TheTime),
			Time_max = dateadd(second,5,max(TheTime)),
			GrNumber
		from ftimes
		group by GrNumber
	)
	insert into @t (ID_min, ID_max, Time_min, Time_max, GrNumber)
	select ID_min, ID_max, Time_min, Time_max, GrNumber 
	from t
	order by ID_min;
	
	RETURN
END

GO
GRANT SELECT ON [dbo].[TimeGrouped] TO [public] AS [dbo]
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

select * from dbo.MetricValuesWithStats('12/8/2018', '12/9/2018', null, null, null, 12)
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
		TimeEnd = case when res.TimeEnd = '00:00:00' then '23:59:59' else res.TimeEnd end,
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
CREATE PROCEDURE [dbo].[GetLookupID]
	@ObjectName as varchar(30), @ObjectValue as nvarchar(200),
	@IsAutoAdd bit = 0

/*
declare @r int
exec @r=[GetLookupID] @ObjectName='metricsets', @ObjectValue='memory'
select @r
*/

AS
set nocount on;
--set transaction isolation level snapshot;

declare @Result int
set @ObjectValue = ltrim(rtrim(@ObjectValue))

if (lower(@ObjectName) = 'servers') begin
	select @Result = ID from Servers where lower(Name) = lower(@ObjectValue)
	if isnull(@Result, 0) < 1 and @IsAutoAdd = 1 begin
		insert into Servers (Name) 
		values (@ObjectValue)
		select @Result = scope_identity()
	end
end

if (lower(@ObjectName) = 'metrics') begin
	select @Result = ID from Metrics where lower(Name) = lower(@ObjectValue)
	if isnull(@Result, 0) < 1 and @IsAutoAdd = 1 begin
		insert into Metrics (Name) 
		values (@ObjectValue)
		select @Result = scope_identity()
	end
end

if (lower(@ObjectName) = 'metricsets') begin
	select @Result = ID from MetricSets where lower(Name) = lower(@ObjectValue)
	if isnull(@Result, 0) < 1 and @IsAutoAdd = 1 begin
		insert into MetricSets (Name) 
		values (@ObjectValue)
		select @Result = scope_identity()
	end
end

if isnull(@Result, 0) < 1 and @IsAutoAdd = 1
	raiserror('Cannot find or create an entry in the [%s] with value [%s].', 16, 1, @ObjectName, @ObjectValue)

RETURN isnull(@Result, 0)

GO
GRANT EXECUTE ON [dbo].[GetLookupID] TO [perfmon] AS [dbo]
GO
CREATE PROCEDURE [dbo].[GetMetricList]
	@ServerID int = null, @ServerName nvarchar(200) = null,
	@MetricSetID int = null, @MetricSetName nvarchar(200) = null

--
-- Gets unique Metric list.
--	If @ServerID/Name is specified, this list is unique for a specified server.
--  If @MetricSetID/Name is specified, this list is (also) unique for a specified metric set.
--

/*
exec GetMetricList @ServerID=1, @MetricSetName='Memory'
*/

AS
set nocount on;
--set transaction isolation level snapshot;

if @ServerID is null and len(isnull(@ServerName,'')) > 0
	exec @ServerID=GetLookupID @ObjectName='servers', @ObjectValue=@ServerName, @IsAutoAdd=0

if @MetricSetID is null and len(isnull(@MetricSetName,'')) > 0
	exec @MetricSetID=GetLookupID @ObjectName='metricsets', @ObjectValue=@MetricSetName, @IsAutoAdd=0

if @ServerID is not null begin
	select 
		ms.ID,
		ms.Name
	from Metrics ms (nolock)
		join (
			select MetricID 
			from Server_MetricSets (nolock)
			where ServerID = @ServerID 
				and (@MetricSetID is null or MetricSetID = @MetricSetID)
			group by MetricID
		) sms on sms.MetricID = ms.ID
	order by Name
end else if @MetricSetID is not null begin
	select 
		ms.ID,
		ms.Name
	from Metrics ms (nolock)
		join (
			select distinct MetricID 
			from Server_MetricSets (nolock)
			where MetricSetID = @MetricSetID
			group by MetricID
		) sms on sms.MetricID = ms.ID
	order by Name
end else begin
	select 
		ID,
		Name
	from Metrics (nolock)
	order by Name
end

RETURN 1

GO
GRANT EXECUTE ON [dbo].[GetMetricList] TO [reporter] AS [dbo]
GO
CREATE PROCEDURE [dbo].[GetMetricSetList]
	@ServerID int = null, @ServerName nvarchar(200) = null

--
-- Gets unique MetricSet list.
--	If @ServerID/Name is specified, this list is unique for a specified server.
--

/* 
exec GetMetricSetList @ServerID=1
*/

AS
set nocount on;
--set transaction isolation level snapshot;

if @ServerID is null and len(isnull(@ServerName,'')) > 0
	exec @ServerID=GetLookupID @ObjectName='servers', @ObjectValue=@ServerName, @IsAutoAdd=0

if @ServerID is not null begin
	select 
		ms.ID,
		ms.Name
	from MetricSets ms (nolock)
		join (
			select MetricSetID 
			from Server_MetricSets (nolock)
			where ServerID = @ServerID 
			group by MetricSetID
		) sms on sms.MetricSetID = ms.ID
	order by Name
end else begin
	select 
		ID,
		Name
	from MetricSets (nolock)
	order by Name
end

RETURN 1

GO
GRANT EXECUTE ON [dbo].[GetMetricSetList] TO [reporter] AS [dbo]
GO
CREATE PROCEDURE [dbo].[GetMetricValueStats]
	@ServerID int = null, @ServerName nvarchar(200) = null, 
	@MetricSetID int = null, @MetricSetName nvarchar(200) = null,
	@MetricID int = null, @MetricName nvarchar(200) = null,
	@GrHours tinyint = 2

--
-- @GrHours - Grouping for stats values. Valid time groups (hours): 0, 1, 2, 4, 6, 8, 12
--	0 is equivalent of 24 and means there will be no aggregation by time.
--

/* Gets basic stats for a particular server/metric for specified date range

exec GetMetricValueStats @ServerID=1, @MetricSetName='Processor(_Total)', 
	@MetricName='% Processor Time',
	@GrHours=2
*/
--with recompile

AS
set nocount on;
--set transaction isolation level snapshot;

---- params 
if @GrHours is null or @GrHours < 0 or @GrHours > 24
	set @GrHours = 2

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
select --top(2147483647)
	s.DayInWeek,
	s.GrNumber,
	StartTime = tstart.TheTime,
	EndTime = dateadd(second,5,tend.TheTime), -- it just look nice
	s.Value_Hi,
	s.Value_Lo,
	s.Value_Avg,
	s.Value_Std
from MetricValueStats s
	join Times tstart on s.StartTimeID = tstart.ID
	join Times tend on s.EndTimeID = tend.ID
where s.ServerID = @ServerID
	and s.MetricSetID = @MetricSetID
	and s.MetricID = @MetricID
	and GrHours = @GrHours
order by s.DayInWeek, s.GrNumber

RETURN 1

GO
GRANT EXECUTE ON [dbo].[GetMetricValueStats] TO [reporter] AS [dbo]
GO
CREATE PROCEDURE [dbo].[GetMetricValues]
	@StartDate date, @EndDate date,

	@ServerID int = null, @ServerName nvarchar(200) = null, 
	@MetricSetID int = null, @MetricSetName nvarchar(200) = null,
	@MetricID int = null, @MetricName nvarchar(200) = null

/* Gets all recorded values for a particular server/metric for specified date range

exec GetMetricValues @StartDate = '12/16/2018', @EndDate = '12/16/2018',
	@ServerID=4, @MetricSetName='Processor(_Total)', 
	@MetricName='% Processor Time'
*/
--with recompile

AS
set nocount on;
--set transaction isolation level snapshot;

---- params 
if @EndDate is NULL
	set @EndDate = getdate()
if @StartDate is NULL
	set @StartDate = dateadd(week, -1, @EndDate)

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
; with fdates as (
	select ID, TheDate, DayInYear
	from Dates (nolock)
	where TheDate between @StartDate and @EndDate
)
select --top(2147483647)
	[Date] = d.TheDate,
	[Time] = t.TheTime,
	Value = mv.Value
from MetricValues mv (nolock)
	join fdates d on mv.DateID = d.ID 
		and mv.DayInYear = d.DayInYear	-- required for proper partitions usage
	join Times t (nolock) on mv.TimeID = t.ID
where --m.DayInYear in (select DayInYear from fdates group by DayInYear)
	mv.ServerID = @ServerID
	and mv.MetricSetID = @MetricSetID
	and mv.MetricID = @MetricID
order by d.ID, t.ID

RETURN 1

GO
GRANT EXECUTE ON [dbo].[GetMetricValues] TO [reporter] AS [dbo]
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
--set transaction isolation level snapshot;

---- params 
if @EndDate is NULL
	set @EndDate = getdate()
if @StartDate is NULL
	set @StartDate = dateadd(week, -1, @EndDate)

if @GrHours is null begin
	if dateadd(day, 14, @StartDate) <= @EndDate	-- 2 weeks and more - every 12 hrs ~ 14 * (24/12) = 28 points
		set @GrHours = 12
	else if dateadd(day, 7, @StartDate) <= @EndDate	-- 1 week - every 6 hrs ~ 7 * (24/6) = 28 points
		set @GrHours = 6
	else if dateadd(day, 5, @StartDate) <= @EndDate	-- 5 days - every 4 hrs ~ 5 * (24/4) = 30 points
		set @GrHours = 4
	else if dateadd(day, 3, @StartDate) <= @EndDate	-- 3 days - every 2 hrs ~ 3 * (24/12) = 36 points
		set @GrHours = 2
	else
		set @GrHours = 1	-- every 1 hour
end

--TEST
--print @GrHours

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
CREATE PROCEDURE [dbo].[GetMetricValuesWithStats]
	@StartDate date, @EndDate date,

	@ServerID int = null, @ServerName nvarchar(200) = null, 
	@MetricSetID int = null, @MetricSetName nvarchar(200) = null,
	@MetricID int = null, @MetricName nvarchar(200) = null

/* Gets all recorded values for a particular server/metric for specified date range

exec GetMetricValuesWithStats @StartDate = '12/16/2018', @EndDate = '12/16/2018',
	@ServerID=4, @MetricSetName='Processor(_Total)', 
	@MetricName='% Processor Time'
*/
--with recompile

AS
set nocount on;
--set transaction isolation level snapshot;

---- params 
if @EndDate is NULL
	set @EndDate = getdate()
if @StartDate is NULL
	set @StartDate = dateadd(week, -1, @EndDate)

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
; with fdates as (
	select ID, TheDate, DayInYear, DayInWeek
	from Dates (nolock)
	where TheDate between @StartDate and @EndDate
)
select --top(2147483647)
	[Date] = d.TheDate,
	[Time] = t.TheTime,
	Value = mv.Value,
	StatValue_Lo = s.Value_Lo,
	StatValue_Hi = s.Value_Hi,
	StatValue_Avg = s.Value_Avg,
	StatValue_Std = s.Value_Std
from MetricValues mv (nolock)
	join fdates d on mv.DateID = d.ID 
		and mv.DayInYear = d.DayInYear	-- required for proper partitions usage
	join Times t (nolock) on mv.TimeID = t.ID

	left join MetricValueStats s (nolock) on mv.ServerID = s.ServerID and mv.MetricSetID = s.MetricSetID and mv.MetricID = s.MetricID
		and s.GrHours = 1
		and d.DayInWeek = s.DayInWeek and mv.TimeID between s.StartTimeID and s.EndTimeID
where --m.DayInYear in (select DayInYear from fdates group by DayInYear)
	mv.ServerID = @ServerID
	and mv.MetricSetID = @MetricSetID
	and mv.MetricID = @MetricID
order by d.ID, t.ID

RETURN 1

GO
GRANT EXECUTE ON [dbo].[GetMetricValuesWithStats] TO [reporter] AS [dbo]
GO
CREATE PROCEDURE [dbo].[GetPotentialIssues]
	@ServerID int = null, @ServerName nvarchar(200) = null, 
	@MetricSetID int = null, @MetricSetName nvarchar(200) = null,
	@MetricID int = null, @MetricName nvarchar(200) = null,
	@StartDate date = null, @EndDate date = null,
	@SigmaNum money = 3

/* Gets recorded values for a particular server/metric for specified date range
	where average value is differ from recorded average for more than @SigmaNum standard deviations.
	If date range is not specified, most recent (last 1 day) will be shown.

exec GetPotentialIssues @ServerID=3, @SigmaNum=3
*/
--with recompile

AS
set nocount on;
--set transaction isolation level snapshot;

---- params 
declare @GrHours tinyint = 1

if @StartDate is null or @EndDate is null
	select @StartDate = dateadd(day, -1, getdate()), @EndDate = getdate()

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

if @SigmaNum < 0
	set @SigmaNum = abs(@SigmaNum)

---- get data
-- MetricValuesWithStats (@StartDate date, @EndDate date,@ServerID int = null, 
--		@MetricSetID int = null, @MetricID int = null, @GrHours)
; with r as (
	select
		ServerID, MetricSetID, MetricID,
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
	where (StatRatio < -@SigmaNum or StatRatio > @SigmaNum)
)
select 
	TheDate,
	TimeStart,
	TimeEnd,
	ServerID = r.ServerID,
	MetricSetID = r.MetricSetID, 
	MetricID = r.MetricID,
	[Server] = s.Name,
	MetricSet = ms.Name,
	Metric = m.Name,
	Value_Lo,
	Value_Hi,
	Value_Avg,
	StatValue_Lo,
	StatValue_Hi,
	StatValue_Avg,
	StatValue_Std,
	StatRatio,
	StatRatioDescr
from r
	join [Servers] s (nolock) on r.ServerID = s.ID
	join MetricSets ms (nolock) on r.MetricSetID = ms.ID
	join Metrics m (nolock) on r.MetricID = m.ID
order by TheDate, s.Name, ms.Name, m.Name, TimeStart

RETURN 1

GO
GRANT EXECUTE ON [dbo].[GetPotentialIssues] TO [reporter] AS [dbo]
GO
CREATE PROCEDURE [dbo].[GetPotentialIssues4All]
	@SigmaNum money = 3,
	@IsCompressedMode bit = 1

/* Gets most recent (last 2 days) recorded values for specified date range
	where average value is differ from recorded average for more than @SigmaNum standard deviations.
	Shows as aggregated values per server/time frame.

   When @IsCompressedMode = 1, it groups by a short metric set name (defined in the MetricSetGroups)

exec GetPotentialIssues4All @SigmaNum=2, @IsCompressedMode=0
*/
--with recompile

AS
set nocount on;
--set transaction isolation level snapshot;

---- params 
declare @GrHours tinyint = 1,
		@StartDate date = dateadd(day, -2, getdate()),
		@EndDate date = getdate()

if @SigmaNum < 0
	set @SigmaNum = abs(@SigmaNum)

---- get data
-- MetricValuesWithStats (@StartDate date, @EndDate date, @ServerID int = null, 
--		@MetricSetID int = null, @MetricID int = null, @GrHours)
if @IsCompressedMode = 0 begin
	; with r as (
		select
			ServerID, MetricSetID, MetricID,
			TheDate,
			StatRatioDescr = dbo.GetStatRatioDescr(StatRatio),
			TimeIntervals = count(*),
			TimeStart = min(TimeStart),
			TimeEnd = max(TimeEnd)
		from dbo.MetricValuesWithStats(@StartDate, @EndDate, null, null, null, @GrHours) mv
		where (StatRatio < -@SigmaNum or StatRatio > @SigmaNum)
		group by ServerID, MetricSetID, MetricID, TheDate, dbo.GetStatRatioDescr(StatRatio)
	)
	select 
		ServerID = r.ServerID,
		[Server] = s.Name,
		MetricName = ms.Name + ' - ' + m.Name,
		TheDate,
		StatRatioDescr,
		TimeIntervals,
		TimeStart,
		TimeEnd
	from r
		join [Servers] s (nolock) on r.ServerID = s.ID
		join MetricSets ms (nolock) on r.MetricSetID = ms.ID
		join Metrics m (nolock) on r.MetricID = m.ID
end else begin
	-- compressed mode
	; with r as (
		select
			ServerID, MetricSetID, 
			TheDate,
			StatRatioDescr = '',	--dbo.GetStatRatioDescr(StatRatio),
			TimeIntervals = count(*),
			TimeStart = min(TimeStart),
			TimeEnd = max(TimeEnd)
		from dbo.MetricValuesWithStats(@StartDate, @EndDate, null, null, null, @GrHours) mv
		where (StatRatio < -@SigmaNum or StatRatio > @SigmaNum)
		group by ServerID, MetricSetID, TheDate	--, dbo.GetStatRatioDescr(StatRatio)
	)
	select 
		ServerID = r.ServerID,
		[Server] = s.Name,
		MetricName = isnull(msg.GroupName, ms.Name),
		TheDate,
		StatRatioDescr = min(StatRatioDescr),
		TimeIntervals = max(TimeIntervals),	-- cannot use sum because it is grouped diffferently
		TimeStart = min(TimeStart),
		TimeEnd = max(TimeEnd)
	from r
		join [Servers] s (nolock) on r.ServerID = s.ID
		join MetricSets ms (nolock) on r.MetricSetID = ms.ID
		left join MetricSetGroups msg (nolock) on ms.Name like msg.MetricSetName_StartWith + '%'
	group by ServerID, s.Name, isnull(msg.GroupName, ms.Name), TheDate
	order by TheDate desc, ServerID, s.Name, isnull(msg.GroupName, ms.Name)
end

RETURN 1

GO
GRANT EXECUTE ON [dbo].[GetPotentialIssues4All] TO [reporter] AS [dbo]
GO
CREATE PROCEDURE [dbo].[GetServerList]

AS
set nocount on;
--set transaction isolation level snapshot;

select 
	ID,
	Name
from Servers (nolock)
order by Name

RETURN 1

GO
GRANT EXECUTE ON [dbo].[GetServerList] TO [reporter] AS [dbo]
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
set xact_abort on;
set transaction isolation level snapshot;

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

truncate table stage.MetricValueStats

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
	insert into stage.MetricValueStats (ServerID, MetricSetID, MetricID,
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

-- copy data from stage
if exists(select 1 from stage.MetricValueStats) begin
	begin tran
		truncate table MetricValueStats
		insert into MetricValueStats (ServerID, MetricSetID, MetricID,
			GrHours, GrNumber, DayInWeek, StartTimeID, EndTimeID, 
			Value_Lo, Value_Hi, Value_Avg, Value_Std)
		select ServerID, MetricSetID, MetricID,
			GrHours, GrNumber, DayInWeek, StartTimeID, EndTimeID, 
			Value_Lo, Value_Hi, Value_Avg, Value_Std
		from stage.MetricValueStats
	commit
end

print '--- DONE ---'

RETURN 1
GO
GO
CREATE PROCEDURE [dbo].[tools_SetUpDimentions]
	@StartDate date = null,
	@NYears int = 10

-- 
-- @StartDate - start date of the Dates dimention. January 1st of the @StartDate year is used.
--		when null, current date is used.
--
-- @NYears - defines for how many years Dates dimention will be populated
-- 

AS
set nocount on;

---------- checks
if exists(select top 1 1 from Times) begin
	raiserror('Times table has already been populated.' ,16, 1)
	RETURN -1
end
if exists(select top 1 1 from Dates) begin
	raiserror('Dates table has already been populated.' ,16, 1)
	RETURN -1
end

if @NYears is null or @NYears < 1
	set @NYears = 10
if @StartDate is null
	set @StartDate = getdate();
-- set to the January 1st of the specified year
select @StartDate = CONVERT(DATE, DATEADD(year, DATEDIFF(year, 0, @StartDate), 0))

--declare @n int = 1;
--select @n = datepart(weekday, @StartDate)-1
--DBCC CHECKIDENT (Dates , RESEED, @n)

------- Populate the time dimension - 5 sec increments (17280 items)
; WITH 
n0 AS (SELECT 1 AS a UNION ALL SELECT 1),
n1 AS (SELECT 1 AS a FROM n0 b, n0 c),
n2 AS (SELECT 1 AS a FROM n1 b, n1 c),
n3 AS (SELECT 1 AS a FROM n2 b, n2 c),
n4 AS (SELECT 1 AS a FROM n3 b, n3 c),
n5 AS (SELECT 1 AS a FROM n4 b, n4 c),
numbers AS 
(
	SELECT TOP(17280)
		ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS number
	FROM n5
)
INSERT dbo.Times
SELECT
	TheTime,
	CONVERT(TINYINT, DATEPART(hour, TheTime)) AS HourInDay,
	CONVERT(TINYINT, DATEPART(minute, TheTime)) AS MinuteInHour,
	EveryHour_2 = convert(tinyint, ntile(24/2) over (order by TheTime)),
	EveryHour_4 = convert(tinyint, ntile(24/4) over (order by TheTime)),
	EveryHour_6 = convert(tinyint, ntile(24/6) over (order by TheTime)),
	EveryHour_8 = convert(tinyint, ntile(24/8) over (order by TheTime)),
	EveryHour_12 = convert(tinyint, ntile(24/12) over (order by TheTime))
FROM
(
	SELECT
		DATEADD(second, 5 * (number-1), CONVERT(TIME(0), '00:00:00')) AS TheTime
	FROM numbers
) AS x
ORDER BY
	TheTime ASC;

--- extra - TimeGrouped
declare @GrHours tinyint = 0	-- valid values 0, 1, 2, 4, 6, 8, 12
while @GrHours <= 12 begin
	print '-- Group by # hours: '  + cast(@GrHours as varchar(20))

	insert into TimesGrouped (GrHours, TimeID_min, TimeID_max, Time_min, Time_max, GrNumber)
	select @GrHours, ID_min, ID_max, Time_min, Time_max, GrNumber 
	from dbo.TimeGrouped(@GrHours)

	if @GrHours < 2
		set @GrHours += 1
	else if @GrHours < 8
		set @GrHours += 2
	else
		set @GrHours += 4
end

-------- populate the date dimension
; WITH 
n0 AS (SELECT 1 AS a UNION ALL SELECT 1),
n1 AS (SELECT 1 AS a FROM n0 b, n0 c),
n2 AS (SELECT 1 AS a FROM n1 b, n1 c),
n3 AS (SELECT 1 AS a FROM n2 b, n2 c),
n4 AS (SELECT 1 AS a FROM n3 b, n3 c),
n5 AS (SELECT 1 AS a FROM n4 b, n4 c),
numbers AS 
(
	SELECT TOP(365 * @NYears)
		ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS number
	FROM n5
)
INSERT dbo.Dates
SELECT
	TheDate,
	CONVERT(SMALLINT, YEAR(TheDate)) AS TheYear,
	CONVERT(SMALLINT, MONTH(TheDate)) AS MonthInYear,
	CONVERT(SMALLINT, DATEPART(quarter, TheDate)) AS QuarterInYear,
	CONVERT(SMALLINT, DATEPART(week, TheDate)) AS WeekInYear,
	CONVERT
	(
		SMALLINT,
		DENSE_RANK() OVER 
		(
			PARTITION BY 
				YEAR(TheDate), 
				MONTH(TheDate) 
			ORDER BY 
				DATEPART(week, TheDate)
		)
	) AS WeekInMonth,
	CONVERT
	(
		SMALLINT,
		DENSE_RANK() OVER 
		(
			PARTITION BY 
				YEAR(TheDate), 
				MONTH(TheDate) 
			ORDER BY 
				DATEPART(quarter, TheDate)
		)
	) AS WeekInQuarter,
	CONVERT(SMALLINT, DATEPART(dayofyear, TheDate)) AS DayInYear,
	CONVERT(TINYINT, DATEPART(day, TheDate)) AS DayInMonth,
	CONVERT(TINYINT, DATEPART(weekday, TheDate)) AS DayInWeek,
	DATENAME(month, TheDate) AS NameOfMonth,
	DATENAME(weekday, TheDate) AS NameOfDay
FROM
(
	SELECT
		DATEADD(day, (number-1), @StartDate) AS TheDate
	FROM numbers
) AS x
ORDER BY
	TheDate ASC;

RETURN 1
GO
CREATE PROCEDURE [dbo].[tools_SetUpLookups]
-- 
-- Populates basic lookup tables.
-- 

AS
set nocount on;

-- MetricSetGroups
if exists(select * from MetricSetGroups)
	truncate table MetricSetGroups

insert into MetricSetGroups
values ('Memory', 'Memory'),
	('Network Interface', 'Network'),
	('PhysicalDisk', 'Disk'),
	('Processor', 'Processor'),
	('SQLServer', 'SQLServer')


RETURN 1
GO
CREATE PROCEDURE [stage].[Perfmon_Import]
	@ShowRes bit = 0,	-- prints results when 1
	@IsDebug bit = 0	-- does not commit transaction when 0
	
/*
exec stage.Perfmon_Import @ShowRes=1, @IsDebug=1;
*/

AS
set nocount on;
set xact_abort on;

-- check if there is anything to import
if not exists(select top 1 * from stage.Perfmon)
	RETURN 0

declare @time_interval int = 5
declare @res TABLE (Act varchar(20))

declare @Metrics TABLE (
	CounterInstance nvarchar(200),
	MetricSet nvarchar(200),
	Metric nvarchar(200)
)

BEGIN TRY

	BEGIN TRAN

		; with r as (
			select CounterInstance from stage.Perfmon group by CounterInstance
		),
		names as (
			select CounterInstance,
				-- if server included into name could be something like
				-- \\SERVERNAME\Processor(6)\% Privileged Time == \\ServerName\SetName\MetricName
				SetName = case 
					when dbo.GetValueFromCSV(CounterInstance, '\', 3) is null then
						dbo.GetValueFromCSV(CounterInstance, '\', 1)
					else
						dbo.GetValueFromCSV(CounterInstance, '\', 2)
					end,
				MetricName = case 
					when dbo.GetValueFromCSV(CounterInstance, '\', 3) is null then
						dbo.GetValueFromCSV(CounterInstance, '\', 2)
					else
						dbo.GetValueFromCSV(CounterInstance, '\', 3)
					end
			from r
		)
		insert into @Metrics (CounterInstance, MetricSet, Metric)
		select CounterInstance, SetName, MetricName
		from names;

		-- registering all required lookup tables: Servers
		; with r as (
			select ServerName from stage.Perfmon group by ServerName
		)
		insert into Servers (Name)
		select ServerName
		from r 
			left join Servers s on r.ServerName = s.Name
		where s.ID is null

		-- registering all required lookup tables: MetricSets
		; with r as (
			select MetricSet from @Metrics group by MetricSet
		)
		insert into MetricSets (Name)
		select r.MetricSet
		from r 
			left join MetricSets s on r.MetricSet = s.Name
		where s.ID is null

		-- registering all required lookup tables: Metrics
		; with r as (
			select Metric from @Metrics group by Metric
		)
		insert into Metrics (Name)
		select r.Metric
		from r 
			left join Metrics s on r.Metric = s.Name
		where s.ID is null

		-- add sitinct combination of servers/metric sets/metrics
		MERGE Server_MetricSets as t
		using (
			select
				ServerID = s.ID,
				MetricSetID = mc.ID,
				MetricID = m.ID
			from stage.Perfmon p
				join Servers s on p.ServerName = s.Name
				join @Metrics mm on p.CounterInstance = mm.CounterInstance
				join MetricSets mc on mm.MetricSet = mc.Name
				join Metrics m on mm.Metric = m.Name
			group by s.ID, mc.ID, m.ID
		) as s on t.ServerID = s.ServerID 
			and t.MetricSetID = s.MetricSetID and t.MetricID = s.MetricID
		when not matched by target then
			INSERT (ServerID, MetricSetID, MetricID)
			values(s.ServerID, s.MetricSetID, s.MetricID)
		;

		-- store metric values
		-- first have to group all rows by 15 sec intervals
		; with times as (
			select 
				ServerName, CounterInstance,
				D = convert(date, DateTimeStamp),
				T = convert(time(0), DateTimeStamp),
				--TPart = datepart(second,convert(time(0), DateTimeStamp)) / @time_interval * @time_interval,
				--TDif = datepart(second,convert(time(0), DateTimeStamp)) % @time_interval,
				CounterValue,
				TGroup = dateadd(second,-(datepart(second,convert(time(0), DateTimeStamp)) % @time_interval), 
					convert(time(0), DateTimeStamp))
			from stage.Perfmon tt
		),
		perf as (
			select 
				ServerName, 
				CounterInstance,
				D, TGroup,
				Value = avg(CounterValue)
			from times
			group by ServerName, CounterInstance, D, TGroup
		)
		MERGE MetricValues as t
		using (
			select
				ServerID = s.ID,
				DateID = d.ID,
				TimeID = t.ID,
				MetricSetID = mc.ID,
				MetricID = m.ID,
				Value = avg(p.Value),
				DayInYear = d.DayInYear
			from perf p
				join Servers s on p.ServerName = s.Name
				join @Metrics mm on p.CounterInstance = mm.CounterInstance
				join MetricSets mc on mm.MetricSet = mc.Name
				join Metrics m on mm.Metric = m.Name
				join dbo.Dates d on p.D = d.TheDate
				join dbo.Times t on p.TGroup = t.TheTime
			group by s.ID, mc.ID, m.ID, d.ID, d.DayInYear, t.ID
		) as s on t.DayInYear = s.DayInYear
			and t.ServerID = s.ServerID 
			and t.MetricSetID = s.MetricSetID and t.MetricID = s.MetricID
			and t.DateID = s.DateID and t.TimeID = s.TimeID
		when matched then 
			UPDATE set
				Value = s.Value
		when not matched by target then
			INSERT (ServerID, DateID, TimeID, MetricSetID, MetricID, Value, DayInYear)
			values(s.ServerID, s.DateID, s.TimeID, s.MetricSetID, s.MetricID, s.Value, s.DayInYear)
		output $action into @res
		;

		if @ShowRes = 1 or @IsDebug = 1 begin
			-- count results
			--select Act, cnt=count(*) from @res group by Act order by Act;
			declare @ins int = 0, @upd int = 0, @stage int = 0
			select @stage = count(*) from stage.Perfmon
			select 
				@ins = sum(case when Act = 'INSERT' then 1 else 0 end),
				@upd = sum(case when Act = 'UPDATE' then 1 else 0 end)
			from @res
			print '== Staging table rows: ' + cast(@stage as varchar(20))
			print '== Total   saved rows: ' + cast(@ins + @upd as varchar(20))
			print '=~ Total grouped rows: ' + cast(@stage - @ins - @upd as varchar(20))
			print '-- Processed  inserts: ' + cast(@ins as varchar(20))
			print '-- Processed  updates: ' + cast(@upd as varchar(20))
		end

		-- clean up stage table
		truncate table stage.Perfmon

		if @IsDebug = 1
			ROLLBACK TRAN
		else
			COMMIT TRAN

END TRY
BEGIN CATCH
	declare @errSeverity int,
			@errMsg nvarchar(2048)
	select	@errSeverity = ERROR_SEVERITY(),
			@errMsg = ERROR_MESSAGE()

    -- Test XACT_STATE:
    -- If 1, the transaction is committable.
    -- If -1, the transaction is uncommittable and should be rolled back.
    -- XACT_STATE = 0 means that there is no transaction and a commit or rollback operation would generate an error.
	 if (xact_state() = 1 or xact_state() = -1)
		ROLLBACK TRAN

	if @ShowRes = 1
		print '!! ERROR: ' + @errMsg
	else
		raiserror(@errMsg, @errSeverity, 1)

END CATCH

RETURN 1
GO
GRANT EXECUTE ON [stage].[Perfmon_Import] TO [importer] AS [dbo]
GO
CREATE PROCEDURE dbo.GetRpt_DataAvailability
	@TopDays int = 7

--
-- Gets total number of recorded metric values for each server for the last @TopDays.
--

AS
set nocount on;

declare @d date = getdate();

; with d as (
	select top (@TopDays)
		ID, TheDate
	from Dates (nolock)
	where TheDate <= @d
	order by TheDate desc
),
mv as (
	select ServerID, DateID, Count=count(*)
	from MetricValues mv (nolock)
		join d on mv.DateID = d.ID
	group by ServerID, DateID
)
select d.ID, d.TheDate,
	ServerID = s.ID, ServerName=s.Name, 
	Count = isnull(mv.Count,0)
into #t
from d
	join mv on d.ID = mv.DateID
	join Servers s (nolock) on mv.ServerID = s.ID
order by s.Name, d.ID desc
;

-- add zero days
; with d as (
	select top (@TopDays)
		ID, TheDate
	from Dates (nolock)
	where TheDate <= @d
	order by TheDate desc
)
insert into #t (ID, TheDate, ServerID, ServerName, Count)
select d.ID, d.TheDate, sn.ServerID, sn.ServerName, Count=0
from d
	cross join (select distinct ServerID, ServerName from #t) sn
	left join #t t on d.ID = t.ID and sn.ServerID = t.ServerID
where t.ID is null;

--results
declare @cols nvarchar(max), @sql nvarchar(max)
select @cols = isnull(@cols + ',[', '[') + ServerName + ']' from (
	select distinct ServerName from #t
) a
order by ServerName
--select @cols

set @sql = N'
	select * 
	from (
		select TheDate, ServerName, Count
		from #t
	) a
	PIVOT (
		sum(Count) for ServerName in (' + @cols + ')
	) b
	order by TheDate desc;
'
exec sp_executesql @sql;

drop table #t

RETURN 1
GO
GRANT EXECUTE ON [dbo].[GetRpt_DataAvailability] TO [reporter] AS [dbo]
GO

print '--- Functions and stored procs: done. ---'
GO
