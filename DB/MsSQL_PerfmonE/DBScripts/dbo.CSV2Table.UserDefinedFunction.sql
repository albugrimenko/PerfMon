SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[CSV2Table] 
(	
	@ItemsStr nvarchar(max), -- comma separated list of values to be returned
	@sep char(1) = ','		-- separator chaacter
)
RETURNS @Items TABLE (Item nvarchar(200))
AS

/*
select * from dbo.CSV2Table('\Network Interface(Intel(R) Ethernet Connection I217-LM)\Bytes Sent/sec', '\')
select * from dbo.CSV2Table('Bytes Sent/sec', '\')
*/

begin
	declare @ItemsList nvarchar(max),
			@Item nvarchar(200), 
			@Pos int;
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

	return 
end
GO
GRANT SELECT ON [dbo].[CSV2Table] TO [public] AS [dbo]
GO
