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
CREATE Function [Display.].[FnConvertSearchJSON2XML]
	(@JSON varchar(max),
	@EverythingSearch bit = 0)
	returns varchar(max)
AS
BEGIN

	/*
	select  [Display.].[FnConvertSearchJSON2XML](
	'{
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
	}')
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


	return @SearchOpts
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Function [Display.Module].[FnCustomViewAssociatedInformationResource.GetList]
	(@GroupID int = NULL,
	@SessionID uniqueidentifier = NULL,
	@count int = 50,
	@sort char)
	returns varchar(max)
AS
BEGIN
	if @count=-1 set @count=10000


	declare @result varchar(max)
	if @sort = 'A'
	BEGIN
		select @result =(
			select 
				EntityID, rdfs_label, prns_informationResourceReference, prns_publicationDate, prns_year, bibo_pmid, vivo_pmcid, 
				bibo_doi, prns_mpid, vivo_webpage, PMCCitations, RelativeCitationRatio, JSON_QUERY(isnull(Fields, '{"Fields":[]}'), '$.Fields') as Fields, TranslationHumans, 
				TranslationAnimals, TranslationCells, TranslationPublicHealth, TranslationClinicalTrial	
			 from (
				select top 100 p.EntityID, p.EntityName rdfs_label, 
					p.Authors + p.Reference prns_informationResourceReference, p.EntityDate prns_publicationDate,
					year(p.EntityDate) prns_year, p.pmid bibo_pmid, p.pmcid vivo_pmcid, p.doi bibo_doi, p.mpid prns_mpid, p.URL vivo_webpage, 
					isnull(b.PMCCitations, -1) as PMCCitations, isnull(b.RelativeCitationRatio, -1) as RelativeCitationRatio, isnull(Fields, '{"Fields":[]}') as Fields, isnull(TranslationHumans , 0) as TranslationHumans, isnull(TranslationAnimals , 0) as TranslationAnimals, 
					isnull(TranslationCells , 0) as TranslationCells, isnull(TranslationPublicHealth , 0) as TranslationPublicHealth, isnull(TranslationClinicalTrial , 0) as TranslationClinicalTrial
				from [Profile.Data].[Publication.Group.Include] e
					inner join [Profile.Data].[Publication.Entity.InformationResource] p
						on e.pmid = p.pmid OR e.mpid = p.MPID and e.groupID = @GroupID and p.IsActive = 1
					left join [Profile.Data].[Publication.Pubmed.Bibliometrics] b on p.PMID = b.PMID
				order by 
					p.EntityDate desc
				UNION
				select top 100 p.EntityID, p.EntityName rdfs_label, 
					p.Authors + p.Reference prns_informationResourceReference, p.EntityDate prns_publicationDate,
					year(p.EntityDate) prns_year, p.pmid bibo_pmid, p.pmcid vivo_pmcid, p.doi bibo_doi, p.mpid prns_mpid, p.URL vivo_webpage, 
					isnull(b.PMCCitations, -1) as PMCCitations, isnull(b.RelativeCitationRatio, -1) as RelativeCitationRatio, isnull(Fields, '{"Fields":[]}') as Fields, isnull(TranslationHumans , 0) as TranslationHumans, isnull(TranslationAnimals , 0) as TranslationAnimals, 
					isnull(TranslationCells , 0) as TranslationCells, isnull(TranslationPublicHealth , 0) as TranslationPublicHealth, isnull(TranslationClinicalTrial , 0) as TranslationClinicalTrial
				from [Profile.Data].[Publication.Group.Include] e
					inner join [Profile.Data].[Publication.Entity.InformationResource] p
						on e.pmid = p.pmid OR e.mpid = p.MPID and e.groupID = @GroupID and p.IsActive = 1
					left join [Profile.Data].[Publication.Pubmed.Bibliometrics] b on p.PMID = b.PMID
				order by 
					b.PMCCitations desc --Most Citations
				) t
			for json path, ROOT ('Publications'))
	END
	ELSE
	BEGIN
		select @result =(
			select top (@count) p.EntityID, p.EntityName rdfs_label, 
				p.Authors + p.Reference prns_informationResourceReference, p.EntityDate prns_publicationDate,
				year(p.EntityDate) prns_year, p.pmid bibo_pmid, p.pmcid vivo_pmcid, p.doi bibo_doi, p.mpid prns_mpid, p.URL vivo_webpage, 
				isnull(b.PMCCitations, -1) as PMCCitations, isnull(b.RelativeCitationRatio, -1) as RelativeCitationRatio, JSON_QUERY(isnull(Fields, '{"Fields":[]}'), '$.Fields') as Fields, isnull(TranslationHumans , 0) as TranslationHumans, isnull(TranslationAnimals , 0) as TranslationAnimals, 
				isnull(TranslationCells , 0) as TranslationCells, isnull(TranslationPublicHealth , 0) as TranslationPublicHealth, isnull(TranslationClinicalTrial , 0) as TranslationClinicalTrial
			from [Profile.Data].[Publication.Group.Include] e
				inner join [Profile.Data].[Publication.Entity.InformationResource] p
					on e.pmid = p.pmid OR e.mpid = p.MPID and e.groupID = @GroupID and p.IsActive = 1
				left join [Profile.Data].[Publication.Pubmed.Bibliometrics] b on p.PMID = b.PMID
			order by 
				case when @sort = 'N' then p.EntityDate end desc, --Newest
				case when @sort = 'O' then p.EntityDate end asc, --Oldest
				case when @sort = 'C' then b.PMCCitations end desc --Most Citations
			for json path, ROOT ('Publications'))
	END


	return @result
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [Display.Module].[FnCustomViewAuthorInAuthorship.GetJournalHeadings]
	(@NodeID bigint = NULL,
	@InternalID int = 0,
	@SessionID uniqueidentifier = NULL)
	returns varchar(max)
AS
BEGIN
	DECLARE @SecurityGroupID BIGINT = -1, @HasSpecialViewAccess BIT = 0
	--EXEC [RDF.Security].GetSessionSecurityGroup @SessionID, @SecurityGroupID OUTPUT, @HasSpecialViewAccess OUTPUT
	Declare @SecurityGroupNodes table(SecurityGroupNode BIGINT PRIMARY KEY)
	INSERT INTO @SecurityGroupNodes (SecurityGroupNode) select * from [RDF.Security].fnGetSessionSecurityGroupNodes(@SessionID, @NodeID)

	declare @class nvarchar(400)
	select @class = class from [RDF.Stage].InternalNodeMap where nodeid=@NodeID 

	declare @tmp table (
		[Order] int,
		BroadJournalHeading varchar(100),
		[Weight] float,
		[Count] int,
		Color varchar(6)
	)

	if @class = 'http://xmlns.com/foaf/0.1/Person'
	BEGIN
		declare @AuthorInAuthorship bigint
		select @AuthorInAuthorship = [RDF.].fnURI2NodeID('http://vivoweb.org/ontology/core#authorInAuthorship') 
		declare @LinkedInformationResource bigint
		select @LinkedInformationResource = [RDF.].fnURI2NodeID('http://vivoweb.org/ontology/core#linkedInformationResource') 

		insert into @tmp
		select /*top 10*/ ROW_NUMBER() OVER (ORDER BY CASE isnull(h.BroadJournalHeading, 'Unknown') WHEN 'Unknown' THEN 1 ELSE 0 END, SUM(isnull(h.Weight, 1)) desc, count(*) desc) as [Order],
		 isnull(h.DisplayName, 'Unknown') BroadJournalHeading, SUM(isnull(h.Weight, 1)) as [Weight], count(*) as [Count], Color--, count(*) * 100.0 / sum (count(*)) over() as Percentage, Sum(isnull(h.Weight, 1))over() as Total
		from [Profile.Data].[Publication.Entity.Authorship] e
		inner join [Profile.Data].[Publication.Entity.InformationResource] p
			on e.InformationResourceID = p.EntityID and e.PersonID = @InternalID and e.IsActive = 1
		left join [Profile.Data].[Publication.Pubmed.Bibliometrics] b on p.PMID = b.PMID
			left join [Profile.Data].[Publication.Pubmed.JournalHeading] h on b.MedlineTA = H.MedlineTA
		--order by p.EntityDate desc
		GROUP BY isnull(h.BroadJournalHeading, 'Unknown'), DisplayName, Color
		ORDER BY CASE isnull(h.BroadJournalHeading, 'Unknown') WHEN 'Unknown' THEN 1 ELSE 0 END, SUM(isnull(h.Weight, 1)) desc, count(*) desc
	END
	ELSE if @class = 'http://xmlns.com/foaf/0.1/Group'
	BEGIN

		declare @AssociatedInformationResource bigint
		select @AssociatedInformationResource = [RDF.].fnURI2NodeID('http://profiles.catalyst.harvard.edu/ontology/prns#associatedInformationResource') 

		insert into @tmp
		select /*top 10*/ ROW_NUMBER() OVER (ORDER BY CASE isnull(h.BroadJournalHeading, 'Unknown') WHEN 'Unknown' THEN 1 ELSE 0 END, SUM(isnull(h.Weight, 1)) desc, count(*) desc) as [Order],
		 isnull(h.DisplayName, 'Unknown') BroadJournalHeading, SUM(isnull(h.Weight, 1)) as [Weight], count(*) as [Count], Color--, count(*) * 100.0 / sum (count(*)) over() as Percentage, Sum(isnull(h.Weight, 1))over() as Total
		from [RDF.].[Triple] t
			inner join [RDF.].[Node] a
				on t.subject = @NodeID and t.predicate = @AssociatedInformationResource
					and t.object = a.NodeID
					and ((t.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (t.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (t.ViewSecurityGroup IN (SELECT * FROM @SecurityGroupNodes)))
					and ((a.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (a.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (a.ViewSecurityGroup IN (SELECT * FROM @SecurityGroupNodes)))
			inner join [RDF.].[Node] i
				on t.object = i.NodeID
					and ((i.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (i.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (i.ViewSecurityGroup IN (SELECT * FROM @SecurityGroupNodes)))
			inner join [RDF.Stage].[InternalNodeMap] m
				on i.NodeID = m.NodeID
			inner join [Profile.Data].[Publication.Entity.InformationResource] p
				on m.InternalID = p.EntityID
			left join [Profile.Data].[Publication.Pubmed.Bibliometrics] b on p.PMID = b.PMID
			left join [Profile.Data].[Publication.Pubmed.JournalHeading] h on b.MedlineTA = H.MedlineTA
		--order by p.EntityDate desc
		GROUP BY isnull(h.BroadJournalHeading, 'Unknown'), DisplayName, Color
		ORDER BY CASE isnull(h.BroadJournalHeading, 'Unknown') WHEN 'Unknown' THEN 1 ELSE 0 END, SUM(isnull(h.Weight, 1)) desc, count(*) desc
	END
	--select * from #tmp ORDER BY [Weight] desc, [count]desc
	
	DECLARE @totalWeight float
	DECLARE @totalCount int
	SELECT @totalWeight = SUM(Weight), @totalCount = SUM(Count) from @tmp

	DELETE FROM @tmp WHERE BroadJournalHeading = 'Unknown' OR [Order] > 9

	INSERT INTO @tmp ([Order], BroadJournalHeading, [Weight], [Count], Color) 
	SELECT top 1 10, 'Other' as BroadJournalHeading, @totalWeight - (Select top 1 sum ([Weight]) over () from @tmp) AS [Weight], @totalCount - (Select top 1 sum ([Count]) over () from @tmp) AS [Count], 'BAB0AC' from @tmp

	UPDATE @tmp set color = '4E79A7' where [Order] = 1
	UPDATE @tmp set color = 'F28E2B' where [Order] = 2
	UPDATE @tmp set color = 'E15759' where [Order] = 3
	UPDATE @tmp set color = '76B7B2' where [Order] = 4
	UPDATE @tmp set color = '59A14F' where [Order] = 5
	UPDATE @tmp set color = 'EDC948' where [Order] = 6
	UPDATE @tmp set color = 'B07AA1' where [Order] = 7
	UPDATE @tmp set color = 'FF9DA7' where [Order] = 8
	UPDATE @tmp set color = '9C755F' where [Order] = 9
	UPDATE @tmp SET [Weight] = [Weight] / @totalWeight;

	declare @result varchar(max)
	select @result = (select BroadJournalHeading, [Count], Weight, Color from @tmp order by [Order] desc for json path, ROOT ('FieldSummary'))
	return @result
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Function [Display.Module].[FnCustomViewAuthorInAuthorship.GetList]
	(@PersonID int = NULL,
	@SessionID uniqueidentifier = NULL,
	@count int = 50,
	@sort char)
	returns varchar(max)
AS
BEGIN
	if @count=-1 set @count=10000


	declare @result varchar(max)
	if @sort = 'A'
	BEGIN
		select @result =(
			select 
				EntityID, rdfs_label, prns_informationResourceReference, prns_publicationDate, prns_year, bibo_pmid, vivo_pmcid, 
				bibo_doi, prns_mpid, vivo_webpage, PMCCitations, RelativeCitationRatio, JSON_QUERY(isnull(Fields, '{"Fields":[]}'), '$.Fields') as Fields, TranslationHumans, 
				TranslationAnimals, TranslationCells, TranslationPublicHealth, TranslationClinicalTrial	
			 from (
				select top 100 p.EntityID, p.EntityName rdfs_label, 
					isnull(e.AuthorsString, p.Authors) + p.Reference prns_informationResourceReference, p.EntityDate prns_publicationDate,
					year(p.EntityDate) prns_year, p.pmid bibo_pmid, p.pmcid vivo_pmcid, p.doi bibo_doi, p.mpid prns_mpid, p.URL vivo_webpage, 
					isnull(b.PMCCitations, -1) as PMCCitations, isnull(b.RelativeCitationRatio, -1) as RelativeCitationRatio, isnull(Fields, '{"Fields":[]}') as Fields, isnull(TranslationHumans , 0) as TranslationHumans, isnull(TranslationAnimals , 0) as TranslationAnimals, 
					isnull(TranslationCells , 0) as TranslationCells, isnull(TranslationPublicHealth , 0) as TranslationPublicHealth, isnull(TranslationClinicalTrial , 0) as TranslationClinicalTrial
				from [Profile.Data].[Publication.Entity.Authorship] e
					inner join [Profile.Data].[Publication.Entity.InformationResource] p
						on e.InformationResourceID = p.EntityID and e.PersonID = @PersonID and e.IsActive = 1
					left join [Profile.Data].[Publication.Pubmed.Bibliometrics] b on p.PMID = b.PMID
				order by 
					p.EntityDate desc
				UNION
				select top 100 p.EntityID, p.EntityName rdfs_label, 
					isnull(e.AuthorsString, p.Authors) + p.Reference prns_informationResourceReference, p.EntityDate prns_publicationDate,
					year(p.EntityDate) prns_year, p.pmid bibo_pmid, p.pmcid vivo_pmcid, p.doi bibo_doi, p.mpid prns_mpid, p.URL vivo_webpage, 
					isnull(b.PMCCitations, -1) as PMCCitations, isnull(b.RelativeCitationRatio, -1) as RelativeCitationRatio, isnull(Fields, '{"Fields":[]}') as Fields, isnull(TranslationHumans , 0) as TranslationHumans, isnull(TranslationAnimals , 0) as TranslationAnimals, 
					isnull(TranslationCells , 0) as TranslationCells, isnull(TranslationPublicHealth , 0) as TranslationPublicHealth, isnull(TranslationClinicalTrial , 0) as TranslationClinicalTrial
				from [Profile.Data].[Publication.Entity.Authorship] e
					inner join [Profile.Data].[Publication.Entity.InformationResource] p
						on e.InformationResourceID = p.EntityID and e.PersonID = @PersonID and e.IsActive = 1
					left join [Profile.Data].[Publication.Pubmed.Bibliometrics] b on p.PMID = b.PMID
				order by 
					b.PMCCitations desc --Most Citations
				) t
			for json path, ROOT ('Publications'))
	END
	ELSE
	BEGIN
		select @result =(
			select top (@count) p.EntityID, p.EntityName rdfs_label, 
				isnull(e.AuthorsString, p.Authors) + p.Reference prns_informationResourceReference, p.EntityDate prns_publicationDate,
				year(p.EntityDate) prns_year, p.pmid bibo_pmid, p.pmcid vivo_pmcid, p.doi bibo_doi, p.mpid prns_mpid, p.URL vivo_webpage, 
				isnull(b.PMCCitations, -1) as PMCCitations, isnull(b.RelativeCitationRatio, -1) as RelativeCitationRatio, JSON_QUERY(isnull(Fields, '{"Fields":[]}'), '$.Fields') as Fields, isnull(TranslationHumans , 0) as TranslationHumans, isnull(TranslationAnimals , 0) as TranslationAnimals, 
				isnull(TranslationCells , 0) as TranslationCells, isnull(TranslationPublicHealth , 0) as TranslationPublicHealth, isnull(TranslationClinicalTrial , 0) as TranslationClinicalTrial
			from [Profile.Data].[Publication.Entity.Authorship] e
				inner join [Profile.Data].[Publication.Entity.InformationResource] p
					on e.InformationResourceID = p.EntityID and e.PersonID = @PersonID and e.IsActive = 1
				left join [Profile.Data].[Publication.Pubmed.Bibliometrics] b on p.PMID = b.PMID
			order by 
				case when @sort = 'N' then p.EntityDate end desc, --Newest
				case when @sort = 'O' then p.EntityDate end asc, --Oldest
				case when @sort = 'C' then b.PMCCitations end desc --Most Citations
			for json path, ROOT ('Publications'))
	END


	return @result
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Function [Display.Module].[FnCustomViewConceptPublications.GetList]
	(@NodeID bigint = NULL,
	@SessionID uniqueidentifier = NULL,
	@count int = 50,
	@sort char)
	returns varchar(max)
AS
BEGIN
	if @count=-1 set @count=10000
	
	DECLARE @DescriptorName NVARCHAR(255)
 	SELECT @DescriptorName = d.DescriptorName
		FROM [RDF.Stage].[InternalNodeMap] m, [RDF.].Node n,
			[Profile.Data].[Concept.Mesh.Descriptor] d
		WHERE m.Status = 3 AND m.ValueHash = n.ValueHash AND n.NodeID = @NodeID
			AND m.InternalID = d.DescriptorUI

	declare @result varchar(max)

	select @result =(
		select top (@count) p.EntityID, p.EntityName rdfs_label, 
			p.Authors + p.Reference prns_informationResourceReference, p.EntityDate prns_publicationDate,
			year(p.EntityDate) prns_year, p.pmid bibo_pmid, p.pmcid vivo_pmcid, p.doi bibo_doi, p.mpid prns_mpid, p.URL vivo_webpage, 
			isnull(b.PMCCitations, -1) as PMCCitations, isnull(b.RelativeCitationRatio, -1) as RelativeCitationRatio, JSON_QUERY(isnull(Fields, '{"Fields":[]}'), '$.Fields') as Fields, isnull(TranslationHumans , 0) as TranslationHumans, isnull(TranslationAnimals , 0) as TranslationAnimals, 
			isnull(TranslationCells , 0) as TranslationCells, isnull(TranslationPublicHealth , 0) as TranslationPublicHealth, isnull(TranslationClinicalTrial , 0) as TranslationClinicalTrial
		from [Profile.Data].[Publication.PubMed.Mesh] m
			inner join [Profile.Data].[Publication.Entity.InformationResource] p
				on  m.descriptorname = @DescriptorName and m.PMID = p.PMID and p.IsActive = 1
			left join [Profile.Data].[Publication.Pubmed.Bibliometrics] b on p.PMID = b.PMID
		order by 
			case when @sort = 'N' then p.EntityDate end desc, --Newest
			case when @sort = 'O' then p.EntityDate end asc, --Oldest
			case when @sort = 'C' then b.PMCCitations end desc --Most Citations
		for json path, ROOT ('Publications'))



	return @result
END

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [Display.Module].[FnNetworkAuthorshipTimeline.Concept.GetData]
	(@NodeID BIGINT)
	returns varchar(max)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	DECLARE @DescriptorName NVARCHAR(255)
 	SELECT @DescriptorName = d.DescriptorName
		FROM [RDF.Stage].[InternalNodeMap] m, [RDF.].Node n,
			[Profile.Data].[Concept.Mesh.Descriptor] d
		WHERE m.Status = 3 AND m.ValueHash = n.ValueHash AND n.NodeID = @NodeID
			AND m.InternalID = d.DescriptorUI

	declare @result varchar(max) = ''

 
    -- Insert statements for procedure here
	declare @gc varchar(max)

	declare @y table (
		y int,
		A int,
		B int,
		C int,
		T int
	)

	insert into @y (y,A,B,C,T)
		select n.n y, 0 A, 0 B, 0 C, coalesce(t.T,0) T
		from [Utility.Math].[N] left outer join (
			select (case when y < 1970 then 1970 else y end) y,
				count(*) T
			from (
				select year(coalesce(a.entitydate,'1/1/1970')) y
				from [Profile.Data].[Publication.PubMed.Mesh] m
					join [Profile.Data].[Publication.Entity.InformationResource] a on  m.descriptorname = @DescriptorName and m.PMID = a.PMID and a.IsActive = 1
			) t
			group by y
		) t on n.n = t.y
		where n.n between year(getdate())-30 and year(getdate())

	declare @x int

	--select @x = max(A+B+C)
	--	from @y

	select @x = max(T)
		from @y

	if coalesce(@x,0) > 0
	begin
		declare @v varchar(1000)
		declare @z int
		declare @k int
		declare @i int

		set @z = power(10,floor(log(@x)/log(10)))
		set @k = floor(@x/@z)
		if @x > @z*@k
			select @k = @k + 1
		if @k > 5
			select @k = floor(@k/2.0+0.5), @z = @z*2

		set @v = ''
		set @i = 0
		while @i <= @k
		begin
			set @v = @v + '|' + cast(@z*@i as varchar(50))
			set @i = @i + 1
		end
		set @v = '|0|'+cast(@x as varchar(50))
		--set @v = '|0|50|100'

		declare @h varchar(1000)
		set @h = ''
		select @h = @h + '|' + (case when y % 2 = 1 then '' else ''''+right(cast(y as varchar(50)),2) end)
			from @y
			order by y 

		declare @w float
		--set @w = @k*@z
		set @w = @x

		declare @c varchar(50)
		declare @d varchar(max)
		set @d = ''

		select @result = (select y, t from @y order by y desc for json path, ROOT ('Timeline'))
	end
	return @result
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [Display.Module].[FnNetworkAuthorshipTimeline.Person.GetData]
	(@NodeID BIGINT, @ShowAuthorPosition BIT = 0)
	returns varchar(max)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	declare @result varchar(max) = '{"Timeline":[]}'

	DECLARE @PersonID INT
 	SELECT @PersonID = CAST(m.InternalID AS INT)
		FROM [RDF.Stage].[InternalNodeMap] m, [RDF.].Node n
		WHERE m.Status = 3 AND m.ValueHash = n.ValueHash AND n.NodeID = @NodeID
 
    -- Insert statements for procedure here
	declare @gc varchar(max)

	declare @y table (
		y int,
		A int,
		B int,
		C int,
		T int
	)

	insert into @y (y,A,B,C,T)
		select n.n y, coalesce(t.A,0) A, coalesce(t.B,0) B, coalesce(t.C,0) C, coalesce(t.T,0) T
		from [Utility.Math].[N] left outer join (
			select (case when y < 1970 then 1970 else y end) y,
				sum(case when r in ('F','S') then 1 else 0 end) A,
				sum(case when r not in ('F','S','L') then 1 else 0 end) B,
				sum(case when r in ('L') then 1 else 0 end) C,
				count(*) T
			from (
				select coalesce(p.AuthorPosition,'U') r, year(coalesce(p.pubdate,m.publicationdt,'1/1/1970')) y
				from [Profile.Data].[Publication.Person.Include] a
					left outer join [Profile.Cache].[Publication.PubMed.AuthorPosition] p on a.pmid = p.pmid and p.personid = a.personid
					left outer join [Profile.Data].[Publication.MyPub.General] m on a.mpid = m.mpid
				where a.personid = @PersonID
			) t
			group by y
		) t on n.n = t.y
		where n.n between year(getdate())-30 and year(getdate())

	declare @x int

	--select @x = max(A+B+C)
	--	from @y

	select @x = max(T)
		from @y

	if coalesce(@x,0) > 0
	begin
		declare @v varchar(1000)
		declare @z int
		declare @k int
		declare @i int

		set @z = power(10,floor(log(@x)/log(10)))
		set @k = floor(@x/@z)
		if @x > @z*@k
			select @k = @k + 1
		if @k > 5
			select @k = floor(@k/2.0+0.5), @z = @z*2

		set @v = ''
		set @i = 0
		while @i <= @k
		begin
			set @v = @v + '|' + cast(@z*@i as varchar(50))
			set @i = @i + 1
		end
		set @v = '|0|'+cast(@x as varchar(50))
		--set @v = '|0|50|100'

		declare @h varchar(1000)
		set @h = ''
		select @h = @h + '|' + (case when y % 2 = 1 then '' else ''''+right(cast(y as varchar(50)),2) end)
			from @y
			order by y 

		declare @w float
		--set @w = @k*@z
		set @w = @x

		declare @c varchar(50)
		declare @d varchar(max)
		set @d = ''
/*
		if @ShowAuthorPosition = 0
		begin
			select @d = @d + cast(floor(0.5 + 100*T/@w) as varchar(50)) + ','
				from @y
				order by y
			set @d = left(@d,len(@d)-1)

			--set @c = 'AC1B30'
			set @c = '80B1D3'
			set @gc = '//chart.googleapis.com/chart?chs=595x100&chf=bg,s,ffffff|c,s,ffffff&chxt=x,y&chxl=0:' + @h + '|1:' + @v + '&cht=bvs&chd=t:' + @d + '&chdl=Publications&chco='+@c+'&chbh=10'
		end
		else
		begin
			select @d = @d + cast(floor(0.5 + 100*A/@w) as varchar(50)) + ','
				from @y
				order by y
			set @d = left(@d,len(@d)-1) + '|'
			select @d = @d + cast(floor(0.5 + 100*B/@w) as varchar(50)) + ','
				from @y
				order by y
			set @d = left(@d,len(@d)-1) + '|'
			select @d = @d + cast(floor(0.5 + 100*C/@w) as varchar(50)) + ','
				from @y
				order by y
			set @d = left(@d,len(@d)-1)

			set @c = 'FB8072,B3DE69,80B1D3'
			set @gc = '//chart.googleapis.com/chart?chs=595x100&chf=bg,s,ffffff|c,s,ffffff&chxt=x,y&chxl=0:' + @h + '|1:' + @v + '&cht=bvs&chd=t:' + @d + '&chdl=First+Author|Middle or Unkown|Last+Author&chco='+@c+'&chbh=10'
		end
		
		declare @asText varchar(max)
		set @asText = '<table style="width:592px"><tr><th>Year</th><th>Publications</th></tr>'
		select @asText = @asText + '<tr><td style="text-align:center;">' + cast(y as varchar(50)) + '</td><td style="text-align:center;">' + cast(t as varchar(50)) + '</td></tr>'
			from @y
			where t > 0
			order by y 
		select @asText = @asText + '</table>'
		
			declare @alt varchar(max)
		select @alt = 'Bar chart showing ' + cast(sum(t) as varchar(50))+ ' publications over ' + cast(count(*) as varchar(50)) + ' distinct years, with a maximum of ' + cast(@x as varchar(50)) + ' publications in ' from @y where t > 0
		select @alt = @alt + cast(y as varchar(50)) + ' and '
			from @y
			where t = @x
			order by y 
		select @alt = left(@alt, len(@alt) - 4)


		select @gc gc, @alt alt, @asText asText --, @w w
		*/

		select @result = (select y, t from @y order by y desc for json path, ROOT ('Timeline'))
	end
	return @result
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Function [Display.Module].[FnNetworkRadial.GetData]
	(@PersonNodeID bigint = NULL,
	@GroupNodeID bigint = NULL,
	@ListUserID int = NULL)
	returns varchar(max)
AS
BEGIN


	declare @result varchar(max)		
	DECLARE @PersonID1 INT, @GroupID INT
	declare @network table(personID int not null, distance int not null, numberofpaths int, weight float, w2 float, lastname nvarchar(max), firstname nvarchar(max), p int, k int, nodeid bigint, uri varchar(400), PreferredPath varchar(400), nodeindex int)
	declare @network2 table (id1 int not null, id2 int not null, n int, w float, y1 int, y2 int, k int, n1 bigint, n2 bigint, u1 varchar(400), u2 varchar(400), connectionURI varchar(400), ni1 int, ni2 int)


	if @PersonNodeID is not null
	BEGIN

		SELECT @PersonID1 = CAST(m.InternalID AS INT)
		FROM [RDF.Stage].[InternalNodeMap] m, [RDF.].Node n
		WHERE m.Status = 3 AND m.ValueHash = n.ValueHash AND n.NodeID = @PersonNodeID
		insert into @network
		SELECT TOP 120
						personid,
						distance,
						numberofpaths,
						weight,
						w2,
						lastname,
						firstname,
						p,
						k,
						cast(-1 as bigint) nodeid,
						cast('' as varchar(400)) uri,
						cast('' as varchar(400)) PreferredPath,
						0 nodeindex
			--INTO #network 
			FROM ( 
							SELECT personid, 
											distance, 
											numberofpaths, 
											weight, 
											w2, 
											p.lastname, 
											p.firstname, 
											p.numpublications p, 
											ROW_NUMBER() OVER (PARTITION BY distance ORDER BY w2 DESC) k 
								FROM [Profile.Cache].Person p
								JOIN ( SELECT *, ROW_NUMBER() OVER (PARTITION BY personid2 ORDER BY distance, w2 DESC) k 
										FROM (
											SELECT personid2, 1 distance, n numberofpaths, w weight, w w2 
												FROM [Profile.Cache].[SNA.Coauthor]  
												WHERE personid1 = @personid1
											UNION ALL 
												SELECT b.personid2, 2 distance, b.n numberofpaths, b.w weight,a.w*b.w w2 
												FROM [Profile.Cache].[SNA.Coauthor] a JOIN [Profile.Cache].[SNA.Coauthor] b ON a.personid2 = b.personid1 
												WHERE a.personid1 = @personid1  
											UNION ALL 
												SELECT @personid1 personid2, 0 distance, 1 numberofpaths, 1 weight, 1 w2 
										) t 
									) t ON p.personid = t.personid2 
								WHERE k = 1  AND p.IsActive = 1
						) t 
			WHERE k <= 80 
		ORDER BY distance, k
	END
 
	ELSE IF @GroupNodeID is not null
	BEGIN

		SET @PersonID1 = -1

		SELECT @GroupID = CAST(m.InternalID AS INT)
			FROM [RDF.Stage].[InternalNodeMap] m, [RDF.].Node n
			WHERE m.Status = 3 AND m.ValueHash = n.ValueHash AND n.NodeID = @GroupNodeID
 
		insert into @network
		SELECT TOP 120
						personid,
						distance,
						numberofpaths,
						weight,
						w2,
						lastname,
						firstname,
						p,
						k,
						cast(-1 as bigint) nodeid,
						cast('' as varchar(400)) uri,
						cast('' as varchar(400)) PreferredPath,
						0 nodeindex
			FROM ( 
							SELECT p.personid, 
											1 as distance, 
											0 as numberofpaths, 
											0 as weight, 
											0.5 as w2, 
											p.lastname, 
											p.firstname, 
											p.numpublications p, 
											ROW_NUMBER() OVER (ORDER BY p.PersonID DESC) k 
								FROM [Profile.Cache].Person p
								JOIN [Profile.Data].[vwGroup.Member] g
								on p.PersonID = g.PersonID
								  AND p.IsActive = 1
								  and g.GroupID = @GroupID
						) t 
			--WHERE k <= 80 
		ORDER BY distance, k
	END


 



	
	--UPDATE n
		/*SET n.NodeID = m.NodeID, n.URI = p.Value + cast(m.NodeID as varchar(50))
		FROM @network n, [RDF.Stage].InternalNodeMap m, [Framework.].Parameter p
		WHERE p.ParameterID = 'baseURI' AND m.InternalHash = [RDF.].fnValueHash(null,null,'http://xmlns.com/foaf/0.1/Person^^Person^^'+cast(n.PersonID as varchar(50)))*/
 

 	declare @relativeBasePath varchar(100)
	select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'

	update n set n.nodeid = p.NodeID,
		n.uri = @relativeBasePath + isnull(DefaultApplication, '') + p.PreferredPath,
		n.PreferredPath = p.PreferredPath
		from @network n
			join [Profile.Cache].Person p
			on n.personID = p.PersonID

	DELETE FROM @network WHERE IsNull(URI,'') = ''	
	
	UPDATE a
		SET a.nodeindex = b.ni
		FROM @network a, (
			SELECT *, row_number() over (order by distance desc, k desc)-1 ni
			FROM @network
		) b
		WHERE a.personid = b.personid


	insert into @network2
	SELECT c.personid1 id1, c.personid2	id2, c.n, CAST(c.w AS VARCHAR) w, 
			(CASE WHEN YEAR(firstpubdate)<1980 THEN 1980 ELSE YEAR(firstpubdate) END) y1, 
			(CASE WHEN YEAR(lastpubdate)<1980 THEN 1980 ELSE YEAR(lastpubdate) END) y2,
			(case when c.personid1 = @personid1 or c.personid2 = @personid1 then 1 else 0 end) k,
			a.nodeid n1, b.nodeid n2, a.uri u1, b.uri u2, a.uri + '/Network/CoAuthors' + b.PreferredPath, a.nodeindex ni1, b.nodeindex ni2
		from @network a
			JOIN @network b on a.personid < b.personid  
			JOIN [Profile.Cache].[SNA.Coauthor] c ON a.personid = c.personid1 and b.personid = c.personid2  
 
	;with a as (
		select id1, id2, w, k from @network2
		union all
		select id2, id1, w, k from @network2
	), b as (
		select a.*, row_number() over (partition by a.id1 order by a.w desc, a.id2) s
		from a, 
			(select id1 from a group by id1 having max(k) = 0) b,
			(select id1 from a group by id1 having max(k) > 0) c
		where a.id1 = b.id1 and a.id2 = c.id1
	)
	update n
		set n.k = 2
		from @network2 n, b
		where (n.id1 = b.id1 and n.id2 = b.id2 and b.s = 1) or (n.id1 = b.id2 and n.id2 = b.id1 and b.s = 1)
 
	update n
		set n.k = 3
		from @network2 n, (
			select *, row_number() over (order by k desc, w desc) r 
			from @network2 
		) r
		where n.id1=r.id1 and n.id2=r.id2 and n.k=0 and r.r<=360
 
		declare @j1 nvarchar(max), @j2 nvarchar(max)
		SELECT @j1 = (select personID id, nodeid, uri, distance d, p pubs, firstname fn, lastname ln, CONVERT(DECIMAL(18,7),w2) w2 from @network order by nodeindex for json path, Root('NetworkPeople'))
		select @j2 = (select ni2 source, ni1 target, n, CONVERT(DECIMAL(18,5),w) w, id1, id2, y1, y2, n1 nodeid1, n2 nodeid2, u1 uri1, u2 uri2, connectionURI FROM @network2 WHERE k > 0 ORDER BY ni2, ni1 for json path, Root('NetworkCoAuthors'))
		select @result = (select JSON_QUERY(@j1, '$.NetworkPeople') as NetworkPeople, JSON_QUERY(@j2, '$.NetworkCoAuthors')as NetworkCoAuthors for json path, ROOT ('module_data'))
		

/*
		SELECT @result = 
			'{'+CHAR(10)
			+'"NetworkPeople":['+CHAR(10)
			+SUBSTRING(ISNULL(CAST((
				SELECT	',{'
						+'"id":'+cast(personid as varchar(50))+','
						+'"nodeid":'+cast(nodeid as varchar(50))+','
						+'"uri":"'+uri+'",'
						+'"d":'+cast(distance as varchar(50))+',' 
						+'"pubs":'+cast(p as varchar(50))+',' 
						+'"fn":"'+firstname+'",' 
						+'"ln":"'+lastname+'",'
						+'"w2":'+cast(w2 as varchar(50))
						+'}'+CHAR(10)
				FROM @network
				ORDER BY nodeindex
				FOR XML PATH(''),TYPE
			) as VARCHAR(MAX)),''),2,9999999)
			+'],'+CHAR(10)
			+'"NetworkCoAuthors":['+CHAR(10)
			+SUBSTRING(ISNULL(CAST((
				SELECT	',{'
						+'"source":'+cast(ni2 as varchar(50))+','
						+'"target":'+cast(ni1 as varchar(50))+','
						+'"n":'+cast(n as varchar(50))+','
						+'"w":'+cast(w as varchar(50))+',' 
						+'"id1":'+cast(id1 as varchar(50))+','
						+'"id2":'+cast(id2 as varchar(50))+','
						+'"y1":'+cast(y1 as varchar(50))+',' 
						+'"y2":'+cast(y2 as varchar(50))+',' 
						+'"nodeid1":'+cast(n1 as varchar(50))+','
						+'"nodeid2":'+cast(n2 as varchar(50))+','
						+'"uri1":"'+u1+'",'
						+'"uri2":"'+u2+'"'
						+'}'+CHAR(10)
				FROM @network2
				WHERE k > 0
				ORDER BY ni2, ni1
				FOR XML PATH(''),TYPE
			) as VARCHAR(MAX)),''),2,9999999)
			+']'+CHAR(10)
			+'}'

 */

	return @result
END
GO







GO
PRINT N'Update complete.';


GO




SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [RDF.Security].[fnGetSessionSecurityGroupNodes]
(@SessionID UNIQUEIDENTIFIER=NULL, @Subject BIGINT=NULL)
RETURNS @nodes TABLE(SecurityGroupNode bigint)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	/*

	This procedure returns Security Group nodes to which
	the given session has access. However, it only returns
	the NodeID of the session itself if the subject is that
	session node; otherwise, there is no need to include
	node in the result set.

	*/
	insert into @nodes
	-- Get the session's NodeID
	SELECT NodeID SecurityGroupNode
		FROM [User.Session].Session
		WHERE NodeID IS NOT NULL
			AND SessionID = @SessionID
	-- Get the user's NodeID
	UNION
	SELECT m.NodeID SecurityGroupNode
		FROM [User.Session].Session s 
			INNER JOIN [RDF.Stage].InternalNodeMap m
				ON	s.SessionID = @SessionID
					AND s.UserID IS NOT NULL
					AND m.Class = 'http://profiles.catalyst.harvard.edu/ontology/prns#User'
					AND m.InternalType = 'User'
					AND m.InternalID = CAST(s.UserID AS VARCHAR(50))
	-- Get designated proxy NodeIDs
	UNION
	SELECT m.NodeID SecurityGroupNode
		FROM [User.Session].Session s
			INNER JOIN [User.Account].[DesignatedProxy] x
				ON	s.SessionID = @SessionID
					AND s.UserID IS NOT NULL
					AND @Subject IS NOT NULL
					AND x.UserID = s.UserID
			INNER JOIN [RDF.Stage].InternalNodeMap m
				ON	m.Class = 'http://profiles.catalyst.harvard.edu/ontology/prns#User'
					AND m.InternalType = 'User'
					AND m.InternalID = CAST(x.ProxyForUserID AS VARCHAR(50))
			INNER JOIN [RDF.].[Node] n
				ON	n.NodeID = @Subject
					AND m.NodeID IN (@Subject, n.ViewSecurityGroup, n.EditSecurityGroup)
	/*
	SELECT m.NodeID SecurityGroupNode
		FROM [User.Session].Session s
			INNER JOIN [RDF.].[Node] n
				ON	s.SessionID = @SessionID
					AND s.UserID IS NOT NULL
					AND @Subject IS NOT NULL
					AND n.NodeID = @Subject
			INNER JOIN [User.Account].[DesignatedProxy] x
				ON	x.UserID = s.UserID
					AND x.ProxyForUserID IN (@Subject, n.ViewSecurityGroup, n.EditSecurityGroup)
			INNER JOIN [RDF.Stage].InternalNodeMap m
				ON	m.Class = 'http://profiles.catalyst.harvard.edu/ontology/prns#User'
					AND m.InternalType = 'User'
					AND m.InternalID = CAST(x.ProxyForUserID AS VARCHAR(50))
	*/
	-- Get default proxy NodeIDs
	UNION
	SELECT m.NodeID SecurityGroupNode
		FROM [User.Session].Session s
			INNER JOIN [RDF.].[Node] n
				ON	s.SessionID = @SessionID
					AND s.UserID IS NOT NULL
					AND @Subject IS NOT NULL
					AND n.NodeID = @Subject
			INNER JOIN [User.Account].[DefaultProxy] x
				ON	x.UserID = s.UserID
			INNER JOIN [Profile.Cache].[Person.Affiliation] a
				ON	((IsNull(x.ProxyForInstitution,'') = '') 
							OR (IsNull(x.ProxyForInstitution,'') = IsNull(a.InstititutionName,'')))
					AND ((IsNull(x.ProxyForDepartment,'') = '') 
							OR (IsNull(x.ProxyForDepartment,'') = IsNull(a.DepartmentName,'')))
					AND ((IsNull(x.ProxyForDivision,'') = '') 
							OR (IsNull(x.ProxyForDivision,'') = IsNull(a.DivisionName,'')))
			INNER JOIN [User.Account].[User] u
				ON a.PersonID = u.PersonID
			INNER JOIN [RDF.Stage].InternalNodeMap m
				ON	m.Class = 'http://profiles.catalyst.harvard.edu/ontology/prns#User'
					AND m.InternalType = 'User'
					AND m.InternalID = CAST(u.UserID AS VARCHAR(50))
					AND m.NodeID IN (@Subject, n.ViewSecurityGroup, n.EditSecurityGroup)
	-- Get Group Administrator NodesIDs
	UNION
	SELECT g.GroupNodeID SecurityGroupNode
		FROM [User.Session].Session s
			INNER JOIN [Profile.Data].[Group.Admin] x
				ON	s.SessionID = @SessionID
					AND s.UserID IS NOT NULL
					AND @Subject IS NOT NULL
					AND x.UserID = s.UserID
			INNER JOIN [Profile.Data].[vwGroup.General] g
				ON g.ViewSecurityGroup <> 0
				AND g.GroupNodeID = @Subject
	-- Get Group Manager NodeIDs
	UNION
	SELECT g.GroupNodeID SecurityGroupNode
		FROM [User.Session].Session s
			INNER JOIN [Profile.Data].[Group.Manager] x
				ON	s.SessionID = @SessionID
					AND s.UserID IS NOT NULL
					AND @Subject IS NOT NULL
					AND x.UserID = s.UserID
			INNER JOIN [Profile.Data].[vwGroup.General] g
				ON g.ViewSecurityGroup <> 0
				AND g.GroupID = x.GroupID
				AND g.GroupNodeID = @Subject					
	/*
	SELECT m.NodeID SecurityGroupNode
		FROM [User.Session].Session s
			INNER JOIN [RDF.].[Node] n
				ON	s.SessionID = @SessionID
					AND s.UserID IS NOT NULL
					AND @Subject IS NOT NULL
					AND n.NodeID = @Subject
			INNER JOIN [User.Account].[DefaultProxy] x
				ON	x.UserID = s.UserID
			INNER JOIN [User.Account].[User] u
				ON	u.UserID IN (@Subject, n.ViewSecurityGroup, n.EditSecurityGroup)
					AND ((IsNull(x.ProxyForInstitution,'') = '') 
							OR (IsNull(x.ProxyForInstitution,'') = IsNull(u.Institution,'')))
					AND ((IsNull(x.ProxyForDepartment,'') = '') 
							OR (IsNull(x.ProxyForDepartment,'') = IsNull(u.Department,'')))
					AND ((IsNull(x.ProxyForDivision,'') = '') 
							OR (IsNull(x.ProxyForDivision,'') = IsNull(u.Division,'')))
			INNER JOIN [RDF.Stage].InternalNodeMap m
				ON	m.Class = 'http://profiles.catalyst.harvard.edu/ontology/prns#User'
					AND m.InternalType = 'User'
					AND m.InternalID = CAST(u.UserID AS VARCHAR(50))
	*/

	/*
	This will later be expanded to include all nodes to which a
	session's users is connected through a membership predicate.
	*/

	RETURN
END

GO





SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [RDF.].[fnNodeID2PersonID] (
	@nodeID	bigint
) 
RETURNS int
AS
BEGIN
	DECLARE @result int
	select @result = internalID from [RDF.Stage].InternalNodeMap where NodeID = @nodeID and class = 'http://xmlns.com/foaf/0.1/Person'
	RETURN @result
END

GO