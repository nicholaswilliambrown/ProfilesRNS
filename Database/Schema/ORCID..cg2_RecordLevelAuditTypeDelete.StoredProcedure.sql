SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [ORCID.].[cg2_RecordLevelAuditTypeDelete]
 
    @RecordLevelAuditTypeID  INT 

 
AS
 
    DECLARE @intReturnVal INT 
    SET @intReturnVal = 0
 
 
        DELETE FROM [ORCID.].[RecordLevelAuditType] WHERE         [ORCID.].[RecordLevelAuditType].[RecordLevelAuditTypeID] = @RecordLevelAuditTypeID

 
        SET @intReturnVal = @@error
        IF @intReturnVal <> 0
        BEGIN
            RAISERROR (N'An error occurred while deleting the RecordLevelAuditType record.', 11, 11); 
            RETURN @intReturnVal 
        END
    RETURN @intReturnVal



GO
