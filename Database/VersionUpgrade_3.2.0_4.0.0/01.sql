 
 SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.].[GetLatestActivityIDs]
	@count int,
	@offset int = 0,
	@lastActivityLogID int = 0

AS
BEGIN
	declare @DisplayProperties table ([methodName] nvarchar(255), Property nvarchar(255))
	insert into @DisplayProperties (methodName, Property) values ('Profiles.Edit.Utilities.DataIO.AddPublication', null)
	insert into @DisplayProperties (methodName, Property) values ('Profiles.Edit.Utilities.DataIO.UpdateSecuritySetting', null)
	insert into @DisplayProperties (methodName, Property) values ('Profiles.Edit.Utilities.DataIO.AddUpdateFunding', null)
	insert into @DisplayProperties (methodName, Property) values ('Profiles.Edit.Utilities.DataIO.AddCustomPublication', null)
	insert into @DisplayProperties (methodName, Property) values ('Profiles.Edit.Utilities.DataIO.AddUpdateFunding', null)
	insert into @DisplayProperties (methodName, Property) values ('Profiles.Edit.Utilities.DataIO.AddGroupMember', null)
	insert into @DisplayProperties (methodName, Property) values ('[Profile.Data].[Funding.LoadDisambiguationResults]', null)
	insert into @DisplayProperties (methodName, Property) values ( '[resnav_people_profileslabs].[dbo].[UpdatePubMedDisambiguation]', null)

	insert into @DisplayProperties (methodName, Property) values ('Profiles.Edit.Utilities.DataIO.UpdateSecuritySetting', 'http://profiles.catalyst.harvard.edu/ontology/plugins#FeaturedPresentations')
	insert into @DisplayProperties (methodName, Property) values ('Profiles.Edit.Utilities.DataIO.UpdateSecuritySetting', 'http://profiles.catalyst.harvard.edu/ontology/plugins#FeaturedVideos')
	insert into @DisplayProperties (methodName, Property) values ('Profiles.Edit.Utilities.DataIO.UpdateSecuritySetting', 'http://profiles.catalyst.harvard.edu/ontology/plugins#Twitter')
	insert into @DisplayProperties (methodName, Property) values ('Profiles.Edit.Utilities.DataIO.UpdateSecuritySetting', 'http://profiles.catalyst.harvard.edu/ontology/prns#hasClinicalTrialRole')
	insert into @DisplayProperties (methodName, Property) values ('Profiles.Edit.Utilities.DataIO.UpdateSecuritySetting', 'http://profiles.catalyst.harvard.edu/ontology/prns#mainImage')
	insert into @DisplayProperties (methodName, Property) values ('Profiles.Edit.Utilities.DataIO.UpdateSecuritySetting', 'http://profiles.catalyst.harvard.edu/ontology/prns#mediaLinks')
	insert into @DisplayProperties (methodName, Property) values ('Profiles.Edit.Utilities.DataIO.UpdateSecuritySetting', 'http://vivoweb.org/ontology/core#authorInAuthorship')
	insert into @DisplayProperties (methodName, Property) values ('Profiles.Edit.Utilities.DataIO.UpdateSecuritySetting', 'http://vivoweb.org/ontology/core#awardOrHonor')
	insert into @DisplayProperties (methodName, Property) values ('Profiles.Edit.Utilities.DataIO.UpdateSecuritySetting', 'http://vivoweb.org/ontology/core#educationalTraining')
	insert into @DisplayProperties (methodName, Property) values ('Profiles.Edit.Utilities.DataIO.UpdateSecuritySetting', 'http://vivoweb.org/ontology/core#freetextKeyword')
	insert into @DisplayProperties (methodName, Property) values ('Profiles.Edit.Utilities.DataIO.UpdateSecuritySetting', 'http://vivoweb.org/ontology/core#hasMemberRole')
	insert into @DisplayProperties (methodName, Property) values ('Profiles.Edit.Utilities.DataIO.UpdateSecuritySetting', 'http://vivoweb.org/ontology/core#hasResearcherRole')
	insert into @DisplayProperties (methodName, Property) values ('Profiles.Edit.Utilities.DataIO.UpdateSecuritySetting', 'http://vivoweb.org/ontology/core#orcidId')
	insert into @DisplayProperties (methodName, Property) values ('Profiles.Edit.Utilities.DataIO.UpdateSecuritySetting', 'http://vivoweb.org/ontology/core#overview')
	insert into @DisplayProperties (methodName, Property) values ('Profiles.Edit.Utilities.DataIO.UpdateSecuritySetting', 'http://vivoweb.org/ontology/core#webpage')

	if @lastActivityLogID = 0
	BEGIN
		select MAX (activityLogID) activityLogID from [Framework.].[Log.Activity] a 
			join @DisplayProperties b on a.methodName = b.methodName and a.Property = isnull(b.property, a.property) 
			join [Profile.Cache].Person c on a.personId = c.PersonID and c.IsActive = 1
			join [RDF.].Node d on  [RDF.].fnValueHash(null, null, b.Property) = d.ValueHash
			left JOIN [RDF.Security].[NodeProperty] e on c.NodeID = e.NodeID and d.NodeID = e.Property
				group by a.personID order by max(activityLogID) desc offset @offset ROWS FETCH NEXT @count ROWS ONLY
				--for json path
	END
	ELSE
	BEGIN
		select MAX (activityLogID) activityLogID from [Framework.].[Log.Activity] a 
			join @DisplayProperties b on a.methodName = b.methodName and a.Property = isnull(b.property, a.property) and a.activityLogId < @lastActivityLogID
			join [Profile.Cache].Person c on a.personId = c.PersonID and c.IsActive = 1
			join [RDF.].Node d on  [RDF.].fnValueHash(null, null, b.Property) = d.ValueHash
			left JOIN [RDF.Security].[NodeProperty] e on c.NodeID = e.NodeID and d.NodeID = e.Property
				group by a.personID order by max(activityLogID) desc offset @offset ROWS FETCH NEXT @count ROWS ONLY
	END
