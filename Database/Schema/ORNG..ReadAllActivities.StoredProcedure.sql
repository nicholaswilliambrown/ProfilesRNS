SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE  [ORNG.].[ReadAllActivities](@Uri nvarchar(255),@AppID INT)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @NodeID bigint
	
	select @NodeID = [RDF.].[fnURI2NodeID](@Uri);

	IF (@AppID IS NULL)
		select Activity from [ORNG.].Activity where NodeID = @NodeID
	ELSE		
		select Activity from [ORNG.].Activity where NodeID = @NodeID AND AppID=@AppID 
END

GO
