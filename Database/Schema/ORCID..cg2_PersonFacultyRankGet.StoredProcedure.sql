SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [ORCID.].[cg2_PersonFacultyRankGet]
 
    @FacultyRankID  INT 

AS
 
    SELECT TOP 100 PERCENT
        [Profile.Data].[Person.FacultyRank].[FacultyRankID]
        , [Profile.Data].[Person.FacultyRank].[FacultyRank]
        , [Profile.Data].[Person.FacultyRank].[FacultyRankSort]
        , [Profile.Data].[Person.FacultyRank].[Visible]
    FROM
        [Profile.Data].[Person.FacultyRank]
    WHERE
        [Profile.Data].[Person.FacultyRank].[FacultyRankID] = @FacultyRankID



GO
