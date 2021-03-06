SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Profile.Data].[List.UpdateAllLists]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT UserID, PersonID
		INTO #p
		FROM [Profile.Data].[List.Member]
		WHERE PersonID NOT IN (SELECT PersonID FROM [Profile.Cache].[Person])

	ALTER TABLE #p ADD PRIMARY KEY (ListID, PersonID)

	BEGIN TRANSACTION

		DELETE m
			FROM [Profile.Data].[List.Member] m
				INNER JOIN #p p ON m.UserID=p.UserID AND m.PersonID=p.PersonID

		SELECT UserID, COUNT(*) n
			INTO #l
			FROM [Profile.Data].[List.Member]
			GROUP BY UserID

		ALTER TABLE #l ADD PRIMARY KEY (UserID)

		UPDATE g
			SET g.Size=l.n
			FROM [Profile.Data].[List.General] g
				INNER JOIN #l l ON g.UserID=l.UserID AND g.Size<>l.n

		UPDATE [Profile.Data].[List.General]
			SET Size=0
			WHERE UserID NOT IN (SELECT UserID FROM #l)

	COMMIT TRANSACTION

END


GO
