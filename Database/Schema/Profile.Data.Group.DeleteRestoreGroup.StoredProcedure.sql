SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Profile.Data].[Group.DeleteRestoreGroup]
	@GroupID INT=NULL, 
	@GroupNodeID BIGINT=NULL,
	@GroupURI VARCHAR(400)=NULL,
	@RestoreGroup BIT=0,
	@SessionID UNIQUEIDENTIFIER=NULL, 
	@Error BIT=NULL OUTPUT, 
	@NodeID BIGINT=NULL OUTPUT	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	/*
	
	This stored procedure either deletes or restores a Group.
	Groups can be specified either by GroupID, NodeID or URI.
	
	*/
	
	SELECT @Error = 0

	-------------------------------------------------
	-- Validate and prepare variables
	-------------------------------------------------

	-- Check that the group is only specified in one way
	IF (CASE WHEN @GroupID IS NULL THEN 0 ELSE 1 END)+(CASE WHEN @GroupNodeID IS NULL THEN 0 ELSE 1 END)+(CASE WHEN @GroupURI IS NULL THEN 0 ELSE 1 END) <> 1
		RETURN;
	
	-- Convert URIs and NodeIDs to GroupID
 	IF (@GroupURI IS NOT NULL)
		SELECT @GroupNodeID = [RDF.].fnURI2NodeID(@GroupURI)
 	IF (@GroupNodeID IS NOT NULL)
		SELECT @GroupID = CAST(m.InternalID AS INT)
			FROM [RDF.Stage].[InternalNodeMap] m, [RDF.].Node n
			WHERE m.Status = 3 AND m.ValueHash = n.ValueHash AND n.NodeID = @GroupNodeID
 
 	IF (@GroupNodeID IS NULL)
		select @GroupNodeID = NodeID from [RDF.Stage].[InternalNodeMap] where status=3 and class = 'http://xmlns.com/foaf/0.1/Group' and InternalID = @GroupID

	-- Make sure both a GroupID and GroupNodeID exist
	IF (@GroupID IS NULL) OR (@GroupNodeID IS NULL)
		RETURN;

	DECLARE @contributingRoleID BIGINT
	SELECT @contributingRoleID = [RDF.].fnURI2NodeID('http://vivoweb.org/ontology/core#contributingRole')

	-------------------------------------------------
	-- Delete a group
	-------------------------------------------------

    IF @RestoreGroup = 0
	BEGIN
		-- Delete the group membership role nodes
		UPDATE n
			SET n.ViewSecurityGroup = 0
			FROM [RDF.].[Triple] t
				INNER JOIN [RDF.].[Node] n
					ON t.Object = n.NodeID
			WHERE Subject = @GroupNodeID AND Predicate = @contributingRoleID
		-- Delete the group node
		UPDATE [RDF.].[Node]
			SET ViewSecurityGroup = 0
			WHERE NodeID = @GroupNodeID
		-- Delete the group
		UPDATE [Profile.Data].[Group.General]
			SET ViewSecurityGroup = 0
			WHERE GroupID = @GroupID
		-- Remove access rights
		EXEC [Profile.Data].[Group.UpdateSecurityMembership]
	END

	-------------------------------------------------
	-- Restore a group, making it private
	-------------------------------------------------

    IF @RestoreGroup = 1
	BEGIN
		-- Restore the group
		UPDATE [Profile.Data].[Group.General]
			SET ViewSecurityGroup = @GroupNodeID,
			EndDate = CASE WHEN EndDate < GETDATE() THEN DATEADD(yy,10,CAST(GetDate() AS DATE)) ELSE EndDate END
			WHERE GroupID = @GroupID
		-- Restore the group node
		UPDATE [RDF.].[Node]
			SET ViewSecurityGroup = @GroupNodeID
			WHERE NodeID = @GroupNodeID
		-- Restore the group membership role nodes (where IsActive=1)
		UPDATE n
			SET n.ViewSecurityGroup = @GroupNodeID
			FROM [RDF.].[Triple] t
				INNER JOIN [RDF.].[Node] n
					ON t.Object = n.NodeID
			WHERE Subject = @GroupNodeID AND Predicate = @contributingRoleID
				AND n.NodeID IN (
					SELECT m.NodeID
					FROM [Profile.Data].[Group.Member] g
						INNER JOIN [RDF.Stage].InternalNodeMap m
							ON m.Class = 'http://vivoweb.org/ontology/core#MemberRole' AND m.InternalType = 'MemberRole' AND m.InternalID = g.MemberRoleID
					WHERE g.GroupID = @GroupID AND g.IsActive = 1
				)
		-- Restore access rights
		EXEC [RDF.].SetNodePropertySecurity @NodeID=@GroupNodeID,@PropertyURI='http://profiles.catalyst.harvard.edu/ontology/prns#hasGroupSettings',@ViewSecurityGroup=@GroupNodeID

		EXEC [Profile.Data].[Group.UpdateSecurityMembership]
	END

END
GO
