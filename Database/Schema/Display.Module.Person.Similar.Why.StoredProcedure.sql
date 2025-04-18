SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[Person.Similar.Why]
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
		@personID2 int, @displayName2 nvarchar(max), @Name2 nvarchar(max), @PersonDefaultApplication2 varchar(max), @PersonPreferredPath2 varchar(max), @weight float

	select @personID = PersonID, @displayName = DisplayName,  @Name = FirstName + ' ' + LastName, @PersonDefaultApplication = defaultApplication, @PersonPreferredPath = PreferredPath from [Profile.Cache].Person where NodeID = @Subject
	select @personID2 = PersonID, @displayName2 = DisplayName,  @Name2 = FirstName + ' ' + LastName, @PersonDefaultApplication2 = defaultApplication, @PersonPreferredPath2 = PreferredPath from [Profile.Cache].Person where NodeID = @object

	select @weight = w from [Profile.Cache].[SNA.Coauthor] where PersonID1 = @personID and PersonID2 = @personID2

	select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'

	select a.pmid, (a.authorweight * b.authorweight * a.YearWeight) w
		into #pmids
		from [Profile.Cache].[Publication.PubMed.AuthorPosition] a, [Profile.Cache].[Publication.PubMed.AuthorPosition] b
		where a.pmid = b.pmid and a.personid = @PersonID and b.personid = @PersonID2

	select @json = (select @personID PersonID, @Name Name, @displayName DisplayName, @relativeBasePath + isnull(@PersonDefaultApplication, '') + @PersonPreferredPath as PersonURL,
						@relativeBasePath + isnull(@PersonDefaultApplication, '') + @PersonPreferredPath + '/Network/SimilarTo/Details' as BackToURL, 
						@Name2 Name2, @displayName2 DisplayName2, @relativeBasePath + isnull(@PersonDefaultApplication2, '') + @PersonPreferredPath2 as PersonURL2, Round(@weight, 3) Weight, '/Concept/ResearchAreas/' NetworkPath,
							 (select a.MeshHeader Concept, ROUND(a.Weight, 3) as Person1Weight, ROUND(b.Weight, 3) as Person2Weight, ROUND(a.Weight * b.weight, 3) as Score, DefaultApplication + URL as ConceptPath
									from [Profile.Cache].[Concept.Mesh.Person] a 
									join [Profile.Cache].[Concept.Mesh.Person] b 
										on a.PersonID = @personID and b.PersonID = @personID2 and a.MeshHeader = b.MeshHeader
									join [Profile.Cache].[Concept.Mesh.URL] c 
										on a.MeshHeader = c.DescriptorName
									for json path) Concepts
							for json path, WITHOUT_ARRAY_WRAPPER)
	select @json = (select JSON_QUERY(@json, '$') as module_data for json path, WITHOUT_ARRAY_WRAPPER)
END
GO
