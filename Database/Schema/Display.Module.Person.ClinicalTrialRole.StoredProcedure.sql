SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Person.ClinicalTrialRole]
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
		select a.clinicalTrialRoleID, a.ClinicalTrialID, a.ID_Source, rtrim(Brief_title) Brief_title, brief_summary, rtrim(overall_status) overall_status, rtrim(Phase) Phase, completion_date, start_date, 
			(select InterventionType, InterventionName, InterventionSort FROM [Profile.Data].[ClinicalTrial.Study.Intervention] WHERE ClinicalTrialID = a.ClinicalTrialID for json path) Interventions,
			(select Condition, ConditionSort FROM [Profile.Data].[ClinicalTrial.Study.Condition] WHERE ClinicalTrialID = a.ClinicalTrialID for json path) Conditions
		From [Profile.Data].[ClinicalTrial.Person.Include] a
			join [Profile.Data].[ClinicalTrial.Study] b
			on a.ClinicalTrialID = b.ClinicalTrialID
			and a.ID_Source = b.ID_Source
			and a.PersonID = @PersonID
			for json path, ROOT ('module_data'))
END
GO
