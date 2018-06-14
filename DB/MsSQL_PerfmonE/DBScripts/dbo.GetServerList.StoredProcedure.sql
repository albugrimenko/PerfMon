SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetServerList]

AS
set nocount on;
--set transaction isolation level snapshot;

select 
	ID,
	Name
from Servers (nolock)
order by Name

RETURN 1
GO
GRANT EXECUTE ON [dbo].[GetServerList] TO [reporter] AS [dbo]
GO
