SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
