SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [Profile.Data].[Group.GetPhotos](@NodeID bigINT)
AS
BEGIN

DECLARE @GroupID INT 

    SELECT @GroupID = CAST(m.InternalID AS INT)
		FROM [RDF.Stage].[InternalNodeMap] m, [RDF.].Node n
		WHERE m.Status = 3 AND m.ValueHash = n.ValueHash AND n.NodeID = @NodeID
		
	SELECT  photo,
			p.PhotoID		
		FROM [Profile.Data].[Group.Photo] p WITH(NOLOCK)
	 WHERE GroupID=@GroupID  
END
GO
