SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[TimeGrouped](@GrHours tinyint)
/*
Gets times grouped by a particular number of hours.
Valid @GrHours values: 0, 1, 2, 4, 6, 8, 12
Default value of 2 is used for any not valid @GrHours.

select * from dbo.TimeGrouped(3)
*/
RETURNS @t TABLE 
(
	ID_min smallint, 
	ID_max smallint, 
	Time_min time, 
	Time_max time,
	GrNumber tinyint
	)
AS
BEGIN

	; with ftimes as (
		select ID, TheTime,
			GrNumber = case 
				when @GrHours = 1 then HourInDay
				when @GrHours = 2 then EveryHour_2
				when @GrHours = 4 then EveryHour_4
				when @GrHours = 6 then EveryHour_6
				when @GrHours = 8 then EveryHour_8
				when @GrHours = 12 then EveryHour_12
				when @GrHours in (0, 24) then 0
				else EveryHour_2
			end
		from Times
	),
	t as (
		select
			ID_min = min(ID),
			ID_max = max(ID),
			Time_min = min(TheTime),
			Time_max = dateadd(second,5,max(TheTime)),
			GrNumber
		from ftimes
		group by GrNumber
	)
	insert into @t (ID_min, ID_max, Time_min, Time_max, GrNumber)
	select ID_min, ID_max, Time_min, Time_max, GrNumber 
	from t
	order by ID_min;
	
	RETURN
END
GO
GRANT SELECT ON [dbo].[TimeGrouped] TO [public] AS [dbo]
GO
