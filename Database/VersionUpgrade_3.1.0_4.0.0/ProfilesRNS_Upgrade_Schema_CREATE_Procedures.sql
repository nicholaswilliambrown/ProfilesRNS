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
CREATE PROCEDURE [Display.].[GetActivity]
	@activityLogIDs varchar(max)
AS
BEGIN
	declare @logIDsTable table (activityLogID int)
	insert into @logIDsTable select * from string_split(@activityLogIDs, ',')

	declare @relativeBasePath varchar(max)
	select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'

	declare @json nvarchar(max)

	select @json = 
		(SELECT i.activityLogID,
			p.personid,n.nodeid,p.firstname,p.lastname, @relativeBasePath + isnull(defaultApplication, '') + PreferredPath as URL,
			md.label, i.methodName,i.property,cp._PropertyLabel as propertyLabel,i.param1,i.param2,i.createdDT, g.JournalTitle, fa.AgreementLabel, gg.GroupName
			FROM [Framework.].[Log.Activity] i 
			join @logIDsTable a on i.activityLogId = a.activityLogID
			join [Display.].[Activity.Log.MethodDetails] md on i.methodName = md.methodName and i.Property = isnull(md.property, i.property)
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
			 for json path)

	if @json is null set @json = '[]'

	select @json
END
GO
/****** Object:  StoredProcedure [Display.].[GetDataRDF]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.].[GetDataRDF]
	@subject BIGINT=NULL,
	@predicate BIGINT=NULL,
	@object BIGINT=NULL,
	@offset BIGINT=NULL,
	@limit BIGINT=NULL,
	@showDetails BIT=1,
	@expand BIT=1,
	@SessionID UNIQUEIDENTIFIER=NULL,
	@NodeListXML XML=NULL,
	@ExpandRDFListXML XML=NULL,
	@returnXML BIT=1,
	@returnXMLasStr BIT=0,
	@dataStr NVARCHAR (MAX)=NULL OUTPUT,
	@dataStrDataType NVARCHAR (255)=NULL OUTPUT,
	@dataStrLanguage NVARCHAR (255)=NULL OUTPUT,
	@RDF XML=NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	/*

	This stored procedure returns the data for a node in RDF format.

	Input parameters:
		@subject		The NodeID whose RDF should be returned.
		@predicate		The predicate NodeID for a network.
		@object			The object NodeID for a connection.
		@offset			Pagination - The first object node to return.
		@limit			Pagination - The number of object nodes to return.
		@showDetails	If 1, then additional properties will be returned.
		@expand			If 1, then object properties will be expanded.
		@SessionID		The SessionID of the user requesting the data.

	There are two ways to call this procedure. By default, @returnXML = 1,
	and the RDF is returned as XML. When @returnXML = 0, the data is instead
	returned as the strings @dataStr, @dataStrDataType, and @dataStrLanguage.
	This second method of calling this procedure is used by other procedures
	and is generally not called directly by the website.

	The RDF returned by this procedure is not equivalent to what is
	returned by SPARQL. This procedure applies security rules, expands
	nodes as defined by [Ontology.].[RDFExpand], and calculates network
	information on-the-fly.

	*/

	--declare @debugLogID int
	--insert into [RDF.].[GetDataRDF.DebugLog] (subject,predicate,object,offset,limit,showDetails,expand,SessionID,StartDate)
	--	select @subject,@predicate,@object,@offset,@limit,@showDetails,@expand,@SessionID,GetDate()
	--select @debugLogID = @@IDENTITY
	--insert into [RDF.].[GetDataRDF.DebugLog.ExpandRDFListXML] (LogID, ExpandRDFListXML)
	--	select @debugLogID, @ExpandRDFListXML

	
	declare @d datetime

	declare @baseURI nvarchar(400)
	select @baseURI = value from [Framework.].Parameter where ParameterID = 'baseURI'

	select @subject = null where @subject = 0
	select @predicate = null where @predicate = 0
	select @object = null where @object = 0
		
	declare @firstURI nvarchar(400)
	select @firstURI = @baseURI+cast(@subject as varchar(50))

	declare @firstValue nvarchar(400)
	select @firstValue = null
	
	declare @typeID bigint
	select @typeID = [RDF.].fnURI2NodeID('http://www.w3.org/1999/02/22-rdf-syntax-ns#type')

	declare @labelID bigint
	select @labelID = [RDF.].fnURI2NodeID('http://www.w3.org/2000/01/rdf-schema#label')	

	declare @validURI bit
	select @validURI = 1
	
	declare @includePredicates bit
	select @includePredicates = 1

	--*******************************************************************************************
	--*******************************************************************************************
	-- Define temp tables
	--*******************************************************************************************
	--*******************************************************************************************

	/*
		drop table #subjects
		drop table #types
		drop table #expand
		drop table #properties
		drop table #connections
	*/

	create table #subjects (
		subject bigint primary key,
		showDetail bit,
		expanded bit,
		uri nvarchar(400)
	)
	
	create table #types (
		subject bigint not null,
		object bigint not null,
		predicate bigint,
		showDetail bit,
		uri nvarchar(400)
	)
	create unique clustered index idx_sop on #types (subject,object,predicate)

	create table #expand (
		subject bigint not null,
		predicate bigint not null,
		uri nvarchar(400),
		property nvarchar(400),
		tagName nvarchar(1000),
		propertyLabel nvarchar(400),
		IsDetail bit,
		limit bigint,
		showStats bit,
		showSummary bit
	)
	alter table #expand add primary key (subject,predicate)

	create table #properties (
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

	create table #connections (
		subject bigint,
		subjectURI nvarchar(400),
		predicate bigint,
		predicateURI nvarchar(400),
		object bigint,
		Language nvarchar(255),
		DataType nvarchar(255),
		Value nvarchar(max),
		ObjectType bit,
		SortOrder int,
		Weight float,
		Reitification bigint,
		ReitificationURI nvarchar(400),
		connectionURI nvarchar(400)
	)
	
	create table #ClassPropertyCustom (
		ClassPropertyID int primary key,
		IncludeProperty bit,
		Limit int,
		IncludeNetwork bit,
		IncludeDescription bit,
		IsDetail bit
	)

	--*******************************************************************************************
	--*******************************************************************************************
	-- Setup variables used for security
	--*******************************************************************************************
	--*******************************************************************************************

	DECLARE @SecurityGroupID BIGINT, @HasSpecialViewAccess BIT, @HasSecurityGroupNodes BIT
	EXEC [RDF.Security].GetSessionSecurityGroup @SessionID, @SecurityGroupID OUTPUT, @HasSpecialViewAccess OUTPUT
	CREATE TABLE #SecurityGroupNodes (SecurityGroupNode BIGINT PRIMARY KEY)
	INSERT INTO #SecurityGroupNodes (SecurityGroupNode) select * from [RDF.Security].[fnGetSessionSecurityGroupNodes]( @SessionID, @Subject)
	SELECT @HasSecurityGroupNodes = (CASE WHEN EXISTS (SELECT * FROM #SecurityGroupNodes) THEN 1 ELSE 0 END)


	--*******************************************************************************************
	--*******************************************************************************************
	-- Check if user has access to the URI
	--*******************************************************************************************
	--*******************************************************************************************

	if @subject is not null
		select @validURI = 0
			where not exists (
				select *
				from [RDF.].Node
				where NodeID = @subject
					and ( (ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)) )
			)

	if @predicate is not null
		select @validURI = 0
			where not exists (
				select *
				from [RDF.].Node
				where NodeID = @predicate and ObjectType = 0
					and ( (ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)) )
			)

	if @object is not null
		select @validURI = 0
			where not exists (
				select *
				from [RDF.].Node
				where NodeID = @object and ObjectType = 0
					and ( (ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)) )
			)


	--*******************************************************************************************
	--*******************************************************************************************
	-- Get subject information when it is a literal
	--*******************************************************************************************
	--*******************************************************************************************

	select @dataStr = Value, @dataStrDataType = DataType, @dataStrLanguage = Language
		from [RDF.].Node
		where NodeID = @subject and ObjectType = 1
			and ( (ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)) )


	--*******************************************************************************************
	--*******************************************************************************************
	-- Seed temp tables
	--*******************************************************************************************
	--*******************************************************************************************

	---------------------------------------------------------------------------------------------
	-- Profile [seed with the subject(s)]
	---------------------------------------------------------------------------------------------
	if (@subject is not null) and (@predicate is null) and (@object is null)
	begin
		insert into #subjects(subject,showDetail,expanded,URI)
			select NodeID, @showDetails, 0, Value
				from [RDF.].Node
				where NodeID = @subject
					and ((ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)))
		select @firstValue = URI
			from #subjects s, [RDF.].Node n
			where s.subject = @subject
				and s.subject = n.NodeID and n.ObjectType = 0
	end
	if (@NodeListXML is not null)
	begin
		insert into #subjects(subject,showDetail,expanded,URI)
			select n.NodeID, t.ShowDetails, 0, n.Value
			from [RDF.].Node n, (
				select NodeID, MAX(ShowDetails) ShowDetails
				from (
					select x.value('@ID','bigint') NodeID, IsNull(x.value('@ShowDetails','tinyint'),0) ShowDetails
					from @NodeListXML.nodes('//Node') as N(x)
				) t
				group by NodeID
				having NodeID not in (select subject from #subjects)
			) t
			where n.NodeID = t.NodeID and n.ObjectType = 0
	end
	
	---------------------------------------------------------------------------------------------
	-- Get all connections
	---------------------------------------------------------------------------------------------
	insert into #connections (subject, subjectURI, predicate, predicateURI, object, Language, DataType, Value, ObjectType, SortOrder, Weight, Reitification, ReitificationURI, connectionURI)
		select	s.NodeID subject, s.value subjectURI, 
				p.NodeID predicate, p.value predicateURI,
				t.object, o.Language, o.DataType, o.Value, o.ObjectType,
				t.SortOrder, t.Weight, 
				r.NodeID Reitification, r.Value ReitificationURI,
				@baseURI+cast(@subject as varchar(50))+'/'+cast(@predicate as varchar(50))+'/'+cast(object as varchar(50)) connectionURI
			from [RDF.].Triple t
				inner join [RDF.].Node s
					on t.subject = s.NodeID
				inner join [RDF.].Node p
					on t.predicate = p.NodeID
				inner join [RDF.].Node o
					on t.object = o.NodeID
				left join [RDF.].Node r
					on t.reitification = r.NodeID
						and t.reitification is not null
						and ((r.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (r.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (r.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)))
			where @subject is not null and @predicate is not null
				and s.NodeID = @subject 
				and p.NodeID = @predicate 
				and o.NodeID = IsNull(@object,o.NodeID)
				and ((t.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (t.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (t.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)))
				and ((s.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (s.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (s.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)))
				and ((p.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (p.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (p.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)))
				and ((o.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (o.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (o.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)))

	-- Make sure there are connections
	if (@subject is not null) and (@predicate is not null)
		select @validURI = 0
		where not exists (select * from #connections)

	---------------------------------------------------------------------------------------------
	-- Network [seed with network statistics and connections]
	---------------------------------------------------------------------------------------------
	if (@subject is not null) and (@predicate is not null) and (@object is null)
	begin
		select @firstURI = @baseURI+cast(@subject as varchar(50))+'/'+cast(@predicate as varchar(50))
		-- Basic network properties
		;with networkProperties as (
			select 1 n, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type' property, 'rdf:type' tagName, 'type' propertyLabel, 0 ObjectType
			union all select 2, 'http://profiles.catalyst.harvard.edu/ontology/prns#numberOfConnections', 'prns:numberOfConnections', 'number of connections', 1
			union all select 3, 'http://profiles.catalyst.harvard.edu/ontology/prns#maxWeight', 'prns:maxWeight', 'maximum connection weight', 1
			union all select 4, 'http://profiles.catalyst.harvard.edu/ontology/prns#minWeight', 'prns:minWeight', 'minimum connection weight', 1
			union all select 5, 'http://profiles.catalyst.harvard.edu/ontology/prns#predicateNode', 'prns:predicateNode', 'predicate node', 0
			union all select 6, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#predicate', 'rdf:predicate', 'predicate', 0
			union all select 7, 'http://www.w3.org/2000/01/rdf-schema#label', 'rdfs:label', 'label', 1
			union all select 8, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#subject', 'rdf:subject', 'subject', 0
		), networkStats as (
			select	cast(isnull(count(*),0) as varchar(50)) numberOfConnections,
					cast(isnull(max(Weight),1) as varchar(50)) maxWeight,
					cast(isnull(min(Weight),1) as varchar(50)) minWeight,
					max(predicateURI) predicateURI
				from #connections
		), subjectLabel as (
			select IsNull(Max(o.Value),'') Label
			from [RDF.].Triple t, [RDF.].Node o
			where t.subject = @subject
				and t.predicate = @labelID
				and t.object = o.NodeID
				and ((t.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (t.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (t.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)))
				and ((o.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (o.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (o.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)))
		)
		insert into #properties (uri,predicate,property,tagName,propertyLabel,Value,ObjectType,SortOrder)
			select	@firstURI,
					[RDF.].fnURI2NodeID(p.property), p.property, p.tagName, p.propertyLabel,
					(case p.n when 1 then 'http://profiles.catalyst.harvard.edu/ontology/prns#Network'
								when 2 then n.numberOfConnections
								when 3 then n.maxWeight
								when 4 then n.minWeight
								when 5 then @baseURI+cast(@predicate as varchar(50))
								when 6 then n.predicateURI
								when 7 then l.Label
								when 8 then @baseURI+cast(@subject as varchar(50))
								end),
					p.ObjectType,
					1
				from networkStats n, networkProperties p, subjectLabel l
		-- Limit the number of connections if the subject is not a person or a group
		select @limit = 10
			where (@limit is null) 
				and not exists (
					select *
					from [rdf.].[triple]
					where subject = @subject
						and predicate = [RDF.].fnURI2NodeID('http://www.w3.org/1999/02/22-rdf-syntax-ns#type')
						and object in ( [RDF.].fnURI2NodeID('http://xmlns.com/foaf/0.1/Person') , [RDF.].fnURI2NodeID('http://xmlns.com/foaf/0.1/Group') )
				)
		-- Remove connections not within offset-limit window
		delete from #connections
			where (SortOrder < 1+IsNull(@offset,0)) or (SortOrder > IsNull(@limit,SortOrder) + (case when IsNull(@offset,0)<1 then 0 else @offset end))
		-- Add hasConnection properties
		insert into #properties (uri,predicate,property,tagName,propertyLabel,Value,ObjectType,SortOrder)
			select	@baseURI+cast(@subject as varchar(50))+'/'+cast(@predicate as varchar(50)),
					[RDF.].fnURI2NodeID('http://profiles.catalyst.harvard.edu/ontology/prns#hasConnection'), 
					'http://profiles.catalyst.harvard.edu/ontology/prns#hasConnection', 'prns:hasConnection', 'has connection',
					connectionURI,
					0,
					SortOrder
				from #connections
	end

	---------------------------------------------------------------------------------------------
	-- Connection [seed with connection]
	---------------------------------------------------------------------------------------------
	if (@subject is not null) and (@predicate is not null) and (@object is not null)
	begin
		select @firstURI = @baseURI+cast(@subject as varchar(50))+'/'+cast(@predicate as varchar(50))+'/'+cast(@object as varchar(50))
	end

	---------------------------------------------------------------------------------------------
	-- Expanded Connections [seed with statistics, subject, object, and connectionDetails]
	---------------------------------------------------------------------------------------------
	if (@expand = 1 or @object is not null) and exists (select * from #connections)
	begin
		-- Connection statistics
		;with connectionProperties as (
			select 1 n, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type' property, 'rdf:type' tagName, 'type' propertyLabel, 0 ObjectType
			union all select 2, 'http://profiles.catalyst.harvard.edu/ontology/prns#connectionWeight', 'prns:connectionWeight', 'connection weight', 1
			union all select 3, 'http://profiles.catalyst.harvard.edu/ontology/prns#sortOrder', 'prns:sortOrder', 'sort order', 1
			union all select 4, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#object', 'rdf:object', 'object', 0
			union all select 5, 'http://profiles.catalyst.harvard.edu/ontology/prns#hasConnectionDetails', 'prns:hasConnectionDetails', 'connection details', 0
			union all select 6, 'http://profiles.catalyst.harvard.edu/ontology/prns#predicateNode', 'prns:predicateNode', 'predicate node', 0
			union all select 7, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#predicate', 'rdf:predicate', 'predicate', 0
			union all select 8, 'http://www.w3.org/2000/01/rdf-schema#label', 'rdfs:label', 'label', 1
			union all select 9, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#subject', 'rdf:subject', 'subject', 0
			union all select 10, 'http://profiles.catalyst.harvard.edu/ontology/prns#connectionInNetwork', 'prns:connectionInNetwork', 'connection in network', 0
		)
		insert into #properties (uri,predicate,property,tagName,propertyLabel,Value,ObjectType,SortOrder)
			select	connectionURI,
					[RDF.].fnURI2NodeID(p.property), p.property, p.tagName, p.propertyLabel,
					(case p.n	when 1 then 'http://profiles.catalyst.harvard.edu/ontology/prns#Connection'
								when 2 then cast(c.Weight as varchar(50))
								when 3 then cast(c.SortOrder as varchar(50))
								when 4 then c.value
								when 5 then c.ReitificationURI
								when 6 then @baseURI+cast(@predicate as varchar(50))
								when 7 then c.predicateURI
								when 8 then l.value
								when 9 then c.subjectURI
								when 10 then c.subjectURI+'/'+cast(@predicate as varchar(50))
								end),
					(case p.n when 4 then c.ObjectType else p.ObjectType end),
					1
				from #connections c, connectionProperties p
					left outer join (
						select o.value
							from [RDF.].Triple t, [RDF.].Node o
							where t.subject = @subject 
								and t.predicate = @labelID
								and t.object = o.NodeID
								and ((t.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (t.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (t.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)))
								and ((o.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (o.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (o.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)))
					) l on p.n = 8
				where (p.n < 5) 
					or (p.n = 5 and c.ReitificationURI is not null)
					or (p.n > 5 and @object is not null)
		if (@expand = 1)
		begin
			-- Connection subject
			insert into #subjects (subject, showDetail, expanded, URI)
				select NodeID, 0, 0, Value
					from [RDF.].Node
					where NodeID = @subject
			-- Connection objects
			insert into #subjects (subject, showDetail, expanded, URI)
				select object, 0, 0, value
					from #connections
					where ObjectType = 0 and object not in (select subject from #subjects)
			-- Connection details (reitifications)
			insert into #subjects (subject, showDetail, expanded, URI)
				select Reitification, 0, 0, ReitificationURI
					from #connections
					where Reitification is not null and Reitification not in (select subject from #subjects)
		end
	end

	--*******************************************************************************************
	--*******************************************************************************************
	-- Get property values
	--*******************************************************************************************
	--*******************************************************************************************

	-- Get custom settings to override the [Ontology.].[ClassProperty] default values
	insert into #ClassPropertyCustom (ClassPropertyID, IncludeProperty, Limit, IncludeNetwork, IncludeDescription, IsDetail)
		select p.ClassPropertyID, t.IncludeProperty, t.Limit, t.IncludeNetwork, t.IncludeDescription, t.IsDetail
			from [Ontology.].[ClassProperty] p
				inner join (
					select	x.value('@Class','varchar(400)') Class,
							x.value('@NetworkProperty','varchar(400)') NetworkProperty,
							x.value('@Property','varchar(400)') Property,
							(case x.value('@IncludeProperty','varchar(5)') when 'true' then 1 when 'false' then 0 else null end) IncludeProperty,
							x.value('@Limit','int') Limit,
							(case x.value('@IncludeNetwork','varchar(5)') when 'true' then 1 when 'false' then 0 else null end) IncludeNetwork,
							(case x.value('@IncludeDescription','varchar(5)') when 'true' then 1 when 'false' then 0 else null end) IncludeDescription,
							(case x.value('@IsDetail','varchar(5)') when 'true' then 1 when 'false' then 0 else null end) IsDetail
					from @ExpandRDFListXML.nodes('//ExpandRDF') as R(x)
				) t
				on p.Class=t.Class and p.Property=t.Property
					and ((p.NetworkProperty is null and t.NetworkProperty is null) or (p.NetworkProperty = t.NetworkProperty))

	declare @ClassPropertyCustomTypeID int
	select @ClassPropertyCustomTypeID = ClassPropertyCustomTypeID from (select x.value('@ClassPropertyCustomTypeID', 'int') ClassPropertyCustomTypeID from @ExpandRDFListXML.nodes('//ExpandRDFOptions') as R(x)) t
	insert into #ClassPropertyCustom (ClassPropertyID, IncludeProperty, Limit, IncludeNetwork, IncludeDescription, IsDetail)
		select _ClassPropertyID, IncludeProperty, Limit, IncludeNetwork, IncludeDescription, IsDetail from [Ontology.].[ClassPropertyCustom]
		where ClassPropertyCustomTypeID=@ClassPropertyCustomTypeID and _ClassPropertyID not in (select ClassPropertyID from #ClassPropertyCustom)

	if exists (select 1 from (select (case x.value('@ExpandPredicates', 'varchar(5)') when 'false' then 0 else 1 end) ExpandPredicates from @ExpandRDFListXML.nodes('//ExpandRDFOptions') as R(x)) t
		where t.ExpandPredicates = 0) begin set @includePredicates = 0 end

	-- Get properties and loop if objects need to be expanded
	declare @numLoops int
	declare @maxLoops int
	declare @actualLoops int
	declare @NewSubjects int
	select @numLoops = 0, @maxLoops = 10, @actualLoops = 0
	while (@numLoops < @maxLoops)
	begin
		-- Get the types of each subject that hasn't been expanded
		truncate table #types
		insert into #types(subject,object,predicate,showDetail,uri)
			select s.subject, t.object, null, s.showDetail, s.uri
				from #subjects s 
					inner join [RDF.].Triple t on s.subject = t.subject 
						and t.predicate = @typeID 
					inner join [RDF.].Node n on t.object = n.NodeID
						and ((n.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (n.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (1 = CASE WHEN @HasSecurityGroupNodes = 0 THEN 0 WHEN n.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes) THEN 1 ELSE 0 END))
						and ((t.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (t.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (1 = CASE WHEN @HasSecurityGroupNodes = 0 THEN 0 WHEN t.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes) THEN 1 ELSE 0 END))
				where s.expanded = 0				   
		-- Get the subject types of each reitification that hasn't been expanded
		insert into #types(subject,object,predicate,showDetail,uri)
		select distinct s.subject, t.object, r.predicate, s.showDetail, s.uri
			from #subjects s 
				inner join [RDF.].Triple r on s.subject = r.reitification
				inner join [RDF.].Triple t on r.subject = t.subject 
					and t.predicate = @typeID 
				inner join [RDF.].Node n on t.object = n.NodeID
					and ((n.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (n.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (1 = CASE WHEN @HasSecurityGroupNodes = 0 THEN 0 WHEN n.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes) THEN 1 ELSE 0 END))
					and ((t.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (t.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (1 = CASE WHEN @HasSecurityGroupNodes = 0 THEN 0 WHEN t.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes) THEN 1 ELSE 0 END))
					and ((r.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (r.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (1 = CASE WHEN @HasSecurityGroupNodes = 0 THEN 0 WHEN r.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes) THEN 1 ELSE 0 END))
			where s.expanded = 0
		-- Get the items that should be expanded
		truncate table #expand
		insert into #expand(subject, predicate, uri, property, tagName, propertyLabel, IsDetail, limit, showStats, showSummary)
			select p.subject, o._PropertyNode, max(p.uri) uri, o.property, o._TagName, o._PropertyLabel, min(o.IsDetail*1) IsDetail, 
					(case when min(IsNull(c.IsDetail, o.IsDetail)*1) = 0 then max(case when IsNull(c.IsDetail, o.IsDetail)=0 then IsNull(c.limit,o.limit) else null end) else max(IsNull(c.limit,o.limit)) end) limit,
					(case when min(IsNull(c.IsDetail, o.IsDetail)*1) = 0 then max(case when IsNull(c.IsDetail, o.IsDetail)=0 then IsNull(c.IncludeNetwork,o.IncludeNetwork)*1 else 0 end) else max(IsNull(c.IncludeNetwork,o.IncludeNetwork)*1) end) showStats,
					(case when min(IsNull(c.IsDetail, o.IsDetail)*1) = 0 then max(case when IsNull(c.IsDetail, o.IsDetail)=0 then IsNull(c.IncludeDescription,o.IncludeDescription)*1 else 0 end) else max(IsNull(c.IncludeDescription,o.IncludeDescription)*1) end) showSummary
				from #types p
					inner join [Ontology.].ClassProperty o
						on p.object = o._ClassNode 
						and ((p.predicate is null and o._NetworkPropertyNode is null) or (p.predicate = o._NetworkPropertyNode))
					left outer join #ClassPropertyCustom c
						on o.ClassPropertyID = c.ClassPropertyID
				where IsNull(c.IncludeProperty,1) = 1
				and IsNull(c.IsDetail, o.IsDetail) <= showDetail
				group by p.subject, o.property, o._PropertyNode, o._TagName, o._PropertyLabel
		-- Get the values for each property that should be expanded
		insert into #properties (uri,subject,predicate,object,showSummary,property,tagName,propertyLabel,Language,DataType,Value,ObjectType,SortOrder)
			select e.uri, e.subject, t.predicate, t.object, e.showSummary,
					e.property, e.tagName, e.propertyLabel, 
					o.Language, o.DataType, o.Value, o.ObjectType, t.SortOrder
			from #expand e
				inner join [RDF.].Triple t
					on t.subject = e.subject and t.predicate = e.predicate
						and (e.limit is null or t.sortorder <= e.limit)
						and ((t.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (t.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (1 = CASE WHEN @HasSecurityGroupNodes = 0 THEN 0 WHEN t.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes) THEN 1 ELSE 0 END))
				inner join [RDF.].Node p
					on t.predicate = p.NodeID
						and ((p.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (p.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (1 = CASE WHEN @HasSecurityGroupNodes = 0 THEN 0 WHEN p.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes) THEN 1 ELSE 0 END))
				inner join [RDF.].Node o
					on t.object = o.NodeID
						and ((o.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (o.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (1 = CASE WHEN @HasSecurityGroupNodes = 0 THEN 0 WHEN o.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes) THEN 1 ELSE 0 END))
		-- Get network properties
		if (@numLoops = 0)
		begin
			-- Calculate network statistics
			select e.uri, e.subject, t.predicate, e.property, e.tagName, e.PropertyLabel, 
					cast(isnull(count(*),0) as varchar(50)) numberOfConnections,
					cast(isnull(max(t.Weight),1) as varchar(50)) maxWeight,
					cast(isnull(min(t.Weight),1) as varchar(50)) minWeight,
					@baseURI+cast(e.subject as varchar(50))+'/'+cast(t.predicate as varchar(50)) networkURI
				into #networks
				from #expand e
					inner join [RDF.].Triple t
						on t.subject = e.subject and t.predicate = e.predicate
							and (e.showStats = 1)
							and ((t.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (t.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (1 = CASE WHEN @HasSecurityGroupNodes = 0 THEN 0 WHEN t.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes) THEN 1 ELSE 0 END))
					inner join [RDF.].Node p
						on t.predicate = p.NodeID
							and ((p.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (p.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (1 = CASE WHEN @HasSecurityGroupNodes = 0 THEN 0 WHEN p.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes) THEN 1 ELSE 0 END))
					inner join [RDF.].Node o
						on t.object = o.NodeID
							and ((o.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (o.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (1 = CASE WHEN @HasSecurityGroupNodes = 0 THEN 0 WHEN o.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes) THEN 1 ELSE 0 END))
				group by e.uri, e.subject, t.predicate, e.property, e.tagName, e.PropertyLabel
			-- Create properties from network statistics
			;with networkProperties as (
				select 1 n, 'http://profiles.catalyst.harvard.edu/ontology/prns#hasNetwork' property, 'prns:hasNetwork' tagName, 'has network' propertyLabel, 0 ObjectType
				union all select 2, 'http://profiles.catalyst.harvard.edu/ontology/prns#numberOfConnections', 'prns:numberOfConnections', 'number of connections', 1
				union all select 3, 'http://profiles.catalyst.harvard.edu/ontology/prns#maxWeight', 'prns:maxWeight', 'maximum connection weight', 1
				union all select 4, 'http://profiles.catalyst.harvard.edu/ontology/prns#minWeight', 'prns:minWeight', 'minimum connection weight', 1
				union all select 5, 'http://profiles.catalyst.harvard.edu/ontology/prns#predicateNode', 'prns:predicateNode', 'predicate node', 0
				union all select 6, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#predicate', 'rdf:predicate', 'predicate', 0
				union all select 7, 'http://www.w3.org/2000/01/rdf-schema#label', 'rdfs:label', 'label', 1
				union all select 8, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type', 'rdf:type', 'type', 0
			)
			insert into #properties (uri,subject,predicate,property,tagName,propertyLabel,Value,ObjectType,SortOrder)
				select	(case p.n when 1 then n.uri else n.networkURI end),
						(case p.n when 1 then subject else null end),
						[RDF.].fnURI2NodeID(p.property), p.property, p.tagName, p.propertyLabel,
						(case p.n when 1 then n.networkURI 
									when 2 then n.numberOfConnections
									when 3 then n.maxWeight
									when 4 then n.minWeight
									when 5 then @baseURI+cast(n.predicate as varchar(50))
									when 6 then n.property
									when 7 then n.PropertyLabel
									when 8 then 'http://profiles.catalyst.harvard.edu/ontology/prns#Network'
									end),
						p.ObjectType,
						1
					from #networks n, networkProperties p
					where p.n = 1 or @expand = 1
		end
		-- Mark that all previous subjects have been expanded
		update #subjects set expanded = 1 where expanded = 0
		-- See if there are any new subjects that need to be expanded
		insert into #subjects(subject,showDetail,expanded,uri)
			select distinct object, 0, 0, value
				from #properties
				where showSummary = 1
					and ObjectType = 0
					and object not in (select subject from #subjects)
		select @NewSubjects = @@ROWCOUNT
		if(@includePredicates = 1)
		begin		
			insert into #subjects(subject,showDetail,expanded,uri)
				select distinct predicate, 0, 0, property
					from #properties
					where predicate is not null
						and predicate not in (select subject from #subjects)
			select @NewSubjects = @NewSubjects + @@ROWCOUNT
		end
		-- If no subjects need to be expanded, then we are done
		if @NewSubjects = 0
			select @numLoops = @maxLoops
		select @numLoops = @numLoops + 1 + @maxLoops * (1 - @expand)
		select @actualLoops = @actualLoops + 1
	end
	-- Add tagName as a property of DatatypeProperty and ObjectProperty classes
	insert into #properties (uri, subject, showSummary, property, tagName, propertyLabel, Value, ObjectType, SortOrder)
		select p.uri, p.subject, 0, 'http://profiles.catalyst.harvard.edu/ontology/prns#tagName', 'prns:tagName', 'tag name', 
				n.prefix+':'+substring(p.uri,len(n.uri)+1,len(p.uri)), 1, 1
			from #properties p, [Ontology.].Namespace n
			where p.property = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'
				and p.value in ('http://www.w3.org/2002/07/owl#DatatypeProperty','http://www.w3.org/2002/07/owl#ObjectProperty')
				and p.uri like n.uri+'%'
	--select @actualLoops
	--select * from #properties order by (case when uri = @firstURI then 0 else 1 end), uri, tagName, value


	--*******************************************************************************************
	--*******************************************************************************************
	-- Handle the special case where a local node is storing a copy of an external URI
	--*******************************************************************************************
	--*******************************************************************************************

	if (@firstValue IS NOT NULL) AND (@firstValue <> @firstURI)
		insert into #properties (uri, subject, predicate, object, 
				showSummary, property, 
				tagName, propertyLabel, 
				Language, DataType, Value, ObjectType, SortOrder
			)
			select @firstURI uri, @subject subject, predicate, object, 
					showSummary, property, 
					tagName, propertyLabel, 
					Language, DataType, Value, ObjectType, 1 SortOrder
				from #properties
				where uri = @firstValue
					and not exists (select * from #properties where uri = @firstURI)
			union all
			select @firstURI uri, @subject subject, null predicate, null object, 
					0 showSummary, 'http://www.w3.org/2002/07/owl#sameAs' property,
					'owl:sameAs' tagName, 'same as' propertyLabel, 
					null Language, null DataType, @firstValue Value, 0 ObjectType, 1 SortOrder

	--*******************************************************************************************
	--*******************************************************************************************
	-- Generate an XML string from the node properties table
	--*******************************************************************************************
	--*******************************************************************************************

	declare @description nvarchar(max)
	select @description = ''
	-- sort the tags
	select *, 
			row_number() over (partition by uri order by i) j, 
			row_number() over (partition by uri order by i desc) k 
		into #propertiesSorted
		from (
			select *, row_number() over (order by (case when uri = @firstURI then 0 else 1 end), uri, tagName, SortOrder, value) i
				from #properties
		) t

	select * from #properties
	return 


	create unique clustered index idx_i on #propertiesSorted(i)
	-- handle special xml characters in the uri and value strings
	update #propertiesSorted
		set uri = replace(replace(replace(uri,'&','&amp;'),'<','&lt;'),'>','&gt;')
		where uri like '%[&<>]%'
	update #propertiesSorted
		set value = replace(replace(replace(value,'&','&amp;'),'<','&lt;'),'>','&gt;')
		where value like '%[&<>]%'
	-- concatenate the tags
	select @description = (
			select (case when j=1 then '<rdf:Description rdf:about="' + uri + '">' else '' end)
					+'<'+tagName
					+(case when ObjectType = 0 then ' rdf:resource="'+value+'"/>' else '>'+value+'</'+tagName+'>' end)
					+(case when k=1 then '</rdf:Description>' else '' end)
			from #propertiesSorted
			order by i
			for xml path(''), type
		).value('(./text())[1]','nvarchar(max)')
	-- default description if none exists
	if (@description IS NULL) OR (@validURI = 0)
		select @description = '<rdf:Description rdf:about="' + @firstURI + '"'
			+IsNull(' xml:lang="'+@dataStrLanguage+'"','')
			+IsNull(' rdf:datatype="'+@dataStrDataType+'"','')
			+IsNull(' >'+replace(replace(replace(@dataStr,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</rdf:Description>',' />')


	--*******************************************************************************************
	--*******************************************************************************************
	-- Return as a string or as XML
	--*******************************************************************************************
	--*******************************************************************************************

	select @dataStr = IsNull(@dataStr,@description)

	declare @x as nvarchar(max)
	select @x = '<rdf:RDF'
	select @x = @x + ' xmlns:'+Prefix+'="'+URI+'"' 
		from [Ontology.].Namespace
	select @x = @x + ' >' + @description + '</rdf:RDF>'

	if @returnXML = 1 and @returnXMLasStr = 0
		select cast(replace(@x,char(13),'&#13;') as xml) RDF

	if @returnXML = 1 and @returnXMLasStr = 1
		select @x RDF

	--update [RDF.].[GetDataRDF.DebugLog]
	--	set DurationMS = DATEDIFF(ms,StartDate,GetDate())
	--	where LogiD = @debugLogID

	/*	
		declare @d datetime
		select @d = getdate()
		select datediff(ms,@d,getdate())
	*/
		
END
GO
/****** Object:  StoredProcedure [Display.].[GetDataURLs]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.].[GetDataURLs]
	@subject bigint = null,
	@predicate bigint = null,
	@object bigint = null,
	@tab varchar(max) = null,
	@SessionID  UNIQUEIDENTIFIER = NULL
AS
BEGIN
	select @predicate = null where @predicate = 0
	select @object = null where @object = 0

/*
	DECLARE @subject bigint = null, @predicate bigint = null, @object bigint = null, @application varchar(50)
	DECLARE @subjectPreferred bit = 1, @predicatePreferred bit = 1, @objectPreferred bit = 1
	DECLARE @redirect bit = 0
	DECLARE @ErrorDescription varchar(max)
	DECLARE @validURI bit = 1
	
	-- Load param values into a table
	DECLARE @params TABLE (id int, val varchar(1000))
*/
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

	DECLARE @SecurityGroupID BIGINT, @HasSpecialViewAccess BIT, @HasSpecialEditAccess BIT

	declare @canEdit int = 0
	if @SessionID is not null
	BEGIN
		
		EXEC [RDF.Security].GetSessionSecurityGroup @SessionID, @SecurityGroupID OUTPUT, @HasSpecialViewAccess OUTPUT, @HasSpecialEditAccess OUTPUT
		CREATE TABLE #SecurityGroupNodes (SecurityGroupNode BIGINT PRIMARY KEY)
		INSERT INTO #SecurityGroupNodes (SecurityGroupNode) EXEC [RDF.Security].GetSessionSecurityGroupNodes @SessionID, @subject
		SELECT @CanEdit = 0
		SELECT @CanEdit = 1
			FROM [RDF.].Node
			WHERE NodeID = @subject
				AND ( (EditSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (EditSecurityGroup > 0 AND @HasSpecialEditAccess = 1) OR (EditSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)) )
	END

	create table #dataModules(
		i int identity,
		DataStoredProc varchar(max),
		subject bigint,
		predicate bigint,
		tagname varchar(max),
		DisplayModule varchar(max),
		object bigint,
		oValue varchar(max),
		GroupLabel varchar(100),
		PropertyLabel varchar(100),
		ToolTip varchar(max),
		Panel varchar(10),
		SortOrder int,
		LayoutDataModule bit,
		json nvarchar(max)
	)

	IF @PresentationID in (5, 17) -- People and Groups.
	BEGIN
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
	
		insert into #dataModules (DataStoredProc, subject, predicate, tagname, DisplayModule, object, oValue, GroupLabel, PropertyLabel, ToolTip, Panel, SortOrder, LayoutDataModule)
		select DataStoredProc, @subject, @predicate, '', DisplayModule, @object, null, GroupLabel, a.PropertyLabel, ToolTip, Panel, a.SortOrder, LayoutDataModule from [Display.].ModuleMapping a
			join #rdf b
			on a.PresentationID = @PresentationID
			and a._ClassPropertyID = b.predicate
			and b.SortOrder = 1 --This should be handled at source
			and LayoutModule = 1
	END
	ELSE
	BEGIN
		insert into #dataModules (DataStoredProc, subject, predicate, tagname, DisplayModule, object, oValue, GroupLabel, PropertyLabel, ToolTip, Panel, SortOrder, LayoutDataModule)
		 select d.DataStoredProc, @subject, case when a.predicate = 1 then @predicate else null end, '', DisplayModule, case when a.object = 1 then @object else null end, null, GroupLabel, d.PropertyLabel, d.ToolTip, d.Panel, d.SortOrder, d.LayoutDataModule from [Display.].[DataPath] a 
			join [Ontology.Presentation].XML b on a.PresentationID = b.PresentationID
			join [Ontology.Presentation].XML c on 
				(a.object = 1 and b.PresentationID = c.PresentationID)
				OR (a.object = 0 and a.predicate = 1 and c.Type = 'N' and isnull(b._SubjectNode, 0) = isnull(c._subjectNode, 0) and isnull(b._PredicateNode, 0) = isnull(c._PredicateNode, 0))
				OR (a.object = 0 and a.predicate = 0 and c.Type = 'P' and isnull(b._SubjectNode, 0) = isnull(c._subjectNode, 0))
			join [Display.].ModuleMapping d on c.PresentationID = d.PresentationID and a.dataTab = d.Tab and d.LayoutModule = 1
			where a.PresentationID = @PresentationID and a.tab = @tab 


	END

	declare @DataStoredProc varchar(max), @subject1 bigint, @predicate1 bigint, @tagname varchar(max), @object1 bigint, @oValue varchar(max), @json nvarchar(max)
	--select * from #dataModules
	--select @subject,@predicate,@object, @tab
	declare @dmi int = 0
	while (1=1)
	BEGIN
		select top 1 @dmi=i, @DataStoredProc=DataStoredProc, @subject1=isnull(subject, @subject), @predicate1=predicate, @tagname=tagname, @object1=object, @oValue=oValue 
			from #dataModules where i > @dmi and LayoutDataModule = 1 order by i
		if @@ROWCOUNT=0 BREAK
		set @json = null
		exec @DataStoredProc @subject=@subject1, @predicate=@predicate1, @tagname=@tagname, @object=@object1, @oValue=@oValue, @SessionID=@SessionID, @json=@json output
		update #dataModules set json = @json where i = @dmi
	END


	-------------------------------------------------------------------------------
	-- Return the URLs for data
	-------------------------------------------------------------------------------
	declare @dataURLs varchar(max)

	if exists (select 1 from [Display.].[DataPath] where PresentationID = @PresentationID and tab = isnull(@tab, ''))
	BEGIN
		select @dataURLs = (select Case when subject = 1 then isnull('s=' + cast(@subject as varchar(50)), '') else '' end
				+ Case when predicate = 1 then isnull('&p=' + cast(@predicate as varchar(50)), '') else '' end
				+ case when object = 1 then isnull('&o=' + cast(@object as varchar(50)), '') else '' end
				+ isnull('&t=' + dataTab, '')
				+ case when @canEdit=1 then '&r=' + cast(round(rand() * 1000, 0,0) as varchar(5)) else '' end
				dataURL
			from [Display.].[DataPath] where PresentationID = @PresentationID and tab = isnull(@tab, '')
			for json path)
	END
	ELSE
	BEGIN
		select @dataURLs = (select isnull('s=' + cast(@subject as varchar(50)), '') + isnull('&p=' + cast(@predicate as varchar(50)), '') + isnull('&o=' + cast(@object as varchar(50)), '') + isnull('&t=' + @tab, '')  dataURL for json path)
	END

	declare @botIndex int
	select @botIndex = botindex from [Display.].DataPath where PresentationID = @PresentationID and Sort = 1

	select 1 as ValidURL, cast(@PresentationID as varchar(50)) as PresentationType, @tab as tab, 0 as Redirect, '' as RedirectURL, @dataURLs as dataURLs, @canEdit as canEdit, @botIndex botIndex, (Select DisplayModule, GroupLabel, PropertyLabel, ToolTip, Panel, SortOrder, JSON_QUERY(json, '$.module_data')as ModuleData from #dataModules for json path) as layoutData

END
GO
/****** Object:  StoredProcedure [Display.].[GetJson]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.].[GetJson]
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
/*		if (@pageCacheSecurityGroup <=-20)
		BEGIN
			CREATE TABLE #SecurityGroupNodes (SecurityGroupNode BIGINT PRIMARY KEY)
			INSERT INTO #SecurityGroupNodes (SecurityGroupNode) select * from [RDF.Security].fnGetSessionSecurityGroupNodes(@SessionID, @Subject)

			SELECT @pageCacheSecurityGroup = 0
				FROM [RDF.].Node
				WHERE NodeID = @subject
					AND ( (EditSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (EditSecurityGroup > 0 AND @HasSpecialEditAccess = 1) OR (EditSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)) )
		END
*/		-------------------------------------------------------------------------------
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
		set @json = null
		exec @DataStoredProc @subject=@subject1, @predicate=@predicate1, @tagname=@tagname, @object=@object1, @oValue=@oValue, @SessionID=@SessionID, @json=@json output
		update #dataModules set json = @json where i = @dmi
	END

	if not exists (select 1 from #dataModules where json is not null) insert into #dataModules(DisplayModule, json) values ('Error', '{"module_data":[{"Error":"Not Found"}]}')

	delete from #dataModules where json is null

	--select * from #dataModules
	--select *, JSON_QUERY(json, '$.module_data')as module_data from #dataModules
	select (Select DisplayModule, JSON_QUERY(json, '$.module_data')as ModuleData from #dataModules for json path) as jsonData,  @pageSecurityType as pageSecurityType, @cacheLength as cacheLength, @pageCacheSecurityGroup as pageCacheSecurityGroup
END
GO
/****** Object:  StoredProcedure [Display.].[GetLatestActivityIDs]    Script Date: 4/14/2025 3:18:55 PM ******/
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
/*	declare @DisplayProperties table ([methodName] nvarchar(255), Property nvarchar(255))
	insert into @DisplayProperties (methodName, Property) values ('Profiles.Edit.Utilities.DataIO.AddPublication', null)
	insert into @DisplayProperties (methodName, Property) values ('Profiles.Edit.Utilities.DataIO.UpdateSecuritySetting', null)
	insert into @DisplayProperties (methodName, Property) values ('Profiles.Edit.Utilities.DataIO.AddUpdateFunding', null)
	insert into @DisplayProperties (methodName, Property) values ('Profiles.Edit.Utilities.DataIO.AddCustomPublication', null)
	insert into @DisplayProperties (methodName, Property) values ('Profiles.Edit.Utilities.DataIO.AddGroupMember', null)
	insert into @DisplayProperties (methodName, Property) values ('[Profile.Data].[Funding.LoadDisambiguationResults]', null)
	insert into @DisplayProperties (methodName, Property) values ( '[resnav_people_profileslabs].[dbo].[UpdatePubMedDisambiguation]', null)
	insert into @DisplayProperties (methodName, Property) values ( 'Profiles.Edit.Modules.CustomEditAuthorInAuthorship.DataIO.AddVerifyPublications', null)
	insert into @DisplayProperties (methodName, Property) values ( 'Profiles.Edit.Utilities.DataIO.SaveImage', null)
	insert into @DisplayProperties (methodName, Property) values ( 'Profiles.Edit.Utilities.DataIO.AddAward', null)

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
*/
	if @lastActivityLogID = 0
	BEGIN
		select MAX (activityLogID) activityLogID from [Framework.].[Log.Activity] a 
			join [Display.].[Activity.Log.MethodDetails] b on a.methodName = b.methodName and a.Property = isnull(b.property, a.property) 
			join [Profile.Cache].Person c on a.personId = c.PersonID and c.IsActive = 1
			join [RDF.].Node d on  [RDF.].fnValueHash(null, null, a.Property) = d.ValueHash
			left JOIN [RDF.Security].[NodeProperty] e on c.NodeID = e.NodeID and d.NodeID = e.Property
				where isnull(e.ViewSecurityGroup, -1) = -1
				group by a.personID order by max(activityLogID) desc offset @offset ROWS FETCH NEXT @count ROWS ONLY
				--for json path
	END
	ELSE
	BEGIN
		select MAX (activityLogID) activityLogID from [Framework.].[Log.Activity] a 
			join [Display.].[Activity.Log.MethodDetails] b on a.methodName = b.methodName and a.Property = isnull(b.property, a.property) and a.activityLogId < @lastActivityLogID
			join [Profile.Cache].Person c on a.personId = c.PersonID and c.IsActive = 1
			join [RDF.].Node d on  [RDF.].fnValueHash(null, null, a.Property) = d.ValueHash
			left JOIN [RDF.Security].[NodeProperty] e on c.NodeID = e.NodeID and d.NodeID = e.Property
				where isnull(e.ViewSecurityGroup, -1) = -1
				group by a.personID order by max(activityLogID) desc offset @offset ROWS FETCH NEXT @count ROWS ONLY
	END
END
GO
/****** Object:  StoredProcedure [Display.].[GetPageParams]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.].[GetPageParams]
	@param1 varchar(max) = null,
	@param2 varchar(max) = null,
	@param3 varchar(max) = null,
	@param4 varchar(max) = null,
	@param5 varchar(max) = null,
	@param6 varchar(max) = null,
	@param7 varchar(max) = null,
	@param8 varchar(max) = null,
	@param9 varchar(max) = null,
	@param10 varchar(max) = null,
	@SessionID  UNIQUEIDENTIFIER = NULL
AS
BEGIN
	DECLARE @subject bigint = null, @predicate bigint = null, @object bigint = null, @application varchar(50)
	DECLARE @subjectPreferred bit = 1, @predicatePreferred bit = 1, @objectPreferred bit = 1
	DECLARE @redirect bit = 0
	DECLARE @ErrorDescription varchar(max)
	DECLARE @validURI bit = 1
	
	-- Load param values into a table
	DECLARE @params TABLE (id int, val varchar(1000))
/*
	-- *** Start Fix for Catalyst ***
	IF (@param1 = 'person' AND @param3 in ('concepts','coauthors','similarpeople'))
	BEGIN
			INSERT INTO @params (id, val) VALUES (1, @param1)
			INSERT INTO @params (id, val) VALUES (2, @param2)
			INSERT INTO @params (id, val) VALUES (3, 'Network')
			INSERT INTO @params (id, val) select 4, CASE @param3
								WHEN 'concepts' THEN 'ResearchAreas'
								WHEN 'coauthors' THEN 'CoAuthors'
								WHEN 'similarpeople' THEN 'SimilarTo'
								ELSE '' END						
			INSERT INTO @params (id, val) VALUES (5, REPLACE(@param4,'view',''))
			INSERT INTO @params (id, val) VALUES (6, @param5)
			INSERT INTO @params (id, val) VALUES (7, @param6)
			INSERT INTO @params (id, val) VALUES (8, @param7)
			INSERT INTO @params (id, val) VALUES (9, @param8)
			INSERT INTO @params (id, val) VALUES (10, @param9)
	END
	-- *** END Fix for Catalyst ***
	ELSE
	BEGIN
		INSERT INTO @params (id, val) VALUES (1, @param1)
		INSERT INTO @params (id, val) VALUES (2, @param2)
		INSERT INTO @params (id, val) VALUES (3, @param3)
		INSERT INTO @params (id, val) VALUES (4, @param4)
		INSERT INTO @params (id, val) VALUES (5, @param5)
		INSERT INTO @params (id, val) VALUES (6, @param6)
		INSERT INTO @params (id, val) VALUES (7, @param7)
		INSERT INTO @params (id, val) VALUES (8, @param8)
		INSERT INTO @params (id, val) VALUES (9, @param9)
	END
*/
	INSERT INTO @params (id, val) VALUES (1, @param1)
	INSERT INTO @params (id, val) VALUES (2, @param2)
	INSERT INTO @params (id, val) VALUES (3, @param3)
	INSERT INTO @params (id, val) VALUES (4, @param4)
	INSERT INTO @params (id, val) VALUES (5, @param5)
	INSERT INTO @params (id, val) VALUES (6, @param6)
	INSERT INTO @params (id, val) VALUES (7, @param7)
	INSERT INTO @params (id, val) VALUES (8, @param8)
	INSERT INTO @params (id, val) VALUES (9, @param9)
	INSERT INTO @params (id, val) VALUES (10, @param10)

	if @param1 in ('display', 'profile')
	BEGIN
		set @application = @param1
		delete from @params where id = 1
		update @params set id = id - 1;
	END

	-- *** Start Fix for Catalyst ***
	IF exists(select 1 from @params a join @params b on a.id = 3 and a.val in ('concepts','coauthors','similarpeople') and b.id = 1 and b.val = 'person')
	BEGIN
		update @params set id = id + 1 where id > 2
		INSERT INTO @params (id, val) VALUES (3, 'Network')
		update @params set val = REPLACE(val,'view','') where id = 5
	END
	-- *** END Fix for Catalyst ***

	DECLARE @MaxParam int
	SELECT @MaxParam = 0
	SELECT @MaxParam = MAX(id) FROM @params WHERE isnull(val, '') > ''

	DECLARE @Tab VARCHAR(1000)
	DECLARE @tabPreferred bit = 1
	DECLARE @File VARCHAR(1000)
	DECLARE @ViewAs VARCHAR(50)
	
	SELECT @subject=NULL, @predicate=NULL, @object=NULL, @Tab=NULL, @File=NULL
	
	SELECT @File = val, @MaxParam = @MaxParam-1
		FROM @params
		WHERE id = @MaxParam and val like '%.%'

	DECLARE @pointer INT
	SELECT @pointer=1
	
	DECLARE @aliases INT
	SELECT @aliases = 0
	
	-- subject
	IF (@MaxParam >= @pointer)
	BEGIN
		SELECT @subject = CAST(val AS BIGINT), @pointer = @pointer + 1
			FROM @params 
			WHERE id=@pointer AND val NOT LIKE '%[^0-9]%'
		IF @subject IS NOT NULL
		BEGIN
			select @subjectPreferred = ISNULL((select 0 from [RDF.].Alias where NodeID = @subject and Preferred = 1), 1)
			select @subjectPreferred = 0 where isnull(@application, '') <> 'display'
		END
		IF @subject IS NULL AND @MaxParam > @pointer
			SELECT @subject = NodeID, @subjectPreferred = case when isnull(@application, '') = DefaultApplication then Preferred else 0 end, @pointer = @pointer + 2, @aliases = @aliases + 1
				FROM [RDF.].Alias 
				WHERE AliasType = (SELECT val FROM @params WHERE id = @pointer)
					AND AliasID = (SELECT val FROM @params WHERE id = @pointer+1)
		IF @subject IS NULL
			SELECT @subject = NodeID, @subjectPreferred = case when isnull(@application, '') = DefaultApplication then Preferred else 0 end, @pointer = @pointer + 1, @aliases = @aliases + 1
				FROM [RDF.].Alias 
				WHERE AliasType = ''
					AND AliasID = (SELECT val FROM @params WHERE id = @pointer)
		IF @subject IS NULL
			SELECT @ErrorDescription = 'The subject cannot be found.'
	END

	-- predicate
	IF (@MaxParam >= @pointer) AND (@subject IS NOT NULL)
	BEGIN
		SELECT @predicate = CAST(val AS BIGINT), @pointer = @pointer + 1
			FROM @params 
			WHERE id=@pointer AND val NOT LIKE '%[^0-9]%'
		IF @predicate IS NOT NULL
			select @predicatePreferred = ISNULL((select 0 from [RDF.].Alias where NodeID = @predicate and Preferred = 1), 1)
		IF @predicate IS NULL AND @MaxParam > @pointer
			SELECT @predicate = NodeID, @predicatePreferred = Preferred, @pointer = @pointer + 2, @aliases = @aliases + 1
				FROM [RDF.].Alias 
				WHERE AliasType = (SELECT val FROM @params WHERE id = @pointer)
					AND AliasID = (SELECT val FROM @params WHERE id = @pointer+1)
		IF @predicate IS NULL
			SELECT @predicate = NodeID, @predicatePreferred = Preferred, @pointer = @pointer + 1, @aliases = @aliases + 1
				FROM [RDF.].Alias 
				WHERE AliasType = ''
					AND AliasID = (SELECT val FROM @params WHERE id = @pointer)
		IF @predicate IS NULL AND @MaxParam = @pointer
			SELECT @Tab=(SELECT val FROM @params WHERE id = @pointer)
		IF @predicate IS NULL AND @Tab IS NULL
			SELECT @ErrorDescription = 'The predicate cannot be found.'
	END
	
	-- object
	IF (@MaxParam >= @pointer) AND (@predicate IS NOT NULL)
	BEGIN
		SELECT @object = CAST(val AS BIGINT), @pointer = @pointer + 1
			FROM @params 
			WHERE id=@pointer AND val NOT LIKE '%[^0-9]%'
		IF @object IS NOT NULL
			select @objectPreferred = ISNULL((select 0 from [RDF.].Alias where NodeID = @object and Preferred = 1), 1)
		IF @object IS NULL AND @MaxParam > @pointer
			SELECT @object = NodeID, @objectPreferred = Preferred, @pointer = @pointer + 2, @aliases = @aliases + 1
				FROM [RDF.].Alias 
				WHERE AliasType = (SELECT val FROM @params WHERE id = @pointer)
					AND AliasID = (SELECT val FROM @params WHERE id = @pointer+1)
		IF @object IS NULL
			SELECT @object = NodeID, @objectPreferred = Preferred, @pointer = @pointer + 1, @aliases = @aliases + 1
				FROM [RDF.].Alias 
				WHERE AliasType = ''
					AND AliasID = (SELECT val FROM @params WHERE id = @pointer)
		IF @object IS NULL AND @MaxParam = @pointer
			SELECT @Tab=(SELECT val FROM @params WHERE id = @pointer)
		IF @object IS NULL AND @Tab IS NULL
			SELECT @ErrorDescription = 'The object cannot be found.'
	END

	--tab
	IF (@MaxParam = @pointer) AND (@object IS NOT NULL) AND (@Tab IS NULL)
	BEGIN
		SELECT @Tab=(SELECT val FROM @params WHERE id = @pointer)
	END

	--*******************************************************************************************
	--*******************************************************************************************
	-- Setup variables used for security
	--*******************************************************************************************
	--*******************************************************************************************

	DECLARE @SecurityGroupID BIGINT, @HasSpecialViewAccess BIT, @HasSecurityGroupNodes BIT
	EXEC [RDF.Security].GetSessionSecurityGroup @SessionID, @SecurityGroupID OUTPUT, @HasSpecialViewAccess OUTPUT
	CREATE TABLE #SecurityGroupNodes (SecurityGroupNode BIGINT PRIMARY KEY)
	--INSERT INTO #SecurityGroupNodes (SecurityGroupNode) EXEC [RDF.Security].GetSessionSecurityGroupNodes @SessionID, @Subject
	SELECT @HasSecurityGroupNodes = (CASE WHEN EXISTS (SELECT * FROM #SecurityGroupNodes) THEN 1 ELSE 0 END)


	--*******************************************************************************************
	--*******************************************************************************************
	-- Check if user has access to the URI
	--*******************************************************************************************
	--*******************************************************************************************

	select @validURI = 0
		where not exists (
			select *
			from [RDF.].Node
			where NodeID = @subject
				and ( (ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)) )
		)

	if @predicate is not null
		select @validURI = 0
			where not exists (
				select *
				from [RDF.].Node
				where NodeID = @predicate and ObjectType = 0
					and ( (ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)) )
			)

	if @predicate is not null
		select @validURI = 0
			where not exists (
				select *
				from [RDF.].Triple
				where subject = @subject and predicate = @predicate
					and ( (ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)) )
			)


	if @object is not null
		select @validURI = 0
			where not exists (
				select *
				from [RDF.].Node
				where NodeID = @object and ObjectType = 0
					and ( (ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)) )
			)

	if @object is not null
		select @validURI = 0
			where not exists (
				select *
				from [RDF.].Triple
				where subject = @subject and predicate = @predicate and object = @object
					and ( (ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)) )
			)

	else if @predicate is not null
		select @validURI = 0
			where not exists (
				select *
				from [RDF.].Triple
				where subject = @subject and predicate = @predicate
					and ( (ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)) )
			)

	if @validURI = 0
	BEGIN
		select 0 as ValidURL, 0 as PresentationType, '' as tab, 0 as Redirect, '' as RedirectURL, '' as dataURLs, 1 as BotIndex
		RETURN
	END
	
	-------------------------------------------------------------------------------
	-- Redirect if this is not the preferred URL
	-------------------------------------------------------------------------------
	declare @redirectURL varchar(max) 
	if (@subjectPreferred = 0 OR @predicatePreferred = 0 OR @objectPreferred = 0 AND @Tab is null)
	BEGIN
		select @redirectURL = isnull((select '/' + case when DefaultApplication <> '' then DefaultApplication + '/' else '' end + case when AliasType <> '' then  AliasType  + '/' else '' end + AliasID from [RDF.].Alias where NodeID = @subject and Preferred = 1) , '/display/' + cast(@subject as varchar(50))) 
							+ isnull('/' + isnull((select case when AliasType <> '' then  AliasType  + '/' else '' end + AliasID from [RDF.].Alias where NodeID = @predicate and Preferred = 1), cast(@predicate as varchar(50))), '') 
							+ isnull('/' + isnull((select  case when AliasType <> '' then  AliasType  + '/' else '' end + AliasID from [RDF.].Alias where NodeID = @object and Preferred = 1), cast(@object as varchar(50))), '')
		select 1 as ValidURL, 0 as PresentationType, @tab as tab, 1 as Redirect, @redirectURL as RedirectURL, '' as dataURLs, 1 as BotIndex
		RETURN
	END


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
	-- Check the tab is the preferred name
	-------------------------------------------------------------------------------
	if (@Tab is not null)
	BEGIN
--		IF NOT EXISTS (select 1 from [Display.].ModuleMapping where PresentationID = @PresentationID and tab = @tab)
--		BEGIN
--			select 0 as ValidURL, 0 as PresentationType, '' as tab, 0 as Redirect, '' as RedirectURL, '' as dataURLs
--			RETURN
--		END
		IF EXISTS (select 1 from [Display.].[TabAlias] where PresentationID = @PresentationID AND tab = @Tab)
		BEGIN
			select @redirectURL = isnull((select '/' + case when DefaultApplication <> '' then DefaultApplication + '/' else '' end + case when AliasType <> '' then  AliasType  + '/' else '' end  + '/' + AliasID from [RDF.].Alias where NodeID = @subject and Preferred = 1) , '/display/' + cast(@subject as varchar(50))) 
								+ isnull('/' + isnull((select case when AliasType <> '' then  AliasType  + '/' else '' end + AliasID from [RDF.].Alias where NodeID = @predicate and Preferred = 1), cast(@predicate as varchar(50))), '') 
								+ isnull('/' + isnull((select case when AliasType <> '' then  AliasType  + '/' else '' end + AliasID from [RDF.].Alias where NodeID = @object and Preferred = 1), cast(@object as varchar(50))), '')
								+ isnull('/' + (select PreferredValue from [Display.].[TabAlias] where PresentationID = @PresentationID AND tab = @Tab), '')
			select 1 as ValidURL, 0 as PresentationType, @tab as tab, 1 as Redirect, @redirectURL as RedirectURL, '' as dataURLs, 1 as BotIndex
			RETURN
		END
		ELSE IF (@subjectPreferred = 0 OR @predicatePreferred = 0 OR @objectPreferred = 0)
		BEGIN

			select @redirectURL = isnull((select '/' + case when DefaultApplication <> '' then DefaultApplication + '/' else '' end + case when AliasType <> '' then  AliasType  + '/' else '' end  + '/' + AliasID from [RDF.].Alias where NodeID = @subject and Preferred = 1) , '/display/' + cast(@subject as varchar(50))) 
								+ isnull('/' + isnull((select case when AliasType <> '' then  AliasType  + '/' else '' end + AliasID from [RDF.].Alias where NodeID = @predicate and Preferred = 1), cast(@predicate as varchar(50))), '') 
								+ isnull('/' + isnull((select case when AliasType <> '' then  AliasType  + '/' else '' end + AliasID from [RDF.].Alias where NodeID = @object and Preferred = 1), cast(@object as varchar(50))), '')
			select 1 as ValidURL, 0 as PresentationType, @tab as tab, 1 as Redirect, @redirectURL as RedirectURL, '' as dataURLs, 1 as BotIndex
			RETURN
		END

	END


	-------------------------------------------------------------------------------
	-- Return the URLs for data
	-------------------------------------------------------------------------------
	declare @dataURLs varchar(max)

	if exists (select 1 from [Display.].[DataPath] where PresentationID = @PresentationID and tab = isnull(@tab, ''))
	BEGIN
		select @dataURLs = (select Case when subject = 1 then isnull('s=' + cast(@subject as varchar(50)), '') else '' end
				+ Case when predicate = 1 then isnull('&p=' + cast(@predicate as varchar(50)), '') else '' end
				+ case when object = 1 then isnull('&o=' + cast(@object as varchar(50)), '') else '' end
				+ isnull('&t=' + dataTab, '') dataURL
			from [Display.].[DataPath] where PresentationID = @PresentationID and tab = isnull(@tab, '')
			for json path)
	END
	ELSE
	BEGIN
		select @dataURLs = (select isnull('s=' + cast(@subject as varchar(50)), '') + isnull('&p=' + cast(@predicate as varchar(50)), '') + isnull('&o=' + cast(@object as varchar(50)), '') + isnull('&t=' + @tab, '')  dataURL for json path)
	END

	declare @botIndex int
	select @botIndex = botindex from [Display.].DataPath where PresentationID = @PresentationID and Sort = 1

	select 1 as ValidURL, cast(@PresentationID as varchar(50)) as PresentationType, @tab as tab, 0 as Redirect, '' as RedirectURL, @dataURLs as dataURLs, @botIndex botIndex
END



GO
/****** Object:  StoredProcedure [Display.].[Search.Params]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [Display.].[Search.Params]
AS
BEGIN

	declare @stats table (label varchar(55), [count] int)
	insert into @stats (label, [count]) SELECT 'Grants', [_NumberOfNodes] FROM [Ontology.].[ClassGroupClass] with (nolock) where ClassGroupURI='http://profiles.catalyst.harvard.edu/ontology/prns#ClassGroupResearch' and ClassURI='http://vivoweb.org/ontology/core#Grant'
	insert into @stats (label, [count]) SELECT 'People', [_NumberOfNodes] FROM [Ontology.].[ClassGroupClass] with (nolock) where ClassGroupURI='http://profiles.catalyst.harvard.edu/ontology/prns#ClassGroupPeople' and ClassURI='http://xmlns.com/foaf/0.1/Person'
	insert into @stats (label, [count]) SELECT 'Publications', [_NumberOfNodes] FROM [Ontology.].[ClassGroupClass] with (nolock) where classuri = 'http://purl.org/ontology/bibo/AcademicArticle' and classgroupuri = 'http://profiles.catalyst.harvard.edu/ontology/prns#ClassGroupResearch'

	declare @filters table (PersonFilter varchar(200), PersonFilterCategory varchar(200), personFilterSort int, nodeID bigint)
	insert into @filters
	SELECT PersonFilter, PersonFilterCategory, PersonFilterSort, m.NodeID
						FROM [Profile.Data].[Person.Filter]
					LEFT OUTER JOIN [RDF.Stage].InternalNodeMap m WITH (NOLOCK)
						ON m.class = 'http://profiles.catalyst.harvard.edu/ontology/prns#PersonFilter'
							AND m.InternalType = 'PersonFilter'
							AND m.InternalID = CAST(PersonFilterID AS VARCHAR(50))
					LEFT OUTER JOIN [RDF.].Node n WITH (NOLOCK)
						ON m.NodeID = n.NodeID
							AND n.ViewSecurityGroup = -1

	select
			(SELECT x.InstitutionName, n.NodeID
				FROM (
						SELECT CAST(MAX(InstitutionID) AS VARCHAR(50)) InstitutionID,
								REPLACE(LTRIM(RTRIM(InstitutionName)), '&', 'and') InstitutionName, 
								MIN(institutionabbreviation) InstitutionAbbreviation
						FROM [Profile.Data].[Organization.Institution] WITH (NOLOCK)
						WHERE InstitutionAbbreviation in (select distinct institutionAbbreviation from [Profile.Cache].[Person])
						GROUP BY LTRIM(RTRIM(InstitutionName))
					) x 
					LEFT OUTER JOIN [RDF.Stage].InternalNodeMap m WITH (NOLOCK)
						ON m.class = 'http://xmlns.com/foaf/0.1/Organization'
							AND m.InternalType = 'Institution'
							AND m.InternalID = CAST(x.InstitutionID AS VARCHAR(50))
					LEFT OUTER JOIN [RDF.].Node n WITH (NOLOCK)
						ON m.NodeID = n.NodeID
							AND n.ViewSecurityGroup = -1
				FOR json path) as Institutions,


			(SELECT replace(x.DepartmentName, '&', 'and') DepartmentName, n.NodeID
			FROM (
					SELECT *
					FROM [Profile.Data].[Organization.Department] WITH (NOLOCK)
					WHERE Visible = 1 AND LTRIM(RTRIM(DepartmentName))<>''
				) x 
				LEFT OUTER JOIN [RDF.Stage].InternalNodeMap m WITH (NOLOCK)
					ON m.class = 'http://xmlns.com/foaf/0.1/Organization'
						AND m.InternalType = 'Department'
						AND m.InternalID = CAST(x.DepartmentID AS VARCHAR(50))
				LEFT OUTER JOIN [RDF.].Node n WITH (NOLOCK)
					ON m.NodeID = n.NodeID
						AND n.ViewSecurityGroup = -1
				for json Path) as Departments,

	/*
			(SELECT x.DivisionName, n.NodeID
			FROM (
					SELECT *
					FROM [Profile.Data].[Organization.Division] WITH (NOLOCK)
					WHERE LTRIM(RTRIM(DivisionName))<>''
				) x 
				LEFT OUTER JOIN [RDF.Stage].InternalNodeMap m WITH (NOLOCK)
					ON m.class = 'http://xmlns.com/foaf/0.1/Organization'
						AND m.InternalType = 'Division'
						AND m.InternalID = CAST(x.DivisionID AS VARCHAR(50))
				LEFT OUTER JOIN [RDF.].Node n WITH (NOLOCK)
					ON m.NodeID = n.NodeID
						AND n.ViewSecurityGroup = -1
					for json path) as Divisions,
	*/
			(SELECT x.FacultyRank,  n.NodeID
			FROM (
					SELECT CAST(MAX(FacultyRankID) AS VARCHAR(50)) FacultyRankID,
							LTRIM(RTRIM(FacultyRank)) FacultyRank					
					FROM [Profile.Data].[Person.FacultyRank] WITH (NOLOCK) where facultyrank <> ''				
					group by FacultyRank ,FacultyRankSort
				) x 
				LEFT OUTER JOIN [RDF.Stage].InternalNodeMap m WITH (NOLOCK)
					ON m.class = 'http://profiles.catalyst.harvard.edu/ontology/prns#FacultyRank'
						AND m.InternalType = 'FacultyRank'
						AND m.InternalID = CAST(x.FacultyRankID AS VARCHAR(50))
				LEFT OUTER JOIN [RDF.].Node n WITH (NOLOCK)
					ON m.NodeID = n.NodeID
						AND n.ViewSecurityGroup = -1
			for json path) as FacultyType,
/*
			(SELECT x.PersonFilterCategory, x.PersonFilter, x.PersonFilterSort, n.NodeID
			FROM (
					SELECT PersonFilterID, PersonFilterCategory, PersonFilter, PersonFilterSort
					FROM [Profile.Data].[Person.Filter]
				) x 
				LEFT OUTER JOIN [RDF.Stage].InternalNodeMap m WITH (NOLOCK)
					ON m.class = 'http://profiles.catalyst.harvard.edu/ontology/prns#PersonFilter'
						AND m.InternalType = 'PersonFilter'
						AND m.InternalID = CAST(x.PersonFilterID AS VARCHAR(50))
				LEFT OUTER JOIN [RDF.].Node n WITH (NOLOCK)
					ON m.NodeID = n.NodeID
						AND n.ViewSecurityGroup = -1
				for json path) as OtherOptions,*/

			(select PersonFilterCategory, row_number() over (order by min(PersonFilterSort)) as CategorySort, (select PersonFilter, PersonFilterSort, NodeID from @filters b where a.PersonFilterCategory = b.PersonFilterCategory for json path) PersonFilters  from [Profile.Data].[Person.Filter] a group by PersonFilterCategory for JSON path) as OtherOptions,
			(SELECT NumberOfQueries, Phrase
				FROM [Search.Cache].[History.TopSearchPhrase]
				WHERE TimePeriod = 'd'
				for json path) as MostViewedDay,
			(SELECT NumberOfQueries, Phrase
				FROM [Search.Cache].[History.TopSearchPhrase]
				WHERE TimePeriod = 'm'
				for json path) as MostViewedMonth,
			(select * from @stats
				for json Path) as ProfilesStats
				for json path , WITHOUT_ARRAY_WRAPPER

END

GO
/****** Object:  StoredProcedure [Display.].[SearchEverything]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.].[SearchEverything]
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


		declare @keyword nvarchar(max), @keywordExact varchar(max), @Offset int, @count int, @sort varchar(max), @currentFilterKey varchar(max)

		select @keyword = [value] from @j where [key] = 'keyword'
		select @keywordExact = [value] from @j where [key] = 'keywordExact'
		select @Offset = [value] from @j where [key] = 'Offset'
		select @count = [value] from @j where [key] = 'count'
		select @sort = [value] from @j where [key] = 'sort'
		select @currentFilterKey = [value] from @j where [key] = 'currentFilterKey'

		--declare @filterOptions varchar(max)
		--select @filterOptions = '<ClassURI>' + Class + '</ClassURI>' from [Display.].[SearchEverything.Filters] where pluralLabel = @currentFilterKey

		declare @SearchOpts varchar(max)
		set @SearchOpts =
			'<SearchOptions><MatchOptions><SearchString ExactMatch="' + @keywordExact + '">' + @keyword + '</SearchString></MatchOptions><OutputOptions><Offset>100</Offset><Limit>0</Limit></OutputOptions></SearchOptions>'
			--'<SearchOptions><MatchOptions><SearchString ExactMatch="' + @keywordExact + '">' + @keyword + '</SearchString>' + isnull(@filterOptions, '') + '</MatchOptions><OutputOptions><Offset>100</Offset><Limit>0</Limit></OutputOptions></SearchOptions>'

		create table #t (SortOrder int, NodeID bigint primary key, Weight float, type bigint, Label nvarchar(max), ClassLabel varchar(255), URL varchar(max))
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
		delete from @filters where label is null
		insert into @filters (type, [count], label) select 0, count(*), 'All' from #t		
		
		if isnull(@currentFilterKey, 'All') = 'All'
		BEGIN
			delete from #t where type not in (select _NodeID from [Display.].[SearchEverything.Filters])
			select @Offset = @Offset - 1
		END
		ELSE
		BEGIN
			delete from #t where type not in (select _NodeID from [Display.].[SearchEverything.Filters] where pluralLabel = @currentFilterKey)
			select nodeID, ROW_NUMBER() over (order by sortOrder) SortOrder into #t2 from #t
			update t set t.sortorder = t2.sortorder from #t t join #t2 t2 on t.NodeID = t2.NodeID
		END


		

		delete from #t where SortOrder < @Offset
		delete from #t where SortOrder > @Offset + @count

		declare @relativeBasePath varchar(100)
		select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'
		update #t set URL = @relativeBasePath + '/Profile/' + cast (nodeID as varchar(50))

		update a set a.ClassLabel = b.Label from #t a join [Display.].[SearchEverything.Filters] b on a.type = _NodeID

		declare @labelNodeID bigint 
		select @labelNodeID	= [RDF.].[fnURI2NodeID]('http://www.w3.org/2000/01/rdf-schema#label')
		update a set a.Label = n.value from #t a join [RDF.].Triple t on a.NodeID = t.Subject and t.Predicate = @labelNodeID join [RDF.].Node n on t.Object = n.NodeID


		select JSON_QUERY(@json, '$') as SearchQuery, (select * from @filters for json Path) as Filters, (select NodeID, Weight, Label,ClassLabel, URL from #t for JSON Path) as Results for json path, WITHOUT_ARRAY_WRAPPER
END
GO
/****** Object:  StoredProcedure [Display.].[SearchPeople]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [Display.].[SearchPeople]
	@json nvarchar(max)
AS
BEGIN
/*
	exec [Display.].[SearchPeople]
	@json='{
		"Keyword": "keyword text here",
		"KeywordExact": false,
		"LastName": "lastname text here",
		"FirstName": "FirstName text here",
		"Institution": 1229480,
		"InstitutionExcept" : false,
		"Department": 1229206,
		"DepartmentExcept": false,
		"FacultyType": [ 65970, 65968, 65967 ],
		"OtherOptions" : [65978, 65976],
		"Offset": 0,
		"Count": 15,
		"Sort": "Relevance"
	}'
*/


		declare @j table([key] varchar(max), [value] varchar(max), [type] int)
		insert into @j
		select * from openjson(@json)


		declare @keyword nvarchar(max), @keywordExact varchar(max), @Lastname nvarchar(max), @FirstName nvarchar(max), @Institution varchar(max), @InstitutionExcept varchar(max), @Department varchar(max), @DepartmentExcept varchar(max), @FacultyType varchar(max), @OtherOptions varchar(max), @Offset int, @count int, @sort varchar(max)

		select @keyword = [value] from @j where [key] = 'keyword'
		select @keywordExact = [value] from @j where [key] = 'keywordExact'
		select @Lastname = [value] from @j where [key] = 'Lastname'
		select @FirstName = [value] from @j where [key] = 'FirstName'
		select @Institution = [value] from @j where [key] = 'Institution'
		select @InstitutionExcept = [value] from @j where [key] = 'InstitutionExcept'
		select @Department = [value] from @j where [key] = 'Department'
		select @DepartmentExcept = [value] from @j where [key] = 'DepartmentExcept'
		select @FacultyType = [value] from @j where [key] = 'FacultyType'
		select @OtherOptions = [value] from @j where [key] = 'OtherOptions'
		select @Offset = [value] from @j where [key] = 'Offset'
		select @count = [value] from @j where [key] = 'count'
		select @sort = [value] from @j where [key] = 'sort'

		declare @f table([key] varchar(max), [value] varchar(max), [type] int)
		insert into @f select * from openjson(@FacultyType)

		declare @o table([key] varchar(max), [value] varchar(max), [type] int)
		insert into @o select * from openjson(@OtherOptions)

		declare @searchFilters varchar(max)
		set @searchFilters = ''

		declare @basePath varchar(max)
		select @basePath = Value from [Framework.].Parameter where ParameterID = 'basePath'

		if isnull(@FirstName, '') <> ''
		BEGIN
			select @searchFilters = '<SearchFilter Property="http://xmlns.com/foaf/0.1/firstName" MatchType="Left">' + @FirstName + '</SearchFilter>'
		END
		if isnull(@Lastname, '') <> ''
		BEGIN
			select @searchFilters = @searchFilters + '<SearchFilter Property="http://xmlns.com/foaf/0.1/lastName" MatchType="Left">' + @LastName + '</SearchFilter>'
		END
		if isnull(@institution, '') <> ''
		BEGIN
			select @InstitutionExcept = case when @InstitutionExcept = 'false' then '0' else '1' end
			select @searchFilters = @searchFilters + '<SearchFilter IsExclude="' + @InstitutionExcept + '" Property="http://profiles.catalyst.harvard.edu/ontology/prns#personInPrimaryPosition" Property2="http://vivoweb.org/ontology/core#positionInOrganization" MatchType="Exact">'
			+ @basePath + '/profile/' + @institution  + '</SearchFilter>'
		END
		if isnull(@department, '') <> ''
		BEGIN
			select @DepartmentExcept = case when @DepartmentExcept = 'false' then '0' else '1' end
			select @searchFilters = @searchFilters + '<SearchFilter IsExclude="' + @DepartmentExcept + '" Property="http://profiles.catalyst.harvard.edu/ontology/prns#personInPrimaryPosition" Property2="http://profiles.catalyst.harvard.edu/ontology/prns#positionInDepartment" MatchType="Exact">'
			+ @basePath + '/profile/' + @Department  + '</SearchFilter>'
		END
		/*
		if isnull(@division, '') <> ''
		BEGIN
			select @searchFilters = @searchFilters + '<SearchFilter IsExclude="0" Property="http://profiles.catalyst.harvard.edu/ontology/prns#personInPrimaryPosition" Property2="http://profiles.catalyst.harvard.edu/ontology/prns#positionInDivision" MatchType="Exact">'
			+ @basePath + '/profile/' + cast(NodeID as varchar(max)) + '</SearchFilter>' from [RDF.Stage].InternalNodeMap where InternalID = cast(@DivisionID as varchar(max)) AND InternalType = 'Division'
		END
		*/
		declare @i int = 0
		if exists (select 1 from @f)
		BEGIN
			select @searchFilters = @searchFilters + '<SearchFilter Property="http://profiles.catalyst.harvard.edu/ontology/prns#hasFacultyRank" MatchType="In">'
			select @i = max([key])  from @f
			while @i >=0
			BEGIN
					select @searchFilters = @searchFilters + '<Item>' + @basePath + '/profile/' + [Value] + '</Item>' from @f where [key] = @i
					select @i = @i - 1
			END
			select @searchFilters = @searchFilters + '</SearchFilter>'
		END
		if exists (select 1 from @o)
		BEGIN
			select @i = max([key])  from @o
			while @i >=0
			BEGIN
					select @searchFilters = @searchFilters + '<SearchFilter Property="http://profiles.catalyst.harvard.edu/ontology/prns#hasPersonFilter" MatchType="Exact">' + @basePath + '/profile/' + [Value] + '</SearchFilter>' from @o where [key] = @i
					select @i = @i - 1
			END
		END
		if @searchFilters <> ''
		BEGIN
			select @searchFilters = '<SearchFiltersList>' + @searchFilters + '</SearchFiltersList>'
		END


		declare @SearchOpts varchar(max)
		set @SearchOpts =
			'<SearchOptions>
				<MatchOptions>
					<SearchString ExactMatch="' + @keywordExact + '">' + @keyword + '</SearchString>'
					+ @searchFilters +
					'<ClassURI>http://xmlns.com/foaf/0.1/Person</ClassURI>
				</MatchOptions>
				<OutputOptions>
					<Offset>' + cast (isnull(@Offset, 0) as varchar(50)) + '</Offset>
					<Limit>' + cast (isnull(@count, 0) as varchar(50)) + '</Limit>
				</OutputOptions>	
			</SearchOptions>'


		declare @t table (SortOrder int, NodeID bigint, Weight float)
		declare @jsonSearchResults varchar(max)
		select @jsonSearchResults = 'a'
		 EXEC [Search.].[GetNodes] @SearchOptions =@SearchOpts, @JSON=@jsonSearchResults output
		 insert into @t (SortOrder, NodeID, Weight)
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
			
		declare @resultCount int
		select @resultCount = count(*) from @t

		declare @t2 table (SortOrder int, NodeID bigint)

		if @sort = 'name'
		begin
			insert into @t2 (nodeid, SortOrder) select a.NodeID, ROW_NUMBER() over (order by LastName, FirstName) as SortOrder from @t a join [Profile.Cache].Person b on a.NodeID = b.NodeID 
			update a set a.SortOrder = b.SortOrder from @t a join @t2 b on a.NodeID = b.NodeID
		end 
		else if @sort = 'nameza'
		begin
			insert into @t2 (nodeid, SortOrder) select a.NodeID, ROW_NUMBER() over (order by LastName desc, FirstName desc) as SortOrder from @t a join [Profile.Cache].Person b on a.NodeID = b.NodeID 
			update a set a.SortOrder = b.SortOrder from @t a join @t2 b on a.NodeID = b.NodeID
		end
		else if @sort = 'institution'
		begin
			insert into @t2 (nodeid, SortOrder) select a.NodeID, ROW_NUMBER() over (order by InstitutionName, LastName, FirstName) as SortOrder from @t a join [Profile.Cache].Person b on a.NodeID = b.NodeID 
			update a set a.SortOrder = b.SortOrder from @t a join @t2 b on a.NodeID = b.NodeID
		end
		else if @sort = 'institutionza'
		begin
			insert into @t2 (nodeid, SortOrder) select a.NodeID, ROW_NUMBER() over (order by InstitutionName desc, LastName desc, FirstName desc) as SortOrder from @t a join [Profile.Cache].Person b on a.NodeID = b.NodeID 
			update a set a.SortOrder = b.SortOrder from @t a join @t2 b on a.NodeID = b.NodeID
		end
		else if @sort = 'department'
		begin
			insert into @t2 (nodeid, SortOrder) select a.NodeID, ROW_NUMBER() over (order by DepartmentName, LastName, FirstName) as SortOrder from @t a join [Profile.Cache].Person b on a.NodeID = b.NodeID 
			update a set a.SortOrder = b.SortOrder from @t a join @t2 b on a.NodeID = b.NodeID
		end
		else if @sort = 'departmentza'
		begin
			insert into @t2 (nodeid, SortOrder) select a.NodeID, ROW_NUMBER() over (order by DepartmentName desc, LastName desc, FirstName desc) as SortOrder from @t a join [Profile.Cache].Person b on a.NodeID = b.NodeID 
			update a set a.SortOrder = b.SortOrder from @t a join @t2 b on a.NodeID = b.NodeID
		end
		else if @sort = 'facultyrank'
		begin
			insert into @t2 (nodeid, SortOrder) select a.NodeID, ROW_NUMBER() over (order by facultyranksort desc, LastName, FirstName) as SortOrder from @t a join [Profile.Cache].Person b on a.NodeID = b.NodeID 
			update a set a.SortOrder = b.SortOrder from @t a join @t2 b on a.NodeID = b.NodeID
		end
		else if @sort = 'facultyrankdesc'
		begin
			insert into @t2 (nodeid, SortOrder) select a.NodeID, ROW_NUMBER() over (order by facultyranksort, LastName desc, FirstName desc) as SortOrder from @t a join [Profile.Cache].Person b on a.NodeID = b.NodeID 
			update a set a.SortOrder = b.SortOrder from @t a join @t2 b on a.NodeID = b.NodeID
		end
		else update @t set SortOrder = SortOrder + 1

		delete from @t where SortOrder < @Offset
		delete from @t where SortOrder >= @Offset + @count

		declare @relativeBasePath varchar(max)
		select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'

		select JSON_QUERY(@json, '$') as SearchQuery, @resultCount [Count], (select DepartmentName, DisplayName, FacultyRank, InstitutionName, p.NodeID, PersonID, @relativeBasePath + isnull(defaultApplication, '') + PreferredPath as URL, Weight, SortOrder   from @t t join [Profile.Cache].Person p on t.nodeid = p.nodeID for JSON Path) as People for json path, WITHOUT_ARRAY_WRAPPER

END
GO
/****** Object:  StoredProcedure [Display.].[SearchWhy]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.].[SearchWhy]
	@json nvarchar(max)
AS
BEGIN
/*
	exec [Display.].[SearchWhy]
	@json='{
		"NodeID": 1233166
		"Keyword": "keyword text here",
		"KeywordExact": false,
		"LastName": "lastname text here",
		"FirstName": "FirstName text here",
		"Institution": 1229480,
		"InstitutionExcept" : false,
		"Department": 1229206,
		"DepartmentExcept": false,
		"FacultyType": [ 65970, 65968, 65967 ],
		"OtherOptions" : [65978, 65976],
		"Offset": 0,
		"Count": 15
	}'
*/
		declare @j table([key] varchar(max), [value] varchar(max), [type] int)
		insert into @j
		select * from openjson(@json)


		declare @keyword nvarchar(max), @keywordExact varchar(max), @Lastname nvarchar(max), @FirstName nvarchar(max), @Institution varchar(max), @InstitutionExcept varchar(max), @Department varchar(max), @DepartmentExcept varchar(max), @FacultyType varchar(max), @OtherOptions varchar(max), @Offset int, @count int, @sort varchar(max), @nodeID bigint

		select @keyword = [value] from @j where [key] = 'keyword'
		select @keywordExact = [value] from @j where [key] = 'keywordExact'
		select @Lastname = [value] from @j where [key] = 'Lastname'
		select @FirstName = [value] from @j where [key] = 'FirstName'
		select @Institution = [value] from @j where [key] = 'Institution'
		select @InstitutionExcept = [value] from @j where [key] = 'InstitutionExcept'
		select @Department = [value] from @j where [key] = 'Department'
		select @DepartmentExcept = [value] from @j where [key] = 'DepartmentExcept'
		select @FacultyType = [value] from @j where [key] = 'FacultyType'
		select @OtherOptions = [value] from @j where [key] = 'OtherOptions'
		select @Offset = [value] from @j where [key] = 'Offset'
		select @count = [value] from @j where [key] = 'count'
		select @sort = [value] from @j where [key] = 'sort'
		select @nodeID = [value] from @j where [key] = 'NodeID'

		declare @f table([key] varchar(max), [value] varchar(max), [type] int)
		insert into @f select * from openjson(@FacultyType)

		declare @o table([key] varchar(max), [value] varchar(max), [type] int)
		insert into @o select * from openjson(@OtherOptions)

		declare @searchFilters varchar(max)
		set @searchFilters = ''

		declare @basePath varchar(max)
		select @basePath = Value from [Framework.].Parameter where ParameterID = 'basePath'

		if isnull(@FirstName, '') <> ''
		BEGIN
			select @searchFilters = '<SearchFilter Property="http://xmlns.com/foaf/0.1/firstName" MatchType="Left">' + @FirstName + '</SearchFilter>'
		END
		if isnull(@Lastname, '') <> ''
		BEGIN
			select @searchFilters = @searchFilters + '<SearchFilter Property="http://xmlns.com/foaf/0.1/lastName" MatchType="Left">' + @LastName + '</SearchFilter>'
		END
		if isnull(@institution, '') <> ''
		BEGIN
			select @InstitutionExcept = case when @InstitutionExcept = 'false' then '0' else '1' end
			select @searchFilters = @searchFilters + '<SearchFilter IsExclude="' + @InstitutionExcept + '" Property="http://profiles.catalyst.harvard.edu/ontology/prns#personInPrimaryPosition" Property2="http://vivoweb.org/ontology/core#positionInOrganization" MatchType="Exact">'
			+ @basePath + '/profile/' + @institution  + '</SearchFilter>'
		END
		if isnull(@department, '') <> ''
		BEGIN
			select @DepartmentExcept = case when @DepartmentExcept = 'false' then '0' else '1' end
			select @searchFilters = @searchFilters + '<SearchFilter IsExclude="' + @DepartmentExcept + '" Property="http://profiles.catalyst.harvard.edu/ontology/prns#personInPrimaryPosition" Property2="http://profiles.catalyst.harvard.edu/ontology/prns#positionInDepartment" MatchType="Exact">'
			+ @basePath + '/profile/' + @Department  + '</SearchFilter>'
		END
		/*
		if isnull(@division, '') <> ''
		BEGIN
			select @searchFilters = @searchFilters + '<SearchFilter IsExclude="0" Property="http://profiles.catalyst.harvard.edu/ontology/prns#personInPrimaryPosition" Property2="http://profiles.catalyst.harvard.edu/ontology/prns#positionInDivision" MatchType="Exact">'
			+ @basePath + '/profile/' + cast(NodeID as varchar(max)) + '</SearchFilter>' from [RDF.Stage].InternalNodeMap where InternalID = cast(@DivisionID as varchar(max)) AND InternalType = 'Division'
		END
		*/
		declare @i int = 0
		if exists (select 1 from @f)
		BEGIN
			select @searchFilters = @searchFilters + '<SearchFilter Property="http://profiles.catalyst.harvard.edu/ontology/prns#hasFacultyRank" MatchType="In">'
			select @i = max([key])  from @f
			while @i >=0
			BEGIN
					select @searchFilters = @searchFilters + '<Item>' + @basePath + '/profile/' + [Value] + '</Item>' from @f where [key] = @i
					select @i = @i - 1
			END
			select @searchFilters = @searchFilters + '</SearchFilter>'
		END
		if exists (select 1 from @o)
		BEGIN
			select @i = max([key])  from @o
			while @i >=0
			BEGIN
					select @searchFilters = @searchFilters + '<SearchFilter Property="http://profiles.catalyst.harvard.edu/ontology/prns#hasPersonFilter" MatchType="Exact">' + @basePath + '/profile/' + [Value] + '</SearchFilter>' from @o where [key] = @i
					select @i = @i - 1
			END
		END
		if @searchFilters <> ''
		BEGIN
			select @searchFilters = '<SearchFiltersList>' + @searchFilters + '</SearchFiltersList>'
		END


		declare @SearchOpts varchar(max)
		set @SearchOpts =
			'<SearchOptions>
				<MatchOptions>
					<SearchString ExactMatch="' + @keywordExact + '">' + @keyword + '</SearchString>'
					+ @searchFilters +
					'<ClassURI>http://xmlns.com/foaf/0.1/Person</ClassURI>
				</MatchOptions>
				<OutputOptions>
					<Offset>' + cast (isnull(@Offset, 0) as varchar(50)) + '</Offset>
					<Limit>' + cast (isnull(@count, 0) as varchar(50)) + '</Limit>
				</OutputOptions>	
			</SearchOptions>'

		declare @results nvarchar(max)
		set @results = 'error'
		exec [Search.Cache].[Public.GetConnection] @SearchOptions=@SearchOpts, @NodeID=@nodeID, @json=@results output

		declare @label varchar(max), @url varchar(255)
		select @label = value from [RDF.].Triple a join [RDF.].Node b on a.Subject = @nodeID and a.Predicate = [RDF.].fnURI2NodeID ('http://www.w3.org/2000/01/rdf-schema#label') and a.Object = b.nodeID
		declare @relativeBasePath varchar(max)
		select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'
		select @url = @relativeBasePath + '/profile/' + cast(@nodeID as varchar(50))

		select JSON_QUERY(@json, '$') as SearchQuery, JSON_QUERY(@results, '$') as 'Connections', @nodeID as "ConnectionNode.NodeID", @label as "ConnectionNode.Label", @url as "ConnectionNode.URL" for json path, WITHOUT_ARRAY_WRAPPER
END
GO
/****** Object:  StoredProcedure [Display.Lists].[UpdateLists]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [Display.Lists].[UpdateLists]
	@UserID  int,
	@Action varchar(15),
	@SessionID  UNIQUEIDENTIFIER,
	@Json nvarchar(max) = null
AS
BEGIN

	SET NOCOUNT ON

	/* Confirm User has access to edit list */
	declare @SessionUserID int
	select @sessionUserID = UserID from [User.Session].Session where LogoutDate is null and sessionID=@sessionID and CreateDate > dateAdd(day, -1, getdate())
	if @userID <> @SessionUserID
	begin
		select -2
		return
	end

	
	declare @size int
	set @size=-1
	declare @SubjectPersonID int
	declare @SubjectNodeID bigint

	declare @j table([key] varchar(max), [value] varchar(max), [type] int)
	insert into @j
	select * from openjson(@json)

	select @SubjectPersonID = [value] from @j where [key] = 'SubjectPersonID'
	select @SubjectNodeID = [value] from @j where [key] = 'SubjectNodeID'
	if @SubjectPersonID is null and @SubjectNodeID is not null
		select @SubjectPersonID = PersonID from [Profile.Cache].Person where NodeID = @SubjectNodeID

	declare @searchXML varchar(max)

	if @action = 'DeleteAll'
	begin
		exec [Profile.Data].[List.AddRemove.Filter] @UserID=@UserID, @Institution=null, @FacultyRank=null, @Remove=1, @Size=@size output
	end
	else if @action = 'DeletePerson' and @SubjectPersonID > 0
	begin
		exec [Profile.Data].[List.AddRemove.Person] @UserID=@UserID, @PersonID=@SubjectPersonID, @Remove=1, @Size=@size output
	end
	else if @action = 'DeleteSearch'
	begin
		set @searchXML = [Display.].[FnConvertSearchJSON2XML](@JSON, 0)
		exec [Profile.Data].[List.AddRemove.Search]	@UserID=@UserID, @SearchXML=@searchXML, @SessionID=@SessionID, @Remove=1, @Size=@size OUTPUT
	end
	else if @action = 'AddPerson' and @SubjectPersonID > 0
	begin
		exec [Profile.Data].[List.AddRemove.Person] @UserID=@UserID, @PersonID=@SubjectPersonID, @Remove=0, @Size=@size output
	end
	else if @action = 'AddSearch'
	begin
		set @searchXML = [Display.].[FnConvertSearchJSON2XML](@JSON, 0)
		exec [Profile.Data].[List.AddRemove.Search]	@UserID=@UserID, @SearchXML=@searchXML, @SessionID=@SessionID, @Remove=0, @Size=@size OUTPUT
	end
	select @size
END
GO
/****** Object:  StoredProcedure [Display.Module].[AwardReceipt.GeneralInfo]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[AwardReceipt.GeneralInfo]
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN
	declare @relativeBasePath varchar(max)
	select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'

	declare @label nvarchar(max), @awardConferredBy nvarchar(max), @startdate varchar(max), @enddate varchar(max), @personNodeID bigint
	select @label = Value from [RDF.].Triple t join [RDF.].Node o on t.Object = o.NodeID and subject = @Subject and Predicate = [RDF.].fnURI2NodeID('http://www.w3.org/2000/01/rdf-schema#label')
	select @awardConferredBy = Value from [RDF.].Triple t join [RDF.].Node o on t.Object = o.NodeID and subject = @Subject and Predicate = [RDF.].fnURI2NodeID('http://profiles.catalyst.harvard.edu/ontology/prns#awardConferredBy')
	select @startdate = Value from [RDF.].Triple t join [RDF.].Node o on t.Object = o.NodeID and subject = @Subject and Predicate = [RDF.].fnURI2NodeID('http://profiles.catalyst.harvard.edu/ontology/prns#startDate')
	select @enddate = Value from [RDF.].Triple t join [RDF.].Node o on t.Object = o.NodeID and subject = @Subject and Predicate = [RDF.].fnURI2NodeID('http://profiles.catalyst.harvard.edu/ontology/prns#endDate')
	select @personNodeID = Object from [RDF.].Triple t where subject = @Subject and Predicate = [RDF.].fnURI2NodeID('http://vivoweb.org/ontology/core#awardOrHonorFor')

	select @json = (select @label label, @awardConferredBy awardConferredBy, @startdate startDate, @enddate endDate, DisplayName, @relativeBasePath + isnull(defaultApplication, '') + PreferredPath as URL
						from [Profile.Cache].Person where nodeID = @personNodeID	
						for json path, WITHOUT_ARRAY_WRAPPER) 
	select @json = (select JSON_QUERY(@json, '$') as module_data for json path, WITHOUT_ARRAY_WRAPPER)
END
GO
/****** Object:  StoredProcedure [Display.Module].[Coauthor.Cluster]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[Coauthor.Cluster]
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
	select @json = [Display.Module].[FnNetworkRadial.GetData](@subject, null, null)
END
GO
/****** Object:  StoredProcedure [Display.Module].[Coauthor.Connection]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[Coauthor.Connection]
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
	declare @relativeBasePath varchar(max), @SubjectPath varchar(max)
	select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'
	select @personID = PersonID, @SubjectPath = @relativeBasePath + isnull(DefaultApplication, '') + PreferredPath from [Profile.Cache].Person where NodeID = @Subject
	declare @PredicatePath varchar(max)
	select @PredicatePath = isnull((select '/' + AliasType + '/' + AliasID from [RDF.].Alias where NodeID = @Predicate), '/' + cast(@predicate as varchar(50)))


	create table #tmpCoauthors (
		[PersonID2] [int] NOT NULL primary key,
		[w] [float] NULL,
		--[FirstPubDate] [datetime] NULL,
		[LastPubYear] int NULL,
		[n] [int] NULL,
		name varchar(255), 
		DisplayName varchar(255),
		URL varchar(max),
		WhyPath varchar(max))

	insert into #tmpCoauthors (PersonID2, w, LastPubYear, n) select PersonID2, w, YEAR(LastPubDate), n FROM [Profile.Cache].[SNA.Coauthor] where PersonID1 = @personID
	

/*
	declare @tmpTriple as [Display.].[utTriple]
	insert into @tmpTriple(personID) select PersonID2 from #tmpCoauthors

	update t set URL = preferredURL
		from #tmpCoauthors t join [Display.].[fnGetPreferredURLs](@tmpTriple) f 
		on t.personID2 = f.personID
*/
	update t set t.name = isnull(LastName, '') + isnull(', ' + firstname, ''), DisplayName = p.DisplayName, URL=@relativeBasePath + isnull(DefaultApplication, '') + PreferredPath, WhyPath = @SubjectPath + @PredicatePath + PreferredPath from #tmpCoauthors t join [Profile.Cache].Person p on t.PersonID2 = p.PersonID
	select @json = (select Name, DisplayName, URL, w as [Weight], n as [Count], LastPubYear, WhyPath from #tmpCoauthors for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[Coauthor.Map]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [Display.Module].[Coauthor.Map]
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN
	declare @personID int, @relativeBasePath varchar(55)
	select @personID = [RDF.].[fnNodeID2PersonID](@Subject)

		select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'

	DECLARE  @f  TABLE(
		PersonID INT,
		display_name NVARCHAR(255),
		latitude FLOAT,
		longitude FLOAT,
		address1 NVARCHAR(1000),
		address2 NVARCHAR(1000),
		URI VARCHAR(400)
	)
 
	INSERT INTO @f (	PersonID,
						display_name,
						latitude,
						longitude,
						address1,
						address2,
						URI
					)
		SELECT	p.PersonID,
				p.displayname,
				p.latitude,
				p.longitude,
				CASE WHEN p.addressstring like '%,%' THEN LEFT(p.addressstring,CHARINDEX(',',p.addressstring) - 1)ELSE P.addressstring END address1,
				CASE WHEN p.addressstring like '%,%' THEN REPLACE(SUBSTRING(p.addressstring,CHARINDEX(',',p.addressstring) + 1,LEN(p.addressstring)),', USA','') ELSE p.addressstring END address2,
				@relativeBasePath + isnull(p.DefaultApplication, '') + p.PreferredPath
		FROM [Profile.Cache].Person p,
				(SELECT DISTINCT PersonID
					FROM  [Profile.Data].[Publication.Person.Include]
					WHERE pmid IN (SELECT pmid
										FROM [Profile.Data].[Publication.Person.Include]
										WHERE PersonID = @PersonID
											AND pmid IS NOT NULL
									)
				) t
		 WHERE p.PersonID = t.PersonID
			 AND p.latitude IS NOT NULL
			 AND p.longitude IS NOT NULL
			 AND p.IsActive = 1
		 ORDER BY p.lastname, p.firstname
/* 
	UPDATE @f
		SET URI = p.Value + cast(m.NodeID as varchar(50))
		FROM @f, [RDF.Stage].InternalNodeMap m, [Framework.].Parameter p
		WHERE p.ParameterID = 'baseURI' AND m.InternalHash = [RDF.].fnValueHash(null,null,'http://xmlns.com/foaf/0.1/Person^^Person^^'+cast(PersonID as varchar(50)))
 */
 
	DELETE FROM @f WHERE URI IS NULL
 
	IF (SELECT COUNT(*) FROM @f) = 1
		IF (SELECT personid from @f)=@PersonID
			DELETE FROM @f
 
	declare @json1 nvarchar(max), @json2 nvarchar(max)
	select @json1 = (SELECT PersonID, 
			display_name,
			CONVERT(DECIMAL(18,5),latitude) latitude,
			CONVERT(DECIMAL(18,5),longitude) longitude,
			address1,
			address2,
			URI
		FROM @f
		ORDER BY address1,
			address2,
			display_name
			for json path, ROOT ('people'))


		select @json2 = (SELECT DISTINCT	a.latitude	x1,
						CONVERT(DECIMAL(18,5),a.longitude)	y1,
						CONVERT(DECIMAL(18,5),d.latitude)	x2,
						CONVERT(DECIMAL(18,5),d.longitude)	y2,
						CONVERT(DECIMAL(18,5),a.PersonID)	a,
						CONVERT(DECIMAL(18,5),d.PersonID)	b,
						(CASE 
							 WHEN a.PersonID = @PersonID
								OR d.PersonID = @PersonID THEN 1
							 ELSE 0
						 END) is_person,
						a.URI u1,
						d.URI u2
			FROM @f a,
					 [Profile.Data].[Publication.Person.Include] b,
					 [Profile.Data].[Publication.Person.Include] c,
					 @f d
		 WHERE a.PersonID = b.PersonID
			 AND b.pmid = c.pmid
			 AND b.PersonID < c.PersonID
			 AND c.PersonID = d.PersonID
			 for json path, ROOT ('connections'))

		 select @json = (select JSON_QUERY(@json1, '$.people') as people, JSON_QUERY(@json2, '$.connections')as connections for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[Coauthor.Timeline]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [Display.Module].[Coauthor.Timeline]
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
	select @personID = [RDF.].[fnNodeID2PersonID](@Subject)

 
 	--DECLARE @baseURI NVARCHAR(400)
	--SELECT @baseURI = value FROM [Framework.].Parameter WHERE ParameterID = 'baseURI'

	declare @relativeBasePath varchar(max)
	select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'

	;with e as (
		select top 20 s.PersonID1, s.PersonID2, s.n PublicationCount, 
			year(s.FirstPubDate) FirstPublicationYear, year(s.LastPubDate) LastPublicationYear, 
			p.DisplayName DisplayName2, ltrim(rtrim(p.FirstName+' '+p.LastName)) FirstLast2, s.w OverallWeight, @relativeBasePath + isnull(defaultApplication, '') + PreferredPath as Person2URL
		from [Profile.Cache].[SNA.Coauthor] s, [Profile.Cache].[Person] p
		where personid1 = @PersonID and personid2 = p.personid
		order by w desc, personid2
	), f as (
		select e.*, g.pubdate
		from [Profile.Data].[Publication.Person.Include] a, 
			[Profile.Data].[Publication.Person.Include] b, 
			[Profile.Data].[Publication.PubMed.General] g,
			e
		where a.personid = e.personid1 and b.personid = e.personid2 and a.pmid = b.pmid and a.pmid = g.pmid
			and g.pubdate > '1/1/1900'
	), g as (
		select min(year(pubdate))-1 a, max(year(pubdate))+1 b,
			cast(cast('1/1/'+cast(min(year(pubdate))-1 as varchar(10)) as datetime) as float) f,
			cast(cast('1/1/'+cast(max(year(pubdate))+1 as varchar(10)) as datetime) as float) g
		from f
	), h as (
		select f.*, (cast(pubdate as float)-f)/(g-f) x, a, b, f, g
		from f, g
	), i as (
		select personid2, min(x) MinX, max(x) MaxX, avg(x) AvgX
		from h
		group by personid2
	), j as (
		select *, cast(a + (b - a) * AvgX  as int) AvgYear, cast(((b - a) * AvgX - cast((b - a) * AvgX  as int)) * 12 + 1 as int) as AvgMonth  from i join g on 1 = 1
	)
	--select @json = (select a MinDisplayYear, b MaxDisplayYear, (select PersonID1, e.PersonID2, PublicationCount, FirstPublicationYear, LastPublicationYear, DisplayName2, FirstLast2, Person2URL, OverallWeight, MinX, MaxX, AvgX, (select x from h where h.PersonID2 = e.PersonID2 for json path) xvals from e e join i i on e.PersonID2 = i.PersonID2 for json path) People from g for json path, ROOT ('module_data'))
	select @json = (select a MinDisplayYear, b MaxDisplayYear, (select PersonID1, e.PersonID2, PublicationCount, FirstPublicationYear, LastPublicationYear, DisplayName2, FirstLast2, Person2URL, OverallWeight, MinX, MaxX, AvgX, AvgYear, AvgMonth, (select x from h where h.PersonID2 = e.PersonID2 for json path) xvals from e e join j i on e.PersonID2 = i.PersonID2 for json path) People from g for json path, WITHOUT_ARRAY_WRAPPER)
	select @json = (select JSON_QUERY(@json, '$') as module_data for json path, WITHOUT_ARRAY_WRAPPER)
END
GO
/****** Object:  StoredProcedure [Display.Module].[CoauthorSimilar.Map]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [Display.Module].[CoauthorSimilar.Map]
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
	select @personID = 0

	declare @relativeBasePath varchar(100)
	select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'

	DECLARE  @f  TABLE(
		PersonID INT,
		display_name NVARCHAR(255),
		latitude FLOAT,
		longitude FLOAT,
		address1 NVARCHAR(1000),
		address2 NVARCHAR(1000),
		URI VARCHAR(400)
	)
 
	IF @Predicate = [RDF.].fnURI2NodeID('http://profiles.catalyst.harvard.edu/ontology/prns#coAuthorOf')
	BEGIN
		select @personID = [RDF.].[fnNodeID2PersonID](@Subject)
		insert into @f (PersonID) 
		SELECT DISTINCT PersonID
			FROM  [Profile.Data].[Publication.Person.Include]
			WHERE pmid IN (SELECT pmid
								FROM [Profile.Data].[Publication.Person.Include]
								WHERE PersonID = @PersonID
									AND pmid IS NOT NULL)
	END 


	ELSE IF @Predicate = [RDF.].fnURI2NodeID('http://profiles.catalyst.harvard.edu/ontology/prns#similarTo')
	BEGIN
		select @personID = [RDF.].[fnNodeID2PersonID](@Subject)
		insert into @f (PersonID) Values (@personID)
		insert into @f (PersonID) 
			SELECT SimilarPersonID FROM [Profile.Cache].[Person.SimilarPerson] WHERE PersonID = @PersonID
	END
	ELSE IF @Predicate = [RDF.].fnURI2NodeID('http://profiles.catalyst.harvard.edu/ontology/prns#hasConnection')
	BEGIN
		declare @groupID int
		select @groupID = cast(internalID as int) from [RDF.Stage].InternalNodeMap where NodeID = @Subject and Class = 'http://xmlns.com/foaf/0.1/Group'
		insert into @f (PersonID) 
			select PersonID from [Profile.Data].[Group.Member] a join [Profile.Cache].[Person] b on a.userID = b.UserID where GroupID = @groupID
	END

	update f 
		set f.display_name = p.displayname,
			f.latitude = p.Latitude,
			f.longitude = p.Longitude,
			f.address1 = CASE WHEN p.addressstring LIKE '%,%' THEN LEFT(p.addressstring,CHARINDEX(',',p.addressstring) - 1)ELSE p.addressstring END,
			f.address2 = REPLACE(SUBSTRING(p.addressstring,CHARINDEX(',',p.addressstring) + 1, LEN(p.addressstring)),', USA',''),
			URI= @relativeBasePath + isnull(DefaultApplication, '') + PreferredPath
		from @f f
		join [Profile.Cache].Person p on f.PersonID = p.PersonID

	delete from @f where latitude IS NULL OR longitude IS NULL OR URI is null
 
	IF (SELECT COUNT(*) FROM @f) = 1
		IF (SELECT personid from @f)=@PersonID
			DELETE FROM @f
 
	declare @json1 nvarchar(max), @json2 nvarchar(max)
	select @json1 = (SELECT PersonID, 
			display_name,
			CONVERT(DECIMAL(18,5),latitude) latitude,
			CONVERT(DECIMAL(18,5),longitude) longitude,
			address1,
			address2,
			URI
		FROM @f
		ORDER BY address1,
			address2,
			display_name
			for json path, ROOT ('people'))


		select @json2 = (SELECT DISTINCT	a.latitude	x1,
						CONVERT(DECIMAL(18,5),a.longitude)	y1,
						CONVERT(DECIMAL(18,5),d.latitude)	x2,
						CONVERT(DECIMAL(18,5),d.longitude)	y2,
						CONVERT(DECIMAL(18,5),a.PersonID)	a,
						CONVERT(DECIMAL(18,5),d.PersonID)	b,
						(CASE 
							 WHEN a.PersonID = @PersonID
								OR d.PersonID = @PersonID THEN 1
							 ELSE 0
						 END) is_person,
						a.URI u1,
						d.URI u2
			FROM @f a,
					 [Profile.Data].[Publication.Person.Include] b,
					 [Profile.Data].[Publication.Person.Include] c,
					 @f d
		 WHERE a.PersonID = b.PersonID
			 AND b.pmid = c.pmid
			 AND b.PersonID < c.PersonID
			 AND c.PersonID = d.PersonID
			 for json path, ROOT ('connections'))

		 select @json = (select JSON_QUERY(@json1, '$.people') as people, JSON_QUERY(@json2, '$.connections')as connections for json path, WITHOUT_ARRAY_WRAPPER)
		 select @json = (select JSON_QUERY(@json, '$') as module_data for json path, WITHOUT_ARRAY_WRAPPER)
END

GO
/****** Object:  StoredProcedure [Display.Module].[Concept.GeneralInfo]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[Concept.GeneralInfo]
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN


	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	declare @baseURI nvarchar(400)
	select @baseURI = value from [Framework.].Parameter where ParameterID = 'baseURI'


	------------------------------------------------------------
	-- Convert the NodeID to a DescriptorUI
	------------------------------------------------------------

	DECLARE @DescriptorUI VARCHAR(50)
	SELECT @DescriptorUI = m.InternalID
		FROM [RDF.Stage].[InternalNodeMap] m, [RDF.].Node n
		WHERE m.Status = 3 AND m.ValueHash = n.ValueHash AND n.NodeID = @Subject
 
	IF @DescriptorUI IS NULL
	BEGIN
		SELECT cast(null as xml) DescriptorXML WHERE 1=0
		RETURN
	END


	------------------------------------------------------------
	-- Combine MeSH tables
	------------------------------------------------------------
	/*
	select r.TreeNumber FullTreeNumber, 
			(case when len(r.TreeNumber)=1 then '' else left(r.TreeNumber,len(r.TreeNumber)-4) end) ParentTreeNumber,
			r.DescriptorName, IsNull(t.TreeNumber,r.TreeNumber) TreeNumber, t.DescriptorUI, m.NodeID, f.Value+cast(m.NodeID as varchar(50)) NodeURI
		into #m
		from [Profile.Data].[Concept.Mesh.TreeTop] r
			left outer join [Profile.Data].[Concept.Mesh.Tree] t
				on t.TreeNumber = substring(r.TreeNumber,3,999)
			left outer join [RDF.Stage].[InternalNodeMap] m
				on m.Class = 'http://www.w3.org/2004/02/skos/core#Concept'
					and m.InternalType = 'MeshDescriptor'
					and m.InternalID = cast(t.DescriptorUI as varchar(50))
					and t.DescriptorUI is not null
					and m.Status = 3
			left outer join [Framework.].[Parameter] f
				on f.ParameterID = 'baseURI'
	
	create unique clustered index idx_f on #m(FullTreeNumber)
	create nonclustered index idx_d on #m(DescriptorUI)
	create nonclustered index idx_p on #m(ParentTreeNumber)
	*/

	------------------------------------------------------------
	-- Construct the DescriptorXML
	------------------------------------------------------------

	declare @name varchar(255), @definition varchar(max)
	select @name = DescriptorName from [Profile.Data].[Concept.Mesh.Descriptor] where DescriptorUI = @DescriptorUI
	select @definition = nref.value('(//ConceptList[1]/Concept[@PreferredConceptYN = "Y"]/ScopeNote[1])[1]','varchar(max)') from [Profile.Data].[Concept.Mesh.XML]  cross apply MeSH.nodes('//DescriptorRecord[1]') as R(nref) where descriptorUI = @DescriptorUI

	;with p0 as (
		select distinct b.*
		from [Profile.Cache].[Concept.Mesh.TreeTop] a, [Profile.Cache].[Concept.Mesh.TreeTop] b
		where a.DescriptorUI = @DescriptorUI
			and a.FullTreeNumber like b.FullTreeNumber+'%'
	), r0 as (
		select c.*, b.DescriptorName ParentName, 2 Depth
			from [Profile.Cache].[Concept.Mesh.TreeTop] a, [Profile.Cache].[Concept.Mesh.TreeTop] b, [Profile.Cache].[Concept.Mesh.TreeTop] c
			where a.DescriptorUI = @DescriptorUI
				and a.ParentTreeNumber = b.FullTreeNumber
				and c.ParentTreeNumber = b.FullTreeNumber
		union all
		select b.*, b.DescriptorName ParentName, 1 Depth
			from [Profile.Cache].[Concept.Mesh.TreeTop] a, [Profile.Cache].[Concept.Mesh.TreeTop] b
			where a.DescriptorUI = @DescriptorUI
				and a.ParentTreeNumber = b.FullTreeNumber
	), r1 as (
		select *
		from (
			select *, row_number() over (partition by DescriptorName, ParentName order by TreeNumber) k
			from r0
		) t
		where k = 1
	), c0 as (
		select top 1 DescriptorUI, TreeNumber, DescriptorName,FullTreeNumber
		from [Profile.Cache].[Concept.Mesh.TreeTop]
		where DescriptorUI = @DescriptorUI
		order by FullTreeNumber
	), c1 as (
		select b.DescriptorUI, b.TreeNumber, b.DescriptorName, 2 Depth
			from c0 a, [Profile.Cache].[Concept.Mesh.TreeTop] b
			where b.ParentTreeNumber = a.FullTreeNumber
		union all
		select DescriptorUI, TreeNumber, DescriptorName, 1 Depth
			from c0
	)
	select @json = 
		(select 
			@DescriptorUI DescriptorID, @name DescriptorName, @definition DescriptorDefinition,
			(select nref.value('.','varchar(50)') TreeNumber from [Profile.Data].[Concept.Mesh.XML]  cross apply MeSH.nodes('/DescriptorRecord[1]/TreeNumberList[1]/TreeNumber') as R(nref) where descriptorUI = @DescriptorUI for json path) TreeNumberList ,
			(select nref.value('String[1]','varchar(50)') Term from [Profile.Data].[Concept.Mesh.XML]  cross apply MeSH.nodes('//TermList/Term') as R(nref) where descriptorUI = @DescriptorUI for json path) TermList, 
			(select DescriptorUI, TreeNumber, DescriptorName,
					len(FullTreeNumber)-len(replace(FullTreeNumber,'.',''))+1 Depth,
					m.NodeID, @baseURI+cast(m.NodeID as varchar(50)) NodeURI,
					row_number() over (order by FullTreeNumber) SortOrder
				from p0 x
					left outer join [RDF.Stage].[InternalNodeMap] m
						on m.Class = 'http://www.w3.org/2004/02/skos/core#Concept'
							and m.InternalType = 'MeshDescriptor'
							and m.InternalID = x.DescriptorUI
							and x.DescriptorUI is not null
							and m.Status = 3
				for json path) ParentDescriptors  ,
			(select DescriptorUI, TreeNumber, DescriptorName, Depth,
					m.NodeID, @baseURI+cast(m.NodeID as varchar(50)) NodeURI,
					row_number() over (order by ParentName, Depth, DescriptorName) SortOrder
				from r1 x
					left outer join [RDF.Stage].[InternalNodeMap] m
						on m.Class = 'http://www.w3.org/2004/02/skos/core#Concept'
							and m.InternalType = 'MeshDescriptor'
							and m.InternalID = x.DescriptorUI
							and x.DescriptorUI is not null
							and m.Status = 3
				for json path) SiblingDescriptors,
			(select DescriptorUI, TreeNumber, DescriptorName, Depth,
					m.NodeID, @baseURI+cast(m.NodeID as varchar(50)) NodeURI,
					row_number() over (order by Depth, DescriptorName) SortOrder
				from c1 x
					left outer join [RDF.Stage].[InternalNodeMap] m
						on m.Class = 'http://www.w3.org/2004/02/skos/core#Concept'
							and m.InternalType = 'MeshDescriptor'
							and m.InternalID = x.DescriptorUI
							and x.DescriptorUI is not null
							and m.Status = 3
				where (select count(*) from c1) > 1
				for json path) ChildDescriptors
			for json path,  WITHOUT_ARRAY_WRAPPER
	)

	select @json = (select JSON_QUERY(@json, '$') as module_data for json path, WITHOUT_ARRAY_WRAPPER)

END
GO
/****** Object:  StoredProcedure [Display.Module].[Concept.PreloadLabel]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[Concept.PreloadLabel]
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN


	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	declare @baseURI nvarchar(400)
	select @baseURI = value from [Framework.].Parameter where ParameterID = 'baseURI'


	------------------------------------------------------------
	-- Convert the NodeID to a DescriptorUI
	------------------------------------------------------------

	DECLARE @DescriptorUI VARCHAR(50)
	SELECT @DescriptorUI = m.InternalID
		FROM [RDF.Stage].[InternalNodeMap] m, [RDF.].Node n
		WHERE m.Status = 3 AND m.ValueHash = n.ValueHash AND n.NodeID = @Subject
 
	IF @DescriptorUI IS NULL
	BEGIN
		SELECT cast(null as xml) DescriptorXML WHERE 1=0
		RETURN
	END

	declare @name varchar(255), @definition varchar(max)
	select @name = DescriptorName from [Profile.Data].[Concept.Mesh.Descriptor] where DescriptorUI = @DescriptorUI

	select @json = (select @name label  for json path, WITHOUT_ARRAY_WRAPPER)
	select @json = (select JSON_QUERY(@json, '$') as module_data for json path, WITHOUT_ARRAY_WRAPPER)

END
GO
/****** Object:  StoredProcedure [Display.Module].[Concept.Publications]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [Display.Module].[Concept.Publications]
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
/*	declare @personID int
	select @personID = cast(internalID as int) from [RDF.Stage].InternalNodeMap 
		where nodeID = @Subject
		and Class = 'http://xmlns.com/foaf/0.1/Person'
		

	create table #personPubs(
		NodeID bigint,
		EntityID int,
		rdf_about varchar(max),
		rdfs_label nvarchar(max),
		prns_informationResourceReference nvarchar(max),
		prns_publicationDate datetime,
		prns_year int,
		bibo_pmid int,
		vivo_pmcid varchar(max),
		bibo_doi varchar(max),
		prns_mpid varchar(max),
		vivo_webpage varchar(max),
		PMCCitations int,
		Fields varchar(max),
		TranslationHumans int,
		TranslationAnimals int, 
		TranslationCells int,
		TranslationPublicHealth int,
		TranslationClinicalTrial int
		)
	insert into #personPubs
	select * from [Profile.Data].[fnPublication.Person.GetPublications](
	--exec [Profile.Module].[CustomViewAuthorInAuthorship.GetList] @nodeID=@subject
	--Select FirstName, LastName, DisplayName, AddressLine1, AddressLine2, AddressLine3, AddressLine4, Phone, Fax from [Profile.Cache].Person where personID = @personID for json path
	 selecT @json = (Select * from #personPubs for json path, ROOT ('module_data'))
*/
	declare @publications nvarchar(max), @timeline nvarchar(max)
	--select @personID = [RDF.].[fnNodeID2PersonID](@Subject)
	--select @pubsCount = count(*) from [Profile.Data].[Publication.Entity.Authorship] where IsActive = 1 and personID = @personID
	select @publications = [Display.Module].[FnCustomViewConceptPublications.GetList](@Subject, null, 10, 'N')
	select @timeline = [Display.Module].[FnNetworkAuthorshipTimeline.Concept.GetData](@subject)
	--select @fieldSummary = [Display.Module].[FnCustomViewAuthorInAuthorship.GetJournalHeadings](@subject, @personID, null)

	--select @json = (select @publications Publications for json path, ROOT ('module_data'))
	select @json = (select JSON_QUERY(@publications, '$.Publications')as Publications, JSON_QUERY(@timeline, '$.Timeline')as Timeline for json path, ROOT ('module_data'))
	--Select DisplayModule, JSON_QUERY(json, '$.module_data')as ModuleData from #dataModules for json path
	 --select @json = [Display.Module].[FnCustomViewAuthorInAuthorship.GetList](@subject, null)
END
GO
/****** Object:  StoredProcedure [Display.Module].[Concept.SimilarConcept]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [Display.Module].[Concept.SimilarConcept]
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

	DECLARE @DescriptorName NVARCHAR(255)
 	SELECT @DescriptorName = d.DescriptorName
		FROM [RDF.Stage].[InternalNodeMap] m, [RDF.].Node n,
			[Profile.Data].[Concept.Mesh.Descriptor] d
		WHERE m.Status = 3 AND m.ValueHash = n.ValueHash AND n.NodeID = @Subject
			AND m.InternalID = d.DescriptorUI

	declare @relativeBasePath varchar(55)
	select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'

	;with a as (
		select SimilarConcept DescriptorName, Weight, SortOrder
		from [Profile.Cache].[Concept.Mesh.SimilarConcept]
		where meshheader = @DescriptorName
	), b as (
		select top 10 DescriptorName, Weight, (select count(*) from a) TotalRecords, SortOrder
		from a
	)
	select @json = (select b.*,  @relativeBasePath + isnull(DefaultApplication, '') + URL URL from b b join [Profile.Cache].[Concept.Mesh.URL] c on b.DescriptorName = c.DescriptorName for json path, ROOT ('module_data'))
END

GO
/****** Object:  StoredProcedure [Display.Module].[Concept.TopJournals]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Concept.TopJournals]
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

	DECLARE @DescriptorName NVARCHAR(255)
 	SELECT @DescriptorName = d.DescriptorName
		FROM [RDF.Stage].[InternalNodeMap] m, [RDF.].Node n,
			[Profile.Data].[Concept.Mesh.Descriptor] d
		WHERE m.Status = 3 AND m.ValueHash = n.ValueHash AND n.NodeID = @Subject
			AND m.InternalID = d.DescriptorUI

	select @json = ( select top 10 Journal, Weight
		from [Profile.Cache].[Concept.Mesh.Journal]
		where meshheader = @DescriptorName
		order by Weight desc for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[Concept.TopPeople]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[Concept.TopPeople]
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

	DECLARE @DescriptorName NVARCHAR(255)
 	SELECT @DescriptorName = d.DescriptorName
		FROM [RDF.Stage].[InternalNodeMap] m, [RDF.].Node n,
			[Profile.Data].[Concept.Mesh.Descriptor] d
		WHERE m.Status = 3 AND m.ValueHash = n.ValueHash AND n.NodeID = @Subject
			AND m.InternalID = d.DescriptorUI

	declare @relativeBasePath varchar(55)
	select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'

	select @json = (select top 5 round(weight, 2) weight, lastname + ', ' + firstname Name, @relativeBasePath + isnull(DefaultApplication, '') + PreferredPath URL from [Profile.Cache].[Concept.Mesh.Person] a
	join [Profile.Cache].Person b on a.PersonID = b.PersonID and b.IsActive = 1
	and MeshHeader = 'adult' order by weight desc for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[Connection]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Connection]
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN
	declare @label bigint = [RDF.].fnURI2NodeID('http://www.w3.org/2000/01/rdf-schema#label')
	select @json = (
		select s.Value subject_label, isnull((select AliasType  + '/' + AliasID from [RDF.].Alias where NodeID = @subject and Preferred = 1) , '/' + cast(@subject as varchar(50))) subject_path
			,p.Value predicate_label
			, o.Value object_label, isnull((select AliasType  + '/' + AliasID from [RDF.].Alias where NodeID = @object and Preferred = 1) , '/' + cast(@object as varchar(50))) object_path
			,CONVERT(DECIMAL(18,2),ROUND(t.Weight, 2)) as weight from [RDF.].Triple t
			join [RDF.].Triple ts on t.Subject = @subject and t.object = @object and t.Predicate = @predicate
				and ts.Subject = t.Subject and ts.predicate= @label
			join [RDF.].Node s on ts.Object = s.nodeID
			join [RDF.].Triple tp on tp.Subject = t.Predicate and tp.predicate= @label
			join [RDF.].Node p on p.NodeID = tp.Object
			join [RDF.].Triple tob on tob.Subject = t.Object and tob.predicate= @label
			join [RDF.].Node o on o.NodeID = tob.Object
		for json path, ROOT ('module_data')
	)
END
GO
/****** Object:  StoredProcedure [Display.Module].[GenericPropertyList]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[GenericPropertyList]
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN

	declare @rdf table (
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
			SortOrder int,
			URL nvarchar(max),
			PropertyGroupLabel varchar(max),
			PropertyGroupSort int,
			PropertyGroupInnerSort int
		)


	insert into @rdf(uri, subject, predicate, object, showSummary, property, tagName, propertyLabel, Language, DataType, Value,	ObjectType, SortOrder)
	exec [Display.].[GetDataRDF] @subject=@Subject,@predicate=@Predicate,@object=@object,@SessionID=null,@Expand=0,@limit=20
	delete from @rdf where predicate = [RDF.].fnURI2NodeID('http://www.w3.org/1999/02/22-rdf-syntax-ns#type')

	update r set r.URL = r.Value, r.value = n.Value from @rdf r join 
		[RDF.].Triple t on r.object = t.Subject and r.ObjectType = 0
		join [RDF.].Node n on t.predicate = [RDF.].fnURI2NodeID('http://www.w3.org/2000/01/rdf-schema#label') and t.Object = n.NodeID

	update r set r.PropertyGroupLabel = pg._PropertyGroupLabel, r.PropertyGroupSort = pg.SortOrder, r.PropertyGroupInnerSort = isnull(pgp.sortOrder, 1000) from @rdf r left join 
		[Ontology.].PropertyGroupProperty pgp on r.predicate = pgp._PropertyNode
		join [Ontology.].PropertyGroup pg on isnull(pgp._PropertyGroupNode, [RDF.].fnURI2NodeID('http://profiles.catalyst.harvard.edu/ontology/prns#PropertyGroupOverview')) = pg._PropertyGroupNode

	select @json = (select PropertyLabel, Value, URL, SortOrder, PropertyGroupSort, PropertyGroupLabel, PropertyGroupInnerSort From @rdf for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[GenericRDF.FeaturedPresentations]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [Display.Module].[GenericRDF.FeaturedPresentations]
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
	select @json = (
		SELECT
			data from [Profile.Module].[GenericRDF.Data] where name = 'FeaturedPresentations' and NodeID = @Subject
			for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[GenericRDF.FeaturedVideos]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[GenericRDF.FeaturedVideos]
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

	select @json = (
		SELECT
			JSON_QUERY(data, '$') as data from [Profile.Module].[GenericRDF.Data] where name = 'FeaturedVideos' and NodeID = @Subject
			for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[GenericRDF.Plugin]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[GenericRDF.Plugin]
	@pluginName varchar(55) = null,
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
	declare @name varchar(55), @dataType varchar(4)
	select @name = Name, @dataType = dataType from [Profile.Module].[GenericRDF.Plugins] where _PropertyNode = @Predicate

	if @dataType = 0 -- String
	BEGIN
		select @json = (
			SELECT
				data from [Profile.Module].[GenericRDF.Data] where name = @name and NodeID = @Subject
				for json path, ROOT ('module_data'))
	END

	else if @dataType = 1 -- String
	BEGIN
		select @json = (
			SELECT
				JSON_QUERY(data, '$') as data from [Profile.Module].[GenericRDF.Data] where name = @name and NodeID = @Subject
				for json path, ROOT ('module_data'))
	END
	else 
	BEGIN
		select @json = (
			SELECT
				@subject Subject, @Predicate Predicate, @tagname tagname, @name name, @pluginName pluginName
				for json path, ROOT ('module_data'))
	END
END
GO
/****** Object:  StoredProcedure [Display.Module].[GenericRDF.Twitter]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[GenericRDF.Twitter]
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
	select @json = (
		SELECT
			data from [Profile.Module].[GenericRDF.Data] where name = 'Twitter' and NodeID = @Subject
			for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[Group.AboutUs]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Group.AboutUs]
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

	declare @ln bigint, @label nvarchar(max)
	select @ln = object from [RDF.].Triple where subject = @Subject and predicate = [RDF.].fnURI2NodeID('http://profiles.catalyst.harvard.edu/ontology/prns#aboutUs')
	select @label = value from [RDF.].Node where nodeID = @ln

	select @json = (select @label label for json path, WITHOUT_ARRAY_WRAPPER)
	select @json = (select JSON_QUERY(@json, '$') as module_data for json path, WITHOUT_ARRAY_WRAPPER)
END
GO
/****** Object:  StoredProcedure [Display.Module].[Group.AssociatedInformationResource]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Group.AssociatedInformationResource]
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

	declare @publications nvarchar(max), @timeline nvarchar(max), @fieldSummary nvarchar(max), @pubsCount int, @personID int
	select @pubsCount = count(*) from [Profile.Data].[Publication.Group.Include] where GroupID = @GroupID
	select @publications = [Display.Module].[FnCustomViewAssociatedInformationResource.GetList](@GroupID, null, 50, 'N')
	--select @timeline = [Display.Module].[FnNetworkAuthorshipTimeline.Person.GetData](@subject,0)
	--select @fieldSummary = [Display.Module].[FnCustomViewAuthorInAuthorship.GetJournalHeadings](@subject, @personID, null)

	--select @json = (select @publications Publications for json path, ROOT ('module_data'))
	select @json = (select @pubsCount as PublicationsCount, JSON_QUERY(@publications, '$.Publications')as Publications, JSON_QUERY(@timeline, '$.Timeline')as Timeline, JSON_QUERY(@fieldSummary, '$.FieldSummary')as FieldSummary for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[Group.AssociatedInformationResource.All]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Group.AssociatedInformationResource.All]
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

	declare @publications nvarchar(max), @timeline nvarchar(max), @fieldSummary nvarchar(max), @pubsCount int, @personID int
	select @pubsCount = count(*) from [Profile.Data].[Publication.Group.Include] where GroupID = @GroupID
	select @publications = [Display.Module].[FnCustomViewAssociatedInformationResource.GetList](@GroupID, null, 10000, 'N')

	select @json = (select JSON_QUERY(@publications, '$.Publications')as Publications for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[Group.AssociatedInformationResource.Cited]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Group.AssociatedInformationResource.Cited]
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

	declare @publications nvarchar(max), @timeline nvarchar(max), @fieldSummary nvarchar(max), @pubsCount int, @personID int
	select @pubsCount = count(*) from [Profile.Data].[Publication.Group.Include] where GroupID = @GroupID
	select @publications = [Display.Module].[FnCustomViewAssociatedInformationResource.GetList](@GroupID, null, 25, 'C')

	select @json = (select JSON_QUERY(@publications, '$.Publications')as Publications for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[Group.AssociatedInformationResource.Discussed]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Group.AssociatedInformationResource.Discussed]
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

	declare @publications nvarchar(max), @timeline nvarchar(max), @fieldSummary nvarchar(max), @pubsCount int, @personID int
	select @pubsCount = count(*) from [Profile.Data].[Publication.Group.Include] where GroupID = @GroupID
	select @publications = [Display.Module].[FnCustomViewAssociatedInformationResource.GetList](@GroupID, null, 25, 'A')

	select @json = (select JSON_QUERY(@publications, '$.Publications')as Publications for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[Group.AssociatedInformationResource.Oldest]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [Display.Module].[Group.AssociatedInformationResource.Oldest]
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

	declare @publications nvarchar(max), @timeline nvarchar(max), @fieldSummary nvarchar(max), @pubsCount int, @personID int
	select @pubsCount = count(*) from [Profile.Data].[Publication.Group.Include] where GroupID = @GroupID
	select @publications = [Display.Module].[FnCustomViewAssociatedInformationResource.GetList](@GroupID, null, 25, 'O')

	select @json = (select JSON_QUERY(@publications, '$.Publications')as Publications for json path, ROOT ('module_data'))

END
GO
/****** Object:  StoredProcedure [Display.Module].[Group.Cluster]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[Group.Cluster]
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
	select @json = [Display.Module].[FnNetworkRadial.GetData](null, @subject, null)
END
GO
/****** Object:  StoredProcedure [Display.Module].[Group.ContactInformation]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Group.ContactInformation]
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
	declare @ln bigint, @label nvarchar(max)
	select @ln = object from [RDF.].Triple where subject = @Subject and predicate = [RDF.].fnURI2NodeID('http://vivoweb.org/ontology/core#contactInformation')
	select @label = value from [RDF.].Node where nodeID = @ln

	select @json = (select @label label for json path, WITHOUT_ARRAY_WRAPPER)
	select @json = (select JSON_QUERY(@json, '$') as module_data for json path, WITHOUT_ARRAY_WRAPPER)
END
GO
/****** Object:  StoredProcedure [Display.Module].[Group.ContributingRole]    Script Date: 4/14/2025 3:18:55 PM ******/
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
/****** Object:  StoredProcedure [Display.Module].[Group.FeaturedPresentations]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[Group.FeaturedPresentations]
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

	DECLARE @SubjectValue nvarchar(max), @PredicateValue nvarchar(max), @ObjectValue nvarchar(max)
	select @SubjectValue = value from [RDF.].Node where NodeID = @Subject
	select @PredicateValue = value from [RDF.].Node where NodeID = @Predicate
	select @ObjectValue = value from [RDF.].Node where NodeID = @object

	select @json = (select @SubjectValue SubjectValue, @PredicateValue PredicateValue, @ObjectValue ObjectValue for json path, WITHOUT_ARRAY_WRAPPER)
	select @json = (select JSON_QUERY(@json, '$') as module_data for json path, WITHOUT_ARRAY_WRAPPER)
END
GO
/****** Object:  StoredProcedure [Display.Module].[Group.FeaturedVideos]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Group.FeaturedVideos]
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

	DECLARE @SubjectValue nvarchar(max), @PredicateValue nvarchar(max), @ObjectValue nvarchar(max)
	select @SubjectValue = value from [RDF.].Node where NodeID = @Subject
	select @PredicateValue = value from [RDF.].Node where NodeID = @Predicate
	select @ObjectValue = value from [RDF.].Node where NodeID = @object

	select @json = (select @SubjectValue SubjectValue, @PredicateValue PredicateValue, @ObjectValue ObjectValue for json path, WITHOUT_ARRAY_WRAPPER)
	select @json = (select JSON_QUERY(@json, '$') as module_data for json path, WITHOUT_ARRAY_WRAPPER)
END
GO
/****** Object:  StoredProcedure [Display.Module].[Group.Label]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Group.Label]
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
	declare @ln bigint, @label nvarchar(max)
	select @ln = object from [RDF.].Triple where subject = @Subject and predicate = [RDF.].fnURI2NodeID('http://www.w3.org/2000/01/rdf-schema#label')
	select @label = value from [RDF.].Node where nodeID = @ln
	
	declare @relativeBasePath varchar(55)
	select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'

	declare @url varchar(max)
	select @URL = @relativeBasePath + '/display/' + cast(@Subject as varchar(50))

	declare @GroupID int, @GroupSize int
	select @GroupID = cast(InternalID as int) from [RDF.Stage].InternalNodeMap where nodeID = @Subject and Class = 'http://xmlns.com/foaf/0.1/Group'
	select @GroupSize = count(*) from [Profile.Data].[Group.Member] a join [Profile.Cache].Person p
		on a.UserID = p.UserID and a.IsActive = 1 and p.IsActive = 1 and GroupID = @GroupID

	select @json = (select @label label, @url URL, @GroupSize groupSize for json path, WITHOUT_ARRAY_WRAPPER)
	select @json = (select JSON_QUERY(@json, '$') as module_data for json path, WITHOUT_ARRAY_WRAPPER)
END
GO
/****** Object:  StoredProcedure [Display.Module].[Group.MainImage]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Group.MainImage]
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

	declare @ln bigint, @label nvarchar(max)
	select @ln = object from [RDF.].Triple where subject = @Subject and predicate = [RDF.].fnURI2NodeID('http://profiles.catalyst.harvard.edu/ontology/prns#mainImage')
	select @label = value from [RDF.].Node where nodeID = @ln

	select @json = (select @label label for json path, WITHOUT_ARRAY_WRAPPER)
	select @json = (select JSON_QUERY(@json, '$') as module_data for json path, WITHOUT_ARRAY_WRAPPER)
END
GO
/****** Object:  StoredProcedure [Display.Module].[Group.MediaLinks]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[Group.MediaLinks]
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

	select @json = (select URL, WebPageTitle, PublicationDate, SortOrder from [Profile.Data].[Group.MediaLinks] where GroupID = @GroupID
			for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[Group.Overview]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Group.Overview]
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

	declare @ln bigint, @label nvarchar(max)
	select @ln = object from [RDF.].Triple where subject = @Subject and predicate = [RDF.].fnURI2NodeID('http://vivoweb.org/ontology/core#overview')
	select @label = value from [RDF.].Node where nodeID = @ln

	select @json = (select @label label for json path, WITHOUT_ARRAY_WRAPPER)
	select @json = (select JSON_QUERY(@json, '$') as module_data for json path, WITHOUT_ARRAY_WRAPPER)
END
GO
/****** Object:  StoredProcedure [Display.Module].[Group.Twitter]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Group.Twitter]
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

	DECLARE @SubjectValue nvarchar(max), @PredicateValue nvarchar(max), @ObjectValue nvarchar(max)
	select @SubjectValue = value from [RDF.].Node where NodeID = @Subject
	select @PredicateValue = value from [RDF.].Node where NodeID = @Predicate
	select @ObjectValue = value from [RDF.].Node where NodeID = @object

	select @json = (select @SubjectValue SubjectValue, @PredicateValue PredicateValue, @ObjectValue ObjectValue for json path, WITHOUT_ARRAY_WRAPPER)
	select @json = (select JSON_QUERY(@json, '$') as module_data for json path, WITHOUT_ARRAY_WRAPPER)
END
GO
/****** Object:  StoredProcedure [Display.Module].[Group.Webpage]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Group.Webpage]
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
	select @GroupID = cast(InternalID as int) from [RDF.Stage].InternalNodeMap where nodeID = 179407 and Class = 'http://xmlns.com/foaf/0.1/Group'

	select @json = (select URL, WebPageTitle, SortOrder from [Profile.Data].[Group.Websites] where GroupID = @GroupID
			for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[Group.Welcome]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Group.Welcome]
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

	declare @ln bigint, @label nvarchar(max)
	select @ln = object from [RDF.].Triple where subject = @Subject and predicate = [RDF.].fnURI2NodeID('http://profiles.catalyst.harvard.edu/ontology/prns#welcome')
	select @label = value from [RDF.].Node where nodeID = @ln

	select @json = (select @label label for json path, WITHOUT_ARRAY_WRAPPER)
	select @json = (select JSON_QUERY(@json, '$') as module_data for json path, WITHOUT_ARRAY_WRAPPER)
END
GO
/****** Object:  StoredProcedure [Display.Module].[Literal]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Literal]
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN
	select @json = (select t.sortOrder, n.value from [RDF.].Triple t
		join [RDF.].Node n 
		on Subject = @Subject and Predicate = @Predicate and Object = NodeID for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[NetworkList]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[NetworkList]
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN
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
	exec [Display.].[GetDataRDF] @subject=@subject,@predicate=@predicate,@SessionID=@SessionID,@Expand=0

	declare @connections nvarchar(max)
	select @connections = (select Value, SortOrder from #RDF where predicate = [RDF.].[fnURI2NodeID] ('http://profiles.catalyst.harvard.edu/ontology/prns#hasConnection') for json path, ROOT ('Connections'))
	declare @label nvarchar(max), @predicateLabel nvarchar(max), @predicateLabelNode bigint
	select @label = value from #rdf where predicate = [RDF.].[fnURI2NodeID] ('http://www.w3.org/2000/01/rdf-schema#label')
	select @predicateLabelNode = object from [RDF.].Triple where subject = @Predicate and predicate = [RDF.].fnURI2NodeID('http://www.w3.org/2000/01/rdf-schema#label') and ViewSecurityGroup = -1
	select @predicateLabel = value from [RDF.].Node where NodeID = @predicateLabelNode and ViewSecurityGroup = -1

	select @json = (
		select @label as label, @predicateLabel as predicate_label, JSON_QUERY(@connections, '$.Connections')as Connections
		for json path, ROOT ('module_data')
	)
END
GO
/****** Object:  StoredProcedure [Display.Module].[Person.AuthorInAuthorship]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Person.AuthorInAuthorship]
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
	declare @publications nvarchar(max), @timeline nvarchar(max), @fieldSummary nvarchar(max), @pubsCount int, @personID int
	select @personID = [RDF.].[fnNodeID2PersonID](@Subject)
	select @pubsCount = count(*) from [Profile.Data].[Publication.Entity.Authorship] where IsActive = 1 and personID = @personID
	select @publications = [Display.Module].[FnCustomViewAuthorInAuthorship.GetList](@personID, null, 25, 'N')
	select @timeline = [Display.Module].[FnNetworkAuthorshipTimeline.Person.GetData](@subject,0)
	select @fieldSummary = [Display.Module].[FnCustomViewAuthorInAuthorship.GetJournalHeadings](@subject, @personID, null)

	select @json = (select @pubsCount as PublicationsCount, JSON_QUERY(@publications, '$.Publications')as Publications, JSON_QUERY(@timeline, '$.Timeline')as Timeline, JSON_QUERY(@fieldSummary, '$.FieldSummary')as FieldSummary for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[Person.AuthorInAuthorship.All]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Person.AuthorInAuthorship.All]
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
	declare @publications nvarchar(max), @personID int
	select @personID = [RDF.].[fnNodeID2PersonID](@Subject)
	select @publications = [Display.Module].[FnCustomViewAuthorInAuthorship.GetList](@personID, null, 10000, 'N')
	select @json = (select JSON_QUERY(@publications, '$.Publications')as Publications for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[Person.AuthorInAuthorship.Cited]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[Person.AuthorInAuthorship.Cited]
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
	declare @publications nvarchar(max), @personID int
	select @personID = [RDF.].[fnNodeID2PersonID](@Subject)
	select @publications = [Display.Module].[FnCustomViewAuthorInAuthorship.GetList](@personID, null, 25, 'C')
	select @json = (select JSON_QUERY(@publications, '$.Publications')as Publications for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[Person.AuthorInAuthorship.Discussed]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[Person.AuthorInAuthorship.Discussed]
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
	declare @publications nvarchar(max), @personID int
	select @personID = [RDF.].[fnNodeID2PersonID](@Subject)
	select @publications = [Display.Module].[FnCustomViewAuthorInAuthorship.GetList](@personID, null, 25, 'A')
	select @json = (select JSON_QUERY(@publications, '$.Publications')as Publications for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[Person.AuthorInAuthorship.Oldest]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[Person.AuthorInAuthorship.Oldest]
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
	declare @publications nvarchar(max), @personID int
	select @personID = [RDF.].[fnNodeID2PersonID](@Subject)
	select @publications = [Display.Module].[FnCustomViewAuthorInAuthorship.GetList](@personID, null, 25, 'O')
	select @json = (select JSON_QUERY(@publications, '$.Publications')as Publications for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[Person.AwardOrHonor]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Person.AwardOrHonor]
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
	select @json = (
		select n1.Value as StartYear, n2.value as EndYear, n3.value as Name, n4.value as Institution, t0.SortOrder From [RDF.].Triple t0
			join [RDF.].Node n on t0.Object = n.NodeID
			and t0.subject=@Subject and t0.Predicate = @Predicate
			left join [RDF.].Triple t1 on t0.Object = t1.Subject and t1.Predicate = [RDF.].fnURI2NodeID('http://profiles.catalyst.harvard.edu/ontology/prns#startDate')
			left join [RDF.].Node n1 on t1.Object = n1.NodeID
			left join [RDF.].Triple t2 on t0.Object = t2.Subject and t2.Predicate = [RDF.].fnURI2NodeID('http://profiles.catalyst.harvard.edu/ontology/prns#endDate')
			left join [RDF.].Node n2 on t2.Object = n2.NodeID
			left join [RDF.].Triple t3 on t0.Object = t3.Subject and t3.Predicate = [RDF.].fnURI2NodeID('http://www.w3.org/2000/01/rdf-schema#label')
			left join [RDF.].Node n3 on t3.Object = n3.NodeID
			left join [RDF.].Triple t4 on t0.Object = t4.Subject and t4.Predicate = [RDF.].fnURI2NodeID('http://profiles.catalyst.harvard.edu/ontology/prns#awardConferredBy')
			left join [RDF.].Node n4 on t4.Object = n4.NodeID
			for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[Person.ClinicalTrialRole]    Script Date: 4/14/2025 3:18:55 PM ******/
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
/****** Object:  StoredProcedure [Display.Module].[Person.Coauthor.Top5]    Script Date: 4/14/2025 3:18:55 PM ******/
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
/****** Object:  StoredProcedure [Display.Module].[Person.Concept.Top5]    Script Date: 4/14/2025 3:18:55 PM ******/
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
/****** Object:  StoredProcedure [Display.Module].[Person.EducationAndTraining]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Person.EducationAndTraining]
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
	select @json = (
		select n1.Value as Institution, n2.value as Location, n3.value as Degree, n4.value as CompletionDate, n5.value as Field, t0.SortOrder From [RDF.].Triple t0
			join [RDF.].Node n on t0.Object = n.NodeID
			and t0.subject=@Subject and t0.Predicate = @Predicate
			left join [RDF.].Triple t1 on t0.Object = t1.Subject and t1.Predicate = [RDF.].fnURI2NodeID('http://profiles.catalyst.harvard.edu/ontology/prns#trainingAtOrganization')
			left join [RDF.].Node n1 on t1.Object = n1.NodeID
			left join [RDF.].Triple t2 on t0.Object = t2.Subject and t2.Predicate = [RDF.].fnURI2NodeID('http://profiles.catalyst.harvard.edu/ontology/prns#trainingLocation')
			left join [RDF.].Node n2 on t2.Object = n2.NodeID
			left join [RDF.].Triple t3 on t0.Object = t3.Subject and t3.Predicate = [RDF.].fnURI2NodeID('http://vivoweb.org/ontology/core#degreeEarned')
			left join [RDF.].Node n3 on t3.Object = n3.NodeID
			left join [RDF.].Triple t4 on t0.Object = t4.Subject and t4.Predicate = [RDF.].fnURI2NodeID('http://profiles.catalyst.harvard.edu/ontology/prns#endDate')
			left join [RDF.].Node n4 on t4.Object = n4.NodeID
			left join [RDF.].Triple t5 on t0.Object = t5.Subject and t5.Predicate = [RDF.].fnURI2NodeID('http://vivoweb.org/ontology/core#majorField')
			left join [RDF.].Node n5 on t5.Object = n5.NodeID
			for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[Person.FreetextKeyword]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Person.FreetextKeyword]
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
	select @json = (select SortOrder, Value from [RDF.].Triple t
	join [RDF.].Node n on t.Object = n.NodeID and t.Predicate = @Predicate and subject = @Subject
	for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[Person.GeneralInfo]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Person.GeneralInfo]
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN
	DECLARE @SecurityGroupID BIGINT, @HasSpecialViewAccess BIT, @HasSecurityGroupNodes BIT
	EXEC [RDF.Security].GetSessionSecurityGroup @SessionID, @SecurityGroupID OUTPUT, @HasSpecialViewAccess OUTPUT
	CREATE TABLE #SecurityGroupNodes (SecurityGroupNode BIGINT PRIMARY KEY)
	INSERT INTO #SecurityGroupNodes (SecurityGroupNode) select * from [RDF.Security].fnGetSessionSecurityGroupNodes(@SessionID, @Subject)

	DECLARE @PhotoPredicateID BIGINT
	SELECT @PhotoPredicateID = _PropertyNode FROM [Ontology.].ClassProperty WHERE Property = 'http://profiles.catalyst.harvard.edu/ontology/prns#mainImage'
	DECLARE @PhotoViewSecurityGroup BIGINT, @PhotoNodeID BIGINT
	SELECT @PhotoViewSecurityGroup = isnull(ViewSecurityGroup, -100), @PhotoNodeID = Object from [RDF.].Triple where Subject = @Subject AND Predicate = @PhotoPredicateID
	declare @PhotoURL varchar(max)
	set @PhotoURL = null
	IF (@PhotoViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (@PhotoViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (@PhotoViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes))
	BEGIN
		select @PhotoURL = Value from [RDF.].Node where NodeID = @PhotoNodeID
	END


	DECLARE @EmailEncryptedPredicateID BIGINT
	SELECT @EmailEncryptedPredicateID = _PropertyNode FROM [Ontology.].ClassProperty WHERE Property = 'http://profiles.catalyst.harvard.edu/ontology/prns#emailEncrypted'
	DECLARE @EmailEncryptedSecurityGroup BIGINT, @EmailEncryptedNodeID BIGINT
	SELECT @EmailEncryptedSecurityGroup = isnull(ViewSecurityGroup, -100), @EmailEncryptedNodeID = Object from [RDF.].Triple where Subject = @Subject AND Predicate = @EmailEncryptedPredicateID
	declare @EmailEncrypted nvarchar(max)
	set @EmailEncrypted = null
	IF (@EmailEncryptedSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (@EmailEncryptedSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (@EmailEncryptedSecurityGroup IN (SELECT * FROM #SecurityGroupNodes))
	BEGIN
		select @EmailEncrypted = Value from [RDF.].Node where NodeID = @EmailEncryptedNodeID
	END

	DECLARE @EmailPredicateID BIGINT
	SELECT @EmailPredicateID = _PropertyNode FROM [Ontology.].ClassProperty WHERE Property = 'http://vivoweb.org/ontology/core#Email'
	DECLARE @EmailSecurityGroup BIGINT, @EmailNodeID BIGINT
	SELECT @EmailSecurityGroup = isnull(ViewSecurityGroup, -100), @EmailNodeID = Object from [RDF.].Triple where Subject = @Subject AND Predicate = @EmailPredicateID
	declare @Email varchar(max)
	set @Email = null
	IF (@EmailSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (@EmailSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (@EmailSecurityGroup IN (SELECT * FROM #SecurityGroupNodes))
	BEGIN
		select @Email = Value from [RDF.].Node where NodeID = @EmailNodeID
	END

	DECLARE @ORCIDPredicateID BIGINT
	SELECT @ORCIDPredicateID = _PropertyNode FROM [Ontology.].ClassProperty WHERE Property = 'http://vivoweb.org/ontology/core#orcidId'
	DECLARE @ORCIDSecurityGroup BIGINT, @ORCIDNodeID BIGINT
	SELECT @ORCIDSecurityGroup = isnull(ViewSecurityGroup, -100), @ORCIDNodeID = Object from [RDF.].Triple where Subject = @Subject AND Predicate = @ORCIDPredicateID
	declare @ORCID varchar(max)
	set @ORCID = null
	IF (@ORCIDSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (@ORCIDSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (@ORCIDSecurityGroup IN (SELECT * FROM #SecurityGroupNodes))
	BEGIN
		select @ORCID = Value from [RDF.].Node where NodeID = @ORCIDNodeID
	END

	declare @supportHTML nvarchar(max)
	select @supportHTML = HTML 
			from [Profile.Cache].Person a 
		join [Profile.Module].[Support.Map] b 
			on nodeID = @subject 
			and a.InstitutionName = b.Institution
			and (b.department is null or b.department = '' or a.DepartmentName = b.Department)
		join [Profile.Module].[Support.HTML] c
			on b.SupportID = c.SupportID 

	-- This is only needed to handle odd data at Harvard
	set @supportHTML = replace(@supportHTML, '<script>document.write(''@'');</script>', '@')

	declare @personID int
	select @personID = personID from [Profile.Cache].Person where NodeID =@Subject
	declare @a nvarchar(max)
	select @a = (Select SortOrder, Title, InstititutionName as InstitutionName, DepartmentName, DivisionName, FacultyRank from [Profile.Cache].[Person.Affiliation] where personID = @PersonID for JSON path, Root ('Affiliation'))
	select @json = (Select FirstName, LastName, DisplayName, AddressLine1, AddressLine2, AddressLine3, AddressLine4, Phone, Fax, @EmailEncrypted EmailEncrypted, @Email Email, @ORCID ORCID, @PhotoURL as ImageURL, JSON_QUERY(@a, '$.Affiliation')as Affiliation, @supportHTML SupportHTML
		from [Profile.Cache].Person
		where NodeID = @subject
		for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[Person.HasCoAuthor.Why]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [Display.Module].[Person.HasCoAuthor.Why]
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
						@relativeBasePath + isnull(@PersonDefaultApplication, '') + @PersonPreferredPath + '/Network/CoAuthors/Details' as BackToURL, 
						@Name2 Name2, @displayName2 DisplayName2, @relativeBasePath + isnull(@PersonDefaultApplication2, '') + @PersonPreferredPath2 as PersonURL2, Round(@weight, 3) Weight,
							 (select a.PMID, b.PMCID, b.DOI, c.AuthorsString, b.Reference, Round(a.w, 2) as Weight from #pmids a
									join [Profile.Data].[Publication.Entity.InformationResource] b on a.pmid = b.pmid
									join [Profile.Data].[Publication.Entity.Authorship] c on b.EntityID = c.InformationResourceID and c.PersonID = @PersonID
									for json path) Publications
							for json path, WITHOUT_ARRAY_WRAPPER)
	select @json = (select JSON_QUERY(@json, '$') as module_data for json path, WITHOUT_ARRAY_WRAPPER)
END
GO
/****** Object:  StoredProcedure [Display.Module].[Person.HasMemberRole]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [Display.Module].[Person.HasMemberRole]
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN
	declare @SessionUserID int
	select @sessionUserID = UserID from [User.Session].Session where LogoutDate is null and sessionID=@sessionID and CreateDate > dateAdd(day, -1, getdate())

	declare @groups table (GroupID int, GroupName varchar(400), NodeID bigint, URL varchar(400))
	insert into @groups (GroupID, GroupName)
	select c.GroupID, c.GroupName from [Profile.Cache].Person a
		join [Profile.Data].[Group.Member] b
			on a.NodeID = @Subject
			and a.UserID = b.UserID
		join [Profile.Data].[Group.General] c
			on b.GroupID = c.GroupID
			and b.IsActive = 1
			and b.IsVisible = 1
			and c.EndDate > GETDATE()
		left join [Profile.Data].[Group.Manager] d
			on c.GroupID = d.GroupID and d.UserID = @SessionUserID
		where c.ViewSecurityGroup = -1 or d.UserID is not null or exists (select 1 from [Profile.Data].[Group.Admin] where UserId = @SessionUserID)

	update a set a.NodeID = b.NodeID from @groups a join [RDF.Stage].InternalNodeMap b on Class = 'http://xmlns.com/foaf/0.1/Group' and b.InternalID = cast(a.groupID as varchar(50))
	declare @relativeBasePath varchar(55)
	select @relativeBasePath = value from [Framework.].Parameter where ParameterID = 'relativeBasePath'

	update @groups set URL = @relativeBasePath + '/display/' + cast (nodeID as varchar(50))

	select @json = (
		select GroupName as Name, URL from @groups
		for json path, root('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[Person.HasResearchArea]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[Person.HasResearchArea]
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN
		declare @relativeBasePath varchar(55), @PersonID int, @PersonPerferredPath varchar(max)
		select @PersonID = personID, @PersonPerferredPath = isnull(DefaultApplication, '') + PreferredPath from [Profile.Cache].Person where NodeID = @subject
		select @relativeBasePath = value from [Framework.].Parameter where ParameterID = 'relativeBasePath'

		select @json = (
			select MeshHeader as Name, NumPubsThis, NumPubsAll, [Weight], NTILE(5) OVER (ORDER BY p.weight) CloudSize, LastPublicationYear LastPubYear, (select top 1 SemanticGroupName from [Profile.Data].[Concept.Mesh.SemanticGroup] g where u.DescriptorUI = g.[DescriptorUI]) SemanticGroupName, (select SemanticGroupName from [Profile.Data].[Concept.Mesh.SemanticGroup] g where u.DescriptorUI = g.[DescriptorUI] for json path) SemanticGroups, @relativeBasePath + isnull(DefaultApplication, '') + URL URL, @relativeBasePath + @PersonPerferredPath + '/Network/ResearchAreas' + URL WhyURL from [Profile.Cache].[Concept.Mesh.Person] p  join [Profile.Cache].[Concept.Mesh.URL] u on p.MeshHeader = u.DescriptorName
			where personID = @PersonID
		 for json path, root('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[Person.HasResearchArea.Timeline]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[Person.HasResearchArea.Timeline]
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
	select @personID = [RDF.].[fnNodeID2PersonID](@Subject)

 
	declare @relativeBasePath varchar(max)
	select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'


	create table #a (i int primary key not null, [MeshHeader] nvarchar(255), FirstPublicationYear int, LastPublicationYear int, NumPubsThis int, Weight float, URL varchar(533), DefaultApplication varchar(55), MinX float, MaxX float, AvgX float, AvgYear int, AvgMonth int)
	insert into #a (i, MeshHeader, FirstPublicationYear, LastPublicationYear, NumPubsThis, Weight, URL, DefaultApplication)  select top 20 ROW_NUMBER() over (order  by weight desc), MeshHeader, cast(FirstPublicationYear as int) FirstPublicationYear, cast(LastPublicationYear as int) LastPublicationYear, NumPubsThis, Weight, URL, DefaultApplication from [Profile.Cache].[Concept.Mesh.Person] z join [Profile.Cache].[Concept.Mesh.URL] y on z.MeshHeader = y.DescriptorName where personID = @PersonID order by Weight desc

	declare @a int, @b int, @f int, @g int
	select @a = min(FirstPublicationYear)-1, 
			@b = max(LastPublicationYear)+1,
			@f = cast(cast('1/1/'+cast(min(FirstPublicationYear)-1 as varchar(10)) as datetime) as float),
			@g = cast(cast('1/1/'+cast(max(LastPublicationYear)+1 as varchar(10)) as datetime) as float)
			from #a

	create table #d (i int not null, x float)
	insert into #d(i, x) select a.i, (cast(pubdate as float)-@f)/(@g-@f) from [Profile.Cache].[Concept.Mesh.PersonPublication] x join #a a on x.MeshHeader = a.MeshHeader where personID = @PersonID

	; with e as  (
			select i, min(x) MinX, max(x) MaxX, avg(x) AvgX
			from #d
			group by i)
	update a set a.MinX = e.MinX, a.MaxX = e.MaxX, a.AvgX = e.AvgX, a.AvgMonth = cast(((@b - @a) * e.AvgX - cast((@b - @a) * e.AvgX  as int)) * 12 + 1 as int), a.AvgYear = cast(@a + (@b - @a) * e.AvgX  as int)  from #a a join e e  on a.i = e.i

	select @json = (select @a MinDisplayYear, @b MaxDisplayYear
			, (select a.MeshHeader, a.FirstPublicationYear, a.LastPublicationYear, a.NumPubsThis NumPubs, @relativeBasePath + isnull(defaultApplication, '') + URL as URL, Weight, MinX, MaxX, AvgX, AvgYear, AvgMonth
					, (select x from #d d where d.i = a.i for json path) xvals from #a a for json path) Concepts 
					for json path, WITHOUT_ARRAY_WRAPPER) 
	select @json = (select JSON_QUERY(@json, '$') as module_data for json path, WITHOUT_ARRAY_WRAPPER)
END
GO
/****** Object:  StoredProcedure [Display.Module].[Person.HasResearchArea.Timeline.backup]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[Person.HasResearchArea.Timeline.backup]
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
	select @personID = [RDF.].[fnNodeID2PersonID](@Subject)

 
declare @relativeBasePath varchar(max)
select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'

;with a as (
		select top 20 MeshHeader, cast(FirstPublicationYear as int) FirstPublicationYear, cast(LastPublicationYear as int) LastPublicationYear, NumPubsThis, Weight, URL, DefaultApplication from [Profile.Cache].[Concept.Mesh.Person] z join [Profile.Cache].[Concept.Mesh.URL] y on z.MeshHeader = y.DescriptorName where personID = @PersonID order by Weight desc
	), b as (
		select min(FirstPublicationYear)-1 a, max(LastPublicationYear)+1 b,
			cast(cast('1/1/'+cast(min(FirstPublicationYear)-1 as varchar(10)) as datetime) as float) f,
			cast(cast('1/1/'+cast(max(LastPublicationYear)+1 as varchar(10)) as datetime) as float) g
		from a
	), c as (
		select  a.MeshHeader, PubDate from [Profile.Cache].[Concept.Mesh.PersonPublication] x join a a on x.MeshHeader = a.MeshHeader where personID = @PersonID
	), d as (
		select c.MeshHeader, (cast(pubdate as float)-f)/(g-f) x
		from c, b
	), e as  (
		select MeshHEader, min(x) MinX, max(x) MaxX, avg(x) AvgX
		from d
		group by MeshHEader
	), f as (
		select *, cast(a + (b - a) * AvgX  as int) AvgYear, cast(((b - a) * AvgX - cast((b - a) * AvgX  as int)) * 12 + 1 as int) as AvgMonth  from e, b
	)
	--select * from e
	select @json = (select a MinDisplayYear, b MaxDisplayYear
			, (select a.MeshHeader, a.FirstPublicationYear, a.LastPublicationYear, a.NumPubsThis NumPubs, @relativeBasePath + isnull(defaultApplication, '') + URL as URL, Weight, MinX, MaxX, AvgX, AvgYear, AvgMonth
					, (select x from d d where d.MeshHeader = a.MeshHeader for json path) xvals from a a join f f  on a.MeshHeader = f.MeshHeader for json path) Concepts 
					from b for json path, WITHOUT_ARRAY_WRAPPER) 
	select @json = (select JSON_QUERY(@json, '$') as module_data for json path, WITHOUT_ARRAY_WRAPPER)
END
GO
/****** Object:  StoredProcedure [Display.Module].[Person.HasResearchArea.Timeline.Test]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[Person.HasResearchArea.Timeline.Test]
	@Subject bigint
AS
BEGIN
declare @sTime datetime 
select @sTime = GETDATE()

	declare @personID int, @json nvarchar(max)
	select @personID = [RDF.].[fnNodeID2PersonID](@Subject)

 
declare @relativeBasePath varchar(max)
select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'
select DATEDIFF(ms, GETDATE(), @sTime)


create table #a (i int primary key not null, [MeshHeader] nvarchar(255), FirstPublicationYear int, LastPublicationYear int, NumPubsThis int, Weight float, URL varchar(533), DefaultApplication varchar(55), MinX float, MaxX float, AvgX float, AvgYear int, AvgMonth int)
insert into #a (i, MeshHeader, FirstPublicationYear, LastPublicationYear, NumPubsThis, Weight, URL, DefaultApplication)  select top 20 ROW_NUMBER() over (order  by weight desc), MeshHeader, cast(FirstPublicationYear as int) FirstPublicationYear, cast(LastPublicationYear as int) LastPublicationYear, NumPubsThis, Weight, URL, DefaultApplication from [Profile.Cache].[Concept.Mesh.Person] z join [Profile.Cache].[Concept.Mesh.URL] y on z.MeshHeader = y.DescriptorName where personID = @PersonID order by Weight desc

declare @a int, @b int, @f int, @g int
select @a = min(FirstPublicationYear)-1, 
		@b = max(LastPublicationYear)+1,
		@f = cast(cast('1/1/'+cast(min(FirstPublicationYear)-1 as varchar(10)) as datetime) as float),
		@g = cast(cast('1/1/'+cast(max(LastPublicationYear)+1 as varchar(10)) as datetime) as float)
		from #a

create table #d (i int not null, x float)
insert into #d(i, x) select a.i, (cast(pubdate as float)-@f)/(@g-@f) from [Profile.Cache].[Concept.Mesh.PersonPublication] x join #a a on x.MeshHeader = a.MeshHeader where personID = @PersonID

; with e as  (
		select i, min(x) MinX, max(x) MaxX, avg(x) AvgX
		from #d
		group by i)
update a set a.MinX = e.MinX, a.MaxX = e.MaxX, a.AvgX = e.AvgX, a.AvgMonth = cast(((@b - @a) * e.AvgX - cast((@b - @a) * e.AvgX  as int)) * 12 + 1 as int), a.AvgYear = cast(@a + (@b - @a) * e.AvgX  as int)  from #a a join e e  on a.i = e.i

	select @json = (select @a MinDisplayYear, @b MaxDisplayYear
			, (select a.MeshHeader, a.FirstPublicationYear, a.LastPublicationYear, a.NumPubsThis NumPubs, @relativeBasePath + isnull(defaultApplication, '') + URL as URL, Weight, MinX, MaxX, AvgX, AvgYear, AvgMonth
					, (select x from #d d where d.i = a.i for json path) xvals from #a a for json path) Concepts 
					for json path, WITHOUT_ARRAY_WRAPPER) 
	select DATEDIFF(ms, GETDATE(), @sTime)
	select @json = (select JSON_QUERY(@json, '$') as module_data for json path, WITHOUT_ARRAY_WRAPPER)
		select DATEDIFF(ms, GETDATE(), @sTime)
select @json
END
GO
/****** Object:  StoredProcedure [Display.Module].[Person.HasResearchArea.Why]    Script Date: 4/14/2025 3:18:55 PM ******/
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
/****** Object:  StoredProcedure [Display.Module].[Person.Label]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Person.Label]
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN
	declare @SubjectPath varchar(max), @relativeBasePath varchar(100)
	select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'

	select @json = (Select FirstName, LastName, DisplayName, @relativeBasePath + isnull(DefaultApplication, '') + PreferredPath as PreferredPath, PersonID, NodeID from [Profile.Cache].Person where NodeID = @subject for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[Person.MediaLinks]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [Display.Module].[Person.MediaLinks]
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

	select @json = (select URL, WebPageTitle, PublicationDate, SortOrder from [Profile.Data].[Person.MediaLinks] where PersonID = @PersonID
	for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[Person.PhysicalNeighbour.Top5]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Person.PhysicalNeighbour.Top5]
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
/*	select top 5 MyNeighbors as Label, @relativeBasePath + isnull(DefaultApplication, '') + PreferredPath URL, ROW_NUMBER() OVER (ORDER BY Distance) Sort  from [Profile.Cache].[Person.PhysicalNeighbor] a 
		join [Profile.Cache].Person b
		on a.NeighborID = b.PersonID
		and a.PersonID = @personID
*/
	if not exists (select  1 from [Profile.Cache].[Person.PhysicalNeighbor] where PersonID = @personID)
	BEGIN
		select @json = null
		return
	END


	select @json = (select top 5 MyNeighbors as Label, @relativeBasePath + isnull(DefaultApplication, '') + PreferredPath URL, ROW_NUMBER() OVER (ORDER BY Distance) Sort  from [Profile.Cache].[Person.PhysicalNeighbor] a 
		join [Profile.Cache].Person b
		on a.NeighborID = b.PersonID
		and a.PersonID = @personID
			ORDER by Distance for json path, ROOT ('Connections'))
	select @json = (Select 'Physical Neighbors' Title, JSON_QUERY(@json, '$.Connections')as Connections  for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[Person.ResearcherRole]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[Person.ResearcherRole]
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
		SELECT
			AgreementLabel,
			EndDate,
			FundingID,
			GrantAwardedBy,
			PrincipalInvestigatorName,
			RoleDescription,
			RoleLabel,
			StartDate,
			ROW_NUMBER() over (order by StartDate desc, EndDate desc, FundingID) Sort
		FROM [Profile.Data].[Funding.Role] r 
			INNER JOIN [Profile.Data].[Funding.Agreement] a
				ON r.FundingAgreementID = a.FundingAgreementID
					AND r.PersonID = @PersonID
		for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[Person.SameDepartment.Top5]    Script Date: 4/14/2025 3:18:55 PM ******/
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
/****** Object:  StoredProcedure [Display.Module].[Person.Similar.Top5]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[Person.Similar.Top5]
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
	select @personID = personID, @ExploreLink = @relativeBasePath + isnull(DefaultApplication, '') + PreferredPath + '/Network/SimilarTo' from [Profile.Cache].Person where NodeID =@Subject

	declare @count int
	select @count = count (*) from [Profile.Cache].[Person.SimilarPerson] where personID = @personID

	if @count = 0
	BEGIN
		select @json = null
		return
	END


	select @json = (select top 5 isnull(LastName, '') + isnull(', ' + firstname, '') Label, @relativeBasePath + isnull(DefaultApplication, '') + PreferredPath URL, ROW_NUMBER() OVER (ORDER BY Weight desc) Sort 
		from [Profile.Cache].[Person.SimilarPerson] a join [Profile.Cache].Person b on a.SimilarPersonID = b.PersonID and a.PersonID = @PersonID order by Weight desc for json path, ROOT ('Connections'))
	select @json = (Select 'Similar People' Title, @ExploreLink ExploreLink, @Count [Count], JSON_QUERY(@json, '$.Connections')as Connections  for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[Person.Similar.Why]    Script Date: 4/14/2025 3:18:55 PM ******/
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
/****** Object:  StoredProcedure [Display.Module].[Person.Websites]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Person.Websites]
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

	select @json = (select URL, WebPageTitle, SortOrder from [Profile.Data].[Person.Websites] where PersonID = @PersonID
	for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[Publication.Authors]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[Publication.Authors]
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN
	declare @EntityID int, @PMID int, @MPID nvarchar(50), @relativeBasePath varchar(55)
	select @EntityID = cast(InternalID as int) from [RDF.Stage].InternalNodeMap where class = 'http://vivoweb.org/ontology/core#InformationResource' and internalType = 'InformationResource' and NodeId = @Subject
	select @PMID = PMID from [Profile.Data].[Publication.Entity.InformationResource] where EntityID = @EntityID

	select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'

	select @json = (select DisplayName, @relativeBasePath + isnull(b.DefaultApplication, '') + PreferredPath URL
		  FROM [Profile.Data].[Publication.Person.Include] a
			join [Profile.Cache].Person b on a.PersonID = b.PersonID and isnull(a.pmid, 0) = isnull(@PMID, 0) and isnull(a.mpid, '') = isnull(@MPID, '') for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[Publication.Concepts]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[Publication.Concepts]
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN
	declare @EntityID int, @PMID int, @relativeBasePath varchar(55)
	select @EntityID = cast(InternalID as int) from [RDF.Stage].InternalNodeMap where class = 'http://vivoweb.org/ontology/core#InformationResource' and internalType = 'InformationResource' and NodeId = @Subject
	select @PMID = PMID from [Profile.Data].[Publication.Entity.InformationResource] where EntityID = @EntityID
	
	select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'

	select @json = (select a.DescriptorName, @relativeBasePath + isnull(b.DefaultApplication, '') + URL URL
		  FROM [Profile.Data].[Publication.PubMed.Mesh] a
		  join [Profile.Cache].[Concept.Mesh.URL] b on a.DescriptorName = b.DescriptorName and PMID = @PMID for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[Publication.GeneralInfo]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[Publication.GeneralInfo]
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN
	declare @EntityID int
	select @EntityID = cast(InternalID as int) from [RDF.Stage].InternalNodeMap where class = 'http://vivoweb.org/ontology/core#InformationResource' and internalType = 'InformationResource' and NodeId = @Subject


	select @json = (select PMID, MPID, PMCID, doi as DOI, EntityName as Title, EntityDate as PublicationDate, Reference as Citation, URL, Authors
					from [Profile.Data].[Publication.Entity.InformationResource] where IsActive = 1 and EntityID = @EntityID for json path, WITHOUT_ARRAY_WRAPPER) 
	select @json = (select JSON_QUERY(@json, '$') as module_data for json path, WITHOUT_ARRAY_WRAPPER)
END
GO
/****** Object:  StoredProcedure [Display.Module].[SimilarPeople.Connection]    Script Date: 4/14/2025 3:18:55 PM ******/
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
/****** Object:  StoredProcedure [Display.Module].[UnmatchedType]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[UnmatchedType]
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN

	declare @rdf table (
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
			SortOrder int,
			URL nvarchar(max),
			PropertyGroupLabel varchar(max),
			PropertyGroupSort int,
			PropertyGroupInnerSort int
		)

		insert into @rdf(uri, subject, predicate, object, showSummary, property, tagName, propertyLabel, Language, DataType, Value,	ObjectType, SortOrder)
		exec [Display.].[GetDataRDF] @subject=@Subject,@predicate=@Predicate,@object=@object,@SessionID=null,@Expand=0,@limit=1

		delete from @rdf where predicate = [RDF.].fnURI2NodeID('http://www.w3.org/1999/02/22-rdf-syntax-ns#type')

		update r set r.URL = r.Value, r.value = n.Value from @rdf r join 
			[RDF.].Triple t on r.object = t.Subject and r.ObjectType = 0
			join [RDF.].Node n on t.predicate = [RDF.].fnURI2NodeID('http://www.w3.org/2000/01/rdf-schema#label') and t.Object = n.NodeID

		update r set r.PropertyGroupLabel = pg._PropertyGroupLabel, r.PropertyGroupSort = pg.SortOrder, r.PropertyGroupInnerSort = isnull(pgp.sortOrder, 1000) from @rdf r left join 
			[Ontology.].PropertyGroupProperty pgp on r.predicate = pgp._PropertyNode
			join [Ontology.].PropertyGroup pg on isnull(pgp._PropertyGroupNode, [RDF.].fnURI2NodeID('http://profiles.catalyst.harvard.edu/ontology/prns#PropertyGroupOverview')) = pg._PropertyGroupNode

		select PropertyLabel, Value, URL, PropertyGroupSort, PropertyGroupLabel, PropertyGroupInnerSort From @rdf

	select @json = (select PropertyLabel, Value, URL, PropertyGroupSort, PropertyGroupLabel, PropertyGroupInnerSort From @rdf as module_data for json path)
END
GO
/****** Object:  StoredProcedure [Profile.Cache].[Concept.UpdatePreferredPath]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [Profile.Cache].[Concept.UpdatePreferredPath]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	CREATE TABLE #tmpURL(
		[DescriptorName] [varchar](255) NOT NULL Primary key,
		[NodeID] [bigint] NULL,
		[DescriptorUI] [varchar](10) NOT NULL,
		[URL] [varchar](553) NULL,
		[DefaultApplication] [varchar](50) NULL,
	)

	insert into #tmpURL([DescriptorName], [DescriptorUI]) select [DescriptorName], [DescriptorUI] from [Profile.Data].[Concept.Mesh.Descriptor]

	update a set a.NodeID = m.NodeID from #tmpURL a join [RDF.Stage].[InternalNodeMap] m on a.DescriptorUI = m.InternalID and m.Status = 3

	update a set a.DefaultApplication = '/' + b.DefaultApplication, a.URL = '/' + AliasType + '/' + AliasID  from #tmpURL a join [RDF.].Alias b on a.NodeID = b.NodeID and b.Preferred = 1

	update #tmpURL set DefaultApplication = '/display', URL = '/' + cast(NodeID as varchar(50))

	truncate table [Profile.Cache].[Concept.Mesh.URL]

	insert into [Profile.Cache].[Concept.Mesh.URL] select * from #tmpURL
END
GO
/****** Object:  StoredProcedure [Profile.Cache].[Person.UpdatePreferredPath]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [Profile.Cache].[Person.UpdatePreferredPath]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
 
	Update p set p.NodeID = i.NodeID from [Profile.Cache].[Person] p
		join [RDF.Stage].InternalNodeMap i
		on HASHBYTES('sha1',N'"'+CAST(N'http://xmlns.com/foaf/0.1/Person^^Person'+N'^^'+cast(p.PersonID as varchar(50)) AS NVARCHAR(4000))+N'"') = InternalHash and p.NodeID is null

	update p set p.PreferredPath = case when AliasType is null then '/' + cast(p.NodeID as varchar(50)) when AliasType = '' then '/' + AliasID else '/' + AliasType + '/' + AliasID end ,
		p.DefaultApplication = isnull(case when a.DefaultApplication = '' then '' else '/' + a.DefaultApplication end, '/display')
		from [Profile.Cache].[Person] p 
			left join [RDF.].Alias a
			on p.NodeID = a.NodeID and a.Preferred = 1
END
GO
/****** Object:  StoredProcedure [Profile.Data].[Group.GetPhotos]    Script Date: 4/14/2025 3:18:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [Profile.Data].[Group.GetPhotos](@NodeID bigINT)
AS
BEGIN

DECLARE @GroupID INT 

    SELECT @GroupID = CAST(m.InternalID AS INT)
		FROM [RDF.Stage].[InternalNodeMap] m, [RDF.].Node n
		WHERE m.Status = 3 AND m.ValueHash = n.ValueHash AND n.NodeID = @NodeID
		
	SELECT  photo,
			p.PhotoID		
		FROM [Profile.Data].[Group.Photo] p WITH(NOLOCK)
	 WHERE GroupID=@GroupID  
END
GO







GO
PRINT N'Update complete.';


GO

