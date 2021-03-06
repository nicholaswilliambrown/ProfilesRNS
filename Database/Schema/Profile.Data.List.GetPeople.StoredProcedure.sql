SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Profile.Data].[List.GetPeople]
	@UserID INT=NULL,
	@Institution VARCHAR(1000)=NULL,
	@FacultyRank VARCHAR(100)=NULL,
	@ReturnInstitutions BIT=0,
	@ReturnFacultyRanks BIT=0,
	@Offset INT=0,
	@Limit INT=100000,
	@NumPeople INT=NULL OUTPUT
AS
BEGIN

	-- Create a temp table to store the list
	CREATE TABLE #p (
		SortOrder INT IDENTITY(0,1) PRIMARY KEY,
		PersonID INT NOT NULL,
		FirstName VARCHAR(100),
		LastName VARCHAR(100),
		DisplayName VARCHAR(510),
		InstitutionName VARCHAR(1000),
		FacultyRank VARCHAR(100),
		FacultyRankSort TINYINT,
		DepartmentName VARCHAR(1000)
	)

	SELECT @FacultyRank = CASE WHEN @FacultyRank = '--' THEN '' ELSE @FacultyRank END

	-- Get the list of people
	INSERT INTO #p (PersonID, FirstName, LastName, DisplayName, InstitutionName, FacultyRank, FacultyRankSort, DepartmentName)
		SELECT m.PersonID, p.FirstName, p.LastName, p.DisplayName, p.InstitutionName, p.FacultyRank, p.FacultyRankSort, p.DepartmentName
		FROM [Profile.Data].[List.Member] m 
			INNER JOIN [Profile.Cache].[Person] p
				ON m.UserID = @UserID AND m.PersonID = p.PersonID
		WHERE
			(CASE WHEN @Institution IS NULL THEN 1
				WHEN @Institution = p.InstitutionName THEN 1
				ELSE 0 END)
			+(CASE WHEN @FacultyRank IS NULL THEN 1
				WHEN @FacultyRank = p.FacultyRank THEN 1
				ELSE 0 END)
			=2
		ORDER BY LastName, FirstName, DisplayName, PersonID

	-- Determine the number of people
	SELECT @NumPeople=(SELECT COUNT(*) FROM #p)

	-- Return the institutions
	IF (@ReturnInstitutions=1)
		SELECT InstitutionName, COUNT(*) n
		FROM #p
		--FROM [Profile.Data].[List.Member] m 
		--	INNER JOIN [Profile.Cache].[Person] p
		--		ON ListID = @ListID AND m.PersonID = p.PersonID
		GROUP BY InstitutionName
		ORDER BY InstitutionName

	-- Return the faculty ranks
	IF (@ReturnFacultyRanks=1)
		SELECT FacultyRank, n
		FROM (
			SELECT FacultyRank, FacultyRankSort, COUNT(*) n
			FROM #p
			--FROM [Profile.Data].[List.Member] m 
			--	INNER JOIN [Profile.Cache].[Person] p
			--		ON ListID = @ListID AND m.PersonID = p.PersonID
			GROUP BY FacultyRank, FacultyRankSort
		) t
		ORDER BY FacultyRankSort

	-- Return the people
	SELECT PersonID, DisplayName, FirstName, LastName, InstitutionName, FacultyRank, DepartmentName
		FROM #p
		WHERE SortOrder>=@Offset AND SortOrder<@Offset+@Limit
		ORDER BY SortOrder

END


GO
