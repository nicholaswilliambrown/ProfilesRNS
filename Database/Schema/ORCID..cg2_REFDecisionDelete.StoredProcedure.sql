SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [ORCID.].[cg2_REFDecisionDelete]
 
    @DecisionID  INT 

 
AS
 
    DECLARE @intReturnVal INT 
    SET @intReturnVal = 0
 
 
        DELETE FROM [ORCID.].[REF_Decision] WHERE         [ORCID.].[REF_Decision].[DecisionID] = @DecisionID

 
        SET @intReturnVal = @@error
        IF @intReturnVal <> 0
        BEGIN
            RAISERROR (N'An error occurred while deleting the REF_Decision record.', 11, 11); 
            RETURN @intReturnVal 
        END
    RETURN @intReturnVal



GO
