/*
Run this script on:

        Profiles 3.2.0   -  This database will be modified

to synchronize it with:

        Profiles 4.0.0

You are recommended to back up your database before running this script

Details of which objects have changed can be found in the release notes.
If you have made changes to existing tables or stored procedures in profiles, you may need to merge changes individually. 

*/


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [Search.].[GetNodes]
	@SearchOptions XML,
	@SessionID UNIQUEIDENTIFIER = NULL,
	@Lookup BIT = 0,
	@UseCache VARCHAR(50) = 'Public',
	@NoRDF BIT =0,
	@JSON VARCHAR(max) = null output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	/*
	
	EXEC [Search.].[GetNodes] @SearchOptions = '
	<SearchOptions>
		<MatchOptions>
			<SearchString ExactMatch="false">options for "lung cancer" treatment</SearchString>
			<ClassURI>http://xmlns.com/foaf/0.1/Person</ClassURI>
			<SearchFiltersList>
				<SearchFilter Property="http://xmlns.com/foaf/0.1/lastName" MatchType="Left">Smit</SearchFilter>
			</SearchFiltersList>
		</MatchOptions>
		<OutputOptions>
			<Offset>0</Offset>
			<Limit>5</Limit>
			<SortByList>
				<SortBy IsDesc="1" Property="http://xmlns.com/foaf/0.1/firstName" />
				<SortBy IsDesc="0" Property="http://xmlns.com/foaf/0.1/lastName" />
			</SortByList>
		</OutputOptions>	
	</SearchOptions>
	'
		
	*/
	
	-- Select either a lookup or a full search
	IF @Lookup = 1
	BEGIN
		-- Run a lookup
		EXEC [Search.].[LookupNodes] @SearchOptions = @SearchOptions, @SessionID = @SessionID
	END
	ELSE
	BEGIN
		-- Run a full search
		-- Determine the cache type if set to auto
		IF IsNull(@UseCache,'Auto') IN ('','Auto')
		BEGIN
			DECLARE @SecurityGroupID BIGINT, @HasSpecialViewAccess BIT
			EXEC [RDF.Security].GetSessionSecurityGroup @SessionID, @SecurityGroupID OUTPUT, @HasSpecialViewAccess OUTPUT
			SELECT @UseCache = (CASE WHEN @SecurityGroupID <= -30 THEN 'Private' ELSE 'Public' END)
		END
		-- Run the search based on the cache type
		IF @UseCache = 'Public'
			EXEC [Search.Cache].[Public.GetNodes] @SearchOptions = @SearchOptions, @SessionID = @SessionID, @NoRDF=@NoRDF, @JSON=@JSON Output
		ELSE IF @UseCache = 'Private'
			EXEC [Search.Cache].[Private.GetNodes] @SearchOptions = @SearchOptions, @SessionID = @SessionID
	END

