SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetStatRatioDescr](@StatRatio float)
--
-- Gets stat ratio description (StatRatio is computed in the MetricValuesWithStats)
--
RETURNS nvarchar(15)
AS
BEGIN
	declare @res nvarchar(15) = case
		when @StatRatio is null then 'Unknown'

		when @StatRatio is not null and @StatRatio < -5 then 'Extremely Low'
		when @StatRatio is not null and @StatRatio >= -5 and @StatRatio < -3 then 'Very Low'
		when @StatRatio is not null and @StatRatio >= -3 and @StatRatio < -2 then 'Low'

		when @StatRatio is not null and @StatRatio > 2 and @StatRatio <= 3 then 'High'
		when @StatRatio is not null and @StatRatio > 3 and @StatRatio <= 5 then 'Very High'
		when @StatRatio is not null and @StatRatio > 5 then 'Extremely High'

		else 'OK'
	end

	RETURN @res
END
GO
GRANT EXECUTE ON [dbo].[GetStatRatioDescr] TO [reporter] AS [dbo]
GO
