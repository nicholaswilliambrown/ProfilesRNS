CREATE PROCEDURE [Profile.Data].[List.AddRemove.CoAuthors]
	@UserID int,
	@Action varchar(55),
	@Size int output
AS
BEGIN

	SELECT DISTINCT personID2 as PersonID into #coauthors FROM [Profile.Data].[List.Member] m
	JOIN [Profile.Cache].[SNA.Coauthor] c
	ON m.PersonID = c.PersonID1
	AND m.UserID = @UserID
	AND c.PersonID2 NOT IN (SELECT PersonID FROM [Profile.Data].[List.Member] m2 WHERE m2.UserID = @UserID)	

		-- Add or Remove
	IF (@Action = 'Add')
	BEGIN
		BEGIN TRANSACTION
			--DELETE FROM #coauthors WHERE PersonID in (SELECT PersonID FROM [Profile.Data].[List.Member] WHERE UserID = @UserID)
			INSERT INTO [Profile.Data].[List.Member] (UserID, PersonID)
				SELECT @UserID, PersonID from #coauthors

			-- Update list size
			SELECT @Size =  COUNT(*) FROM [Profile.Data].[List.Member] WHERE UserID=@UserID
			UPDATE [Profile.Data].[List.General] SET Size = @Size WHERE UserID = @UserID
		COMMIT TRANSACTION
	END
		-- Add or Remove
	IF (@Action = 'Replace')
	BEGIN
		BEGIN TRANSACTION
			DELETE FROM [Profile.Data].[List.Member] WHERE UserID = @UserID
			INSERT INTO [Profile.Data].[List.Member] (UserID, PersonID)
			SELECT @UserID, PersonID from #coauthors

			-- Update list size
			SELECT @Size =  COUNT(*) FROM [Profile.Data].[List.Member] WHERE UserID=@UserID
			UPDATE [Profile.Data].[List.General] SET Size = @Size WHERE UserID = @UserID
		COMMIT TRANSACTION
	END	
END;
GO
CREATE PROCEDURE [Profile.Data].[List.SavedLists.AddUpdateList]
	@ListID [int] = -1,
	@Action varchar(55),
	@UserID [int] = -1,
	@Name varchar(max) = ''
AS
BEGIN
	-- Actions: Save( name), Replace, Rename (name), Delete (), 
	insert into [Debug.].DebugLog (Date, ProcedureName, LocationID, Message) values (GETDATE(), '[Profile.Data].[List.SavedLists.AddUpdateList]', 1, 'ListID: ' + cast (@listID as varchar(50)) + '    Action: ' + @Action + '     UserID: ' + Cast(@UserID as varchar(50)) + '    Name: ' + @Name)
	DECLARE @Size int

	IF @Action = 'Save' AND @UserID <> -1
	BEGIN
		SELECT @Size = isnull(Size, 0)
			FROM [Profile.Data].[List.General]
			WHERE UserID = @UserID

		BEGIN TRANSACTION
			DECLARE @ListIDTable TABLE (ListID int)
			INSERT INTO [Profile.Data].[List.SavedLists.General] (UserID, Name, CreateDate, UpdatedDate, Size)
				OUTPUT inserted.ListID into @ListIDTable
				VALUES(@UserID, @Name, GETDATE(), GETDATE(), @Size)

			INSERT INTO [Profile.Data].[List.SavedLists.Member] (ListID, PersonID) 
				SELECT ListID, PersonID FROM [Profile.Data].[List.Member] a JOIN @ListIDTable b
				ON a.UserID = @UserID
		COMMIT TRANSACTION
	END

	ELSE IF @Action = 'Replace' AND @UserID <> -1 AND @ListID <> -1
	BEGIN
		SELECT @Size = isnull(Size, 0)
			FROM [Profile.Data].[List.General]
			WHERE UserID = @UserID
		BEGIN TRANSACTION
			UPDATE [Profile.Data].[List.SavedLists.General] SET Size = @Size, UpdatedDate =  GETDATE() WHERE ListID = @ListID
			DELETE FROM [Profile.Data].[List.SavedLists.Member] WHERE ListID = @ListID
			INSERT INTO [Profile.Data].[List.SavedLists.Member] (ListID, PersonID) 
				SELECT @ListID, PersonID FROM [Profile.Data].[List.Member] a WHERE a.UserID = @UserID
		COMMIT TRANSACTION
	END

	IF @Action = 'Rename' AND @ListID <> -1 AND @Name <> ''
	BEGIN
		UPDATE [Profile.Data].[List.SavedLists.General] SET Name = @Name, UpdatedDate =  GETDATE() WHERE ListID = @ListID
	END

	IF @Action = 'Delete' AND @ListID <> -1
	BEGIN
		BEGIN TRANSACTION
			DELETE FROM [Profile.Data].[List.SavedLists.General] WHERE ListID = @ListID
			DELETE FROM [Profile.Data].[List.SavedLists.Member] WHERE ListID = @ListID
		COMMIT TRANSACTION
	END
END;
GO

CREATE PROCEDURE [Profile.Data].[List.SavedLists.GetLists]
	@UserID int,
	@ListIDs varchar(max) = null
