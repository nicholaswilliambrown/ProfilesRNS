/****** Object:  Schema [Display.]    Script Date: 4/22/2024 12:52:32 PM ******/
CREATE SCHEMA [Display.]
GO
/****** Object:  Schema [Display.Module]    Script Date: 4/22/2024 12:52:32 PM ******/
CREATE SCHEMA [Display.Module]
GO
/****** Object:  UserDefinedFunction [Display.Module].[FnCustomViewAuthorInAuthorship.GetDisplaySettings]    Script Date: 4/22/2024 12:52:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Function [Display.Module].[FnCustomViewAuthorInAuthorship.GetDisplaySettings]
	(@PersonID int = NULL)
	returns varchar(max)
AS
BEGIN
	declare @result varchar(max)
	select @result =(
		select isnull(PMC, 1) PMC, isnull(Dimensions, 1) Dimensions, isnull(Altmetric, 1) Altmetric, isnull(Scite, 0) Scite, isnull(RCR, 1) RCR 
			from  [Profile.Data].Person p 
			left join [Profile.Data].[Publication.Person.DisplaySettings] ds on p.PersonID = ds.personID
			where p.personID=@PersonID  for json path, ROOT ('DisplaySettings'))

	return @result
END
GO
/****** Object:  UserDefinedFunction [Display.Module].[FnCustomViewAuthorInAuthorship.GetJournalHeadings]    Script Date: 4/22/2024 12:52:32 PM ******/
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
/****** Object:  UserDefinedFunction [Display.Module].[FnCustomViewAuthorInAuthorship.GetList]    Script Date: 4/22/2024 12:52:32 PM ******/
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
/****** Object:  UserDefinedFunction [Display.Module].[FnCustomViewAuthorInAuthorship.GetListFast]    Script Date: 4/22/2024 12:52:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Function [Display.Module].[FnCustomViewAuthorInAuthorship.GetListFast]
	(@PersonID int = NULL,
	@SessionID uniqueidentifier = NULL,
	@count int = 50)
	returns varchar(max)
AS
BEGIN
	if @count=-1 set @count=10000


	declare @result varchar(max)
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
	order by p.EntityDate desc for json path, ROOT ('Publications'))

	return @result
END
GO
/****** Object:  UserDefinedFunction [Display.Module].[FnCustomViewAuthorInAuthorship.GetListNick]    Script Date: 4/22/2024 12:52:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Function [Display.Module].[FnCustomViewAuthorInAuthorship.GetListNick]
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
/****** Object:  UserDefinedFunction [Display.Module].[FnCustomViewAuthorInAuthorship.GetListTable]    Script Date: 4/22/2024 12:52:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [Display.Module].[FnCustomViewAuthorInAuthorship.GetListTable]
(	@PersonID int = NULL,
	@count int,
	@sort char)
RETURNS  @p  TABLE(EntityID int, rdfs_label varchar(4000), prns_informationResourceReference varchar(max), prns_publicationDate datetime, prns_year int, bibo_pmid int, vivo_pmcid nvarchar(55), 
	bibo_doi varchar(100), prns_mpid nvarchar(50), vivo_webpage varchar(2000), PMCCitations int, RelativeCitationRatio float, Fields nvarchar(max), TranslationHumans int, 
	TranslationAnimals int, TranslationCells int, TranslationPublicHealth int, TranslationClinicalTrial int )
AS
BEGIN

	insert into @p
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

	return
END

GO
/****** Object:  UserDefinedFunction [Display.Module].[FnNetworkAuthorshipTimeline.Person.GetData]    Script Date: 4/22/2024 12:52:32 PM ******/
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

	declare @result varchar(max) = ''

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
/****** Object:  UserDefinedFunction [Display.Module].[FnNetworkRadial.GetData]    Script Date: 4/22/2024 12:52:32 PM ******/
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
		
	DECLARE @PersonID1 INT
 
	SELECT @PersonID1 = CAST(m.InternalID AS INT)
		FROM [RDF.Stage].[InternalNodeMap] m, [RDF.].Node n
		WHERE m.Status = 3 AND m.ValueHash = n.ValueHash AND n.NodeID = @PersonNodeID
 
	declare @network table(personID int not null, distance int not null, numberofpaths int, weight float, w2 float, lastname nvarchar(max), firstname nvarchar(max), p int, k int, nodeid bigint, uri varchar(400), nodeindex int)
	declare @network2 table (id1 int not null, id2 int not null, n int, w float, y1 int, y2 int, k int, n1 bigint, n2 bigint, u1 varchar(400), u2 varchar(400), ni1 int, ni2 int)


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
	
	UPDATE n
		SET n.NodeID = m.NodeID, n.URI = p.Value + cast(m.NodeID as varchar(50))
		FROM @network n, [RDF.Stage].InternalNodeMap m, [Framework.].Parameter p
		WHERE p.ParameterID = 'baseURI' AND m.InternalHash = [RDF.].fnValueHash(null,null,'http://xmlns.com/foaf/0.1/Person^^Person^^'+cast(n.PersonID as varchar(50)))
 
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
			a.nodeid n1, b.nodeid n2, a.uri u1, b.uri u2, a.nodeindex ni1, b.nodeindex ni2
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
		select @j2 = (select ni2 source, ni1 target, n, CONVERT(DECIMAL(18,5),w) w, id1, id2, y1, y2, n1 nodeid1, n2 nodeid2, u1 uri1, u2 uri2 FROM @network2 WHERE k > 0 ORDER BY ni2, ni1 for json path, Root('NetworkCoAuthors'))
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
/****** Object:  UserDefinedFunction [RDF.].[fnNodeID2PersonID]    Script Date: 4/22/2024 12:52:32 PM ******/
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
/****** Object:  UserDefinedFunction [RDF.Security].[fnGetSessionSecurityGroupNodes]    Script Date: 4/22/2024 12:52:32 PM ******/
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
/****** Object:  Table [Display.].[DataPath]    Script Date: 4/22/2024 12:52:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Display.].[DataPath](
	[PresentationID] [int] NOT NULL,
	[Tab] [varchar](16) NOT NULL,
	[Sort] [int] NOT NULL,
	[subject] [bit] NULL,
	[predicate] [bit] NULL,
	[object] [bit] NULL,
	[dataTab] [varchar](16) NULL,
 CONSTRAINT [PK_Display__DataPath] PRIMARY KEY CLUSTERED 
(
	[PresentationID] ASC,
	[Tab] ASC,
	[Sort] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Display.].[GetJsonLog]    Script Date: 4/22/2024 12:52:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Display.].[GetJsonLog](
	[getJsonLogID] [int] IDENTITY(1,1) NOT NULL,
	[timestamp] [datetime] NULL,
	[subject] [bigint] NULL,
	[predicate] [bigint] NULL,
	[object] [bigint] NULL,
	[tab] [varchar](16) NULL,
	[SessionID] [uniqueidentifier] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [Display.].[GetProfileDataLog]    Script Date: 4/22/2024 12:52:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Display.].[GetProfileDataLog](
	[GetProfileDataLogID] [int] IDENTITY(1,1) NOT NULL,
	[timestamp] [datetime] NULL,
	[param1] [varchar](max) NULL,
	[param2] [varchar](max) NULL,
	[param3] [varchar](max) NULL,
	[param4] [varchar](max) NULL,
	[param5] [varchar](max) NULL,
	[param6] [varchar](max) NULL,
	[param7] [varchar](max) NULL,
	[param8] [varchar](max) NULL,
	[param9] [varchar](max) NULL,
	[SessionID] [uniqueidentifier] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [Display.].[ModuleMapping]    Script Date: 4/22/2024 12:52:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Display.].[ModuleMapping](
	[PresentationID] [int] NOT NULL,
	[ClassProperty] [varchar](400) NULL,
	[_ClassPropertyID] [bigint] NULL,
	[DisplayModule] [varchar](max) NULL,
	[DataStoredProc] [varchar](max) NULL,
	[Tab] [varchar](16) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [Display.].[TabAlias]    Script Date: 4/22/2024 12:52:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Display.].[TabAlias](
	[PresentationID] [int] NOT NULL,
	[Tab] [varchar](16) NOT NULL,
	[PreferredValue] [varchar](16) NULL,
 CONSTRAINT [PK_Display__TabAlias] PRIMARY KEY CLUSTERED 
(
	[PresentationID] ASC,
	[Tab] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab]) VALUES (5, N'', 1, 1, 0, 0, N'pNetworks')
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab]) VALUES (5, N'', 2, 1, 0, 0, N'data')
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab]) VALUES (6, N'', 1, 1, 0, 0, N'pNetworks')
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab]) VALUES (6, N'', 2, 1, 1, 0, N'data')
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab]) VALUES (6, N'Cluster', 1, 1, 0, 0, N'pNetworks')
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab]) VALUES (6, N'Cluster', 2, 1, 1, 0, N'Cluster')
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab]) VALUES (6, N'Details', 1, 1, 0, 0, N'pNetworks')
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab]) VALUES (6, N'Details', 2, 1, 1, 0, N'data')
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab]) VALUES (6, N'map', 1, 1, 0, 0, N'pNetworks')
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab]) VALUES (6, N'map', 2, 1, 1, 0, N'map')
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab]) VALUES (6, N'Radial', 1, 1, 0, 0, N'pNetworks')
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab]) VALUES (6, N'Radial', 2, 1, 1, 0, N'Cluster')
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab]) VALUES (6, N'timeline', 1, 1, 0, 0, N'pNetworks')
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab]) VALUES (6, N'timeline', 2, 1, 1, 0, N'timeline')
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab]) VALUES (7, N'', 1, 1, 0, 0, N'pNetworks')
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab]) VALUES (7, N'', 2, 1, 1, 0, N'list')
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab]) VALUES (7, N'Details', 1, 1, 0, 0, N'pNetworks')
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab]) VALUES (7, N'Details', 2, 1, 1, 0, N'list')
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab]) VALUES (7, N'Map', 1, 1, 0, 0, N'pNetworks')
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab]) VALUES (7, N'Map', 2, 1, 1, 0, N'map')
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab]) VALUES (8, N'', 1, 1, 0, 0, N'pNetworks')
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab]) VALUES (8, N'', 2, 1, 1, 0, N'cloud')
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab]) VALUES (8, N'categories', 1, 1, 0, 0, N'pNetworks')
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab]) VALUES (8, N'categories', 2, 1, 1, 0, N'cloud')
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab]) VALUES (8, N'Cloud', 1, 1, 0, 0, N'pNetworks')
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab]) VALUES (8, N'Cloud', 2, 1, 1, 0, N'cloud')
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab]) VALUES (8, N'details', 1, 1, 0, 0, N'pNetworks')
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab]) VALUES (8, N'details', 2, 1, 1, 0, N'cloud')
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab]) VALUES (8, N'timeline', 1, 1, 0, 0, N'pNetworks')
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab]) VALUES (8, N'timeline', 2, 1, 1, 0, N'timeline')
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab]) VALUES (9, N'', 1, 1, 1, 1, N'data')
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab]) VALUES (10, N'', 1, 1, 1, 1, N'data')
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab]) VALUES (11, N'', 1, 1, 1, 1, N'data')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (5, N'http://www.w3.org/2000/01/rdf-schema#label', 15, N'Person.GeneralInfo', N'[Display.Module].[Person.GeneralInfo]', N'data')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (5, N'http://vivoweb.org/ontology/core#authorInAuthorship', 94, N'Person.AuthorInAuthorship', N'[Display.Module].[Person.AuthorInAuthorship]', N'data')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (5, N'http://vivoweb.org/ontology/core#overview', 1711, N'Person.Overview', N'[Display.Module].[Literal]', N'data')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (5, N'http://profiles.catalyst.harvard.edu/ontology/prns#coAuthorOf', 349, N'Person.CoAuthors', N'[Display.Module].[Person.Coauthor.Top5]', N'pNetworks')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (5, N'http://vivoweb.org/ontology/core#freetextKeyword', 133, N'Person.FreetextKeyword', N'[Display.Module].[Person.FreetextKeyword]', N'data')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (5, N'http://profiles.catalyst.harvard.edu/ontology/prns#similarTo', 506, N'Person.Similar', N'[Display.Module].[Person.Similar.Top5]', N'pNetworks')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (5, N'http://vivoweb.org/ontology/core#hasResearchArea', 198, N'Person.Concept', N'[Display.Module].[Person.Concept.Top5]', N'pNetworks')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (5, N'http://vivoweb.org/ontology/core#webpage', 53, N'Person.Websites', N'[Display.Module].[Person.Websites]', N'data')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (5, N'http://profiles.catalyst.harvard.edu/ontology/prns#mediaLinks', 413, N'Person.MediaLinks', N'[Display.Module].[Person.MediaLinks]', N'data')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (5, N'http://vivoweb.org/ontology/core#educationalTraining', 1325, N'Person.EducationAndTraining', N'[Display.Module].[Person.EducationAndTraining]', N'data')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (5, N'http://vivoweb.org/ontology/core#awardOrHonor', 205, N'Person.AwardOrHonor', N'[Display.Module].[Person.AwardOrHonor]', N'data')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (5, N'http://profiles.catalyst.harvard.edu/ontology/catalyst#advisorInMentoringCurrentStudentOpportunity', 26, N'Person.CatalystMentoringCurrentStudentOpportunity', N'[Catalyst.Display].[Person.MentoringCurrentStudentOpportunity]', N'data')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (5, N'http://vivoweb.org/ontology/core#hasResearcherRole', 1478, N'Person.ResearcherRole', N'[Display.Module].[Person.ResearcherRole]', N'data')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (5, N'http://profiles.catalyst.harvard.edu/ontology/prns#hasClinicalTrialRole', 194685193, N'Person.ClinicalTrialRole', N'[Display.Module].[Person.ClinicalTrialRole]', N'data')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (5, N'http://profiles.catalyst.harvard.edu/ontology/plugins#FeaturedPresentations', 2055, N'Person.FeaturedPresentations', N'[Display.Module].[GenericRDF.Plugin]', N'data')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (5, N'http://profiles.catalyst.harvard.edu/ontology/plugins#FeaturedVideos', 2057, N'Person.FeaturedVideos', N'[Display.Module].[GenericRDF.Plugin]', N'data')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (5, N'http://profiles.catalyst.harvard.edu/ontology/plugins#Twitter', 2059, N'Person.Twitter', N'[Display.Module].[GenericRDF.Plugin]', N'data')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (6, N'http://profiles.catalyst.harvard.edu/ontology/prns#hasConnection', 371, N'Coauthor.Connection', N'[Display.Module].[Coauthor.Connection]', N'data')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (3, N'http://profiles.catalyst.harvard.edu/ontology/prns#connectionWeight', 357, N'Connection', N'[Display.Module].[Connection]', NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (9, N'http://profiles.catalyst.harvard.edu/ontology/prns#connectionWeight', 357, N'Person.HasCoAuthor.Why', N'[Display.Module].[Person.HasCoAuthor.Why]', N'data')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (10, N'http://profiles.catalyst.harvard.edu/ontology/prns#connectionWeight', 357, N'Person.Similar.Why', N'[Display.Module].[Person.Similar.Why]', N'data')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (11, N'http://profiles.catalyst.harvard.edu/ontology/prns#connectionWeight', 357, N'Person.HasResearchArea.Why', N'[Display.Module].[Person.HasResearchArea.Why]', N'data')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (2, NULL, NULL, N'NetworkList', N'[Display.Module].[NetworkList]', NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (6, NULL, NULL, N'NetworkList', N'[Display.Module].[NetworkList]', NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (7, NULL, NULL, N'NetworkList', N'[Display.Module].[NetworkList]', NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (8, NULL, NULL, N'NetworkList', N'[Display.Module].[NetworkList]', NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (18, NULL, NULL, N'NetworkList', N'[Display.Module].[NetworkList]', NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (6, NULL, NULL, N'Coauthor.Map', N'[Display.Module].[Coauthor.Map]', N'map')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (6, NULL, NULL, N'Coauthor.Cluster', N'[Display.Module].[Coauthor.Cluster]', N'radial')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (6, NULL, NULL, N'Coauthor.Cluster', N'[Display.Module].[Coauthor.Cluster]', N'cluster')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (6, NULL, NULL, N'Coauthor.Timeline', N'[Display.Module].[Coauthor.Timeline]', N'timeline')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (7, NULL, NULL, N'SimilarPeople.Connection', N'[Display.Module].[SimilarPeople.Connection]', N'list')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (7, NULL, NULL, N'CoauthorSimilar.Map', N'[Display.Module].[CoauthorSimilar.Map]', N'map')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (7, NULL, NULL, N'SimilarPeople.Connection', N'[Display.Module].[SimilarPeople.Connection]', N'details')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (8, NULL, NULL, N'Person.HasResearchArea', N'[Display.Module].[Person.HasResearchArea]', N'cloud')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (8, NULL, NULL, N'NetworkList', N'[Display.Module].[NetworkList]', N'categories')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (8, NULL, NULL, N'Person.HasResearchArea.Timeline', N'[Display.Module].[Person.HasResearchArea.Timeline]', N'timeline')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (8, NULL, NULL, N'NetworkList', N'[Display.Module].[NetworkList]', N'details')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (1, N'http://www.w3.org/2000/01/rdf-schema#label', 15, N'Profile', N'[Display.Module].[Profile]', NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (4, N'http://www.w3.org/2000/01/rdf-schema#label', 15, N'Profile', N'[Display.Module].[Profile]', NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (13, N'http://www.w3.org/2000/01/rdf-schema#label', 15, N'Profile', N'[Display.Module].[Profile]', NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (14, N'http://www.w3.org/2000/01/rdf-schema#label', 15, N'Profile', N'[Display.Module].[Profile]', NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (15, N'http://www.w3.org/2000/01/rdf-schema#label', 15, N'Profile', N'[Display.Module].[Profile]', NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (16, N'http://www.w3.org/2000/01/rdf-schema#label', 15, N'Profile', N'[Display.Module].[Profile]', NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (17, N'http://www.w3.org/2000/01/rdf-schema#label', 15, N'Profile', N'[Display.Module].[Profile]', NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab]) VALUES (5, N'http://www.w3.org/2000/01/rdf-schema#label', 15, N'Person.Label', N'[Display.Module].[Person.Label]', N'pNetworks')
GO
INSERT [Display.].[TabAlias] ([PresentationID], [Tab], [PreferredValue]) VALUES (6, N'list', NULL)
GO
INSERT [Display.].[TabAlias] ([PresentationID], [Tab], [PreferredValue]) VALUES (7, N'list', NULL)
GO
/****** Object:  StoredProcedure [Display.].[GetActivity]    Script Date: 4/22/2024 12:52:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.].[GetActivity]
	@count int = 3,
	@lastActivityLogID int = -1
AS
BEGIN
		declare @relativeBasePath varchar(max)
		select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'


		if @lastActivityLogID < 0
		BEGIN
		SELECT i.activityLogID,
			p.personid,n.nodeid,p.firstname,p.lastname, @relativeBasePath + isnull(defaultApplication, '') + PreferredPath as URL,
            i.methodName,i.property,cp._PropertyLabel as propertyLabel,i.param1,i.param2,i.createdDT, g.JournalTitle, fa.AgreementLabel, gg.GroupName
            FROM [Framework.].[Log.Activity] i 
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
            order by i.activityLogID desc offset 0 ROWS FETCH NEXT @count ROWS ONLY for json path
		END 

		else
		BEGIN
		SELECT i.activityLogID,
			p.personid,n.nodeid,p.firstname,p.lastname, @relativeBasePath + isnull(defaultApplication, '') + PreferredPath as URL,
            i.methodName,i.property,cp._PropertyLabel as propertyLabel,i.param1,i.param2,i.createdDT, g.JournalTitle, fa.AgreementLabel, gg.GroupName
            FROM [Framework.].[Log.Activity] i 
            LEFT OUTER JOIN [Profile.Cache].[Person] p ON i.personId = p.personID
            LEFT OUTER JOIN [RDF.Stage].internalnodemap n on n.internalid = p.personId and n.[class] = 'http://xmlns.com/foaf/0.1/Person' 
            LEFT OUTER JOIN [Ontology.].[ClassProperty] cp ON cp.Property = i.property  and cp.Class = 'http://xmlns.com/foaf/0.1/Person' 
            LEFT OUTER JOIN [RDF.].[Node] rn on [RDF.].fnValueHash(null, null, i.property) = rn.ValueHash 
            LEFT OUTER JOIN [RDF.Security].[NodeProperty] np on n.NodeID = np.NodeID and rn.NodeID = np.Property
			LEFT OUTER JOIN [Profile.Data].[Publication.PubMed.General] g on i.param1 in ('PMID', 'Add PMID') and param2 = cast(g.PMID as varchar(50))
			LEFT OUTER JOIN [Profile.Data].[Funding.Role] fr on i.property = 'http://vivoweb.org/ontology/core#ResearcherRole' and i.param1 = FundingRoleID LEFT OUTER JOIN [Profile.Data].[Funding.Agreement] fa on fr.FundingAgreementID = fa.FundingAgreementID
			LEFT OUTER JOIN [Profile.Data].[vwGroup.General] gg on i.param1 = cast(gg.GroupID as varchar(50))
            where p.IsActive=1 and (np.ViewSecurityGroup = -1 or (i.privacyCode = -1 and np.ViewSecurityGroup is null) or (i.privacyCode is null and np.ViewSecurityGroup is null))
            and i.activityLogID < @lastActivityLogID
            order by i.activityLogID desc offset 0 ROWS FETCH NEXT @count ROWS ONLY for json path
		END 
END

GO
/****** Object:  StoredProcedure [Display.].[GetDataRDF]    Script Date: 4/22/2024 12:52:32 PM ******/
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
	--TODO CONVERT [RDF.Security].[GetSessionSecurityGroupNodes] to function and add back into GetDataRDF




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
/****** Object:  StoredProcedure [Display.].[GetDataURLs]    Script Date: 4/22/2024 12:52:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.].[GetDataURLs]
	@subject bigint = null,
	@predicate bigint = null,
	@object bigint = null,
	@tab varchar(max) = null
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

	select 1 as ValidURL, cast(@PresentationID as varchar(50)) as PresentationType, @tab as tab, 0 as Redirect, '' as RedirectURL, @dataURLs as dataURLs
END
GO
/****** Object:  StoredProcedure [Display.].[GetJson]    Script Date: 4/22/2024 12:52:32 PM ******/
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

	IF @PresentationType = 'P'
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

	
		insert into #dataModules (DataStoredProc, subject, predicate, tagname, DisplayModule, object, oValue)
		select DataStoredProc, isnull(subject, @subject), predicate, tagname, DisplayModule, object, Value from [Display.].ModuleMapping a
			join #rdf b
			on a.PresentationID = @PresentationID
			and a._ClassPropertyID = b.predicate
			and b.SortOrder = 1 --This should be handled at source
			and isnull(a.tab, '') = isnull(@tab, '')
	END
	ELSE IF @PresentationType in ('N', 'C')
	BEGIN
		insert into #dataModules (DataStoredProc, subject, predicate, tagname, DisplayModule, object, oValue)
		select DataStoredProc, @subject, @predicate, '', DisplayModule, @object, null from [Display.].ModuleMapping a
			where a.PresentationID = @PresentationID
			and isnull(a.tab, '') = isnull(@tab, '')
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

	--select * from #dataModules
	--select *, JSON_QUERY(json, '$.module_data')as module_data from #dataModules
	Select DisplayModule, JSON_QUERY(json, '$.module_data')as ModuleData from #dataModules for json path
