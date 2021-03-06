SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 
CREATE PROCEDURE [ORCID.].[cg2_PersonTokenEdit]

    @PersonTokenID  INT =NULL OUTPUT 
    , @PersonID  INT 
    , @PermissionID  INT 
    , @AccessToken  VARCHAR(50) 
    , @TokenExpiration  SMALLDATETIME 
    , @RefreshToken  VARCHAR(50) =NULL

AS


    DECLARE @intReturnVal INT 
    SET @intReturnVal = 0
    DECLARE @strReturn  Varchar(200) 
    SET @intReturnVal = 0
    DECLARE @intRecordLevelAuditTrailID INT 
    DECLARE @intFieldLevelAuditTrailID INT 
    DECLARE @intTableID INT 
    SET @intTableID = 3595
 
  
        UPDATE [ORCID.].[PersonToken]
        SET
            [PersonID] = @PersonID
            , [PermissionID] = @PermissionID
            , [AccessToken] = @AccessToken
            , [TokenExpiration] = @TokenExpiration
            , [RefreshToken] = @RefreshToken
        FROM
            [ORCID.].[PersonToken]
        WHERE
        [ORCID.].[PersonToken].[PersonTokenID] = @PersonTokenID

        
        SET @intReturnVal = @@error
        IF @intReturnVal <> 0
        BEGIN
            RAISERROR (N'An error occurred while editing the PersonToken record.', 11, 11); 
            RETURN @intReturnVal 
        END



GO
