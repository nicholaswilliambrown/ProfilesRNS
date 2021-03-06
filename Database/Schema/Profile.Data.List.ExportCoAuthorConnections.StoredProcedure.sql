SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Profile.Data].[List.ExportCoAuthorConnections] 
	@UserID int
AS
BEGIN

	SELECT Data 
	FROM (
		SELECT 0 x, 0 PersonID1, 0 PersonID2, '"PersonID 1","PersonID 2","First Name 1","Last Name 1","Display Name 1","First Name 2","Last Name 2","Display Name 2"'
				+',"CoAuthored Publications","First CoAuthored Publication","Last CoAuthored Publication"' AS Data
		UNION
		SELECT 1 x, m1.PersonID, m2.PersonID,
				CAST(m1.PersonID AS VARCHAR(50))
				+ ',' + CAST(m2.PersonID as varchar(MAX))
				+ ',"' + REPLACE(p1.FirstName,'"','""') + '"'
				+ ',"' + REPLACE(p1.LastName,'"','""') + '"'
				+ ',"' + REPLACE(p1.DisplayName,'"','""') + '"'
				+ ',"' + REPLACE(p2.FirstName,'"','""') + '"'
				+ ',"' + REPLACE(p2.LastName,'"','""') + '"'
				+ ',"' + REPLACE(p2.DisplayName,'"','""') + '"'
				+ ',' + CAST(n AS VARCHAR(50))
				+ ',"' + CONVERT(VARCHAR(50), FirstPubDate, 101) + '"'
				+ ',"' + CONVERT(VARCHAR(50), LastPubDate, 101) + '"'
			FROM [Profile.Cache].[SNA.Coauthor] c 
				INNER JOIN [Profile.Data].[List.Member] m1 ON c.PersonID1 = m1.PersonID  AND m1.UserID = @UserID
				INNER JOIN [Profile.Data].[List.Member] m2 ON c.PersonID2 = m2.PersonID AND m2.UserID = @UserID
				INNER JOIN [Profile.Cache].[Person] p1 ON PersonID1 = p1.PersonID
				INNER JOIN [Profile.Cache].[Person] p2 ON PersonID2 = p2.PersonID
			WHERE c.PersonID1 < c.PersonID2
	) t
	ORDER BY x, PersonID1, PersonID2

END


GO
