SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[Person.Concept.Top5]
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN
	declare @personID int, @relativeBasePath varchar(55), @ExploreLink varchar(1000)
	select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'
	select @personID = personID, @ExploreLink = @relativeBasePath + isnull(DefaultApplication, '') + PreferredPath + '/Network/ResearchAreas' from [Profile.Cache].Person where NodeID =@Subject

	declare @count int
	select @count = count (*) from [Profile.Cache].[Concept.Mesh.Person] p join [Profile.Cache].[Concept.Mesh.URL] u on p.MeshHeader = u.DescriptorName and personID = @personID


	select @json = (select top 5 MeshHeader as Label, @relativeBasePath + isnull(DefaultApplication, '') + URL URL, ROW_NUMBER() OVER (ORDER BY Weight desc) Sort from [Profile.Cache].[Concept.Mesh.Person] p  join [Profile.Cache].[Concept.Mesh.URL] u on p.MeshHeader = u.DescriptorName
			where personID = @PersonID
			ORDER by weight desc for json path, ROOT ('Connections'))
	select @json = (Select 'Concepts' Title, @ExploreLink ExploreLink, @Count [Count], JSON_QUERY(@json, '$.Connections')as Connections  for json path, ROOT ('module_data'))
END
GO
