SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 
CREATE PROCEDURE [ORCID.].[cg2_REFPermissionAdd]

    @PermissionID  INT =NULL OUTPUT 
    , @PermissionScope  VARCHAR(100) 
    , @PermissionDescription  VARCHAR(500) 
    , @MethodAndRequest  VARCHAR(100) =NULL
    , @SuccessMessage  VARCHAR(1000) =NULL
    , @FailedMessage  VARCHAR(1000) =NULL

AS


    DECLARE @intReturnVal INT 
    SET @intReturnVal = 0
    DECLARE @strReturn  Varchar(200) 
    SET @intReturnVal = 0
    DECLARE @intRecordLevelAuditTrailID INT 
    DECLARE @intFieldLevelAuditTrailID INT 
    DECLARE @intTableID INT 
    SET @intTableID = 3722
 
  
        INSERT INTO [ORCID.].[REF_Permission]
        (
            [PermissionScope]
            , [PermissionDescription]
            , [MethodAndRequest]
            , [SuccessMessage]
            , [FailedMessage]
        )
        (
            SELECT
            @PermissionScope
            , @PermissionDescription
            , @MethodAndRequest
            , @SuccessMessage
            , @FailedMessage
        )
   
        SET @intReturnVal = @@error
        SET @PermissionID = @@IDENTITY
        IF @intReturnVal <> 0
        BEGIN
            RAISERROR (N'An error occurred while adding the REF_Permission record.', 11, 11); 
            RETURN @intReturnVal 
        END



GO
