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
