SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [RDF.].[fnNodeID2PersonID] (
	@nodeID	bigint
) 
RETURNS int
AS
BEGIN
	DECLARE @result int
	select @result = internalID from [RDF.Stage].InternalNodeMap where NodeID = @nodeID and class = 'http://xmlns.com/foaf/0.1/Person'
	RETURN @result
END
GO
