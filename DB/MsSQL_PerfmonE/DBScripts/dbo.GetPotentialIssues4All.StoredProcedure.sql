SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
