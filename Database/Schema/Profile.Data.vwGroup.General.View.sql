SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [Profile.Data].[vwGroup.General] AS 
	SELECT GroupID, GroupName, ViewSecurityGroup, EditSecurityGroup, CreateDate, ViewSecurityGroupName, GroupNodeID
	FROM [Profile.Data].[vwGroup.GeneralWithDeleted]
	WHERE ViewSecurityGroup <> 0

GO
