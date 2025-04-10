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
