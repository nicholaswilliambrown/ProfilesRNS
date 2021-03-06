SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Profile.Data].[List.GetList]
	@SessionID UNIQUEIDENTIFIER,
	@ListID INT=NULL OUTPUT,
	@Size INT=NULL OUTPUT
AS
BEGIN

	-- Convert SessionID to UserID
	DECLARE @UserID INT
	SELECT @UserID = UserID
		FROM [User.Session].[Session]
		WHERE SessionID = @SessionID

	-- Exit if there is no user account
	IF @UserID IS NULL
		RETURN;

	-- Get existing list info
	SELECT @ListID = UserID, @Size = Size
		FROM [Profile.Data].[List.General]
		WHERE UserID = @UserID

	-- Create a new list if needed
	IF @ListID IS NULL
	BEGIN
		INSERT INTO [Profile.Data].[List.General] (UserID, Size, CreateDate)
			SELECT @UserID, 0, GetDate()
		SELECT @ListID = @UserID, @Size = 0
	END

END


GO
