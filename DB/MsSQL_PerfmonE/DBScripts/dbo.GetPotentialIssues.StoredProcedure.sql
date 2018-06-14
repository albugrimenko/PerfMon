SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetPotentialIssues]
	@ServerID int = null, @ServerName nvarchar(200) = null, 
	@MetricSetID int = null, @MetricSetName nvarchar(200) = null,
	@MetricID int = null, @MetricName nvarchar(200) = null,
	@SigmaNum money = 3

/* Gets most recent (last 2 days) recorded values for a particular server/metric for specified date range
	where average value is differ from recorded average for more than @SigmaNum standard deviations.

exec GetPotentialIssues @ServerID=1, @SigmaNum=2
*/
--with recompile

AS
set nocount on;
set transaction isolation level snapshot;

---- params 
declare @GrHours tinyint = 1,
		@StartDate date = dateadd(day, -2, getdate()),
		@EndDate date = getdate()

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
	[Server] = s.Name,
	MetricSet = ms.Name,
	Metric = m.Name,
	TimeStart,
	TimeEnd,
	StatRatioDescr,
	Value_Lo,
	Value_Hi,
	Value_Avg,
	StatValue_Lo,
	StatValue_Hi,
	StatValue_Avg,
	StatValue_Std,
	StatRatio
from r
	join [Servers] s on r.ServerID = s.ID
	join MetricSets ms on r.MetricSetID = ms.ID
	join Metrics m on r.MetricID = m.ID
order by TheDate, s.Name, ms.Name, m.Name, TimeStart

RETURN 1
GO
GRANT EXECUTE ON [dbo].[GetPotentialIssues] TO [reporter] AS [dbo]
GO