END
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [Search.Cache].[Public.GetConnection]
	@SearchOptions XML,
	@NodeID BIGINT = NULL,
	@NodeURI VARCHAR(400) = NULL,
	@SessionID UNIQUEIDENTIFIER = NULL,
	@JSON VARCHAR(max) = null output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- start timer
	declare @d datetime
	select @d = GetDate()

	-- get the NodeID
	IF (@NodeID IS NULL) AND (@NodeURI IS NOT NULL)
		SELECT @NodeID = [RDF.].fnURI2NodeID(@NodeURI)
	IF @NodeID IS NULL
		RETURN
	SELECT @NodeURI = Value
		FROM [RDF.].Node
		WHERE NodeID = @NodeID

	-- get the search string
	declare @SearchString varchar(500)
	declare @DoExpandedSearch bit
	select	@SearchString = @SearchOptions.value('SearchOptions[1]/MatchOptions[1]/SearchString[1]','varchar(500)'),
			@DoExpandedSearch = (case when @SearchOptions.value('SearchOptions[1]/MatchOptions[1]/SearchString[1]/@ExactMatch','varchar(50)') = 'true' then 0 else 1 end)

	if @SearchString is null
		RETURN

	-- set constants
	declare @baseURI nvarchar(400)
	declare @typeID bigint
	declare @labelID bigint
	select @baseURI = value from [Framework.].Parameter where ParameterID = 'baseURI'
	select @typeID = [RDF.].fnURI2NodeID('http://www.w3.org/1999/02/22-rdf-syntax-ns#type')
	select @labelID = [RDF.].fnURI2NodeID('http://www.w3.org/2000/01/rdf-schema#label')

	-------------------------------------------------------
	-- Parse search string and convert to fulltext query
	-------------------------------------------------------
	
	declare @NumberOfPhrases INT
	declare @CombinedSearchString VARCHAR(8000)
	declare @SearchPhraseXML XML
	declare @SearchPhraseFormsXML XML
	declare @ParseProcessTime INT

		
	EXEC [Search.].[ParseSearchString]	@SearchString = @SearchString,
										@NumberOfPhrases = @NumberOfPhrases OUTPUT,
										@CombinedSearchString = @CombinedSearchString OUTPUT,
										@SearchPhraseXML = @SearchPhraseXML OUTPUT,
										@SearchPhraseFormsXML = @SearchPhraseFormsXML OUTPUT,
										@ProcessTime = @ParseProcessTime OUTPUT

	declare @PhraseList table (PhraseID int, Phrase varchar(max), ThesaurusMatch bit, Forms varchar(max))
	insert into @PhraseList (PhraseID, Phrase, ThesaurusMatch, Forms)
	select	x.value('@ID','INT'),
			x.value('.','VARCHAR(MAX)'),
			x.value('@ThesaurusMatch','BIT'),
			x.value('@Forms','VARCHAR(MAX)')
		from @SearchPhraseFormsXML.nodes('//SearchPhrase') as p(x)


	-------------------------------------------------------
	-- Find matching nodes connected to NodeID
	-------------------------------------------------------

	-- Get nodes that match separate phrases
	create table #PhraseNodeMap (
		PhraseID int not null,
		NodeID bigint not null,
		MatchedByNodeID bigint not null,
		Distance int,
		Paths int,
		MapWeight float,
		TextWeight float,
		Weight float
	)
	if (@DoExpandedSearch = 1)
	begin
		declare @PhraseSearchString varchar(8000)
		declare @loop int
		select @loop = 1
		while @loop <= @NumberOfPhrases
		begin
			select @PhraseSearchString = Forms
				from @PhraseList
				where PhraseID = @loop
			insert into #PhraseNodeMap (PhraseID, NodeID, MatchedByNodeID, Distance, Paths, MapWeight, TextWeight, Weight)
				select @loop, s.NodeID, s.MatchedByNodeID, s.Distance, s.Paths, s.Weight, m.Weight,
						(case when s.Weight*m.Weight > 0.999999 then 0.999999 else s.Weight*m.Weight end) Weight
					from [Search.Cache].[Public.NodeMap] s, (
						select [Key] NodeID, [Rank]*0.000999+0.001 Weight
							from Containstable ([RDF.].[vwLiteral], value, @PhraseSearchString) n
					) m
					where s.MatchedByNodeID = m.NodeID and s.NodeID = @NodeID
			select @loop = @loop + 1
		end
	end
	else
	begin
		insert into #PhraseNodeMap (PhraseID, NodeID, MatchedByNodeID, Distance, Paths, MapWeight, TextWeight, Weight)
			select 1, s.NodeID, s.MatchedByNodeID, s.Distance, s.Paths, s.Weight, m.Weight,
					(case when s.Weight*m.Weight > 0.999999 then 0.999999 else s.Weight*m.Weight end) Weight
				from [Search.Cache].[Public.NodeMap] s, (
					select [Key] NodeID, [Rank]*0.000999+0.001 Weight
						from Containstable ([RDF.].[vwLiteral], value, @CombinedSearchString) n
				) m
				where s.MatchedByNodeID = m.NodeID and s.NodeID = @NodeID
	end

	-------------------------------------------------------
	-- Get details on the matches
	-------------------------------------------------------
	
	SELECT *
		INTO #m
		FROM (
			SELECT 1 DirectMatch, NodeID, NodeID MiddleNodeID, MatchedByNodeID, 
					COUNT(DISTINCT PhraseID) Phrases, 1-exp(sum(log(1-Weight))) Weight
				FROM #PhraseNodeMap
				WHERE Distance = 1
				GROUP BY NodeID, MatchedByNodeID
			UNION ALL
			SELECT 0 DirectMatch, d.NodeID, y.NodeID MiddleNodeID, d.MatchedByNodeID,
					COUNT(DISTINCT d.PhraseID) Phrases, 1-exp(sum(log(1-d.Weight))) Weight
				FROM #PhraseNodeMap d
					INNER JOIN [Search.Cache].[Public.NodeMap] x
						ON x.NodeID = d.NodeID
							AND x.Distance = d.Distance - 1
					INNER JOIN [Search.Cache].[Public.NodeMap] y
						ON y.NodeID = x.MatchedByNodeID
							AND y.MatchedByNodeID = d.MatchedByNodeID
							AND y.Distance = 1
				WHERE d.Distance > 1
				GROUP BY d.NodeID, d.MatchedByNodeID, y.NodeID
		) t

	SELECT *
		INTO #w
		FROM (
			SELECT DISTINCT m.DirectMatch, m.NodeID, m.MiddleNodeID, m.MatchedByNodeID, m.Phrases, m.Weight,
				p._PropertyLabel PropertyLabel, p._PropertyNode PropertyNode
			FROM #m m
				INNER JOIN [Search.Cache].[Public.NodeClass] c
					ON c.NodeID = m.MiddleNodeID
				INNER JOIN [Ontology.].[ClassProperty] p
					ON p._ClassNode = c.Class
						AND p._NetworkPropertyNode IS NULL
						AND p.SearchWeight > 0
				INNER JOIN [RDF.].Triple t
					ON t.subject = m.MiddleNodeID
						AND t.predicate = p._PropertyNode
						AND t.object = m.MatchedByNodeID
		) t

	SELECT w.DirectMatch, w.Phrases, w.Weight,
			n.NodeID, n.Value URI, c.ShortLabel Label, c.ClassName, 
			w.PropertyLabel Predicate, 
			w.MatchedByNodeID, o.value Value
		INTO #MatchDetails
		FROM #w w
			INNER JOIN [RDF.].Node n
				ON n.NodeID = w.MiddleNodeID
			INNER JOIN [Search.Cache].[Public.NodeSummary] c
				ON c.NodeID = w.MiddleNodeID
			INNER JOIN [RDF.].Node o
				ON o.NodeID = w.MatchedByNodeID

	UPDATE #MatchDetails
		SET Weight = (CASE WHEN Weight > 0.999999 THEN 999999 WHEN Weight < 0.000001 THEN 0.000001 ELSE Weight END)

	-------------------------------------------------------
	-- Build ConnectionDetailsXML
	-------------------------------------------------------

	if @json is not null
	BEGIN
		SELECT DirectMatch, NodeID, URI, Label, ClassName, 
				COUNT(*) NumberOfProperties, 1-exp(sum(log(1-Weight))) Weight,
				(
					SELECT	p.Predicate "Name",
							--p.Phrases "NumberOfPhrases",
							p.Weight "Weight",
							p.Value "Value"/*,
							(
								SELECT r.Phrase "MatchedPhrase"
								FROM #PhraseNodeMap q, @PhraseList r
								WHERE q.MatchedByNodeID = p.MatchedByNodeID
									AND r.PhraseID = q.PhraseID
								ORDER BY r.PhraseID
								FOR JSON PATH
							) "MatchedPhraseList"*/
						FROM #MatchDetails p
						WHERE p.DirectMatch = m.DirectMatch
							AND p.NodeID = m.NodeID
						ORDER BY p.Predicate
						FOR JSON PATH
				) PropertyList
				into #a
			FROM #MatchDetails m
			GROUP BY DirectMatch, NodeID, URI, Label, ClassName
