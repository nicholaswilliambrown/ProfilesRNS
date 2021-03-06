SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [Profile.Data].[vwGroup.GeneralWithDeleted] AS 
	SELECT GroupID, GroupName, g.ViewSecurityGroup, ISNULL(m.NodeID,-40) EditSecurityGroup, CreateDate, EndDate,
		(case when g.ViewSecurityGroup = 0 then 'Deleted' when g.ViewSecurityGroup > 0 then 'Private' else isnull(s.Label,'Unknown') end) ViewSecurityGroupName, 
		m.NodeID GroupNodeID
	FROM [Profile.Data].[Group.General] g
		LEFT OUTER JOIN [RDF.Security].[Group] s
			ON g.ViewSecurityGroup = s.SecurityGroupID
		LEFT OUTER JOIN [RDF.Stage].InternalNodeMap m
			ON m.Class = 'http://xmlns.com/foaf/0.1/Group' AND m.InternalType = 'Group' AND InternalID = g.GroupID
		LEFT OUTER JOIN [RDF.].[Node] n
			ON m.NodeID = n.NodeID

GO
