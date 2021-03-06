SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [Profile.Data].[vwGroup.Member] AS 
	SELECT m.MemberRoleID, m.GroupID, m.UserID, u.PersonID, m.IsActive, m.IsApproved, m.IsVisible, m.Title, m.IsFeatured, m.SortOrder, g.ViewSecurityGroup, -40 EditSecurityGroup
	FROM [Profile.Data].[Group.Member] m
		INNER JOIN [Profile.Data].[Group.General] g
			ON g.GroupID = m.GroupID
		INNER JOIN [User.Account].[User] u
			ON m.UserID = u.UserID
	WHERE (m.IsActive=1) AND (m.IsApproved=1) AND (m.IsVisible=1) AND (u.PersonID IS NOT NULL) and (g.ViewSecurityGroup <> 0)
GO
