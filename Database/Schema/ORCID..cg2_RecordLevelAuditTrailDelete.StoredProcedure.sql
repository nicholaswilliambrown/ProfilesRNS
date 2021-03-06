SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [ORCID.].[cg2_RecordLevelAuditTrailDelete]
 
    @RecordLevelAuditTrailID  BIGINT 

 
AS
 
    DECLARE @intReturnVal INT 
    SET @intReturnVal = 0
 
 
        DELETE FROM [ORCID.].[RecordLevelAuditTrail] WHERE         [ORCID.].[RecordLevelAuditTrail].[RecordLevelAuditTrailID] = @RecordLevelAuditTrailID

 
        SET @intReturnVal = @@error
        IF @intReturnVal <> 0
        BEGIN
            RAISERROR (N'An error occurred while deleting the RecordLevelAuditTrail record.', 11, 11); 
            RETURN @intReturnVal 
        END
    RETURN @intReturnVal



GO
