SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
set transaction isolation level snapshot;

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
