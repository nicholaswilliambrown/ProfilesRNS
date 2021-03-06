SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 
CREATE PROCEDURE [ORCID.].[cg2_PersonURLEdit]

    @PersonURLID  INT =NULL OUTPUT 
    , @PersonID  INT 
    , @PersonMessageID  INT =NULL
    , @URLName  VARCHAR(500) =NULL
    , @URL  VARCHAR(2000) 
    , @DecisionID  INT 

AS


    DECLARE @intReturnVal INT 
    SET @intReturnVal = 0
    DECLARE @strReturn  Varchar(200) 
    SET @intReturnVal = 0
    DECLARE @intRecordLevelAuditTrailID INT 
    DECLARE @intFieldLevelAuditTrailID INT 
    DECLARE @intTableID INT 
    SET @intTableID = 3621
 
  
        UPDATE [ORCID.].[PersonURL]
        SET
            [PersonID] = @PersonID
            , [PersonMessageID] = @PersonMessageID
            , [URLName] = @URLName
            , [URL] = @URL
            , [DecisionID] = @DecisionID
        FROM
            [ORCID.].[PersonURL]
        WHERE
        [ORCID.].[PersonURL].[PersonURLID] = @PersonURLID

        
        SET @intReturnVal = @@error
        IF @intReturnVal <> 0
        BEGIN
            RAISERROR (N'An error occurred while editing the PersonURL record.', 11, 11); 
            RETURN @intReturnVal 
        END



GO
