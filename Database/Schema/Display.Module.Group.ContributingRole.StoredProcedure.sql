SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Group.ContributingRole]
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN

	SET NOCOUNT ON;
	declare @GroupID int
	select @GroupID = cast(InternalID as int) from [RDF.Stage].InternalNodeMap where nodeID = @Subject and Class = 'http://xmlns.com/foaf/0.1/Group'

	declare @relativeBasePath varchar(55)
	select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'

	declare @url varchar(max)
	select @URL = @relativeBasePath + '/display/' + cast(@Subject as varchar(50)) + '/' + cast([RDF.].fnURI2NodeID('http://vivoweb.org/ontology/core#contributingRole') as varchar(50))

	select @json = (	
		select b.PersonID, FirstName, LastName, DisplayName, b.InstitutionName, b.DepartmentName, c.Title, @relativeBasePath + isnull(DefaultApplication, '') + PreferredPath URL
			from [Profile.Data].[Group.Member] a 
				join [Profile.Cache].Person b on a.UserID = b.UserID and a.GroupID = @GroupID
				join [Profile.Cache].[Person.Affiliation] c on b.PersonID = c.PersonID and c.IsPrimary = 1
				for json path)

	select @json = (select @url ExploreURL, JSON_QUERY(@json, '$') Members for json path, WITHOUT_ARRAY_WRAPPER)
	select @json = (select JSON_QUERY(@json, '$') as module_data for json path, WITHOUT_ARRAY_WRAPPER)
END
GO