END
GO
/****** Object:  StoredProcedure [Display.].[GetPageParams]    Script Date: 4/22/2024 12:52:32 PM ******/
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
		select 0 as ValidURL, 0 as PresentationType, '' as tab, 0 as Redirect, '' as RedirectURL, '' as dataURLs
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
		select 1 as ValidURL, 0 as PresentationType, @tab as tab, 1 as Redirect, @redirectURL as RedirectURL, '' as dataURLs
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
			select 1 as ValidURL, 0 as PresentationType, @tab as tab, 1 as Redirect, @redirectURL as RedirectURL, '' as dataURLs
			RETURN
		END
		ELSE IF (@subjectPreferred = 0 OR @predicatePreferred = 0 OR @objectPreferred = 0)
		BEGIN

			select @redirectURL = isnull((select '/' + case when DefaultApplication <> '' then DefaultApplication + '/' else '' end + case when AliasType <> '' then  AliasType  + '/' else '' end  + '/' + AliasID from [RDF.].Alias where NodeID = @subject and Preferred = 1) , '/display/' + cast(@subject as varchar(50))) 
								+ isnull('/' + isnull((select case when AliasType <> '' then  AliasType  + '/' else '' end + AliasID from [RDF.].Alias where NodeID = @predicate and Preferred = 1), cast(@predicate as varchar(50))), '') 
								+ isnull('/' + isnull((select case when AliasType <> '' then  AliasType  + '/' else '' end + AliasID from [RDF.].Alias where NodeID = @object and Preferred = 1), cast(@object as varchar(50))), '')
			select 1 as ValidURL, 0 as PresentationType, @tab as tab, 1 as Redirect, @redirectURL as RedirectURL, '' as dataURLs
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

	select 1 as ValidURL, cast(@PresentationID as varchar(50)) as PresentationType, @tab as tab, 0 as Redirect, '' as RedirectURL, @dataURLs as dataURLs
