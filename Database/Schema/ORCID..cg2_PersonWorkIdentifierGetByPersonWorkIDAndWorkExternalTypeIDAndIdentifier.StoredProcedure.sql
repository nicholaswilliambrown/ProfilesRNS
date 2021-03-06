SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [ORCID.].[cg2_PersonWorkIdentifierGetByPersonWorkIDAndWorkExternalTypeIDAndIdentifier]
 
    @PersonWorkID  INT 
    , @WorkExternalTypeID  INT 
    , @Identifier  VARCHAR(250) 

AS
 
    SELECT TOP 100 PERCENT
        [ORCID.].[PersonWorkIdentifier].[PersonWorkIdentifierID]
        , [ORCID.].[PersonWorkIdentifier].[PersonWorkID]
        , [ORCID.].[PersonWorkIdentifier].[WorkExternalTypeID]
        , [ORCID.].[PersonWorkIdentifier].[Identifier]
    FROM
        [ORCID.].[PersonWorkIdentifier]
    WHERE
        [ORCID.].[PersonWorkIdentifier].[PersonWorkID] = @PersonWorkID
        AND [ORCID.].[PersonWorkIdentifier].[WorkExternalTypeID] = @WorkExternalTypeID
        AND [ORCID.].[PersonWorkIdentifier].[Identifier] = @Identifier




GO
