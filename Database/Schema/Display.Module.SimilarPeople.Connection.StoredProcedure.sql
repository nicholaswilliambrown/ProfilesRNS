SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[SimilarPeople.Connection]
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
	declare @SubjectPath varchar(max), @relativeBasePath varchar(100)
	select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'
	select @personID = PersonID, @SubjectPath = @relativeBasePath + isnull(DefaultApplication, '') + PreferredPath from [Profile.Cache].Person where NodeID = @Subject
	declare @PredicatePath varchar(max)
	select @PredicatePath = isnull((select '/' + AliasType + '/' + AliasID from [RDF.].Alias where NodeID = @Predicate), '/' + cast(@predicate as varchar(50)))




	create table #tmpCoauthors (
		[PersonID2] [int] NOT NULL primary key,
		[w] [float] NULL,
		--[FirstPubDate] [datetime] NULL,
		[Coauthor] bit NULL,
		name varchar(255), 
		DisplayName varchar(255),
		URL varchar(max),
		WhyPath varchar(max))

	insert into #tmpCoauthors (PersonID2, w, Coauthor) select SimilarPersonID, Weight, CoAuthor FROM [Profile.Cache].[Person.SimilarPerson] where PersonID = @personID


	update t set t.name = isnull(LastName, '') + isnull(', ' + firstname, ''), DisplayName = p.DisplayName, URL= @relativeBasePath + isnull(DefaultApplication, '') + PreferredPath, WhyPath = @SubjectPath + @PredicatePath + PreferredPath from #tmpCoauthors t join [Profile.Cache].Person p on t.PersonID2 = p.PersonID
	select @json = (select Name, DisplayName, URL, ROUND(w, 3) as [Weight], CoAuthor, WhyPath from #tmpCoauthors for json path, ROOT ('module_data'))
	--select @json = (select JSON_QUERY(@json, '$') as module_data for json path, WITHOUT_ARRAY_WRAPPER)
END
GO