END



GO
/****** Object:  StoredProcedure [Display.].[GetProfileData]    Script Date: 4/22/2024 12:52:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.].[GetProfileData]
	@param1 varchar(max) = null,
	@param2 varchar(max) = null,
	@param3 varchar(max) = null,
	@param4 varchar(max) = null,
	@param5 varchar(max) = null,
	@param6 varchar(max) = null,
	@param7 varchar(max) = null,
	@param8 varchar(max) = null,
	@param9 varchar(max) = null,
	@SessionID  UNIQUEIDENTIFIER = NULL
AS
BEGIN

	DECLARE @subject bigint = null, @predicate bigint = null, @object bigint = null
	DECLARE @subjectPreferred bit = 1, @predicatePreferred bit = 1, @objectPreferred bit = 1
	DECLARE @ErrorDescription varchar(max)

	
	-- Load param values into a table
	DECLARE @params TABLE (id int, val varchar(1000))

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
			select @subjectPreferred = ISNULL((select 0 from [RDF.].Alias where NodeID = @subject and Preferred = 1), 1)
		IF @subject IS NULL AND @MaxParam > @pointer
			SELECT @subject = NodeID, @subjectPreferred = Preferred, @pointer = @pointer + 2, @aliases = @aliases + 1
				FROM [RDF.].Alias 
				WHERE AliasType = (SELECT val FROM @params WHERE id = @pointer)
					AND AliasID = (SELECT val FROM @params WHERE id = @pointer+1)
		IF @subject IS NULL
			SELECT @subject = NodeID, @subjectPreferred = Preferred, @pointer = @pointer + 1, @aliases = @aliases + 1
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

	
	-------------------------------------------------------------------------------
	-- Redirect if this is not the preferred URL
	-------------------------------------------------------------------------------

	if (@subjectPreferred = 0 OR @predicatePreferred = 0 OR @objectPreferred = 0 AND @Tab is null)
	BEGIN
		declare @redirectURL varchar(max) 
		select @redirectURL = isnull((select AliasType  + '/' + AliasID from [RDF.].Alias where NodeID = @subject and Preferred = 1) , cast(@subject as varchar(50))) 
							+ isnull('/' + isnull((select AliasType  + '/' + AliasID from [RDF.].Alias where NodeID = @predicate and Preferred = 1), cast(@predicate as varchar(50))), '') 
							+ isnull('/' + isnull((select AliasType  + '/' + AliasID from [RDF.].Alias where NodeID = @object and Preferred = 1), cast(@object as varchar(50))), '')
		Select @redirectURL as PreferredURL for json path
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
		IF EXISTS (select 1 from [Display.].[TabAlias] where PresentationID = @PresentationID AND tab = @Tab)
		BEGIN
			declare @redirectURL2 varchar(max) 
			select @redirectURL2 = isnull((select AliasType  + '/' + AliasID from [RDF.].Alias where NodeID = @subject and Preferred = 1) , cast(@subject as varchar(50))) 
								+ isnull('/' + isnull((select AliasType  + '/' + AliasID from [RDF.].Alias where NodeID = @predicate and Preferred = 1), cast(@predicate as varchar(50))), '') 
								+ isnull('/' + isnull((select AliasType  + '/' + AliasID from [RDF.].Alias where NodeID = @object and Preferred = 1), cast(@object as varchar(50))), '')
								+ isnull('/' + (select PreferredValue from [Display.].[TabAlias] where PresentationID = @PresentationID AND tab = @Tab), '')
			Select @redirectURL2 as PreferredURL for json path
			RETURN
		END
	END


	-------------------------------------------------------------------------------
	-- Return the URLs for data
	-------------------------------------------------------------------------------
	if exists (select 1 from [Display.].[DataPath] where PresentationID = @PresentationID and tab = isnull(@tab, ''))
	BEGIN
		select Case when subject = 1 then isnull((select AliasType  + '/' + AliasID from [RDF.].Alias where NodeID = @subject and Preferred = 1) , cast(@subject as varchar(50))) else '' end
				+ Case when predicate = 1 then isnull('/' + isnull((select AliasType  + '/' + AliasID from [RDF.].Alias where NodeID = @predicate and Preferred = 1), cast(@predicate as varchar(50))), '') else '' end
				+ case when object = 1 then isnull('/' + isnull((select AliasType  + '/' + AliasID from [RDF.].Alias where NodeID = @object and Preferred = 1), cast(@object as varchar(50))), '') else '' end
				+ isnull('/' + dataTab, '') as DataPath
			from [Display.].[DataPath] where PresentationID = @PresentationID and tab = isnull(@tab, '')
			for json path
			return
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
	--ALTER TABLE #dataModules ADD CONSTRAINT aa CHECK(ISJSON(json)=1);
	
	insert into #dataModules (DataStoredProc, subject, predicate, tagname, DisplayModule, object, oValue)
	select DataStoredProc, subject, predicate, tagname, DisplayModule, object, Value from [Display.].ModuleMapping a
		join #rdf b
		on a.PresentationID = @PresentationID
		and a._ClassPropertyID = b.predicate
		and b.SortOrder = 1 --This should be handled at source
		and a.tab = isnull(@tab, a.tab)
--	select * from #rdf
--	select @PresentationID

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
		exec @DataStoredProc @subject=@subject1, @predicate=@predicate1, @tagname=@tagname, @object=@object1, @oValue=@oValue, @json=@json output
		update #dataModules set json = @json where i = @dmi
	END

	--select *, JSON_QUERY(json, '$.module_data')as module_data from #dataModules
	Select DisplayModule, JSON_QUERY(json, '$.module_data')as ModuleData from #dataModules for json path
END
GO
/****** Object:  StoredProcedure [Display.].[GetProfileData2]    Script Date: 4/22/2024 12:52:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.].[GetProfileData2]
	@param1 varchar(max) = null,
	@param2 varchar(max) = null,
	@param3 varchar(max) = null,
	@param4 varchar(max) = null,
	@param5 varchar(max) = null,
	@param6 varchar(max) = null,
	@param7 varchar(max) = null,
	@param8 varchar(max) = null,
	@param9 varchar(max) = null,
	@SessionID  UNIQUEIDENTIFIER = NULL
AS
BEGIN
	DECLARE @subject bigint = null, @predicate bigint = null, @object bigint = null
	DECLARE @ErrorDescription varchar(max)

	
	-- Load param values into a table
	DECLARE @params TABLE (id int, val varchar(1000))

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


	DECLARE @MaxParam int
	SELECT @MaxParam = 0
	SELECT @MaxParam = MAX(id) FROM @params WHERE isnull(val, '') > ''

	DECLARE @Tab VARCHAR(1000)
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
		IF @subject IS NULL AND @MaxParam > @pointer
			SELECT @subject = NodeID, @pointer = @pointer + 2, @aliases = @aliases + 1
				FROM [RDF.].Alias 
				WHERE AliasType = (SELECT val FROM @params WHERE id = @pointer)
					AND AliasID = (SELECT val FROM @params WHERE id = @pointer+1)
		IF @subject IS NULL
			SELECT @subject = NodeID, @pointer = @pointer + 1, @aliases = @aliases + 1
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
		IF @predicate IS NULL AND @MaxParam > @pointer
			SELECT @predicate = NodeID, @pointer = @pointer + 2, @aliases = @aliases + 1
				FROM [RDF.].Alias 
				WHERE AliasType = (SELECT val FROM @params WHERE id = @pointer)
					AND AliasID = (SELECT val FROM @params WHERE id = @pointer+1)
		IF @predicate IS NULL
			SELECT @predicate = NodeID, @pointer = @pointer + 1, @aliases = @aliases + 1
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
		IF @object IS NULL AND @MaxParam > @pointer
			SELECT @object = NodeID, @pointer = @pointer + 2, @aliases = @aliases + 1
				FROM [RDF.].Alias 
				WHERE AliasType = (SELECT val FROM @params WHERE id = @pointer)
					AND AliasID = (SELECT val FROM @params WHERE id = @pointer+1)
		IF @object IS NULL
			SELECT @object = NodeID, @pointer = @pointer + 1, @aliases = @aliases + 1
				FROM [RDF.].Alias 
				WHERE AliasType = ''
					AND AliasID = (SELECT val FROM @params WHERE id = @pointer)
		IF @object IS NULL AND @MaxParam = @pointer
			SELECT @Tab=(SELECT val FROM @params WHERE id = @pointer)
		IF @object IS NULL AND @Tab IS NULL
			SELECT @ErrorDescription = 'The object cannot be found.'
	END
	
	-- tab
	IF (@MaxParam = @pointer) AND (@object IS NOT NULL) AND (@Tab IS NULL)
		SELECT @Tab=(SELECT val FROM @params WHERE id = @pointer)


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
	exec [Display.].[GetDataRDF] @subject=@subject,@predicate=@predicate,@object=@object,@SessionID=@SessionID,@Expand=0

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
	ALTER TABLE #dataModules ADD CONSTRAINT aa CHECK(ISJSON(json)=1);
	
	insert into #dataModules (DataStoredProc, subject, predicate, tagname, DisplayModule, object, oValue)
	select DataStoredProc, subject, predicate, tagname, DisplayModule, object, Value from [Display.].ModuleMapping a
		join #rdf b
		on a.PresentationID = @PresentationID
		and a._ClassPropertyID = b.predicate
		and b.SortOrder = 1 --This should be handled at source
--	select * from #rdf
--	select @PresentationID

	declare @DataStoredProc varchar(max), @subject1 bigint, @predicate1 bigint, @tagname varchar(max), @object1 bigint, @oValue varchar(max), @json nvarchar(max)

	declare @dmi int = 0
	while (1=1)
	BEGIN
		select top 1 @dmi=i, @DataStoredProc=DataStoredProc, @subject1=subject, @predicate1=predicate, @tagname=tagname, @object1=object, @oValue=oValue 
			from #dataModules where i > @dmi order by i
		if @@ROWCOUNT=0 BREAK
		exec @DataStoredProc @subject=@subject1, @predicate=@predicate1, @tagname=@tagname, @object=@object1, @oValue=@oValue, @json=@json output
		update #dataModules set json = @json where i = @dmi
	END

	--select *, JSON_QUERY(json, '$.module_data')as module_data from #dataModules
	Select DisplayModule, JSON_QUERY(json, '$.module_data')as ModuleData from #dataModules for json path
END
GO
/****** Object:  StoredProcedure [Display.].[Search.Params]    Script Date: 4/22/2024 12:52:32 PM ******/
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
/****** Object:  StoredProcedure [Display.].[SearchEverything]    Script Date: 4/22/2024 12:52:32 PM ******/
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


		declare @filterLabels table (Class varchar(255), _NodeID bigint, Label varchar(255), pluralLabel varchar(max))
		insert into @filterLabels values('http://profiles.catalyst.harvard.edu/ontology/catalyst#MentoringCompletedStudentProject', 38, 'Mentoring - Completed Student Project', 'Mentoring')
		insert into @filterLabels values('http://vivoweb.org/ontology/core#Grant', 47, 'Grant', 'Grants')
		insert into @filterLabels values('http://xmlns.com/foaf/0.1/Person', 67, 'Person', 'People')
		insert into @filterLabels values('http://purl.org/ontology/bibo/Document', 76, 'Academic Article', 'Research')
		insert into @filterLabels values('http://vivoweb.org/ontology/core#AwardReceipt', 223, 'Award or Honor Receipt', 'Awards')
		insert into @filterLabels values('http://www.w3.org/2004/02/skos/core#Concept', 2001, 'Concept', 'Concepts')


		update a set a.type = b.object from #t a join [RDF.].Triple b on a.NodeID = b.Subject and b.Predicate = [RDF.].[fnURI2NodeID]('http://www.w3.org/1999/02/22-rdf-syntax-ns#type')

		declare @filters table(type bigint, [count] int, label varchar(255))
		insert into @filters(type, [count])
		select type, count(*) as c from #t group by type
		update a set a.Label = b.pluralLabel from @filters a join @filterLabels b on a.type = b._NodeID
		
		delete from #t where type not in (select _NodeID from @filterLabels)
		delete from @filters where label is null

		insert into @filters (type, [count], label) select 0, count(*), 'All' from #t

		delete from #t where SortOrder < @Offset
		delete from #t where SortOrder > @Offset + @count

		update a set a.ClassLabel = b.Label from #t a join @filterLabels b on a.type = _NodeID

		declare @labelNodeID bigint 
		select @labelNodeID	= [RDF.].[fnURI2NodeID]('http://www.w3.org/2000/01/rdf-schema#label')
		update a set a.Label = n.value from #t a join [RDF.].Triple t on a.NodeID = t.Subject and t.Predicate = @labelNodeID join [RDF.].Node n on t.Object = n.NodeID


		select JSON_QUERY(@json, '$') as SearchQuery, (select * from @filters for json Path) as Filters, (select NodeID, Weight, Label,ClassLabel from #t for JSON Path) as Results for json path, WITHOUT_ARRAY_WRAPPER
END
GO
/****** Object:  StoredProcedure [Display.].[SearchPeople]    Script Date: 4/22/2024 12:52:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


Create PROCEDURE [Display.].[SearchPeople]
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
			select @DepartmentExcept = case when @InstitutionExcept = 'false' then '0' else '1' end
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
		else 

		delete from @t where SortOrder < @Offset
		delete from @t where SortOrder > @Offset + @count



		declare @relativeBasePath varchar(max)
		select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'

		select JSON_QUERY(@json, '$') as SearchQuery, @resultCount [Count], (select DepartmentName, DisplayName, FacultyRank, InstitutionName, p.NodeID, PersonID, @relativeBasePath + isnull(defaultApplication, '') + PreferredPath as URL, Weight   from @t t join [Profile.Cache].Person p on t.nodeid = p.nodeID for JSON Path) as People for json path, WITHOUT_ARRAY_WRAPPER

END
GO
/****** Object:  StoredProcedure [Display.].[SearchWhy]    Script Date: 4/22/2024 12:52:32 PM ******/
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
			select @DepartmentExcept = case when @InstitutionExcept = 'false' then '0' else '1' end
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
/****** Object:  StoredProcedure [Display.Module].[Coauthor.Cluster]    Script Date: 4/22/2024 12:52:32 PM ******/
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
/****** Object:  StoredProcedure [Display.Module].[Coauthor.Connection]    Script Date: 4/22/2024 12:52:32 PM ******/
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
	declare @SubjectPath varchar(max)
	select @personID = PersonID, @SubjectPath = isnull('/' + DefaultApplication, '') + PreferredPath from [Profile.Cache].Person where NodeID = @Subject
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
	update t set t.name = isnull(LastName, '') + isnull(', ' + firstname, ''), DisplayName = p.DisplayName, URL=isnull('/' + DefaultApplication, '') + PreferredPath, WhyPath = @SubjectPath + @PredicatePath + PreferredPath from #tmpCoauthors t join [Profile.Cache].Person p on t.PersonID2 = p.PersonID
	select @json = (select Name, DisplayName, URL, w as [Weight], n as [Count], LastPubYear, WhyPath from #tmpCoauthors for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[Coauthor.Map]    Script Date: 4/22/2024 12:52:32 PM ******/
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
	declare @personID int
	select @personID = [RDF.].[fnNodeID2PersonID](@Subject)

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
				isnull('/' + p.DefaultApplication, '') + p.PreferredPath
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
/****** Object:  StoredProcedure [Display.Module].[Coauthor.Timeline]    Script Date: 4/22/2024 12:52:32 PM ******/
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
/****** Object:  StoredProcedure [Display.Module].[CoauthorSimilar.Map]    Script Date: 4/22/2024 12:52:32 PM ******/
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
	select @personID = [RDF.].[fnNodeID2PersonID](@Subject)

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
		insert into @f (PersonID) Values (@personID)
		insert into @f (PersonID) 
			SELECT SimilarPersonID FROM [Profile.Cache].[Person.SimilarPerson] WHERE PersonID = @PersonID
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
/****** Object:  StoredProcedure [Display.Module].[Connection]    Script Date: 4/22/2024 12:52:32 PM ******/
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
/****** Object:  StoredProcedure [Display.Module].[GenericRDF.Plugin]    Script Date: 4/22/2024 12:52:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[GenericRDF.Plugin]
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


END
GO
/****** Object:  StoredProcedure [Display.Module].[Literal]    Script Date: 4/22/2024 12:52:32 PM ******/
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
/****** Object:  StoredProcedure [Display.Module].[NetworkList]    Script Date: 4/22/2024 12:52:32 PM ******/
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
/****** Object:  StoredProcedure [Display.Module].[Person.AuthorInAuthorship]    Script Date: 4/22/2024 12:52:32 PM ******/
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
	declare @publications nvarchar(max), @timeline nvarchar(max), @fieldSummary nvarchar(max), @pubsCount int, @personID int
	select @personID = [RDF.].[fnNodeID2PersonID](@Subject)
	select @pubsCount = count(*) from [Profile.Data].[Publication.Entity.Authorship] where IsActive = 1 and personID = @personID
	select @publications = [Display.Module].[FnCustomViewAuthorInAuthorship.GetList](@personID, null, @count, 'N')
	select @timeline = [Display.Module].[FnNetworkAuthorshipTimeline.Person.GetData](@subject,0)
	select @fieldSummary = [Display.Module].[FnCustomViewAuthorInAuthorship.GetJournalHeadings](@subject, @personID, null)

	--select @json = (select @publications Publications for json path, ROOT ('module_data'))
	select @json = (select @pubsCount as PublicationsCount, JSON_QUERY(@publications, '$.Publications')as Publications, JSON_QUERY(@timeline, '$.Timeline')as Timeline, JSON_QUERY(@fieldSummary, '$.FieldSummary')as FieldSummary for json path, ROOT ('module_data'))
	--Select DisplayModule, JSON_QUERY(json, '$.module_data')as ModuleData from #dataModules for json path
	 --select @json = [Display.Module].[FnCustomViewAuthorInAuthorship.GetList](@subject, null)
END
GO
/****** Object:  StoredProcedure [Display.Module].[Person.AwardOrHonor]    Script Date: 4/22/2024 12:52:32 PM ******/
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
/****** Object:  StoredProcedure [Display.Module].[Person.ClinicalTrialRole]    Script Date: 4/22/2024 12:52:32 PM ******/
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
/****** Object:  StoredProcedure [Display.Module].[Person.Coauthor.Top5]    Script Date: 4/22/2024 12:52:32 PM ******/
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

	create table #tmpCoauthors(personID int, name varchar(255), URL varchar(max), sort int Identity (1,1))
	insert into #tmpCoauthors(personID) select top 5 PersonID2 from [Profile.Cache].[SNA.Coauthor] where PersonID1 = @personID order by w desc
	update t set t.name = isnull(LastName, '') + isnull(', ' + firstname, ''),URL = DefaultApplication + PreferredPath from #tmpCoauthors t join [Profile.Cache].Person p on t.personID = p.PersonID

	select @json = (select Name Label, URL, Sort from #tmpCoauthors for json path, ROOT ('Connections'))
	select @json = (Select 'Co-Authors' Title, @ExploreLink ExploreLink, @Count [Count], JSON_QUERY(@json, '$.Connections')as Connections  for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[Person.Concept.Top5]    Script Date: 4/22/2024 12:52:32 PM ******/
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
	select @count = count (*) from [Profile.Cache].[Concept.Mesh.Person] where personID = @personID


	select @json = (select top 5 MeshHeader as Label, @relativeBasePath + isnull(DefaultApplication, '') + URL URL, ROW_NUMBER() OVER (ORDER BY Weight desc) Sort from [Profile.Cache].[Concept.Mesh.Person] p  join [Profile.Cache].[Concept.Mesh.URL] u on p.MeshHeader = u.DescriptorName
			where personID = @PersonID
			ORDER by weight desc for json path, ROOT ('Connections'))
	select @json = (Select 'Concepts' Title, @ExploreLink ExploreLink, @Count [Count], JSON_QUERY(@json, '$.Connections')as Connections  for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[Person.EducationAndTraining]    Script Date: 4/22/2024 12:52:32 PM ******/
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
/****** Object:  StoredProcedure [Display.Module].[Person.FreetextKeyword]    Script Date: 4/22/2024 12:52:32 PM ******/
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
/****** Object:  StoredProcedure [Display.Module].[Person.GeneralInfo]    Script Date: 4/22/2024 12:52:32 PM ******/
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
	declare @personID int
	select @personID = personID from [Profile.Cache].Person where NodeID =@Subject
	declare @a nvarchar(max)
	select @a = (Select SortOrder, Title, InstititutionName as InstitutionName, DepartmentName, DivisionName, FacultyRank from [Profile.Cache].[Person.Affiliation] where personID = @PersonID for JSON path, Root ('Affiliation'))
	select @json = (Select FirstName, LastName, DisplayName, AddressLine1, AddressLine2, AddressLine3, AddressLine4, Phone, Fax, JSON_QUERY(@a, '$.Affiliation')as Affiliation from [Profile.Cache].Person where personID = @personID for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[Person.HasCoAuthor.Why]    Script Date: 4/22/2024 12:52:32 PM ******/
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
						@Name2 Name2, @displayName2 DisplayName2, @relativeBasePath + isnull(@PersonDefaultApplication2, '') + @PersonPreferredPath2 as PersonURL2, Round(@weight, 3) Weight,
							 (select a.PMID, b.PMCID, b.DOI, c.AuthorsString, b.Reference, Round(a.w, 2) as Weight from #pmids a
									join [Profile.Data].[Publication.Entity.InformationResource] b on a.pmid = b.pmid
									join [Profile.Data].[Publication.Entity.Authorship] c on b.EntityID = c.InformationResourceID and c.PersonID = @PersonID
									for json path) Publications
							for json path, WITHOUT_ARRAY_WRAPPER)
	select @json = (select JSON_QUERY(@json, '$') as module_data for json path, WITHOUT_ARRAY_WRAPPER)
END
GO
/****** Object:  StoredProcedure [Display.Module].[Person.HasResearchArea]    Script Date: 4/22/2024 12:52:32 PM ******/
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
			select top 1000 MeshHeader as Name, NumPubsThis, NumPubsAll, [Weight], NTILE(5) OVER (ORDER BY p.weight) CloudSize, LastPublicationYear LastPubYear, SemanticGroupName, @relativeBasePath + isnull(DefaultApplication, '') + URL URL, @relativeBasePath + @PersonPerferredPath + '/Network/ResearchAreas' + URL WhyURL from [Profile.Cache].[Concept.Mesh.Person] p  join [Profile.Cache].[Concept.Mesh.URL] u on p.MeshHeader = u.DescriptorName
			join [Profile.Data].[Concept.Mesh.SemanticGroup] g on u.DescriptorUI = g.[DescriptorUI]
			where personID = @PersonID
		 for json path, root('module_data'))
END
GO
/****** Object:  StoredProcedure [Display.Module].[Person.HasResearchArea.Timeline]    Script Date: 4/22/2024 12:52:32 PM ******/
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
/****** Object:  StoredProcedure [Display.Module].[Person.HasResearchArea.Why]    Script Date: 4/22/2024 12:52:32 PM ******/
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

	select @json = (select @personID PersonID, @Name Name, @displayName DisplayName, @relativeBasePath + isnull(@PersonDefaultApplication, '') + @PersonPreferredPath as PersonURL, @MeshHeader Concept, @relativeBasePath + isnull(@ConceptDefaultApplication, '') + @ConceptPreferredPath as ConceptURL, Round(@weight, 3) Weight,
							 (select a.PMID, b.PMCID, b.DOI, c.AuthorsString, b.Reference, Round(a.MeshWeight, 3) as Weight from [Profile.Cache].[Concept.Mesh.PersonPublication] a
									join [Profile.Data].[Publication.Entity.InformationResource] b on a.pmid = b.pmid
									join [Profile.Data].[Publication.Entity.Authorship] c on b.EntityID = c.InformationResourceID and c.PersonID = @PersonID
									where a.personID = @PersonID and MeshHeader = @MeshHeader for json path) Publications
							for json path, WITHOUT_ARRAY_WRAPPER)
	select @json = (select JSON_QUERY(@json, '$') as module_data for json path, WITHOUT_ARRAY_WRAPPER)
END
GO
/****** Object:  StoredProcedure [Display.Module].[Person.Label]    Script Date: 4/22/2024 12:52:32 PM ******/
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
	select @json = (Select FirstName, LastName, DisplayName, DefaultApplication + PreferredPath as PreferredPath from [Profile.Cache].Person where NodeID = @subject for json path, ROOT ('module_data'))
END
GO
/****** Object:  StoredProcedure [Profile.Cache].[Person.UpdatePreferredPath]    Script Date: 4/22/2024 12:52:32 PM ******/
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


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [Profile.Cache].[Concept.Mesh.URL](
	[DescriptorName] [varchar](255) NOT NULL,
	[NodeID] [bigint] NULL,
	[DescriptorUI] [varchar](10) NOT NULL,
	[URL] [varchar](553) NULL,
	[DefaultApplication] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[DescriptorName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


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

	select @json = (select top 5 isnull(LastName, '') + isnull(', ' + firstname, '') Label, @relativeBasePath + isnull(DefaultApplication, '') + PreferredPath URL, ROW_NUMBER() OVER (ORDER BY Weight desc) Sort 
		from [Profile.Cache].[Person.SimilarPerson] a join [Profile.Cache].Person b on a.SimilarPersonID = b.PersonID and a.PersonID = @PersonID order by Weight desc for json path, ROOT ('Connections'))
	select @json = (Select 'Similar People' Title, @ExploreLink ExploreLink, @Count [Count], JSON_QUERY(@json, '$.Connections')as Connections  for json path, ROOT ('module_data'))
END
GO

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
	declare @SubjectPath varchar(max)
	select @personID = PersonID, @SubjectPath = isnull(DefaultApplication, '') + PreferredPath from [Profile.Cache].Person where NodeID = @Subject
	declare @PredicatePath varchar(max)
	select @PredicatePath = isnull((select '/' + AliasType + '/' + AliasID from [RDF.].Alias where NodeID = @Predicate), '/' + cast(@predicate as varchar(50)))

	declare @relativeBasePath varchar(100)
	select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'


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


exec [Profile.Cache].[Person.UpdatePreferredPath]

insert into [Framework.].Parameter (ParameterID, Value) values ('relativeBasePath', '')

 insert into [Profile.Cache].[Concept.Mesh.URL]([DescriptorName],[NodeID],[DescriptorUI],[URL],[DefaultApplication])
  select DescriptorName, NodeID, DescriptorUI, '/Profile/' + cast(nodeID as varchar(50)), '/display' from [Profile.Data].[Concept.Mesh.Descriptor] a join [RDF.Stage].InternalNodeMap b on a.DescriptorUI = b.InternalID

  update a set a._classPropertyID = b.nodeID from [Display.].[ModuleMapping] a join [RDF.].Node b on [RDF.].fnValueHash(null, null, a.ClassProperty) = b.ValueHash