--select * from #a
		select @json = null
		select @json = PropertyList from #a where DirectMatch = 1
		select @json = (select
		/*(SELECT	/*NodeID "NodeID",
								URI "URI",
								Label "Label",
								ClassName "ClassName",
								NumberOfProperties "NumberOfProperties",
								Weight "Weight"*/
								JSON_QUERY(PropertyList, '$') AS "PropertyList"
						FROM #a
						WHERE DirectMatch = 1 for json path, without_array_wrapper) DirectMatchList,*/
					JSON_QUERY(isnull(@json, '{}'), '$') DirectMatchList,
	
					(SELECT	NodeID "NodeID",
								URI "URI",
								Label "Label",
								ClassName "ClassName",
								NumberOfProperties "NumberOfProperties",
								Weight "Weight"--,
								--PropertyList "PropertyList"
						FROM #a
						WHERE DirectMatch = 0 for json path) IndirectMatchList
					for JSON path, WITHOUT_ARRAY_WRAPPER)

			return
	END

	DECLARE @ConnectionDetailsXML XML
	
	;WITH a AS (
		SELECT DirectMatch, NodeID, URI, Label, ClassName, 
				COUNT(*) NumberOfProperties, 1-exp(sum(log(1-Weight))) Weight,
				(
					SELECT	p.Predicate "Name",
							p.Phrases "NumberOfPhrases",
							p.Weight "Weight",
							p.Value "Value",
							(
								SELECT r.Phrase "MatchedPhrase"
								FROM #PhraseNodeMap q, @PhraseList r
								WHERE q.MatchedByNodeID = p.MatchedByNodeID
									AND r.PhraseID = q.PhraseID
								ORDER BY r.PhraseID
								FOR XML PATH(''), TYPE
							) "MatchedPhraseList"
						FROM #MatchDetails p
						WHERE p.DirectMatch = m.DirectMatch
							AND p.NodeID = m.NodeID
						ORDER BY p.Predicate
						FOR XML PATH('Property'), TYPE
				) PropertyList
			FROM #MatchDetails m
			GROUP BY DirectMatch, NodeID, URI, Label, ClassName
	)
	SELECT @ConnectionDetailsXML = (
		SELECT	(
					SELECT	NodeID "NodeID",
							URI "URI",
							Label "Label",
							ClassName "ClassName",
							NumberOfProperties "NumberOfProperties",
							Weight "Weight",
							PropertyList "PropertyList"
					FROM a
					WHERE DirectMatch = 1
					FOR XML PATH('Match'), TYPE
				) "DirectMatchList",
				(
					SELECT	NodeID "NodeID",
							URI "URI",
							Label "Label",
							ClassName "ClassName",
							NumberOfProperties "NumberOfProperties",
							Weight "Weight",
							PropertyList "PropertyList"
					FROM a
					WHERE DirectMatch = 0
					FOR XML PATH('Match'), TYPE
				) "IndirectMatchList"				
		FOR XML PATH(''), TYPE
	)
	
	--SELECT @ConnectionDetailsXML ConnectionDetails
	--SELECT * FROM #PhraseNodeMap

	-------------------------------------------------------
	-- Get RDF of the NodeID
	-------------------------------------------------------

	DECLARE @ObjectNodeRDF NVARCHAR(MAX)
	
	EXEC [RDF.].GetDataRDF	@subject = @NodeID,
							@showDetails = 0,
							@expand = 0,
							@SessionID = @SessionID,
							@returnXML = 0,
							@dataStr = @ObjectNodeRDF OUTPUT


	-------------------------------------------------------
	-- Form search results details RDF
	-------------------------------------------------------

	DECLARE @results NVARCHAR(MAX)

	SELECT @results = ''
			+'<rdf:Description rdf:nodeID="SearchResultsDetails">'
			+'<rdf:type rdf:resource="http://profiles.catalyst.harvard.edu/ontology/prns#Connection" />'
			+'<prns:connectionInNetwork rdf:NodeID="SearchResults" />'
			--+'<prns:connectionWeight>0.37744</prns:connectionWeight>'
			+'<prns:hasConnectionDetails rdf:NodeID="ConnectionDetails" />'
			+'<rdf:object rdf:resource="'+@NodeURI+'" />'
			+'<rdfs:label>Search Results Details</rdfs:label>'
			+'</rdf:Description>'
			+'<rdf:Description rdf:nodeID="SearchResults">'
			+'<rdf:type rdf:resource="http://profiles.catalyst.harvard.edu/ontology/prns#Network" />'
			+'<rdfs:label>Search Results</rdfs:label>'
			+'<vivo:overview rdf:parseType="Literal">'
			+CAST(@SearchOptions AS NVARCHAR(MAX))
			+IsNull('<SearchDetails>'+CAST(@SearchPhraseXML AS NVARCHAR(MAX))+'</SearchDetails>','')
			+'</vivo:overview>'
			+'<prns:hasConnection rdf:nodeID="SearchResultsDetails" />'
			+'</rdf:Description>'
			+IsNull(@ObjectNodeRDF,'')
			+'<rdf:Description rdf:NodeID="ConnectionDetails">'
			+'<rdf:type rdf:resource="http://profiles.catalyst.harvard.edu/ontology/prns#ConnectionDetails" />'
			+'<vivo:overview rdf:parseType="Literal">'
			+CAST(@ConnectionDetailsXML AS NVARCHAR(MAX))
			+'</vivo:overview>'
			+'</rdf:Description> '

	declare @x as varchar(max)
	select @x = '<rdf:RDF'
	select @x = @x + ' xmlns:'+Prefix+'="'+URI+'"' 
		from [Ontology.].Namespace
	select @x = @x + ' >' + @results + '</rdf:RDF>'
	select cast(@x as xml) RDF

/*


	EXEC [Search.].[GetNodes] @SearchOptions = '
	<SearchOptions>
		<MatchOptions>
			<SearchString ExactMatch="false">options for "lung cancer" treatment</SearchString>
			<ClassURI>http://xmlns.com/foaf/0.1/Person</ClassURI>
		</MatchOptions>
		<OutputOptions>
			<Offset>0</Offset>
			<Limit>5</Limit>
		</OutputOptions>	
	</SearchOptions>
	'

	EXEC [Search.].[GetConnection] @SearchOptions = '
	<SearchOptions>
		<MatchOptions>
			<SearchString ExactMatch="false">options for "lung cancer" treatment</SearchString>
			<ClassURI>http://xmlns.com/foaf/0.1/Person</ClassURI>
		</MatchOptions>
		<OutputOptions>
			<Offset>0</Offset>
			<Limit>5</Limit>
		</OutputOptions>	
	</SearchOptions>
	', @NodeURI = 'http://localhost:55956/profile/1069731'


*/

