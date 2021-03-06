SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Profile.Data].[Publication.SetGroupOption]
	@GroupID INT=NULL,
	@IncludeMemberPublications INT=0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DELETE FROM [Profile.Data].[Publication.Group.Option] WHERE GroupID = @GroupID
	INSERT INTO [Profile.Data].[Publication.Group.Option] (GroupID, IncludeMemberPublications) VALUES (@GroupID, @IncludeMemberPublications)
	
	EXEC [Profile.Data].[Publication.Entity.UpdateEntityOneGroup] @GroupID=@GroupID
END

GO
