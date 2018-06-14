SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
