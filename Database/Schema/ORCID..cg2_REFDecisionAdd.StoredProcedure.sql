SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 
CREATE PROCEDURE [ORCID.].[cg2_REFDecisionAdd]

    @DecisionID  INT =NULL OUTPUT 
    , @DecisionDescription  VARCHAR(150) 
    , @DecisionDescriptionLong  VARCHAR(500) 

AS


    DECLARE @intReturnVal INT 
    SET @intReturnVal = 0
    DECLARE @strReturn  Varchar(200) 
    SET @intReturnVal = 0
    DECLARE @intRecordLevelAuditTrailID INT 
    DECLARE @intFieldLevelAuditTrailID INT 
    DECLARE @intTableID INT 
    SET @intTableID = 3730
 
  
        INSERT INTO [ORCID.].[REF_Decision]
        (
            [DecisionDescription]
            , [DecisionDescriptionLong]
        )
        (
            SELECT
            @DecisionDescription
            , @DecisionDescriptionLong
        )
   
        SET @intReturnVal = @@error
        SET @DecisionID = @@IDENTITY
        IF @intReturnVal <> 0
        BEGIN
            RAISERROR (N'An error occurred while adding the REF_Decision record.', 11, 11); 
            RETURN @intReturnVal 
        END



GO