END
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [Search.Cache].[Public.GetNodes]
	@SearchOptions XML,
	@SessionID UNIQUEIDENTIFIER = NULL,
	@NoRDF BIT =0,
	@JSON VARCHAR(max) = null output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
		-- interfering with SELECT statements.
		SET NOCOUNT ON;

	/*
	
	EXEC [Search.].[GetNodes] @SearchOptions = '
	<SearchOptions>
		<MatchOptions>
			<SearchString ExactMatch="false">options for "lung cancer" treatment</SearchString>
			<ClassURI>http://xmlns.com/foaf/0.1/Person</ClassURI>
			<SearchFiltersList>
				<SearchFilter Property="http://xmlns.com/foaf/0.1/lastName" MatchType="Left">Smit</SearchFilter>
			</SearchFiltersList>
		</MatchOptions>
		<OutputOptions>
			<Offset>0</Offset>
			<Limit>5</Limit>
			<SortByList>
				<SortBy IsDesc="1" Property="http://xmlns.com/foaf/0.1/firstName" />
				<SortBy IsDesc="0" Property="http://xmlns.com/foaf/0.1/lastName" />
			</SortByList>
		</OutputOptions>	
	</SearchOptions>
	'
		
	*/

	declare @MatchOptions xml
	declare @OutputOptions xml
	declare @SearchString varchar(500)
	declare @ClassGroupURI varchar(400)
	declare @ClassURI varchar(400)
	declare @SearchFiltersXML xml
	declare @offset bigint
	declare @limit bigint
	declare @SortByXML xml
	declare @DoExpandedSearch bit
	
	select	@MatchOptions = @SearchOptions.query('SearchOptions[1]/MatchOptions[1]'),
			@OutputOptions = @SearchOptions.query('SearchOptions[1]/OutputOptions[1]')
	
	select	@SearchString = @MatchOptions.value('MatchOptions[1]/SearchString[1]','varchar(500)'),
			@DoExpandedSearch = (case when @MatchOptions.value('MatchOptions[1]/SearchString[1]/@ExactMatch','varchar(50)') = 'true' then 0 else 1 end),
			@ClassGroupURI = @MatchOptions.value('MatchOptions[1]/ClassGroupURI[1]','varchar(400)'),
			@ClassURI = @MatchOptions.value('MatchOptions[1]/ClassURI[1]','varchar(400)'),
			@SearchFiltersXML = @MatchOptions.query('MatchOptions[1]/SearchFiltersList[1]'),
			@offset = @OutputOptions.value('OutputOptions[1]/Offset[1]','bigint'),
			@limit = @OutputOptions.value('OutputOptions[1]/Limit[1]','bigint'),
			@SortByXML = @OutputOptions.query('OutputOptions[1]/SortByList[1]')

	declare @baseURI nvarchar(400)
	select @baseURI = value from [Framework.].Parameter where ParameterID = 'baseURI'

	declare @d datetime
	select @d = GetDate()
	
	declare @IsBot bit
	if @SessionID is not null
		select @IsBot = IsBot
			from [User.Session].[Session]
			where SessionID = @SessionID
	select @IsBot = IsNull(@IsBot,0)

	select @limit = 100
		where (@limit is null) or (@limit > 100)
	
	declare @SearchHistoryQueryID int
	insert into [Search.].[History.Query] (StartDate, SessionID, IsBot, SearchOptions)
		select GetDate(), @SessionID, @IsBot, @SearchOptions
	select @SearchHistoryQueryID = @@IDENTITY

	-------------------------------------------------------
	-- Parse search string and convert to fulltext query
	-------------------------------------------------------
