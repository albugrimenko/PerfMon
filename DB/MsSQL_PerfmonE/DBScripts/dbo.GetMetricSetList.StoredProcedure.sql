SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
