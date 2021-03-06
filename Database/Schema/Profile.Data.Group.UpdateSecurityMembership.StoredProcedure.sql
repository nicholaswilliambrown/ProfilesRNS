SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Profile.Data].[Group.UpdateSecurityMembership]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	------------------------------------------------------------
	-- Get the users who currently can edit a group
	------------------------------------------------------------

	SELECT s.UserID, ISNULL(m.NodeID,0) NodeID, g.GroupID
		INTO #OldSecurityMembership
		FROM [Profile.Data].[Group.General] g
			INNER JOIN [RDF.Stage].InternalNodeMap m
				ON m.Class = 'http://xmlns.com/foaf/0.1/Group' AND m.InternalType = 'Group' AND m.InternalID = CAST(g.GroupID AS VARCHAR(50))
			INNER JOIN [RDF.Security].[Member] s
				ON m.NodeID = s.SecurityGroupID
		WHERE m.NodeID IS NOT NULL

	ALTER TABLE #OldSecurityMembership ADD PRIMARY KEY (UserID,NodeID)

	------------------------------------------------------------
	-- Get the users who should be able to edit a group
	------------------------------------------------------------

	;WITH a AS (
		SELECT DISTINCT UserID, GroupID
		FROM (
				SELECT a.UserID, g.GroupID
					FROM [Profile.Data].[Group.Admin] a
						CROSS JOIN [Profile.Data].[Group.General] g
					WHERE g.ViewSecurityGroup <> 0
				UNION ALL
				SELECT a.UserID, g.GroupID
					FROM [Profile.Data].[Group.Manager] a
						CROSS JOIN [Profile.Data].[Group.General] g
					WHERE g.ViewSecurityGroup <> 0
			) t 
	)
	SELECT a.UserID, ISNULL(m.NodeID,0) NodeID, a.GroupID
		INTO #NewSecurityMembership
		FROM a INNER JOIN [RDF.Stage].InternalNodeMap m
			ON m.Class = 'http://xmlns.com/foaf/0.1/Group' AND m.InternalType = 'Group' AND m.InternalID = CAST(a.GroupID AS VARCHAR(50))
		WHERE m.NodeID IS NOT NULL

	ALTER TABLE #NewSecurityMembership ADD PRIMARY KEY (UserID,NodeID)

	------------------------------------------------------------
	-- Update the group security membership
	------------------------------------------------------------

	DELETE m
		FROM [RDF.Security].[Member] m
		WHERE EXISTS (SELECT * FROM #OldSecurityMembership o WHERE o.UserID=m.UserID AND o.NodeID=m.SecurityGroupID)
			AND NOT EXISTS (SELECT * FROM #NewSecurityMembership n WHERE n.UserID=m.UserID AND n.NodeID=m.SecurityGroupID)

	INSERT INTO [RDF.Security].[Member] (UserID, SecurityGroupID, IsVisible)
		SELECT UserID, NodeID, 0 IsVisible
		FROM #NewSecurityMembership n
		WHERE NOT EXISTS (SELECT * FROM [RDF.Security].[Member] m WHERE n.UserID=m.UserID AND n.NodeID=m.SecurityGroupID)

END

GO
