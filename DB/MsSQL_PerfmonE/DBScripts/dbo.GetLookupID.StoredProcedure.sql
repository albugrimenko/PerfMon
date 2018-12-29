SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