AS
BEGIN
	if @ListIDs is not null
	BEGIN
		select b.ListID, b.Name from (
		SELECT Split.a.value('.', 'VARCHAR(100)') ListID
			FROM ( select CAST('<c>' + REPLACE(@ListIDs, ',', '</c><c>') + '</c>' as XML) as A) AS A CROSS APPLY A.nodes ('/c') AS Split(a)) i
			join [Profile.Data].[List.SavedLists.General] b
			on i.ListID = b.ListID
			and b.UserID = @UserID
	END
	ELSE 
	BEGIN
		SELECT [ListID]
			  ,[Name]
			  ,[CreateDate]
			  ,[UpdatedDate]
			  ,[Size]
		  FROM [Profile.Data].[List.SavedLists.General]
		  WHERE UserID = @UserID
	  END
END;
GO

CREATE PROCEDURE [Profile.Data].[List.SavedLists.ModifyActiveList]
	@ListID [int] = 0,
	@ListIDs varchar(max) = '',
	@UserID [int],
	@Action varchar(55),
	@Size INT=NULL OUTPUT
AS
BEGIN

	CREATE TABLE #ListIDs (ListID INT PRIMARY KEY)
	IF @ListID <> 0 INSERT INTO #ListIDs SELECT @ListID
	ELSE
	BEGIN
		DECLARE @xListIDs xml
		SET @xListIDs = CAST('<ID>' + REPLACE(@ListIDs, ',', '</ID><ID>') + '</ID>' as xml)
		INSERT INTO #ListIDs SELECT x.element.value ('.', 'INT') from @xListIDs.nodes('//ID') as x(element)
	END


	IF @Action = 'Replace'
	BEGIN
		BEGIN TRANSACTION
			DELETE FROM [Profile.Data].[List.Member] WHERE UserID = @UserID
			INSERT INTO [Profile.Data].[List.Member] (UserID, PersonID) 
				SELECT DISTINCT @UserID, PersonID FROM [Profile.Data].[List.SavedLists.Member] WHERE ListID IN (SELECT ListID from #ListIDs)

			SELECT @Size =  COUNT(*) FROM [Profile.Data].[List.Member] WHERE UserID=@UserID
			UPDATE [Profile.Data].[List.General] SET Size = @Size WHERE UserID = @UserID
		COMMIT TRANSACTION
	END

	IF @Action = 'Add'
	BEGIN
		BEGIN TRANSACTION
			--DELETE FROM [Profile.Data].[List.Member] WHERE UserID = @UserID
			INSERT INTO [Profile.Data].[List.Member] (UserID, PersonID) 
				SELECT DISTINCT @UserID, PersonID FROM [Profile.Data].[List.SavedLists.Member] 
				WHERE ListID IN (SELECT ListID from #ListIDs) AND PersonID NOT IN (SELECT PersonID from [Profile.Data].[List.Member] WHERE UserID = @UserID)

			SELECT @Size =  COUNT(*) FROM [Profile.Data].[List.Member] WHERE UserID=@UserID
			UPDATE [Profile.Data].[List.General] SET Size = @Size WHERE UserID = @UserID
		COMMIT TRANSACTION
	END

	IF @Action = 'Remove'
	BEGIN
		BEGIN TRANSACTION
			--DELETE FROM [Profile.Data].[List.Member] WHERE UserID = @UserID
			DELETE FROM [Profile.Data].[List.Member] WHERE UserID = @UserID AND PersonID IN (SELECT PersonID from [Profile.Data].[List.SavedLists.Member] WHERE ListID IN (SELECT ListID from #ListIDs))

			SELECT @Size =  COUNT(*) FROM [Profile.Data].[List.Member] WHERE UserID=@UserID
			UPDATE [Profile.Data].[List.General] SET Size = @Size WHERE UserID = @UserID
		COMMIT TRANSACTION
	END

	IF @Action = 'RemoveNotInAny'
	BEGIN
		BEGIN TRANSACTION
			--DELETE FROM [Profile.Data].[List.Member] WHERE UserID = @UserID
			DELETE FROM [Profile.Data].[List.Member] WHERE UserID = @UserID AND PersonID NOT IN (SELECT PersonID from [Profile.Data].[List.SavedLists.Member] WHERE ListID IN (SELECT ListID from #ListIDs))

			SELECT @Size =  COUNT(*) FROM [Profile.Data].[List.Member] WHERE UserID=@UserID
			UPDATE [Profile.Data].[List.General] SET Size = @Size WHERE UserID = @UserID
		COMMIT TRANSACTION
	END

	IF @Action = 'RemoveNotInAll'
	BEGIN
		BEGIN TRANSACTION
			DECLARE @noOfLists int 
			SELECT @noOfLists = COUNT(1) FROM #ListIDs
			SELECT PersonID INTO #Intersection FROM [Profile.Data].[List.SavedLists.Member] a JOIN #ListIDs b
				ON a.ListID = b.ListID GROUP BY PersonID
				HAVING COUNT(*) = @noOfLists

			--DELETE FROM [Profile.Data].[List.Member] WHERE UserID = @UserID
			DELETE FROM [Profile.Data].[List.Member] WHERE UserID = @UserID AND PersonID NOT IN (SELECT PersonID from #Intersection)

			SELECT @Size =  COUNT(*) FROM [Profile.Data].[List.Member] WHERE UserID=@UserID
			UPDATE [Profile.Data].[List.General] SET Size = @Size WHERE UserID = @UserID
		COMMIT TRANSACTION
	END
END;
GO