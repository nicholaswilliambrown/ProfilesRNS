SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [Display.Module].[Person.HasResearchArea.Why]
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN
	declare @personID int, @displayName nvarchar(max), @Name nvarchar(max), @relativeBasePath varchar(max), @PersonDefaultApplication varchar(max), @PersonPreferredPath varchar(max),
		@MeshHeader varchar(max), @ConceptDefaultApplication varchar(max), @ConceptPreferredPath varchar(max), @weight float

	select @personID = PersonID, @displayName = DisplayName,  @Name = FirstName + ' ' + LastName, @PersonDefaultApplication = defaultApplication, @PersonPreferredPath = PreferredPath from [Profile.Cache].Person where NodeID = @Subject
	select @MeshHeader = DescriptorName,  @ConceptDefaultApplication = DefaultApplication, @ConceptPreferredPath = URL  from [Profile.Cache].[Concept.Mesh.URL] where NodeID = @object

	select @weight = Weight from [Profile.Cache].[Concept.Mesh.Person] where PersonID = @personID and MeshHeader = @MeshHeader

select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'

	select @json = (select @personID PersonID, @Name Name, @displayName DisplayName, @relativeBasePath + isnull(@PersonDefaultApplication, '') + @PersonPreferredPath as PersonURL, 
							@MeshHeader Concept, @relativeBasePath + isnull(@ConceptDefaultApplication, '') + @ConceptPreferredPath as ConceptURL, Round(@weight, 3) Weight,
							@relativeBasePath + isnull(@PersonDefaultApplication, '') + @PersonPreferredPath + '/Network/ResearchAreas/Details' as BackToURL, 
							 (select a.PMID, b.PMCID, b.DOI, c.AuthorsString, b.Reference, Round(a.MeshWeight, 3) as Weight from [Profile.Cache].[Concept.Mesh.PersonPublication] a
									join [Profile.Data].[Publication.Entity.InformationResource] b on a.pmid = b.pmid
									join [Profile.Data].[Publication.Entity.Authorship] c on b.EntityID = c.InformationResourceID and c.PersonID = @PersonID
									where a.personID = @PersonID and MeshHeader = @MeshHeader for json path) Publications
							for json path, WITHOUT_ARRAY_WRAPPER)
	select @json = (select JSON_QUERY(@json, '$') as module_data for json path, WITHOUT_ARRAY_WRAPPER)
END
GO
