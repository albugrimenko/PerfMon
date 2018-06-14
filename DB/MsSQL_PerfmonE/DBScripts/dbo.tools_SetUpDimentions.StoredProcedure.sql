SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[tools_SetUpDimentions]
	@StartDate date = null,
	@NYears int = 10

-- 
-- @StartDate - start date of the Dates dimention. January 1st of the @StartDate year is used.
--		when null, current date is used.
--
-- @NYears - defines for how many years Dates dimention will be populated
-- 

AS
set nocount on;

---------- checks
if exists(select top 1 1 from Times) begin
	raiserror('Times table has already been populated.' ,16, 1)
	RETURN -1
end
if exists(select top 1 1 from Dates) begin
	raiserror('Dates table has already been populated.' ,16, 1)
	RETURN -1
end

if @NYears is null or @NYears < 1
	set @NYears = 10
if @StartDate is null
	set @StartDate = getdate();
-- set to the January 1st of the specified year
select @StartDate = CONVERT(DATE, DATEADD(year, DATEDIFF(year, 0, @StartDate), 0))

--declare @n int = 1;
--select @n = datepart(weekday, @StartDate)-1
--DBCC CHECKIDENT (Dates , RESEED, @n)

------- Populate the time dimension - 5 sec increments (17280 items)
; WITH 
n0 AS (SELECT 1 AS a UNION ALL SELECT 1),
n1 AS (SELECT 1 AS a FROM n0 b, n0 c),
n2 AS (SELECT 1 AS a FROM n1 b, n1 c),
n3 AS (SELECT 1 AS a FROM n2 b, n2 c),
n4 AS (SELECT 1 AS a FROM n3 b, n3 c),
n5 AS (SELECT 1 AS a FROM n4 b, n4 c),
numbers AS 
(
	SELECT TOP(17280)
		ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS number
	FROM n5
)
INSERT dbo.Times
SELECT
	TheTime,
	CONVERT(TINYINT, DATEPART(hour, TheTime)) AS HourInDay,
	CONVERT(TINYINT, DATEPART(minute, TheTime)) AS MinuteInHour,
	EveryHour_2 = convert(tinyint, ntile(24/2) over (order by TheTime)),
	EveryHour_4 = convert(tinyint, ntile(24/4) over (order by TheTime)),
	EveryHour_6 = convert(tinyint, ntile(24/6) over (order by TheTime)),
	EveryHour_8 = convert(tinyint, ntile(24/8) over (order by TheTime)),
	EveryHour_12 = convert(tinyint, ntile(24/12) over (order by TheTime))
FROM
(
	SELECT
		DATEADD(second, 5 * (number-1), CONVERT(TIME(0), '00:00:00')) AS TheTime
	FROM numbers
) AS x
ORDER BY
	TheTime ASC;

--- extra - TimeGrouped
declare @GrHours tinyint = 0	-- valid values 0, 1, 2, 4, 6, 8, 12
while @GrHours <= 12 begin
	print '-- Group by # hours: '  + cast(@GrHours as varchar(20))

	insert into TimesGrouped (GrHours, TimeID_min, TimeID_max, Time_min, Time_max, GrNumber)
	select @GrHours, ID_min, ID_max, Time_min, Time_max, GrNumber 
	from dbo.TimeGrouped(@GrHours)

	if @GrHours < 2
		set @GrHours += 1
	else if @GrHours < 8
		set @GrHours += 2
	else
		set @GrHours += 4
end

-------- populate the date dimension
; WITH 
n0 AS (SELECT 1 AS a UNION ALL SELECT 1),
n1 AS (SELECT 1 AS a FROM n0 b, n0 c),
n2 AS (SELECT 1 AS a FROM n1 b, n1 c),
n3 AS (SELECT 1 AS a FROM n2 b, n2 c),
n4 AS (SELECT 1 AS a FROM n3 b, n3 c),
n5 AS (SELECT 1 AS a FROM n4 b, n4 c),
numbers AS 
(
	SELECT TOP(365 * @NYears)
		ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS number
	FROM n5
)
INSERT dbo.Dates
SELECT
	TheDate,
	CONVERT(SMALLINT, YEAR(TheDate)) AS TheYear,
	CONVERT(SMALLINT, MONTH(TheDate)) AS MonthInYear,
	CONVERT(SMALLINT, DATEPART(quarter, TheDate)) AS QuarterInYear,
	CONVERT(SMALLINT, DATEPART(week, TheDate)) AS WeekInYear,
	CONVERT
	(
		SMALLINT,
		DENSE_RANK() OVER 
		(
			PARTITION BY 
				YEAR(TheDate), 
				MONTH(TheDate) 
			ORDER BY 
				DATEPART(week, TheDate)
		)
	) AS WeekInMonth,
	CONVERT
	(
		SMALLINT,
		DENSE_RANK() OVER 
		(
			PARTITION BY 
				YEAR(TheDate), 
				MONTH(TheDate) 
			ORDER BY 
				DATEPART(quarter, TheDate)
		)
	) AS WeekInQuarter,
	CONVERT(SMALLINT, DATEPART(dayofyear, TheDate)) AS DayInYear,
	CONVERT(TINYINT, DATEPART(day, TheDate)) AS DayInMonth,
	CONVERT(TINYINT, DATEPART(weekday, TheDate)) AS DayInWeek,
	DATENAME(month, TheDate) AS NameOfMonth,
	DATENAME(weekday, TheDate) AS NameOfDay
FROM
(
	SELECT
		DATEADD(day, (number-1), @StartDate) AS TheDate
	FROM numbers
) AS x
ORDER BY
	TheDate ASC;

RETURN 1
GO
