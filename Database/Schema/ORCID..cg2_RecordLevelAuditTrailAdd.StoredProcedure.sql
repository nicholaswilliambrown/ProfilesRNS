SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 
CREATE PROCEDURE [ORCID.].[cg2_RecordLevelAuditTrailAdd]

    @RecordLevelAuditTrailID  BIGINT =NULL OUTPUT 
    , @MetaTableID  INT 
    , @RowIdentifier  BIGINT 
    , @RecordLevelAuditTypeID  INT 
    , @CreatedDate  SMALLDATETIME 
    , @CreatedBy  VARCHAR(10) 

AS


    DECLARE @intReturnVal INT 
    SET @intReturnVal = 0
    DECLARE @strReturn  Varchar(200) 
    SET @intReturnVal = 0
 
  
        INSERT INTO [ORCID.].[RecordLevelAuditTrail]
        (
            [MetaTableID]
            , [RowIdentifier]
            , [RecordLevelAuditTypeID]
            , [CreatedDate]
            , [CreatedBy]
        )
        (
            SELECT
            @MetaTableID
            , @RowIdentifier
            , @RecordLevelAuditTypeID
            , @CreatedDate
            , @CreatedBy
        )
   
        SET @intReturnVal = @@error
        SET @RecordLevelAuditTrailID = @@IDENTITY
        IF @intReturnVal <> 0
        BEGIN
            RAISERROR (N'An error occurred while adding the RecordLevelAuditTrail record.', 11, 11); 
            RETURN @intReturnVal 
        END



GO