END
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [Display.].[GetActivity]
	@activityLogIDs varchar(max)
AS
BEGIN
	declare @logIDsTable table (activityLogID int)
	insert into @logIDsTable select * from string_split(@activityLogIDs, ',')

	declare @relativeBasePath varchar(max)
	select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'

	SELECT i.activityLogID,
		p.personid,n.nodeid,p.firstname,p.lastname, @relativeBasePath + isnull(defaultApplication, '') + PreferredPath as URL,
        i.methodName,i.property,cp._PropertyLabel as propertyLabel,i.param1,i.param2,i.createdDT, g.JournalTitle, fa.AgreementLabel, gg.GroupName
        FROM [Framework.].[Log.Activity] i 
		join @logIDsTable a on i.activityLogId = a.activityLogID	
        LEFT OUTER JOIN [Profile.Cache].[Person] p ON i.personId = p.personID
        LEFT OUTER JOIN [RDF.Stage].internalnodemap n on n.internalid = p.personId and n.[class] = 'http://xmlns.com/foaf/0.1/Person' 
        LEFT OUTER JOIN [Ontology.].[ClassProperty] cp ON cp.Property = i.property  and cp.Class = 'http://xmlns.com/foaf/0.1/Person' 
        LEFT OUTER JOIN [RDF.].[Node] rn on [RDF.].fnValueHash(null, null, i.property) = rn.ValueHash 
        LEFT OUTER JOIN [RDF.Security].[NodeProperty] np on n.NodeID = np.NodeID and rn.NodeID = np.Property
		LEFT OUTER JOIN [Profile.Data].[Publication.PubMed.General] g on i.param1 in ('PMID', 'Add PMID') and param2 = cast(g.PMID as varchar(50))
		LEFT OUTER JOIN [Profile.Data].[Funding.Role] fr on i.property = 'http://vivoweb.org/ontology/core#ResearcherRole' and i.param1 = FundingRoleID LEFT OUTER JOIN [Profile.Data].[Funding.Agreement] fa on fr.FundingAgreementID = fa.FundingAgreementID
		LEFT OUTER JOIN [Profile.Data].[vwGroup.General] gg on i.param1 = cast(gg.GroupID as varchar(50))
        where p.IsActive=1 and (np.ViewSecurityGroup = -1 or (i.privacyCode = -1 and np.ViewSecurityGroup is null) or (i.privacyCode is null and np.ViewSecurityGroup is null))
        --(lastActivityLogID != -1 ? (" and i.activityLogID " + (older ? "< " : "> ") + lastActivityLogID) : "") +
         for json path
