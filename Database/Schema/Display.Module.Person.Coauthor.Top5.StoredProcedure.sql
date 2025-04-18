SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Person.Coauthor.Top5]
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN
	declare @personID int
	declare @coauthorNodeID bigint = [RDF.].[fnURI2NodeID]('http://profiles.catalyst.harvard.edu/ontology/prns#coAuthorOf')
	declare @PredicatePath varchar(max)
	select @PredicatePath = isnull((select '/' + AliasType + '/' + AliasID from [RDF.].Alias where NodeID = @coauthorNodeID), '/' + cast(@coauthorNodeID as varchar(50)))
	declare @ExploreLink varchar(1000)
	select @PersonID = PersonID, @ExploreLink =  DefaultApplication + PreferredPath + @PredicatePath from [Profile.Cache].Person where NodeID = @Subject

	declare @count int
	select @count = count (*) from [Profile.Cache].[SNA.Coauthor] where personID1 = @personID

	if @count = 0
	BEGIN
		select @json = null
		return
	END

	create table #tmpCoauthors(personID int, name varchar(255), URL varchar(max), sort int Identity (1,1))
	insert into #tmpCoauthors(personID) select top 5 PersonID2 from [Profile.Cache].[SNA.Coauthor] where PersonID1 = @personID order by w desc
	update t set t.name = isnull(LastName, '') + isnull(', ' + firstname, ''),URL = DefaultApplication + PreferredPath from #tmpCoauthors t join [Profile.Cache].Person p on t.personID = p.PersonID

	select @json = (select Name Label, URL, Sort from #tmpCoauthors for json path, ROOT ('Connections'))
	select @json = (Select 'Co-Authors' Title, @ExploreLink ExploreLink, @Count [Count], JSON_QUERY(@json, '$.Connections')as Connections  for json path, ROOT ('module_data'))
END
GO