/*
	declare @NumberOfPhrases INT
	declare @CombinedSearchString VARCHAR(8000)
	declare @SearchPhraseXML XML
	declare @SearchPhraseFormsXML XML
	declare @ParseProcessTime INT

	EXEC [Search.].[ParseSearchString]	@SearchString = @SearchString,
										@NumberOfPhrases = @NumberOfPhrases OUTPUT,
										@CombinedSearchString = @CombinedSearchString OUTPUT,
										@SearchPhraseXML = @SearchPhraseXML OUTPUT,
										@SearchPhraseFormsXML = @SearchPhraseFormsXML OUTPUT,
										@ProcessTime = @ParseProcessTime OUTPUT

*/

	declare @NumberOfPhrases INT
	declare @CombinedSearchString VARCHAR(8000)
	declare @SearchString1 VARCHAR(8000)
	declare @SearchString2 VARCHAR(8000)
	declare @SearchString3 VARCHAR(8000)
	declare @SearchPhraseXML XML
	declare @SearchPhraseFormsXML XML
	declare @ParseProcessTime INT

	EXEC [Search.].[ParseSearchString]	@SearchString = @SearchString,
										@NumberOfPhrases = @NumberOfPhrases OUTPUT,
										@CombinedSearchString = @CombinedSearchString OUTPUT,
										@SearchString1 = @SearchString1 OUTPUT,
										@SearchString2 = @SearchString2 OUTPUT,
										@SearchString3 = @SearchString3 OUTPUT,
										@SearchPhraseXML = @SearchPhraseXML OUTPUT,
										@SearchPhraseFormsXML = @SearchPhraseFormsXML OUTPUT,
										@ProcessTime = @ParseProcessTime OUTPUT


	declare @PhraseList table (PhraseID int, Phrase varchar(max), ThesaurusMatch bit, Forms varchar(max))
	insert into @PhraseList (PhraseID, Phrase, ThesaurusMatch, Forms)
	select	x.value('@ID','INT'),
			x.value('.','VARCHAR(MAX)'),
			x.value('@ThesaurusMatch','BIT'),
			x.value('@Forms','VARCHAR(MAX)')
		from @SearchPhraseFormsXML.nodes('//SearchPhrase') as p(x)

	--SELECT @NumberOfPhrases, @CombinedSearchString, @SearchPhraseXML, @SearchPhraseFormsXML, @ParseProcessTime, @SearchString1, @SearchString2, @SearchString3
	--SELECT * FROM @PhraseList
	--select datediff(ms,@d,GetDate())


	-------------------------------------------------------
	-- Parse search filters
	-------------------------------------------------------

	create table #SearchFilters (
		SearchFilterID int identity(0,1) primary key,
		IsExclude bit,
		PropertyURI varchar(400),
		PropertyURI2 varchar(400),
		MatchType varchar(100),
		Value varchar(750),
		Predicate bigint,
		Predicate2 bigint
	)
	
	insert into #SearchFilters (IsExclude, PropertyURI, PropertyURI2, MatchType, Value, Predicate, Predicate2)	
		select t.IsExclude, t.PropertyURI, t.PropertyURI2, t.MatchType, t.Value,
				--left(t.Value,750)+(case when t.MatchType='Left' then '%' else '' end),
				t.Predicate, t.Predicate2
			from (
				select IsNull(IsExclude,0) IsExclude, PropertyURI, PropertyURI2, MatchType, Value,
					[RDF.].fnURI2NodeID(PropertyURI) Predicate,
					[RDF.].fnURI2NodeID(PropertyURI2) Predicate2
				from (
					select distinct S.x.value('@IsExclude','bit') IsExclude,
							S.x.value('@Property','varchar(400)') PropertyURI,
							S.x.value('@Property2','varchar(400)') PropertyURI2,
							S.x.value('@MatchType','varchar(100)') MatchType,
							--S.x.value('.','nvarchar(max)') Value
							(case when cast(S.x.query('./*') as nvarchar(max)) <> '' then cast(S.x.query('./*') as nvarchar(max)) else S.x.value('.','nvarchar(max)') end) Value
					from @SearchFiltersXML.nodes('//SearchFilter') as S(x)
				) t
			) t
			where t.Value IS NOT NULL and t.Value <> ''
			
	declare @NumberOfIncludeFilters int
	select @NumberOfIncludeFilters = IsNull((select count(*) from #SearchFilters where IsExclude=0),0)

	-------------------------------------------------------
	-- Parse sort by options
	-------------------------------------------------------

	create table #SortBy (
		SortByID int identity(1,1) primary key,
		IsDesc bit,
		PropertyURI varchar(400),
		PropertyURI2 varchar(400),
		PropertyURI3 varchar(400),
		Predicate bigint,
		Predicate2 bigint,
		Predicate3 bigint
	)
	
	insert into #SortBy (IsDesc, PropertyURI, PropertyURI2, PropertyURI3, Predicate, Predicate2, Predicate3)	
		select IsNull(IsDesc,0), PropertyURI, PropertyURI2, PropertyURI3,
				[RDF.].fnURI2NodeID(PropertyURI) Predicate,
				[RDF.].fnURI2NodeID(PropertyURI2) Predicate2,
				[RDF.].fnURI2NodeID(PropertyURI3) Predicate3
			from (
				select S.x.value('@IsDesc','bit') IsDesc,
						S.x.value('@Property','varchar(400)') PropertyURI,
						S.x.value('@Property2','varchar(400)') PropertyURI2,
						S.x.value('@Property3','varchar(400)') PropertyURI3
				from @SortByXML.nodes('//SortBy') as S(x)
			) t

	-------------------------------------------------------
	-- Get initial list of matching nodes (before filters)
	-------------------------------------------------------

	create table #FullNodeMatch (
		NodeID bigint not null,
		Paths bigint,
		Weight float
	)

	if @CombinedSearchString <> ''
	begin

		-- Get nodes that match separate phrases
		create table #PhraseNodeMatch (
			PhraseID int not null,
			NodeID bigint not null,
			Paths bigint,
			Weight float
		)
		if (@NumberOfPhrases > 1) and (@DoExpandedSearch = 1)
		begin
			declare @PhraseSearchString varchar(8000)
			declare @loop int
			select @loop = 1
			while @loop <= @NumberOfPhrases
			begin
				select @PhraseSearchString = Forms
					from @PhraseList
					where PhraseID = @loop
				select * into #NodeRankTemp from containstable ([RDF.].[vwLiteral], value, @PhraseSearchString, 100000)
				alter table #NodeRankTemp add primary key ([Key])
				insert into #PhraseNodeMatch (PhraseID, NodeID, Paths, Weight)
					select @loop, s.NodeID, count(*) Paths, 1-exp(sum(log(case when s.Weight*(m.[Rank]*0.000999+0.001) > 0.999999 then 0.000001 else 1-s.Weight*(m.[Rank]*0.000999+0.001) end))) Weight
						from #NodeRankTemp m
							inner loop join [Search.Cache].[Public.NodeMap] s
								on s.MatchedByNodeID = m.[Key]
						group by s.NodeID
				drop table #NodeRankTemp
				select @loop = @loop + 1
			end
			--create clustered index idx_n on #PhraseNodeMatch(NodeID)
		end

		-- Get nodes that match the combined search string
		create table #TempMatchNodes (
			NodeID bigint,
			MatchedByNodeID bigint,
			Distance int,
			Paths int,
			Weight float,
			mWeight float
		)
		-- Run each search string
		if @SearchString1 <> ''
				select * into #CombinedSearch1 from containstable ([RDF.].[vwLiteral], value, @SearchString1, 100000) t
		if @SearchString2 <> ''
				select * into #CombinedSearch2 from containstable ([RDF.].[vwLiteral], value, @SearchString2, 100000) t
		if @SearchString3 <> ''
				select * into #CombinedSearch3 from containstable ([RDF.].[vwLiteral], value, @SearchString3, 100000) t
		-- Combine each search string
		create table #CombinedSearch ([key] bigint primary key, [rank] int)
		if IsNull(@SearchString1,'') <> '' and IsNull(@SearchString2,'') = '' and IsNull(@SearchString3,'') = ''
			insert into #CombinedSearch select [key], max([rank]) [rank] from #CombinedSearch1 t group by [key]
		if IsNull(@SearchString1,'') <> '' and IsNull(@SearchString2,'') <> '' and IsNull(@SearchString3,'') = ''
			insert into #CombinedSearch select [key], max([rank]) [rank] from (select * from #CombinedSearch1 union all select * from #CombinedSearch2) t group by [key]
		if IsNull(@SearchString1,'') <> '' and IsNull(@SearchString2,'') <> '' and IsNull(@SearchString3,'') <> ''
			insert into #CombinedSearch select [key], max([rank]) [rank] from (select * from #CombinedSearch1 union all select * from #CombinedSearch2 union all select * from #CombinedSearch3) t group by [key]
		-- Get the TempMatchNodes
		insert into #TempMatchNodes (NodeID, MatchedByNodeID, Distance, Paths, Weight, mWeight)
			select s.*, m.[Rank]*0.000999+0.001 mWeight
				from #CombinedSearch m
					inner loop join [Search.Cache].[Public.NodeMap] s
						on s.MatchedByNodeID = m.[key]
		-- Delete temp tables
		if @SearchString1 <> ''
				drop table #CombinedSearch1
		if @SearchString2 <> ''
				drop table #CombinedSearch2
		if @SearchString3 <> ''
				drop table #CombinedSearch3
		drop table #CombinedSearch

		-- Get nodes that match either all phrases or the combined search string
		insert into #FullNodeMatch (NodeID, Paths, Weight)
			select IsNull(a.NodeID,b.NodeID) NodeID, IsNull(a.Paths,b.Paths) Paths,
					(case when a.weight is null or b.weight is null then IsNull(a.Weight,b.Weight) else 1-(1-a.Weight)*(1-b.Weight) end) Weight
				from (
					select NodeID, exp(sum(log(Paths))) Paths, exp(sum(log(Weight))) Weight
						from #PhraseNodeMatch
						group by NodeID
						having count(*) = @NumberOfPhrases
				) a full outer join (
					select NodeID, count(*) Paths, 1-exp(sum(log(case when Weight*mWeight > 0.999999 then 0.000001 else 1-Weight*mWeight end))) Weight
						from #TempMatchNodes
						group by NodeID
				) b on a.NodeID = b.NodeID
		--select 'Text Matches Found', datediff(ms,@d,getdate())
	end
	else if (@NumberOfIncludeFilters > 0)
	begin
		insert into #FullNodeMatch (NodeID, Paths, Weight)
			select t1.Subject, 1, 1
				from #SearchFilters f
					inner join [RDF.].Triple t1
						on f.Predicate is not null
							and t1.Predicate = f.Predicate 
							and t1.ViewSecurityGroup = -1
					left outer join [Search.Cache].[Public.NodePrefix] n1
						on n1.NodeID = t1.Object
					left outer join [RDF.].Triple t2
						on f.Predicate2 is not null
							and t2.Subject = n1.NodeID
							and t2.Predicate = f.Predicate2
							and t2.ViewSecurityGroup = -1
					left outer join [Search.Cache].[Public.NodePrefix] n2
						on n2.NodeID = t2.Object
				where f.IsExclude = 0
					and 1 = (case	when (f.Predicate2 is not null) then
										(case	when f.MatchType = 'Left' then
													(case when n2.Prefix like f.Value+'%' then 1 else 0 end)
												when f.MatchType = 'In' then
													(case when n2.Prefix in (select r.x.value('.','varchar(max)') v from (select cast(f.Value as xml) x) t cross apply x.nodes('//Item') as r(x)) then 1 else 0 end)
												else
													(case when n2.Prefix = f.Value then 1 else 0 end)
												end)
									else
										(case	when f.MatchType = 'Left' then
													(case when n1.Prefix like f.Value+'%' then 1 else 0 end)
												when f.MatchType = 'In' then
													(case when n1.Prefix in (select r.x.value('.','varchar(max)') v from (select cast(f.Value as xml) x) t cross apply x.nodes('//Item') as r(x)) then 1 else 0 end)
												else
													(case when n1.Prefix = f.Value then 1 else 0 end)
												end)
									end)
					--and (case when f.Predicate2 is not null then n2.Prefix else n1.Prefix end)
					--	like f.Value
				group by t1.Subject
				having count(distinct f.SearchFilterID) = @NumberOfIncludeFilters
		delete from #SearchFilters where IsExclude = 0
		select @NumberOfIncludeFilters = 0
	end
	else if (IsNull(@ClassGroupURI,'') <> '' or IsNull(@ClassURI,'') <> '')
	begin
		insert into #FullNodeMatch (NodeID, Paths, Weight)
			select distinct n.NodeID, 1, 1
				from [Search.Cache].[Public.NodeClass] n, [Ontology.].ClassGroupClass c
				where n.Class = c._ClassNode
					and ((@ClassGroupURI is null) or (c.ClassGroupURI = @ClassGroupURI))
					and ((@ClassURI is null) or (c.ClassURI = @ClassURI))
		select @ClassGroupURI = null, @ClassURI = null
	end

	-------------------------------------------------------
	-- Run the actual search
	-------------------------------------------------------
	create table #Node (
		SortOrder bigint identity(0,1) primary key,
		NodeID bigint,
		Paths bigint,
		Weight float
	)

	insert into #Node (NodeID, Paths, Weight)
		select s.NodeID, s.Paths, s.Weight
			from #FullNodeMatch s
				inner join [Search.Cache].[Public.NodeSummary] n on
					s.NodeID = n.NodeID
					and ( IsNull(@ClassGroupURI,@ClassURI) is null or s.NodeID in (
							select NodeID
								from [Search.Cache].[Public.NodeClass] x, [Ontology.].ClassGroupClass c
								where x.Class = c._ClassNode
									and c.ClassGroupURI = IsNull(@ClassGroupURI,c.ClassGroupURI)
									and c.ClassURI = IsNull(@ClassURI,c.ClassURI)
						) )
					and ( @NumberOfIncludeFilters =
							(select count(distinct f.SearchFilterID)
								from #SearchFilters f
									inner join [RDF.].Triple t1
										on f.Predicate is not null
											and t1.Subject = s.NodeID
											and t1.Predicate = f.Predicate 
											and t1.ViewSecurityGroup = -1
									left outer join [Search.Cache].[Public.NodePrefix] n1
										on n1.NodeID = t1.Object
									left outer join [RDF.].Triple t2
										on f.Predicate2 is not null
											and t2.Subject = n1.NodeID
											and t2.Predicate = f.Predicate2
											and t2.ViewSecurityGroup = -1
									left outer join [Search.Cache].[Public.NodePrefix] n2
										on n2.NodeID = t2.Object
								where f.IsExclude = 0
									and 1 = (case	when (f.Predicate2 is not null) then
														(case	when f.MatchType = 'Left' then
																	(case when n2.Prefix like f.Value+'%' then 1 else 0 end)
																when f.MatchType = 'In' then
																	(case when n2.Prefix in (select r.x.value('.','varchar(max)') v from (select cast(f.Value as xml) x) t cross apply x.nodes('//Item') as r(x)) then 1 else 0 end)
																else
																	(case when n2.Prefix = f.Value then 1 else 0 end)
																end)
													else
														(case	when f.MatchType = 'Left' then
																	(case when n1.Prefix like f.Value+'%' then 1 else 0 end)
																when f.MatchType = 'In' then
																	(case when n1.Prefix in (select r.x.value('.','varchar(max)') v from (select cast(f.Value as xml) x) t cross apply x.nodes('//Item') as r(x)) then 1 else 0 end)
																else
																	(case when n1.Prefix = f.Value then 1 else 0 end)
																end)
													end)
									--and (case when f.Predicate2 is not null then n2.Prefix else n1.Prefix end)
									--	like f.Value
							)
						)
					and not exists (
							select *
								from #SearchFilters f
									inner join [RDF.].Triple t1
										on f.Predicate is not null
											and t1.Subject = s.NodeID
											and t1.Predicate = f.Predicate 
											and t1.ViewSecurityGroup = -1
									left outer join [Search.Cache].[Public.NodePrefix] n1
										on n1.NodeID = t1.Object
									left outer join [RDF.].Triple t2
										on f.Predicate2 is not null
											and t2.Subject = n1.NodeID
											and t2.Predicate = f.Predicate2
											and t2.ViewSecurityGroup = -1
									left outer join [Search.Cache].[Public.NodePrefix] n2
										on n2.NodeID = t2.Object
								where f.IsExclude = 1
									and 1 = (case	when (f.Predicate2 is not null) then
														(case	when f.MatchType = 'Left' then
																	(case when n2.Prefix like f.Value+'%' then 1 else 0 end)
																when f.MatchType = 'In' then
																	(case when n2.Prefix in (select r.x.value('.','varchar(max)') v from (select cast(f.Value as xml) x) t cross apply x.nodes('//Item') as r(x)) then 1 else 0 end)
																else
																	(case when n2.Prefix = f.Value then 1 else 0 end)
																end)
													else
														(case	when f.MatchType = 'Left' then
																	(case when n1.Prefix like f.Value+'%' then 1 else 0 end)
																when f.MatchType = 'In' then
																	(case when n1.Prefix in (select r.x.value('.','varchar(max)') v from (select cast(f.Value as xml) x) t cross apply x.nodes('//Item') as r(x)) then 1 else 0 end)
																else
																	(case when n1.Prefix = f.Value then 1 else 0 end)
																end)
													end)
									--and (case when f.Predicate2 is not null then n2.Prefix else n1.Prefix end)
									--	like f.Value
						)
				outer apply (
					select	max(case when SortByID=1 then AscSortBy else null end) AscSortBy1,
							max(case when SortByID=2 then AscSortBy else null end) AscSortBy2,
							max(case when SortByID=3 then AscSortBy else null end) AscSortBy3,
							max(case when SortByID=1 then DescSortBy else null end) DescSortBy1,
							max(case when SortByID=2 then DescSortBy else null end) DescSortBy2,
							max(case when SortByID=3 then DescSortBy else null end) DescSortBy3
						from (
							select	SortByID,
									(case when f.IsDesc = 1 then null
											when f.Predicate3 is not null then n3.Value
											when f.Predicate2 is not null then n2.Value
											else n1.Value end) AscSortBy,
									(case when f.IsDesc = 0 then null
											when f.Predicate3 is not null then n3.Value
											when f.Predicate2 is not null then n2.Value
											else n1.Value end) DescSortBy
								from #SortBy f
									inner join [RDF.].Triple t1
										on f.Predicate is not null
											and t1.Subject = s.NodeID
											and t1.Predicate = f.Predicate 
											and t1.ViewSecurityGroup = -1
									left outer join [RDF.].Node n1
										on n1.NodeID = t1.Object
											and n1.ViewSecurityGroup = -1
									left outer join [RDF.].Triple t2
										on f.Predicate2 is not null
											and t2.Subject = n1.NodeID
											and t2.Predicate = f.Predicate2
											and t2.ViewSecurityGroup = -1
									left outer join [RDF.].Node n2
										on n2.NodeID = t2.Object
											and n2.ViewSecurityGroup = -1
									left outer join [RDF.].Triple t3
										on f.Predicate3 is not null
											and t3.Subject = n2.NodeID
											and t3.Predicate = f.Predicate3
											and t3.ViewSecurityGroup = -1
									left outer join [RDF.].Node n3
										on n3.NodeID = t3.Object
											and n3.ViewSecurityGroup = -1
							) t
					) o
			order by	(case when o.AscSortBy1 is null then 1 else 0 end),
						o.AscSortBy1,
						(case when o.DescSortBy1 is null then 1 else 0 end),
						o.DescSortBy1 desc,
						(case when o.AscSortBy2 is null then 1 else 0 end),
						o.AscSortBy2,
						(case when o.DescSortBy2 is null then 1 else 0 end),
						o.DescSortBy2 desc,
						(case when o.AscSortBy3 is null then 1 else 0 end),
						o.AscSortBy3,
						(case when o.DescSortBy3 is null then 1 else 0 end),
						o.DescSortBy3 desc,
						s.Weight desc,
						n.ShortLabel,
						n.NodeID

	if @NoRDF = 1
	BEGIN
		SELECT * FROM #Node
		return 
	END

	if @JSON is not null
	BEGIN
		--select @json = (select SortOrder, NodeID, ROUND(Weight, 3) Weight from #Node order by SortOrder offset @offset ROWS FETCH NEXT @limit ROWS ONLY for JSON PATH )
		select @json = (select SortOrder, NodeID, ROUND(Weight, 3) Weight from #Node /*order by SortOrder offset @offset ROWS FETCH NEXT @limit ROWS ONLY*/ for JSON PATH )


		update [Search.].[History.Query]
			set EndDate = GetDate(),
				DurationMS = datediff(ms,StartDate,GetDate()),
				NumberOfConnections = (select count(*) from #node)
			where SearchHistoryQueryID = @SearchHistoryQueryID
	
		insert into [Search.].[History.Phrase] (SearchHistoryQueryID, PhraseID, ThesaurusMatch, Phrase, EndDate, IsBot, NumberOfConnections)
			select	@SearchHistoryQueryID,
					PhraseID,
					ThesaurusMatch,
					Phrase,
					GetDate(),
					@IsBot,
					(select count(*) from #node)
				from @PhraseList


		return
	END

	--select 'Search Nodes Found', datediff(ms,@d,GetDate())

	-------------------------------------------------------
	-- Get network counts
	-------------------------------------------------------

	declare @NumberOfConnections as bigint
	declare @MaxWeight as float
	declare @MinWeight as float

	select @NumberOfConnections = count(*), @MaxWeight = max(Weight), @MinWeight = min(Weight) 
		from #Node

	-------------------------------------------------------
	-- Get matching class groups and classes
	-------------------------------------------------------

	declare @MatchesClassGroups nvarchar(max)

/*
	select c.ClassGroupURI, c.ClassURI, n.NodeID
		into #NodeClass
		from #Node n, [Search.Cache].[Public.NodeClass] s, [Ontology.].ClassGroupClass c
		where n.NodeID = s.NodeID and s.Class = c._ClassNode
*/

	select n.NodeID, s.Class
		into #NodeClassTemp
		from #Node n
			inner join [Search.Cache].[Public.NodeClass] s
				on n.NodeID = s.NodeID
	select c.ClassGroupURI, c.ClassURI, n.NodeID
		into #NodeClass
		from #NodeClassTemp n
			inner join [Ontology.].ClassGroupClass c
				on n.Class = c._ClassNode

	;with a as (
		select ClassGroupURI, count(distinct NodeID) NumberOfNodes
			from #NodeClass s
			group by ClassGroupURI
	), b as (
		select ClassGroupURI, ClassURI, count(distinct NodeID) NumberOfNodes
			from #NodeClass s
			group by ClassGroupURI, ClassURI
	)
	select @MatchesClassGroups = replace(cast((
			select	g.ClassGroupURI "@rdf_.._resource", 
				g._ClassGroupLabel "rdfs_.._label",
				'http://www.w3.org/2001/XMLSchema#int' "prns_.._numberOfConnections/@rdf_.._datatype",
				a.NumberOfNodes "prns_.._numberOfConnections",
				g.SortOrder "prns_.._sortOrder",
				(
					select	c.ClassURI "@rdf_.._resource",
							c._ClassLabel "rdfs_.._label",
							'http://www.w3.org/2001/XMLSchema#int' "prns_.._numberOfConnections/@rdf_.._datatype",
							b.NumberOfNodes "prns_.._numberOfConnections",
							c.SortOrder "prns_.._sortOrder"
						from b, [Ontology.].ClassGroupClass c
						where b.ClassGroupURI = c.ClassGroupURI and b.ClassURI = c.ClassURI
							and c.ClassGroupURI = g.ClassGroupURI
						order by c.SortOrder
						for xml path('prns_.._matchesClass'), type
				)
			from a, [Ontology.].ClassGroup g
			where a.ClassGroupURI = g.ClassGroupURI and g.IsVisible = 1
			order by g.SortOrder
			for xml path('prns_.._matchesClassGroup'), type
		) as nvarchar(max)),'_.._',':')

	-------------------------------------------------------
	-- Get RDF of search results objects
	-------------------------------------------------------

	declare @ObjectNodesRDF nvarchar(max)

	if @NumberOfConnections > 0
	begin
		/*
			-- Alternative methods that uses GetDataRDF to get the RDF
			declare @NodeListXML xml
			select @NodeListXML = (
					select (
							select NodeID "@ID"
							from #Node
							where SortOrder >= IsNull(@offset,0) and SortOrder < IsNull(IsNull(@offset,0)+@limit,SortOrder+1)
							order by SortOrder
							for xml path('Node'), type
							)
					for xml path('NodeList'), type
				)
			exec [RDF.].GetDataRDF @NodeListXML = @NodeListXML, @expand = 1, @showDetails = 0, @returnXML = 0, @dataStr = @ObjectNodesRDF OUTPUT
		*/
		create table #OutputNodes (
			NodeID bigint primary key,
			k int
		)
		insert into #OutputNodes (NodeID,k)
			SELECT DISTINCT  NodeID,0
			from #Node
			where SortOrder >= IsNull(@offset,0) and SortOrder < IsNull(IsNull(@offset,0)+@limit,SortOrder+1)
		declare @k int
		select @k = 0
		while @k < 10
		begin
			insert into #OutputNodes (NodeID,k)
				select distinct e.ExpandNodeID, @k+1
				from #OutputNodes o, [Search.Cache].[Public.NodeExpand] e
				where o.k = @k and o.NodeID = e.NodeID
					and e.ExpandNodeID not in (select NodeID from #OutputNodes)
			if @@ROWCOUNT = 0
				select @k = 10
			else
				select @k = @k + 1
		end
		select @ObjectNodesRDF = replace(replace(cast((
				select r.RDF + ''
				from #OutputNodes n, [Search.Cache].[Public.NodeRDF] r
				where n.NodeID = r.NodeID
				order by n.NodeID
				for xml path(''), type
			) as nvarchar(max)),'_TAGLT_','<'),'_TAGGT_','>')
	end


	-------------------------------------------------------
	-- Form search results RDF
	-------------------------------------------------------

	declare @results nvarchar(max)

	select @results = ''
			+'<rdf:Description rdf:nodeID="SearchResults">'
			+'<rdf:type rdf:resource="http://profiles.catalyst.harvard.edu/ontology/prns#Network" />'
			+'<rdfs:label>Search Results</rdfs:label>'
			+'<prns:numberOfConnections rdf:datatype="http://www.w3.org/2001/XMLSchema#int">'+cast(IsNull(@NumberOfConnections,0) as nvarchar(50))+'</prns:numberOfConnections>'
			+'<prns:offset rdf:datatype="http://www.w3.org/2001/XMLSchema#int"' + IsNull('>'+cast(@offset as nvarchar(50))+'</prns:offset>',' />')
			+'<prns:limit rdf:datatype="http://www.w3.org/2001/XMLSchema#int"' + IsNull('>'+cast(@limit as nvarchar(50))+'</prns:limit>',' />')
			+'<prns:maxWeight rdf:datatype="http://www.w3.org/2001/XMLSchema#float"' + IsNull('>'+cast(@MaxWeight as nvarchar(50))+'</prns:maxWeight>',' />')
			+'<prns:minWeight rdf:datatype="http://www.w3.org/2001/XMLSchema#float"' + IsNull('>'+cast(@MinWeight as nvarchar(50))+'</prns:minWeight>',' />')
			+'<vivo:overview rdf:parseType="Literal">'
			+IsNull(cast(@SearchOptions as nvarchar(max)),'')
			+'<SearchDetails>'+IsNull(cast(@SearchPhraseXML as nvarchar(max)),'')+'</SearchDetails>'
			+IsNull('<prns:matchesClassGroupsList>'+@MatchesClassGroups+'</prns:matchesClassGroupsList>','')
			+'</vivo:overview>'
			+IsNull((select replace(replace(cast((
					select '_TAGLT_prns:hasConnection rdf:nodeID="C'+cast(SortOrder as nvarchar(50))+'" /_TAGGT_'
					from #Node
					where SortOrder >= IsNull(@offset,0) and SortOrder < IsNull(IsNull(@offset,0)+@limit,SortOrder+1)
					order by SortOrder
					for xml path(''), type
				) as nvarchar(max)),'_TAGLT_','<'),'_TAGGT_','>')),'')
			+'</rdf:Description>'
			+IsNull((select replace(replace(cast((
					select ''
						+'_TAGLT_rdf:Description rdf:nodeID="C'+cast(x.SortOrder as nvarchar(50))+'"_TAGGT_'
						+'_TAGLT_prns:connectionWeight_TAGGT_'+cast(x.Weight as nvarchar(50))+'_TAGLT_/prns:connectionWeight_TAGGT_'
						+'_TAGLT_prns:sortOrder_TAGGT_'+cast(x.SortOrder as nvarchar(50))+'_TAGLT_/prns:sortOrder_TAGGT_'
						+'_TAGLT_rdf:object rdf:resource="'+replace(n.Value,'"','')+'"/_TAGGT_'
						+'_TAGLT_rdf:type rdf:resource="http://profiles.catalyst.harvard.edu/ontology/prns#Connection" /_TAGGT_'
						+'_TAGLT_rdfs:label_TAGGT_'+(case when s.ShortLabel<>'' then ltrim(rtrim(s.ShortLabel)) else 'Untitled' end)+'_TAGLT_/rdfs:label_TAGGT_'
						+IsNull(+'_TAGLT_vivo:overview_TAGGT_'+s.ClassName+'_TAGLT_/vivo:overview_TAGGT_','')
						+'_TAGLT_/rdf:Description_TAGGT_'
					from #Node x, [RDF.].Node n, [Search.Cache].[Public.NodeSummary] s
					where x.SortOrder >= IsNull(@offset,0) and x.SortOrder < IsNull(IsNull(@offset,0)+@limit,x.SortOrder+1)
						and x.NodeID = n.NodeID
						and x.NodeID = s.NodeID
					order by x.SortOrder
					for xml path(''), type
				) as nvarchar(max)),'_TAGLT_','<'),'_TAGGT_','>')),'')
			+IsNull(@ObjectNodesRDF,'')

	declare @x as varchar(max)
	select @x = '<rdf:RDF'
	select @x = @x + ' xmlns:'+Prefix+'="'+URI+'"' 
		from [Ontology.].Namespace
	select @x = @x + ' >' + @results + '</rdf:RDF>'
	select cast(@x as xml) RDF


	-------------------------------------------------------
	-- Log results
	-------------------------------------------------------

	update [Search.].[History.Query]
		set EndDate = GetDate(),
			DurationMS = datediff(ms,StartDate,GetDate()),
			NumberOfConnections = IsNull(@NumberOfConnections,0)
		where SearchHistoryQueryID = @SearchHistoryQueryID
	
	insert into [Search.].[History.Phrase] (SearchHistoryQueryID, PhraseID, ThesaurusMatch, Phrase, EndDate, IsBot, NumberOfConnections)
		select	@SearchHistoryQueryID,
				PhraseID,
				ThesaurusMatch,
				Phrase,
				GetDate(),
				@IsBot,
				IsNull(@NumberOfConnections,0)
			from @PhraseList

END
GO









GO
PRINT N'Update complete.';


GO

