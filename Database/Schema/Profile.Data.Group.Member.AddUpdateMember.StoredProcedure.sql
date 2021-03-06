SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Profile.Data].[Group.Member.AddUpdateMember]
	-- Role
	@MemberRoleID VARCHAR(50)=NULL,
	@MemberRoleNodeID BIGINT=NULL,
	@MemberRoleURI VARCHAR(400)=NULL,
	-- Group
	@GroupID INT=NULL, 
	@GroupNodeID BIGINT=NULL,
	@GroupURI VARCHAR(400)=NULL,
	-- User
	@UserID INT=NULL,
	@UserNodeID BIGINT=NULL,
	@UserURI VARCHAR(400)=NULL,
	-- Other
	@IsApproved bit=NULL,
	@IsVisible bit=NULL,
	@Title nvarchar(255)=NULL,
	@SessionID UNIQUEIDENTIFIER=NULL, 
	@Error BIT=NULL OUTPUT, 
	@NodeID BIGINT=NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	/*
	
	This stored procedure either adds or updates a Group Member.
	Either specify:
	1) A MemberRole by either MemberRoleID, NodeID, or URI.
	2) A Group by either GroupID, NodeID or URI;
		and, a User by UserID, NodeID, or URI.
	
	*/
	
	SELECT @Error = 0

	-------------------------------------------------
	-- Validate and prepare variables
	-------------------------------------------------
	
	-- Convert MemberRoleID to GroupID and NodeID
 	IF (@MemberRoleNodeID IS NULL) AND (@MemberRoleURI IS NOT NULL)
		SELECT @MemberRoleNodeID = [RDF.].fnURI2NodeID(@MemberRoleURI)
 	IF (@MemberRoleID IS NULL) AND (@MemberRoleNodeID IS NOT NULL)
		SELECT @MemberRoleID = CAST(m.InternalID AS INT)
			FROM [RDF.Stage].[InternalNodeMap] m, [RDF.].Node n
			WHERE m.Status = 3 AND m.ValueHash = n.ValueHash AND n.NodeID = @MemberRoleNodeID
	IF (@MemberRoleID IS NOT NULL)
		SELECT @GroupID = GroupID, @UserID = UserID
		FROM [Profile.Data].[Group.Member]
		WHERE MemberRoleID = @MemberRoleID

	-- Convert URIs and NodeIDs to GroupID
 	IF (@GroupNodeID IS NULL) AND (@GroupURI IS NOT NULL)
		SELECT @GroupNodeID = [RDF.].fnURI2NodeID(@GroupURI)
 	IF (@GroupID IS NULL) AND (@GroupNodeID IS NOT NULL)
		SELECT @GroupID = CAST(m.InternalID AS INT)
			FROM [RDF.Stage].[InternalNodeMap] m, [RDF.].Node n
			WHERE m.Status = 3 AND m.ValueHash = n.ValueHash AND n.NodeID = @GroupNodeID
	IF @GroupNodeID IS NULL
		SELECT @GroupNodeID = NodeID
			FROM [RDF.Stage].InternalNodeMap
			WHERE Class = 'http://xmlns.com/foaf/0.1/Group' AND InternalType = 'Group' AND InternalID = @GroupID

	-- Convert URIs and NodeIDs to UserID
 	IF (@UserNodeID IS NULL) AND (@UserURI IS NOT NULL)
		SELECT @UserNodeID = [RDF.].fnURI2NodeID(@UserURI)
 	IF (@UserID IS NULL) AND (@UserNodeID IS NOT NULL)
		SELECT @UserID = CAST(m.InternalID AS INT)
			FROM [RDF.Stage].[InternalNodeMap] m, [RDF.].Node n
			WHERE m.Status = 3 AND m.ValueHash = n.ValueHash AND n.NodeID = @UserNodeID
	IF @UserNodeID IS NULL
		SELECT @UserNodeID = NodeID
			FROM [RDF.Stage].InternalNodeMap
			WHERE Class = 'http://profiles.catalyst.harvard.edu/ontology/prns#User' AND InternalType = 'User' AND InternalID = @UserID

	-- Convert the UserID to a PersonNodeID
	DECLARE @PersonNodeID BIGINT
	SELECT @PersonNodeID = m.NodeID
		FROM [User.Account].[User] u
			INNER JOIN [RDF.Stage].InternalNodeMap m
				ON m.Class = 'http://xmlns.com/foaf/0.1/Person' AND InternalType = 'Person' AND InternalID = u.PersonID
		WHERE u.UserID = @UserID AND u.PersonID IS NOT NULL

	IF @PersonNodeID IS NULL
		RETURN;

	-------------------------------------------------
	-- Create or update the membership
	-------------------------------------------------

	DECLARE @IsActive BIT
	SELECT @MemberRoleID = MemberRoleID, @IsActive = IsActive
		FROM [Profile.Data].[Group.Member] 
		WHERE GroupID=@GroupID AND UserID=@UserID

	DECLARE @labelNodeID BIGINT
	DECLARE @SecurityGroupID BIGINT


	-- Check if this is a new member
	IF @MemberRoleID IS NULL
	BEGIN
		-- Create a MemberRoleID
		SELECT @MemberRoleID = CAST(NEWID() AS VARCHAR(50))
		-- Validate the title
		SELECT @Title = ISNULL(NULLIF(@Title,''),'Member')
		-- Add the new member
		INSERT INTO [Profile.Data].[Group.Member] (MemberRoleID, GroupID, UserID, IsActive, IsApproved, IsVisible, Title)
			SELECT @MemberRoleID, @GroupID, @UserID, 1, ISNULL(@IsApproved,1), ISNULL(@IsVisible,1), @Title

		-- Order the members
		UPDATE x
		SET x.SortOrder = x.memberSort
			FROM (
                SELECT MemberRoleID, SortOrder, ROW_NUMBER () OVER ( ORDER BY lastname, firstname) AS memberSort FROM [Profile.Data].[Group.Member] m
				JOIN [User.Account].[User] u ON m.UserID = u.UserID				
				AND GroupID = @GroupID
			) x

		DECLARE @SortOrder BIGINT
		SELECT @SortOrder = SortOrder FROM [Profile.Data].[Group.Member] where MemberRoleID = @MemberRoleID

		----------------------------------
		-- Create the MemberRole RDF
		----------------------------------
		-- Get the Group's ViewSecurityGroup
		SELECT @SecurityGroupID = ViewSecurityGroup
			FROM [Profile.Data].[Group.General]
			WHERE GroupID = @GroupID
		-- Create the NodeID (hidden by default)
		EXEC [RDF.].GetStoreNode @Class = 'http://vivoweb.org/ontology/core#MemberRole', @InternalType = 'MemberRole', @InternalID = @MemberRoleID,
			@ViewSecurityGroup = @SecurityGroupID, @EditSecurityGroup = -40,
			@SessionID = @SessionID, @Error = @Error OUTPUT, @NodeID = @MemberRoleNodeID OUTPUT
		-- Add the class types
		EXEC [RDF.].GetStoreTriple	@SubjectID = @MemberRoleNodeID,
									@PredicateURI = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type',
									@ObjectURI = 'http://vivoweb.org/ontology/core#MemberRole',
									@ViewSecurityGroup = -1,
									@Weight = 1,
									@SessionID = @SessionID,
									@Error = @Error OUTPUT
		EXEC [RDF.].GetStoreTriple	@SubjectID = @MemberRoleNodeID,
									@PredicateURI = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type',
									@ObjectURI = 'http://vivoweb.org/ontology/core#Role',
									@ViewSecurityGroup = -1,
									@Weight = 1,
									@SessionID = @SessionID,
									@Error = @Error OUTPUT
		-- Add the title (label)
		EXEC [RDF.].GetStoreNode	@Value = @Title, 
									@Language = NULL,
									@DataType = NULL,
									@SessionID = @SessionID, 
									@Error = @Error OUTPUT, 
									@NodeID = @labelNodeID OUTPUT
		EXEC [RDF.].GetStoreTriple	@SubjectID = @MemberRoleNodeID,
									@PredicateURI = 'http://www.w3.org/2000/01/rdf-schema#label',
									@ObjectID = @labelNodeID,
									@SessionID = @SessionID,
									@Error = @Error OUTPUT
		-- Link the MemberRole to the Group and the Person
		EXEC [RDF.].GetStoreTriple	@SubjectID = @MemberRoleNodeID,
									@PredicateURI = 'http://vivoweb.org/ontology/core#roleContributesTo',
									@ObjectID = @GroupNodeID,
									@SessionID = @SessionID,
									@Error = @Error OUTPUT
		EXEC [RDF.].GetStoreTriple	@SubjectID = @MemberRoleNodeID,
									@PredicateURI = 'http://vivoweb.org/ontology/core#memberRoleOf',
									@ObjectID = @PersonNodeID,
									@SessionID = @SessionID,
									@Error = @Error OUTPUT
		-- Link the Group and the Person to the MemberRole
		EXEC [RDF.].GetStoreTriple	@SubjectID = @GroupNodeID,
									@PredicateURI = 'http://vivoweb.org/ontology/core#contributingRole',
									@ObjectID = @MemberRoleNodeID,
									@SessionID = @SessionID,
									@SortOrder = @SortOrder,
									@Error = @Error OUTPUT
		EXEC [RDF.].GetStoreTriple	@SubjectID = @PersonNodeID,
									@PredicateURI = 'http://vivoweb.org/ontology/core#hasMemberRole',
									@ObjectID = @MemberRoleNodeID,
									@SessionID = @SessionID,
									@Error = @Error OUTPUT
	END
	ELSE
	BEGIN
		-- Update an existing member
		SELECT @MemberRoleNodeID = NodeID
			FROM [RDF.Stage].InternalNodeMap
			WHERE Class = 'http://vivoweb.org/ontology/core#MemberRole' AND InternalType = 'MemberRole' AND InternalID = @MemberRoleID
		-- Confirm the MemberRole NodeID exists
		IF @MemberRoleNodeID IS NULL
			RETURN;
		-- Activate an inactive member
		IF @IsActive = 0
		BEGIN
			UPDATE [Profile.Data].[Group.Member] 
				SET IsActive = 1
				WHERE MemberRoleID = @MemberRoleID
			SELECT @SecurityGroupID = ViewSecurityGroup
				FROM [Profile.Data].[Group.General]
				WHERE GroupID = @GroupID
			UPDATE [RDF.].[Node]
				SET ViewSecurityGroup = @SecurityGroupID
				WHERE NodeID = @MemberRoleNodeID
		END
		-- Update the title
		IF (ISNULL(@Title,'')<>'')
		BEGIN
			-- Update the General table
			UPDATE [Profile.Data].[Group.Member] 
				SET Title = @Title
				WHERE MemberRoleID = @MemberRoleID
			-- Get the NodeID for the label
			EXEC [RDF.].GetStoreNode	@Value = @Title, 
										@Language = NULL,
										@DataType = NULL,
										@SessionID = @SessionID, 
										@Error = @Error OUTPUT, 
										@NodeID = @labelNodeID OUTPUT
			-- Check if a label already exists
			DECLARE @ExistingTripleID BIGINT
			SELECT @ExistingTripleID = TripleID
				FROM [RDF.].[Triple]
				WHERE Subject = @MemberRoleNodeID AND Predicate = [RDF.].fnURI2NodeID('http://www.w3.org/2000/01/rdf-schema#label')
			IF @ExistingTripleID IS NOT NULL
			BEGIN
				-- Update an existing label
				UPDATE [RDF.].[Triple]
					SET Object = @labelNodeID
					WHERE TripleID = @ExistingTripleID
			END
			ELSE
			BEGIN
				-- Create a new label
				EXEC [RDF.].GetStoreTriple	@SubjectID = @MemberRoleNodeID,
											@PredicateURI = 'http://www.w3.org/2000/01/rdf-schema#label',
											@ObjectID = @labelNodeID,
											@SessionID = @SessionID,
											@Error = @Error OUTPUT
			END

		END
	END
	
	EXEC [Profile.Data].[Publication.Entity.UpdateEntityOneGroup] @GroupID=@GroupID

	SELECT @NodeID = @MemberRoleNodeID

END



GO
