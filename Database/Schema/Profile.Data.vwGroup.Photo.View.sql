SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [Profile.Data].[vwGroup.Photo]
AS
SELECT p.*, m.NodeID GroupNodeID, o.Value+'Modules/CustomViewPersonGeneralInfo/PhotoHandler.ashx?NodeID='+CAST(m.NodeID as varchar(50)) URI
FROM [Profile.Data].[Group.Photo] p
	INNER JOIN [RDF.Stage].[InternalNodeMap] m
		ON m.Class = 'http://xmlns.com/foaf/0.1/Group'
			AND m.InternalType = 'Group'
			AND m.InternalID = CAST(p.GroupID as varchar(50))
	INNER JOIN [Framework.].[Parameter] o
		ON o.ParameterID = 'baseURI';

GO
