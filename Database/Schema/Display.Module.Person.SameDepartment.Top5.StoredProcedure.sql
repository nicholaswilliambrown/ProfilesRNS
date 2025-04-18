SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Person.SameDepartment.Top5]
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
	select @count = count (*) from [Profile.Cache].[Concept.Mesh.Person] where personID = @personID

	if not exists (select top 1 1 from [Profile.Cache].[Person] a 
		join [Profile.Cache].[Person] b
			on a.PersonID = @personID and a.DepartmentName = b.DepartmentName and b.PersonID <> @personID)
	BEGIN
		select @json = null
		return
	END

	declare @departmentID bigint, @institutionID bigint, @departmentName nvarchar(500)
	select @departmentID = departmentID, @institutionID = InstitutionID from [Profile.Data].[Person.Affiliation] where  personID = @personID and IsPrimary = 1
	select @departmentID = NodeID from [RDF.Stage].InternalNodeMap where internalID = cast(@departmentID as varchar(50)) and InternalType = 'Department'
	select @institutionID = NodeID from [RDF.Stage].InternalNodeMap where internalID = cast(@institutionID as varchar(50)) and InternalType = 'Institution'
	select @departmentName = DepartmentName from [Profile.Cache].[Person] where PersonID = @personID
	select @ExploreLink = (select @departmentID Department, @departmentName DepartmentName, @institutionID Institution, 0 Offset, 15 [Count], 'Relevance' Sort for json path , WITHOUT_ARRAY_WRAPPER)
	select @json = (select top 5 b.LastName + ', ' + b.firstname as Label, @relativeBasePath + isnull(b.DefaultApplication, '') + b.PreferredPath URL, ROW_NUMBER() OVER (ORDER BY rand()) Sort  from [Profile.Cache].[Person] a 
	join [Profile.Cache].[Person] b
	on a.PersonID = @personID and a.DepartmentName = b.DepartmentName and b.PersonID <> @personID
			ORDER by rand() desc for json path, ROOT ('Connections'))
	select @json = (Select 'Same Department' Title, JSON_QUERY(@ExploreLink, '$') SearchQuery, JSON_QUERY(@json, '$.Connections')as Connections  for json path, ROOT ('module_data'))
END
GO
