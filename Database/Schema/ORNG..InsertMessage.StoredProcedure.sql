SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [ORNG.].[InsertMessage](@MsgID nvarchar(255),@Coll nvarchar(255), @Title nvarchar(255), @Body nvarchar(255),
										@senderUri nvarchar(255), @RecipientUri nvarchar(255))
As
BEGIN
	SET NOCOUNT ON
	DECLARE @SenderNodeID bigint
	DECLARE @RecipientNodeID bigint
	
	select @SenderNodeID = [RDF.].[fnURI2NodeID](@senderUri)
	select @RecipientNodeID = [RDF.].[fnURI2NodeID](@RecipientUri)
	
	INSERT [ORNG.].[Messages]  (MsgID, Coll, Title, Body, SenderNodeID, RecipientNodeID) 
			VALUES (@MsgID, @Coll, @Title, @Body, @SenderNodeID, @RecipientNodeID)
END		

GO
