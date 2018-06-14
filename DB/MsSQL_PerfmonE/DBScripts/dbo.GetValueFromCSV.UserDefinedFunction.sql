SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetValueFromCSV] 
(	
	@ItemsStr nvarchar(max), -- comma separated list of values to be returned
	@sep char(1) = ',',		-- separator chaacter
	@ItemNumber int = 1		-- item number to get
)
RETURNS nvarchar(200)
AS

/*
select dbo.GetValueFromCSV('\Network Interface(Intel(R) Ethernet Connection I217-LM)\Bytes Sent/sec', '\', 2)
select dbo.GetValueFromCSV('Bytes Sent/sec', '\', 2)
select dbo.GetValueFromCSV('Bytes Sent/sec', '\', 1)
*/

begin
	declare @ItemsList nvarchar(max),
			@Item nvarchar(200), 
			@Pos int;

	declare @Items table (ID int identity(1,1), Item nvarchar(200))

	--possible separators char(13),char(9)-tab; char(10)(LF) gets removed
	select @ItemsList = LTRIM(RTRIM(
		replace(
			replace(
				replace(@ItemsStr, char(13), @sep)
				, char(9), @sep)
			, char(10), '')
		)) + @sep

	select @Pos = CHARINDEX(@sep, @ItemsList, 1)
	if REPLACE(@ItemsList, @sep, '') <> '' begin
		while @Pos > 0 begin
			select @Item = LTRIM(RTRIM(LEFT(@ItemsList, @Pos - 1)))
			if @Item <> '' begin
				insert into @Items (Item) 
				values (@Item)
			end
			select @ItemsList = RIGHT(@ItemsList, LEN(@ItemsList) - @Pos)
			select @Pos = CHARINDEX(@sep, @ItemsList, 1)
		end
	end	

	select @Item = null
	select @Item = Item from @Items where ID = @ItemNumber

	return @Item
end
GO
GRANT EXECUTE ON [dbo].[GetValueFromCSV] TO [public] AS [dbo]
GO
