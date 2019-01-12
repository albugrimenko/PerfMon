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
