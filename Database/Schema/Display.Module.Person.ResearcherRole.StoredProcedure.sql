SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[Person.ResearcherRole]
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@count int = 50,
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN
	declare @personID int
	select @personID = [RDF.].[fnNodeID2PersonID](@Subject)

	select @json = (
		SELECT
			AgreementLabel,
			EndDate,
			FundingID,
			GrantAwardedBy,
			PrincipalInvestigatorName,
			RoleDescription,
			RoleLabel,
			StartDate,
			ROW_NUMBER() over (order by StartDate desc, EndDate desc, FundingID) Sort
		FROM [Profile.Data].[Funding.Role] r 
			INNER JOIN [Profile.Data].[Funding.Agreement] a
				ON r.FundingAgreementID = a.FundingAgreementID
					AND r.PersonID = @PersonID
		for json path, ROOT ('module_data'))
END
GO
