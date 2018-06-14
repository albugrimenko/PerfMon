SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetMetricValues]
	@StartDate date, @EndDate date,

	@ServerID int = null, @ServerName nvarchar(200) = null, 
	@MetricSetID int = null, @MetricSetName nvarchar(200) = null,
	@MetricID int = null, @MetricName nvarchar(200) = null

/* Gets all recorded values for a particular server/metric for specified date range

exec GetMetricValues @StartDate = '5/7/2018', @EndDate = '5/10/2018',
	@ServerID=1, @MetricSetName='Processor(_Total)', 
	@MetricName='% Processor Time'
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
	from Dates
	where TheDate between @StartDate and @EndDate
)
select --top(2147483647)
	[Date] = d.TheDate,
	[Time] = t.TheTime,
	Value = mv.Value
from MetricValues mv
	join fdates d on mv.DateID = d.ID 
		and mv.DayInYear = d.DayInYear	-- required for proper partitions usage
	join Times t on mv.TimeID = t.ID
where --m.DayInYear in (select DayInYear from fdates group by DayInYear)
	mv.ServerID = @ServerID
	and mv.MetricSetID = @MetricSetID
	and mv.MetricID = @MetricID
order by d.ID, t.ID

RETURN 1
GO
GRANT EXECUTE ON [dbo].[GetMetricValues] TO [reporter] AS [dbo]
GO