END
GO



 
 
  ALTER TABLE [Display.].[DataPath] ADD pageSecurityType varchar(32)
  ALTER TABLE [Display.].[DataPath] ADD cacheLength varchar(32)


  -- cache type: Global, Session // Global pages are identical for everyone, logged in or not. We just have to confirm that the page has a security group of -1. Individual pages can be different for each viewer, this includes profile and group pages. 
  -- cache length: EDITABLE_PAGE_CACHE_EXPIRE, GENERATED_PAGE_CACHE_EXPIRE

  update [Display.].[DataPath] set pageSecurityType = 'Global', CacheLength = 'GENERATED_PAGE_CACHE_EXPIRE' -- Defaults
  update [Display.].[DataPath] set pageSecurityType = 'Session', CacheLength = 'EDITABLE_PAGE_CACHE_EXPIRE' where PresentationID = 5 and dataTab = 'data'





SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [Display.].[GetJson]
	@subject bigint,
	@predicate bigint = null,
	@object bigint = null,
	@tab varchar(16) = null,
	@SessionID  UNIQUEIDENTIFIER = NULL
AS
BEGIN

	insert into [Display.].[GetJsonLog] (timestamp, subject, predicate, object, tab, SessionID)
		values (getdate(), @subject, @predicate, @object, @tab, @SessionID)

	DECLARE @ErrorDescription varchar(max)


	if @predicate = 0
	 select	@predicate = null

	 if @object = 0
	 select	@object = null

	-------------------------------------------------------------------------------
	-- Determine the PresentationType (P = profile, N = network, C = connection)
	-------------------------------------------------------------------------------

	declare @PresentationType char(1)
	select @PresentationType = (case when @object is not null AND @predicate is not null AND @subject is not null then 'C'
									when @predicate is not null AND @subject is not null then 'N'
									when @subject is not null then 'P'
									else NULL end)


	-------------------------------------------------------------------------------
	-- Get the PresentationID based on type
	-------------------------------------------------------------------------------
	declare @typeID bigint
	select @typeID = [RDF.].fnURI2NodeID('http://www.w3.org/1999/02/22-rdf-syntax-ns#type')
	declare @PresentationID int
	select @PresentationID = (
			select top 1 PresentationID
				from [Ontology.Presentation].[XML]
				where type = IsNull(@PresentationType,'P')
					AND	(_SubjectNode IS NULL
							OR _SubjectNode IN (select object from [RDF.].Triple where @subject is not null and subject=@subject and predicate=@typeID)
						)
					AND	(_PredicateNode IS NULL
							OR _PredicateNode = @predicate
						)
					AND	(_ObjectNode IS NULL
							OR _ObjectNode IN (select object from [RDF.].Triple where @object is not null and subject=@object and predicate=@typeID)
						)
				order by	(case when _ObjectNode is null then 1 else 0 end),
							(case when _PredicateNode is null then 1 else 0 end),
							(case when _SubjectNode is null then 1 else 0 end),
							PresentationID
		)
	

	-------------------------------------------------------------------------------
	-- Get the Security and Cache length for the page based on type
	-------------------------------------------------------------------------------
	declare @cacheLength varchar(32), @pageSecurityType varchar(32)
	select @cacheLength = cacheLength, @pageSecurityType = pageSecurityType from [Display.].[DataPath] where PresentationID = @PresentationID and dataTab = @tab


	-------------------------------------------------------------------------------
	-- Get the datamodules
	-------------------------------------------------------------------------------
	create table #dataModules(
		i int identity,
		DataStoredProc varchar(max),
		subject bigint,
		predicate bigint,
		tagname varchar(max),
		DisplayModule varchar(max),
		object bigint,
		oValue varchar(max),
		json nvarchar(max)
	)

	declare @pageCacheSecurityGroup int
	set @pageCacheSecurityGroup = 0

	IF @pageSecurityType = 'Session'
	BEGIN
		DECLARE @SecurityGroupID BIGINT, @HasSpecialViewAccess BIT, @HasSpecialEditAccess BIT
		EXEC [RDF.Security].GetSessionSecurityGroup @SessionID, @pageCacheSecurityGroup OUTPUT, @HasSpecialViewAccess OUTPUT, @HasSpecialEditAccess OUTPUT
		if (@pageCacheSecurityGroup <=20)
		BEGIN
			CREATE TABLE #SecurityGroupNodes (SecurityGroupNode BIGINT PRIMARY KEY)
			INSERT INTO #SecurityGroupNodes (SecurityGroupNode) EXEC [RDF.Security].GetSessionSecurityGroupNodes @SessionID, @subject
			SELECT @pageCacheSecurityGroup = 0
				FROM [RDF.].Node
				WHERE NodeID = @subject
					AND ( (EditSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (EditSecurityGroup > 0 AND @HasSpecialEditAccess = 1) OR (EditSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)) )
		END
		-------------------------------------------------------------------------------
		-- Get the RDF to assess which modules should be displayed
		-------------------------------------------------------------------------------
		create table #rdf(
			uri nvarchar(400),
			subject bigint,
			predicate bigint,
			object bigint,
			showSummary bit,
			property nvarchar(400),
			tagName nvarchar(1000),
			propertyLabel nvarchar(400),
			Language nvarchar(255),
			DataType nvarchar(255),
			Value nvarchar(max),
			ObjectType bit,
			SortOrder int
		)

		--TODO CONVERT [RDF.Security].[GetSessionSecurityGroupNodes] to function and add back into GetDataRDF
		insert into #rdf
		exec [Display.].[GetDataRDF] @subject=@subject,@predicate=@predicate,@object=@object,@SessionID=@SessionID,@Expand=0,@limit=1

	
		insert into #dataModules (DataStoredProc, subject, predicate, tagname, DisplayModule, object, oValue)
		select DataStoredProc, isnull(subject, @subject), predicate, tagname, DisplayModule, object, Value from [Display.].ModuleMapping a
			join #rdf b
			on a.PresentationID = @PresentationID
			and a._ClassPropertyID = b.predicate
			and b.SortOrder = 1 --This should be handled at source
			and isnull(a.tab, '') = isnull(@tab, '')
	END
	ELSE IF @pageSecurityType = 'Global'
	BEGIN
		declare @hasPermissions bit = 0
		select @hasPermissions = case when ViewSecurityGroup = -1 then 1 else 0 end  from [RDF.].Node where nodeID = @subject
		if @predicate is not null select @hasPermissions = case when ViewSecurityGroup = -1 then @hasPermissions else 0 end  from [RDF.].Node where nodeID =  @predicate
		if @object is not null select @hasPermissions = case when ViewSecurityGroup = -1 then @hasPermissions else 0 end  from [RDF.].Node where nodeID =  @object

		if (@hasPermissions = 1)
		BEGIN
			set @pageCacheSecurityGroup = -1
			insert into #dataModules (DataStoredProc, subject, predicate, tagname, DisplayModule, object, oValue)
			select DataStoredProc, @subject, @predicate, '', DisplayModule, @object, null from [Display.].ModuleMapping a
				where a.PresentationID = @PresentationID
				and isnull(a.tab, '') = isnull(@tab, '')
		END
	END

	-------------------------------------------------------------------------------
	-- Get the JSON
	-------------------------------------------------------------------------------
	declare @DataStoredProc varchar(max), @subject1 bigint, @predicate1 bigint, @tagname varchar(max), @object1 bigint, @oValue varchar(max), @json nvarchar(max)
	--select * from #dataModules
	--select @subject,@predicate,@object, @tab
	declare @dmi int = 0
	while (1=1)
	BEGIN
		select top 1 @dmi=i, @DataStoredProc=DataStoredProc, @subject1=isnull(subject, @subject), @predicate1=predicate, @tagname=tagname, @object1=object, @oValue=oValue 
			from #dataModules where i > @dmi order by i
		if @@ROWCOUNT=0 BREAK
		exec @DataStoredProc @subject=@subject1, @predicate=@predicate1, @tagname=@tagname, @object=@object1, @oValue=@oValue, @SessionID=@SessionID, @json=@json output
		update #dataModules set json = @json where i = @dmi
	END

	if not exists (select 1 from #dataModules where json is not null) insert into #dataModules(DisplayModule, json) values ('Error', '{"module_data":[{"Error":"Not Found"}]}')

	--select * from #dataModules
	--select *, JSON_QUERY(json, '$.module_data')as module_data from #dataModules
	select (Select DisplayModule, JSON_QUERY(json, '$.module_data')as ModuleData from #dataModules for json path) as jsonData,  @pageSecurityType as pageSecurityType, @cacheLength as cacheLength, @pageCacheSecurityGroup as pageCacheSecurityGroup
END
GO 




CREATE TABLE [Display.].[SearchEverything.Filters](Class varchar(255), _NodeID bigint, Label varchar(255), pluralLabel varchar(max))
GO
insert into [Display.].[SearchEverything.Filters](class, label, pluralLabel) values('http://profiles.catalyst.harvard.edu/ontology/catalyst#MentoringCompletedStudentProject', 'Mentoring - Completed Student Project', 'Mentoring')
insert into [Display.].[SearchEverything.Filters](class, label, pluralLabel) values('http://vivoweb.org/ontology/core#Grant', 'Grant', 'Grants')
insert into [Display.].[SearchEverything.Filters](class, label, pluralLabel) values('http://xmlns.com/foaf/0.1/Person', 'Person', 'People')
insert into [Display.].[SearchEverything.Filters](class, label, pluralLabel) values('http://purl.org/ontology/bibo/Document', 'Academic Article', 'Research')
insert into [Display.].[SearchEverything.Filters](class, label, pluralLabel) values('http://vivoweb.org/ontology/core#AwardReceipt', 'Award or Honor Receipt', 'Awards')
insert into [Display.].[SearchEverything.Filters](class, label, pluralLabel) values('http://www.w3.org/2004/02/skos/core#Concept', 'Concept', 'Concepts')
GO
update a set a._nodeID = b.nodeID From [Display.].[SearchEverything.Filters] a join [RDF.].Node b on a.class = b.value
GO



SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [Display.].[SearchEverything]
	@json nvarchar(max)
AS
BEGIN
/*
	exec [Display.].[SearchEverything]
	@json='{
		"Keyword": "keyword text here",
		"KeywordExact": false,
		"FilterType": 1229480, --NodeID for filtertype
		"Offset": 0,
		"Count": 15
	}'
*/

	--<SearchOptions><MatchOptions><SearchString ExactMatch="false">beer</SearchString></MatchOptions><OutputOptions><Offset>100</Offset><Limit>0</Limit></OutputOptions></SearchOptions>
			declare @j table([key] varchar(max), [value] varchar(max), [type] int)
		insert into @j
		select * from openjson(@json)


		declare @keyword nvarchar(max), @keywordExact varchar(max), @Offset int, @count int, @sort varchar(max)

		select @keyword = [value] from @j where [key] = 'keyword'
		select @keywordExact = [value] from @j where [key] = 'keywordExact'
		select @Offset = [value] from @j where [key] = 'Offset'
		select @count = [value] from @j where [key] = 'count'
		select @sort = [value] from @j where [key] = 'sort'

				declare @SearchOpts varchar(max)
		set @SearchOpts =
			'<SearchOptions><MatchOptions><SearchString ExactMatch="' + @keywordExact + '">' + @keyword + '</SearchString></MatchOptions><OutputOptions><Offset>100</Offset><Limit>0</Limit></OutputOptions></SearchOptions>'

		create table #t (SortOrder int, NodeID bigint primary key, Weight float, type bigint, Label nvarchar(max), ClassLabel varchar(255))
		declare @jsonSearchResults varchar(max)
		select @jsonSearchResults = 'a'
		 EXEC [Search.].[GetNodes] @SearchOptions =@SearchOpts, @JSON=@jsonSearchResults output

		 insert into #t (SortOrder, NodeID, Weight)
		SELECT
			  b.SortOrder,
			  b.NodeID,
			  b.Weight
			FROM OPENJSON(@jsonSearchResults) a
			CROSS APPLY OPENJSON(a.value)
			  WITH (
				SortOrder INT,
				NodeID bigint,
				Weight float
			) AS b;


		update a set a.type = b.object from #t a join [RDF.].Triple b on a.NodeID = b.Subject and b.Predicate = [RDF.].[fnURI2NodeID]('http://www.w3.org/1999/02/22-rdf-syntax-ns#type')

		declare @filters table(type bigint, [count] int, label varchar(255))
		insert into @filters(type, [count])
		select type, count(*) as c from #t group by type
		update a set a.Label = b.pluralLabel from @filters a join [Display.].[SearchEverything.Filters] b on a.type = b._NodeID
		
		delete from #t where type not in (select _NodeID from [Display.].[SearchEverything.Filters])
		delete from @filters where label is null

		insert into @filters (type, [count], label) select 0, count(*), 'All' from #t

		delete from #t where SortOrder < @Offset
		delete from #t where SortOrder > @Offset + @count

		update a set a.ClassLabel = b.Label from #t a join [Display.].[SearchEverything.Filters] b on a.type = _NodeID

		declare @labelNodeID bigint 
		select @labelNodeID	= [RDF.].[fnURI2NodeID]('http://www.w3.org/2000/01/rdf-schema#label')
		update a set a.Label = n.value from #t a join [RDF.].Triple t on a.NodeID = t.Subject and t.Predicate = @labelNodeID join [RDF.].Node n on t.Object = n.NodeID


		select JSON_QUERY(@json, '$') as SearchQuery, (select * from @filters for json Path) as Filters, (select NodeID, Weight, Label,ClassLabel from #t for JSON Path) as Results for json path, WITHOUT_ARRAY_WRAPPER
END
GO
