/*
Run this script on:

        Profiles 3.0.0   -  This database will be modified

to synchronize it with:

        Profiles 3.1.0

You are recommended to back up your database before running this script

Details of which objects have changed can be found in the release notes.
If you have made changes to existing tables or stored procedures in profiles, you may need to merge changes individually. 

*/

DROP INDEX [idx_PublicationEntityAuthorshipIsActive] ON [Profile.Data].[Publication.Entity.Authorship];
ALTER TABLE [Profile.Data].[Publication.Entity.Authorship] ALTER COLUMN [EntityName] NVARCHAR(4000)
ALTER TABLE [Profile.Data].[Publication.Entity.Authorship] ADD [AuthorsString] VARCHAR (MAX)
DBCC CLEANTABLE (0,'[Profile.Data].[Publication.Entity.Authorship]');  
CREATE NONCLUSTERED INDEX [idx_PublicationEntityAuthorshipIsActive] ON [Profile.Data].[Publication.Entity.Authorship] 
	([IsActive] ASC) INCLUDE ( [EntityID],[EntityName],[EntityDate],[authorPosition],[authorRank],[PersonID],[numberOfAuthors],[authorWeight],[YearWeight],[InformationResourceID])
GO


DROP INDEX [idx_PublicationEntityInformationResourceIsActive] ON [Profile.Data].[Publication.Entity.InformationResource] 
ALTER TABLE [Profile.Data].[Publication.Entity.InformationResource] ADD [doi] VARCHAR (100)
ALTER TABLE [Profile.Data].[Publication.Entity.InformationResource] ALTER COLUMN [EntityName] NVARCHAR (4000)
ALTER TABLE [Profile.Data].[Publication.Entity.InformationResource] ALTER COLUMN [EntityDate] DATETIME
ALTER TABLE [Profile.Data].[Publication.Entity.InformationResource] ALTER COLUMN [Reference]  NVARCHAR (MAX)
ALTER TABLE [Profile.Data].[Publication.Entity.InformationResource] ADD [Authors] NVARCHAR (MAX)
DBCC CLEANTABLE (0,'[Profile.Data].[Publication.Entity.InformationResource]');  
CREATE NONCLUSTERED INDEX [idx_PublicationEntityInformationResourceIsActive]
    ON [Profile.Data].[Publication.Entity.InformationResource]([IsActive] ASC)
    INCLUDE([EntityID], [PubYear], [PMID], [EntityDate], [Reference]);
GO


ALTER TABLE [Profile.Data].[Publication.PubMed.Author] ADD [CollectiveName] NVARCHAR (1000)
ALTER TABLE [Profile.Data].[Publication.PubMed.Author] ADD [ORCID] VARCHAR (50)
ALTER TABLE [Profile.Data].[Publication.PubMed.Author] ADD [ValueHash] VARBINARY (32)
GO

ALTER TABLE [Profile.Data].[Publication.PubMed.Author.Stage] ADD [CollectiveName] NVARCHAR (1000)
ALTER TABLE [Profile.Data].[Publication.PubMed.Author.Stage] ADD [ORCID] VARCHAR (50)
ALTER TABLE [Profile.Data].[Publication.PubMed.Author.Stage] ADD [ExistingPmPubsAuthorID] INT
ALTER TABLE [Profile.Data].[Publication.PubMed.Author.Stage] ADD [ValueHash] VARBINARY (32)
GO

ALTER TABLE [Profile.Data].[Publication.PubMed.General] ADD [doi] VARCHAR (100)
ALTER TABLE [Profile.Data].[Publication.PubMed.General] ALTER COLUMN [ArticleTitle] NVARCHAR (4000)
ALTER TABLE [Profile.Data].[Publication.PubMed.General] ALTER COLUMN [Authors] NVARCHAR (4000)
DBCC CLEANTABLE (0,'[Profile.Data].[Publication.PubMed.General]');  	
GO
	
ALTER TABLE [Profile.Data].[Publication.PubMed.General.Stage] ADD [doi] VARCHAR (100)
ALTER TABLE [Profile.Data].[Publication.PubMed.General.Stage] ALTER COLUMN [ArticleTitle] NVARCHAR (4000)
ALTER TABLE [Profile.Data].[Publication.PubMed.General.Stage] ALTER COLUMN [Authors] NVARCHAR (4000)	
DBCC CLEANTABLE (0,'[Profile.Data].[Publication.PubMed.General.Stage]');  	
GO

ALTER TABLE [Profile.Import].[PRNSWebservice.Options] ADD [options] VARCHAR (100)
ALTER TABLE [Profile.Import].[PRNSWebservice.Options] ADD [GetPostDataProc] VARCHAR (1000)
ALTER TABLE [Profile.Import].[PRNSWebservice.Options] ADD [ImportDataProc] VARCHAR (1000)
	
GO	
	
CREATE TABLE [Profile.Import].[PRNSWebservice.Log.Summary] (
    [LogID]        INT           IDENTITY (1, 1) NOT NULL,
    [Job]          VARCHAR (100) NOT NULL,
    [BatchID]      VARCHAR (100) NOT NULL,
    [RecordsCount] INT           NULL,
    [RowsCount]    INT           NULL,
    [JobStart]     DATETIME      NULL,
    [JobEnd]       DATETIME      NULL,
    [ErrorCount]   INT           NULL
);
GO

CREATE NONCLUSTERED INDEX [idx_PRNSWebserviceLogSummaryBatch]
    ON [Profile.Import].[PRNSWebservice.Log.Summary]([BatchID] ASC)
    INCLUDE([LogID]);
GO

	
	
CREATE view [Profile.Data].[vwPublication.PubMed.AllXML.PubMedBookArticle]
as
		select pmid, 
			'PubMedBookDocument' HmsPubCategory,
			nref.value('Book[1]/BookTitle[1]','varchar(2000)') PubTitle, 
			nref.value('ArticleTitle[1]','varchar(2000)') ArticleTitle,
			nref.value('Book[1]/Publisher[1]/PublisherLocation[1]','varchar(60)') PlaceOfPub, 
			nref.value('Book[1]/Publisher[1]/PublisherName[1]','varchar(255)') Publisher, 
			cast(isnull(nref.value('Book[1]/PubDate[1]/Year[1]','varchar(4)'), '1900') + '-' + isnull(nref.value('Book[1]/PubDate[1]/Month[1]','varchar(2)'), '01') + '-' + isnull(nref.value('Book[1]/PubDate[1]/Day[1]','varchar(2)'), '01') as DATETIME) PublicationDT
		from [Profile.Data].[Publication.PubMed.AllXML] cross apply x.nodes('//PubmedBookArticle/BookDocument') as R(nref)
GO
PRINT N'Altering [Profile.Cache].[fnPublication.Pubmed.General2Reference]...';
GO

ALTER function [Profile.Data].[fnPublication.Pubmed.GetPubDate]
(
	@MedlineDate varchar(255),
	@JournalYear varchar(50),
	@JournalMonth varchar(50),	
	@JournalDay varchar(50),	
	@ArticleYear varchar(10),
	@ArticleMonth varchar(10),	
	@ArticleDay varchar(10)
)
RETURNS datetime
AS
BEGIN
	-- Declare the return variable here
	DECLARE @PubDate datetime


	declare @MedlineMonth varchar(10)
	declare @MedlineYear varchar(10)

	set @MedlineYear = left(@MedlineDate,4)

	set @JournalMonth = (select case left(@JournalMonth,3)
								when 'Jan' then '1'
								when 'Feb' then '2'
								when 'Mar' then '3'
								when 'Apr' then '4'
								when 'May' then '5'
								when 'Jun' then '6'
								when 'Jul' then '7'
								when 'Aug' then '8'
								when 'Sep' then '9'
								when 'Oct' then '10'
								when 'Nov' then '11'
								when 'Dec' then '12'
								when 'Win' then '1'
								when 'Spr' then '4'
								when 'Sum' then '7'
								when 'Fal' then '10'
								when '1' then '1'
								when '2' then '2'
								when '3' then '3'
								when '4' then '4'
								when '5' then '5'
								when '6' then '6'
								when '7' then '7'
								when '8' then '8'
								when '9' then '9'
								when '01' then '1'
								when '02' then '2'
								when '03' then '3'
								when '04' then '4'
								when '05' then '5'
								when '06' then '6'
								when '07' then '7'
								when '08' then '8'
								when '09' then '9'
								when '10' then '10'
								when '11' then '11'
								when '12' then '12'
								else null end)
	set @MedlineMonth = (select case substring(replace(@MedlineDate,' ',''),5,3)
								when 'Jan' then '1'
								when 'Feb' then '2'
								when 'Mar' then '3'
								when 'Apr' then '4'
								when 'May' then '5'
								when 'Jun' then '6'
								when 'Jul' then '7'
								when 'Aug' then '8'
								when 'Sep' then '9'
								when 'Oct' then '10'
								when 'Nov' then '11'
								when 'Dec' then '12'
								when 'Win' then '1'
								when 'Spr' then '4'
								when 'Sum' then '7'
								when 'Fal' then '10'
								else null end)
	set @ArticleMonth = (select case @ArticleMonth
								when 'Jan' then '1'
								when 'Feb' then '2'
								when 'Mar' then '3'
								when 'Apr' then '4'
								when 'May' then '5'
								when 'Jun' then '6'
								when 'Jul' then '7'
								when 'Aug' then '8'
								when 'Sep' then '9'
								when 'Oct' then '10'
								when 'Nov' then '11'
								when 'Dec' then '12'
								when 'Win' then '1'
								when 'Spr' then '4'
								when 'Sum' then '7'
								when 'Fal' then '10'
								when '1' then '1'
								when '2' then '2'
								when '3' then '3'
								when '4' then '4'
								when '5' then '5'
								when '6' then '6'
								when '7' then '7'
								when '8' then '8'
								when '9' then '9'
								when '01' then '1'
								when '02' then '2'
								when '03' then '3'
								when '04' then '4'
								when '05' then '5'
								when '06' then '6'
								when '07' then '7'
								when '08' then '8'
								when '09' then '9'
								when '10' then '10'
								when '11' then '11'
								when '12' then '12'
								else null end)
	declare @jd datetime
	declare @ad datetime


	set @jd = (select case when @JournalYear is not null and (@MedlineYear is null or @JournalMonth is not null) then
							cast(coalesce(@JournalMonth,'1') + '/' + coalesce(@JournalDay,'1') + '/' + @JournalYear as datetime)
						when @MedlineYear is not null then
							cast(coalesce(@MedlineMonth,'1') + '/1/' + @MedlineYear as datetime)
						else
							null
						end)

	set @ad = (select case when @ArticleYear is not null then
							cast(coalesce(@ArticleMonth,'1') + '/' + coalesce(nullif(@ArticleDay,''),'1') + '/' + @ArticleYear as datetime)
						else
							null
						end)

	declare @jdx int
	declare @adx int

	set @jdx = (select case when @jd is null then 0
							when @JournalDay is not null then 3
							when @JournalMonth is not null then 2
							else 1
							end)
	set @adx = (select case when @ad is null then 0
							when @ArticleDay is not null then 3
							when @ArticleMonth is not null then 2
							else 1
							end)

	set @PubDate = (select case when @jdx + @adx = 0 then cast('1/1/1900' as datetime)
								when @jdx > @adx then @jd
								when @adx > @jdx then @ad
								when @ad < @jd then @ad
								else @jd
								end)

	-- Return the result of the function
	RETURN @PubDate

END



GO
ALTER function [Profile.Cache].[fnPublication.Pubmed.General2Reference]	(
	@pmid int,
	@ArticleDay varchar(10),
	@ArticleMonth varchar(10),
	@ArticleYear varchar(10),
	@ArticleTitle nvarchar(4000),
	@Authors nvarchar(4000),
	@AuthorListCompleteYN varchar(1),
	@Issue varchar(255),
	@JournalDay varchar(50),
	@JournalMonth varchar(50),
	@JournalYear varchar(50),
	@MedlineDate varchar(255),
	@MedlinePgn varchar(255),
	@MedlineTA varchar(1000),
	@Volume varchar(255),
	@encode_html bit=0
)

RETURNS NVARCHAR(MAX) 
AS 
BEGIN

	DECLARE @Reference NVARCHAR(MAX)

	SET @Reference = /*(case when right(@Authors,5) = 'et al' then @Authors+'. '
								when @AuthorListCompleteYN = 'N' then @Authors+', et al. '
								when @Authors <> '' then @Authors+'. '
								else '' end)
					+*/ CASE WHEN @encode_html=1 THEN '<a href="'+'http'+'://www.ncbi.nlm.nih.gov/pubmed/'+cast(@pmid as varchar(50))+'" target="_blank">'+coalesce(@ArticleTitle,'')+'</a>' + ' '
								 ELSE coalesce(@ArticleTitle,'') + ' '
						END
					+ coalesce(@MedlineTA,'') + '. '
					+ (case when @JournalYear is not null then rtrim(@JournalYear + ' ' + coalesce(@JournalMonth,'') + ' ' + coalesce(@JournalDay,''))
							when @MedlineDate is not null then @MedlineDate
							when @ArticleYear is not null then rtrim(@ArticleYear + ' ' + coalesce(@ArticleMonth,'') + ' ' + coalesce(@ArticleDay,''))
						else '' end)
					+ (case when coalesce(@JournalYear,@MedlineDate,@ArticleYear) is not null
								and (coalesce(@Volume,'')+coalesce(@Issue,'')+coalesce(@MedlinePgn,'') <> '')
							then '; ' else '' end)
					+ coalesce(@Volume,'')
					+ (case when coalesce(@Issue,'') <> '' then '('+@Issue+')' else '' end)
					+ (case when (coalesce(@MedlinePgn,'') <> '') and (coalesce(@Volume,'')+coalesce(@Issue,'') <> '') then ':' else '' end)
					+ coalesce(@MedlinePgn,'')
					+ '.'

	RETURN @Reference

END
GO
PRINT N'Creating [Profile.Data].[fnPublication.MyPub.HighlightAuthors]...';


GO
CREATE FUNCTION [Profile.Data].[fnPublication.MyPub.HighlightAuthors]	(
	@Authors varchar(max),
	@FirstName varchar(50),
	@Middlename varchar(50),
	@LastName varchar(50)
)
RETURNS NVARCHAR(MAX) 
AS 
BEGIN

	DECLARE @highlightedAuthors NVARCHAR(MAX)

	if @Authors like '%' + @LastName  + ' '+ SUBSTRING(@FirstName, 1, 1) + isnull(SUBSTRING(@Middlename, 1, 1), '') + '%'
		SET @highlightedAuthors = replace(@Authors, @LastName  + ' '+ SUBSTRING(@FirstName, 1, 1) + isnull(SUBSTRING(@Middlename, 1, 1), ''), '<b>' + @LastName + ' ' + SUBSTRING(@FirstName, 1, 1) + case when @Middlename = '' then '' else isnull(SUBSTRING(@Middlename, 1, 1), '') end + '</b>')

	else if @Authors like '%' + @LastName  + ' '+ SUBSTRING(@FirstName, 1, 1) + ',%' 
		SET @highlightedAuthors = replace(@Authors, @LastName  + ' '+ SUBSTRING(@FirstName, 1, 1) + ',', '<b>' + @LastName + ' ' + SUBSTRING(@FirstName, 1, 1) + '</b>,')

	else if @Authors like '%' + @LastName  + ' '+ SUBSTRING(@FirstName, 1, 1)
		SET @highlightedAuthors = SUBSTRING(@Authors, 1, len(@authors) - len (@Lastname) - 2) + '<b>' + @LastName  + ' '+ SUBSTRING(@FirstName, 1, 1) + '</b>'

	RETURN @highlightedAuthors

END
GO
PRINT N'Creating [Profile.Data].[fnPublication.Pubmed.ShortenAuthorLengthString]...';


GO
CREATE FUNCTION [Profile.Data].[fnPublication.Pubmed.ShortenAuthorLengthString](@strInput VARCHAR(max)) 
RETURNS VARCHAR(MAX)
AS
BEGIN
		select @strInput = substring(@strInput,3,len(@strInput))
		return case	when len(@strInput) < 3990 then @strInput
					when charindex(',',reverse(left(@strInput,3990)))>0 then
						left(@strInput,3990-charindex(',',reverse(left(@strInput,3990))))+', et al'
					else left(@strInput,3990)
					end
END
GO
PRINT N'Creating [RDF.].[fnNodeID2TypeID]...';


GO
CREATE FUNCTION [RDF.].[fnNodeID2TypeID] (
	@NodeID	bigint
) 
RETURNS nvarchar(200)
AS
BEGIN
	DECLARE @result nvarchar(200)

	declare @typeID bigint
	select @typeID = [RDF.].fnURI2NodeID('http://www.w3.org/1999/02/22-rdf-syntax-ns#type')

	select @result = coalesce(@result + ',', '') + cast(Object as nvarchar(10))  from [RDF.].Triple where subject=@NodeID and predicate=@typeID order by Object
	RETURN @result
END
GO
PRINT N'Altering [Profile.Data].[Publication.Entity.UpdateEntityOnePerson]...';


GO
ALTER PROCEDURE [Profile.Data].[Publication.Entity.UpdateEntityOnePerson]
	@PersonID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

 
	-- *******************************************************************
	-- *******************************************************************
	-- Update InformationResource entities
	-- *******************************************************************
	-- *******************************************************************
 
 
	----------------------------------------------------------------------
	-- Get a list of current publications
	----------------------------------------------------------------------
 
	CREATE TABLE #Publications
	(
		PMID INT NULL ,
		MPID NVARCHAR(50) NULL ,
		PMCID NVARCHAR(55) NULL,
		doi [varchar](100) NULL,				  
		EntityDate DATETIME NULL ,
		Authors NVARCHAR(4000) NULL,
		Reference NVARCHAR(MAX) NULL ,
		Source VARCHAR(25) NULL ,
		URL VARCHAR(1000) NULL ,
		Title NVARCHAR(4000) NULL ,
		EntityID INT NULL
	)
 
	-- Add PMIDs to the publications temp table
	INSERT  INTO #Publications
            ( PMID ,
			  PMCID,
              EntityDate ,
			  Authors,
              Reference ,
              Source ,
              URL ,
              Title
            )
            SELECT -- Get Pub Med pubs
                    PG.PMID ,
					PG.PMCID,
                    EntityDate = PG.PubDate,
					authors = case when right(PG.Authors,5) = 'et al' then PG.Authors+'. '
						when PG.AuthorListCompleteYN = 'N' then PG.Authors+', et al. '
						when PG.Authors <> '' then PG.Authors+'. '
						else '' end,
                    Reference = REPLACE([Profile.Cache].[fnPublication.Pubmed.General2Reference](PG.PMID,
                                                              PG.ArticleDay,
                                                              PG.ArticleMonth,
                                                              PG.ArticleYear,
                                                              PG.ArticleTitle,
                                                              PG.Authors,
                                                              PG.AuthorListCompleteYN,
                                                              PG.Issue,
                                                              PG.JournalDay,
                                                              PG.JournalMonth,
                                                              PG.JournalYear,
                                                              PG.MedlineDate,
                                                              PG.MedlinePgn,
                                                              PG.MedlineTA,
                                                              PG.Volume, 0),
                                        CHAR(11), '') ,
                    Source = 'PubMed',
                    URL = 'http://www.ncbi.nlm.nih.gov/pubmed/' + CAST(ISNULL(PG.pmid, '') AS VARCHAR(20)),
                    Title = left((case when IsNull(PG.ArticleTitle,'') <> '' then PG.ArticleTitle else 'Untitled Publication' end),4000)
            FROM    [Profile.Data].[Publication.PubMed.General] PG
			WHERE	PG.PMID IN (
						SELECT PMID 
						FROM [Profile.Data].[Publication.Person.Include]
						WHERE PMID IS NOT NULL AND PersonID = @PersonID
					)
					AND PG.PMID NOT IN (
						SELECT PMID
						FROM [Profile.Data].[Publication.Entity.InformationResource]
						WHERE PMID IS NOT NULL)
 
	-- Add MPIDs to the publications temp table
	INSERT  INTO #Publications
            ( MPID ,
              EntityDate ,
			  Authors,
			  Reference ,
			  Source ,
              URL ,
              Title
            )
            SELECT  MPID ,
                    EntityDate ,
					Authors = REPLACE(authors, CHAR(11), '') ,
                    Reference = REPLACE( (CASE WHEN IsNull(article,'') <> '' THEN article + '. ' ELSE '' END)
										+ (CASE WHEN IsNull(pub,'') <> '' THEN pub + '. ' ELSE '' END)
										+ y
                                        + CASE WHEN y <> ''
                                                    AND vip <> '' THEN '; '
                                               ELSE ''
                                          END + vip
                                        + CASE WHEN y <> ''
                                                    OR vip <> '' THEN '.'
                                               ELSE ''
                                          END, CHAR(11), '') ,
                    Source = 'Custom' ,
                    URL = url,
                    Title = left((case when IsNull(article,'')<>'' then article when IsNull(pub,'')<>'' then pub else 'Untitled Publication' end),4000)
            FROM    ( SELECT    MPID ,
                                EntityDate ,
                                url ,
                                authors = CASE WHEN authors = '' THEN ''
                                               WHEN RIGHT(authors, 1) = '.'
                                               THEN LEFT(authors,
                                                         LEN(authors) - 1)
                                               ELSE authors
                                          END ,
                                article = CASE WHEN article = '' THEN ''
                                               WHEN RIGHT(article, 1) = '.'
                                               THEN LEFT(article,
                                                         LEN(article) - 1)
                                               ELSE article
                                          END ,
                                pub = CASE WHEN pub = '' THEN ''
                                           WHEN RIGHT(pub, 1) = '.'
                                           THEN LEFT(pub, LEN(pub) - 1)
                                           ELSE pub
                                      END ,
                                y ,
                                vip
                      FROM      ( SELECT    MPG.mpid ,
											EntityDate = MPG.publicationdt ,
                                            authors = CASE WHEN RTRIM(LTRIM(COALESCE(MPG.authors,
                                                              ''))) = ''
                                                           THEN ''
                                                           WHEN RIGHT(COALESCE(MPG.authors,
                                                              ''), 1) = '.'
                                                            THEN  COALESCE([Profile.Data].[fnPublication.MyPub.HighlightAuthors] (MPG.authors, p.FirstName, p.MiddleName, p.LastName),
                                                              '') + ' '
                                                           ELSE COALESCE([Profile.Data].[fnPublication.MyPub.HighlightAuthors] (MPG.authors, p.FirstName, p.MiddleName, p.LastName),
                                                              '') + '. '
                                                      END ,
                                            url = CASE WHEN COALESCE(MPG.url,
                                                              '') <> ''
                                                            AND LEFT(COALESCE(MPG.url,
                                                              ''), 4) = 'http'
                                                       THEN MPG.url
                                                       WHEN COALESCE(MPG.url,
                                                              '') <> ''
                                                       THEN 'http://' + MPG.url
                                                       ELSE ''
                                                  END ,
                                            article = LTRIM(RTRIM(COALESCE(MPG.articletitle,
                                                              ''))) ,
                                            pub = LTRIM(RTRIM(COALESCE(MPG.pubtitle,
                                                              ''))) ,
                                            y = CASE WHEN MPG.publicationdt > '1/1/1901'
                                                     THEN CONVERT(VARCHAR(50), YEAR(MPG.publicationdt))
                                                     ELSE ''
                                                END ,
                                            vip = COALESCE(MPG.volnum, '')
                                            + CASE WHEN COALESCE(MPG.issuepub,
                                                              '') <> ''
                                                   THEN '(' + MPG.issuepub
                                                        + ')'
                                                   ELSE ''
                                              END
                                            + CASE WHEN ( COALESCE(MPG.paginationpub,
                                                              '') <> '' )
                                                        AND ( COALESCE(MPG.volnum,
                                                              '')
                                                              + COALESCE(MPG.issuepub,
                                                              '') <> '' )
                                                   THEN ':'
                                                   ELSE ''
                                              END + COALESCE(MPG.paginationpub,
                                                             '')
                                  FROM      [Profile.Data].[Publication.MyPub.General] MPG
                                  INNER JOIN [Profile.Data].[Publication.Person.Include] PL ON MPG.mpid = PL.mpid
                                                           AND PL.mpid NOT LIKE 'DASH%'
                                                           AND PL.mpid NOT LIKE 'ISI%'
                                                           AND PL.pmid IS NULL
                                                           AND PL.PersonID = @PersonID
									join [Profile.Data].Person p on pl.PersonID = p.PersonID
									WHERE MPG.MPID NOT IN (
										SELECT MPID
										FROM [Profile.Data].[Publication.Entity.InformationResource]
										WHERE (MPID IS NOT NULL)
									)
                                ) T0
                    ) T0
 
	CREATE NONCLUSTERED INDEX idx_pmid on #publications(pmid)
	CREATE NONCLUSTERED INDEX idx_mpid on #publications(mpid)

	declare @baseURI varchar(255)
	select @baseURI = Value From [Framework.].Parameter where ParameterID = 'baseURI'
	select a.PmPubsAuthorID, a.pmid, a2p.personID, isnull(Lastname + ' ' + Initials, CollectiveName) as Name, case when nodeID is not null then'<a href="' + @baseURI + cast(i.nodeID as varchar(55)) + '">'+ Lastname + ' ' + Initials + '</a>' else isnull(Lastname + ' ' + Initials, CollectiveName) END as link into #tmpAuthorLinks from [Profile.Data].[Publication.PubMed.Author] a
		join [Profile.Data].[Publication.Person.Include] p on a.pmid = p.pmid and p.PersonID = @personID
		left outer join [Profile.Data].[Publication.PubMed.Author2Person] a2p on a.PmPubsAuthorID = a2p.PmPubsAuthorID
		left outer join [RDF.Stage].InternalNodeMap i on a2p.PersonID = i.InternalID and i.class = 'http://xmlns.com/foaf/0.1/Person'

	select pmid, [Profile.Data].[fnPublication.Pubmed.ShortenAuthorLengthString](replace(replace(isnull(cast((
		select ', '+ link
		from #tmpAuthorLinks q
		where q.pmid = p.pmid
		order by PmPubsAuthorID
		for xml path(''), type
		) as nvarchar(max)),''), '&lt;' , '<'), '&gt;', '>')) s
		into #tmpPublicationLinks from #publications p where pmid is not null

	update g set g.Authors = t.s from #publications g
		join #tmpPublicationLinks t on g.PMID = t.PMID
	----------------------------------------------------------------------
	-- Update the Publication.Entity.InformationResource table
	--
	-- Commented out, we don't update publications in the one person/group version
	----------------------------------------------------------------------
 /*
	-- Determine which publications already exist
	UPDATE p
		SET p.EntityID = e.EntityID
		FROM #publications p, [Profile.Data].[Publication.Entity.InformationResource] e
		WHERE p.PMID = e.PMID and p.PMID is not null
	UPDATE p
		SET p.EntityID = e.EntityID
		FROM #publications p, [Profile.Data].[Publication.Entity.InformationResource] e
		WHERE p.MPID = e.MPID and p.MPID is not null
	CREATE NONCLUSTERED INDEX idx_entityid on #publications(EntityID)

	-- Deactivate old publications
	UPDATE e
		SET e.IsActive = 0
		FROM [Profile.Data].[Publication.Entity.InformationResource] e
		WHERE e.EntityID NOT IN (SELECT EntityID FROM #publications)											  
	-- Update the data for existing publications
	UPDATE e
		SET e.EntityDate = p.EntityDate,
			e.pmcid = p.pmcid,
			e.doi = p.doi,	 
			e.Authors = p.Authors,
			e.Reference = p.Reference,
			e.Source = p.Source,
			e.URL = p.URL,
			e.EntityName = p.Title,
			e.IsActive = 1,
			e.PubYear = year(p.EntityDate),
            e.YearWeight = (case when p.EntityDate is null then 0.5
                when year(p.EntityDate) <= 1901 then 0.5
                else power(cast(0.5 as float),cast(datediff(d,p.EntityDate,GetDate()) as float)/365.25/10)
                end)
		FROM #publications p, [Profile.Data].[Publication.Entity.InformationResource] e
		WHERE p.EntityID = e.EntityID and p.EntityID is not null
*/
	-- Insert new publications
	INSERT INTO [Profile.Data].[Publication.Entity.InformationResource] (
			PMID,
			PMCID,
			MPID,
			EntityName,
			EntityDate,
			Authors,
			Reference,
			Source,
			URL,
			IsActive,
			PubYear,
			YearWeight
		)
		SELECT 	PMID,
				PMCID,
				MPID,
				Title,
				EntityDate,
				Authors,
				Reference,
				Source,
				URL,
				1 IsActive,
				PubYear = year(EntityDate),
				YearWeight = (case when EntityDate is null then 0.5
								when year(EntityDate) <= 1901 then 0.5
								else power(cast(0.5 as float),cast(datediff(d,EntityDate,GetDate()) as float)/365.25/10)
								end)
		FROM #publications
		WHERE EntityID IS NULL
 
	-- *******************************************************************
	-- *******************************************************************
	-- Update Authorship entities
	-- *******************************************************************
	-- *******************************************************************
 
 	----------------------------------------------------------------------
	-- Get a list of current Authorship records
	----------------------------------------------------------------------

	CREATE TABLE #Authorship
	(
		EntityDate DATETIME NULL ,
		authorRank INT NULL,
		numberOfAuthors INT NULL,
		authorNameAsListed VARCHAR(255) NULL,
		AuthorWeight FLOAT NULL,
		AuthorPosition VARCHAR(1) NULL,
		PubYear INT NULL ,
		YearWeight FLOAT NULL ,
		PersonID INT NULL ,
		InformationResourceID INT NULL,
		PMID INT NULL,
		IsActive BIT,
		EntityID INT,			   
		AuthorsString varchar(max)	   
	)
 
	INSERT INTO #Authorship (EntityDate, PersonID, InformationResourceID, PMID, IsActive)
		SELECT e.EntityDate, i.PersonID, e.EntityID, e.PMID, 1 IsActive
			FROM [Profile.Data].[Publication.Entity.InformationResource] e,
				[Profile.Data].[Publication.Person.Include] i
			WHERE (e.PMID = i.PMID) and (e.PMID is not null) and (i.PersonID = @PersonID)
	INSERT INTO #Authorship (EntityDate, PersonID, InformationResourceID, PMID, IsActive)
		SELECT e.EntityDate, i.PersonID, e.EntityID, null PMID, 1 IsActive
			FROM [Profile.Data].[Publication.Entity.InformationResource] e,
				[Profile.Data].[Publication.Person.Include] i
			WHERE (e.MPID = i.MPID) and (e.MPID is not null) and (e.PMID is null) and (i.PersonID = @PersonID)
	CREATE NONCLUSTERED INDEX idx_person_pmid ON #Authorship(PersonID, PMID)
	CREATE NONCLUSTERED INDEX idx_person_pub ON #Authorship(PersonID, InformationResourceID)
 
	UPDATE a
		SET	a.authorRank=p.authorRank,
			a.numberOfAuthors=p.numberOfAuthors,
			a.authorNameAsListed=p.authorNameAsListed, 
			a.AuthorWeight=p.AuthorWeight, 
			a.AuthorPosition=p.AuthorPosition,
			a.PubYear=p.PubYear,
			a.YearWeight=p.YearWeight
		FROM #Authorship a, [Profile.Cache].[Publication.PubMed.AuthorPosition]  p
		WHERE a.PersonID = p.PersonID and a.PMID = p.PMID and a.PMID is not null
	UPDATE #authorship
		SET authorWeight = 0.5
		WHERE authorWeight IS NULL
	UPDATE #authorship
		SET authorPosition = 'U'
		WHERE authorPosition IS NULL
	UPDATE #authorship
		SET PubYear = year(EntityDate)
		WHERE PubYear IS NULL
	UPDATE #authorship
		SET	YearWeight = (case when EntityDate is null then 0.5
							when year(EntityDate) <= 1901 then 0.5
							else power(cast(0.5 as float),cast(datediff(d,EntityDate,GetDate()) as float)/365.25/10)
							end)
		WHERE YearWeight IS NULL

																												select pmid, personID, [Profile.Data].[fnPublication.Pubmed.ShortenAuthorLengthString](replace(replace(isnull(cast((
		select ', '+case when p.personID = q.personID then '<b>' + name + '</b>' else link end
		from #tmpAuthorLinks q
		where q.pmid = p.pmid
		order by PmPubsAuthorID
		for xml path(''), type
	) as nvarchar(max)),''), '&lt;' , '<'), '&gt;', '>')) s
	into #tmp2 from #Authorship p where pmid is not null

	update a set a.s = case when right(a.s,5) = 'et al' then a.s+'. '
								when g.AuthorListCompleteYN = 'N' then a.s+', et al. '
								when a.s <> '' then a.s+'. '
								else '' end
		from #tmp2 a join [Profile.Data].[Publication.PubMed.General] g on a.PMID = g.PMID


	update a set a.AuthorsString = b.s from #Authorship a join #tmp2 b on a.pmid = b.PMID and a.PersonID = b.PersonID																																																											   
	----------------------------------------------------------------------
	-- Update the Publication.Authorship table
	----------------------------------------------------------------------
 
	-- Determine which authorships already exist
	UPDATE a
		SET a.EntityID = e.EntityID
		FROM #authorship a, [Profile.Data].[Publication.Entity.Authorship] e
		WHERE a.PersonID = e.PersonID and a.InformationResourceID = e.InformationResourceID
 	CREATE NONCLUSTERED INDEX idx_entityid on #authorship(EntityID)											 

	-- Deactivate old authorships				
	UPDATE a
		SET a.IsActive = 0
		FROM [Profile.Data].[Publication.Entity.Authorship] a							
		WHERE a.EntityID NOT IN (SELECT EntityID FROM #authorship)
			and PersonID = @PersonID

	-- Update the data for existing authorships										
	UPDATE e
		SET e.EntityDate = a.EntityDate,
			e.authorRank = a.authorRank,
			e.numberOfAuthors = a.numberOfAuthors,
			e.authorNameAsListed = a.authorNameAsListed,
			e.authorWeight = a.authorWeight,
			e.authorPosition = a.authorPosition,
			e.PubYear = a.PubYear,
			e.YearWeight = a.YearWeight,
			e.IsActive = 1,
			e.AuthorsString = a.AuthorsString						
		FROM #authorship a, [Profile.Data].[Publication.Entity.Authorship] e
		WHERE a.EntityID = e.EntityID and a.EntityID is not null
	-- Insert new Authorships
	INSERT INTO [Profile.Data].[Publication.Entity.Authorship] (
			EntityDate,
			authorRank,
			numberOfAuthors,
			authorNameAsListed,
			authorWeight,
			authorPosition,
			PubYear,
			YearWeight,
			PersonID,
			InformationResourceID,
			IsActive,
			AuthorsString
		)
		SELECT 	EntityDate,
				authorRank,
				numberOfAuthors,
				authorNameAsListed,
				authorWeight,
				authorPosition,
				PubYear,
				YearWeight,
				PersonID,
				InformationResourceID,
				IsActive,
				AuthorsString
		FROM #authorship a
		WHERE EntityID IS NULL
		
	-- Assign an EntityName
	UPDATE [Profile.Data].[Publication.Entity.Authorship]
		SET EntityName = 'Authorship ' + CAST(EntityID as VARCHAR(50))
		WHERE PersonID = @PersonID AND EntityName is null


	-- *******************************************************************
	-- *******************************************************************
	-- Update RDF
	-- *******************************************************************
	-- *******************************************************************



	--------------------------------------------------------------
	-- Version 3 : Create stub RDF
	--------------------------------------------------------------

	CREATE TABLE #sql (
		i INT IDENTITY(0,1) PRIMARY KEY,
		s NVARCHAR(MAX)
	)
	INSERT INTO #sql (s)
		SELECT	'EXEC [RDF.Stage].ProcessDataMap '
					+'  @DataMapID = '+CAST(DataMapID AS VARCHAR(50))
					+', @InternalIdIn = '+InternalIdIn
					+', @TurnOffIndexing=0, @SaveLog=0; '
		FROM (
			SELECT *, '''SELECT CAST(EntityID AS VARCHAR(50)) FROM [Profile.Data].[Publication.Entity.Authorship] WHERE PersonID = '+CAST(@PersonID AS VARCHAR(50))+'''' InternalIdIn
				FROM [Ontology.].DataMap
				WHERE class = 'http://vivoweb.org/ontology/core#Authorship'
					AND NetworkProperty IS NULL
					AND Property IS NULL
			UNION ALL
			SELECT *, '''' + CAST(@PersonID AS VARCHAR(50)) + '''' InternalIdIn
				FROM [Ontology.].DataMap
				WHERE class = 'http://xmlns.com/foaf/0.1/Person' 
					AND property = 'http://vivoweb.org/ontology/core#authorInAuthorship'
					AND NetworkProperty IS NULL
		) t
		ORDER BY DataMapID

	DECLARE @s NVARCHAR(MAX)
	WHILE EXISTS (SELECT * FROM #sql)
	BEGIN
		SELECT @s = s
			FROM #sql
			WHERE i = (SELECT MIN(i) FROM #sql)
		print @s
		EXEC sp_executesql @s
		DELETE
			FROM #sql
			WHERE i = (SELECT MIN(i) FROM #sql)
	END

END
GO
PRINT N'Altering [Profile.Data].[Publication.Entity.UpdateEntity]...';


GO
ALTER PROCEDURE [Profile.Data].[Publication.Entity.UpdateEntity]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

 
	-- *******************************************************************
	-- *******************************************************************
	-- Update InformationResource entities
	-- *******************************************************************
	-- *******************************************************************
 
 
	----------------------------------------------------------------------
	-- Get a list of current publications
	----------------------------------------------------------------------

	CREATE TABLE #Publications
	(
		PMID INT NULL ,
		MPID NVARCHAR(50) NULL ,
		PMCID NVARCHAR(55) NULL,
		doi [varchar](100) NULL,
		EntityDate DATETIME NULL ,
		Authors NVARCHAR(4000) NULL,
		Reference NVARCHAR(MAX) NULL ,
		Source VARCHAR(25) NULL ,
		URL VARCHAR(1000) NULL ,
		Title NVARCHAR(4000) NULL ,
		EntityID INT NULL
	)
 
	-- Add PMIDs to the publications temp table
	INSERT  INTO #Publications
            ( PMID ,
			  PMCID,
			  doi,
              EntityDate ,
			  Authors,
              Reference ,
              Source ,
              URL ,
              Title
            )
            SELECT -- Get Pub Med pubs
                    PG.PMID ,
					PG.PMCID,
					PG.doi,
                    EntityDate = PG.PubDate,
					authors = case when right(PG.Authors,5) = 'et al' then PG.Authors+'. '
								when PG.AuthorListCompleteYN = 'N' then PG.Authors+', et al. '
								when PG.Authors <> '' then PG.Authors+'. '
								else '' end,
                    Reference = REPLACE([Profile.Cache].[fnPublication.Pubmed.General2Reference](PG.PMID,
                                                              PG.ArticleDay,
                                                              PG.ArticleMonth,
                                                              PG.ArticleYear,
                                                              PG.ArticleTitle,
                                                              PG.Authors,
                                                              PG.AuthorListCompleteYN,
                                                              PG.Issue,
                                                              PG.JournalDay,
                                                              PG.JournalMonth,
                                                              PG.JournalYear,
                                                              PG.MedlineDate,
                                                              PG.MedlinePgn,
                                                              PG.MedlineTA,
                                                              PG.Volume, 0),
                                        CHAR(11), '') ,
                    Source = 'PubMed',
                    URL = 'http://www.ncbi.nlm.nih.gov/pubmed/' + CAST(ISNULL(PG.pmid, '') AS VARCHAR(20)),
                    Title = left((case when IsNull(PG.ArticleTitle,'') <> '' then PG.ArticleTitle else 'Untitled Publication' end),4000)
            FROM    [Profile.Data].[Publication.PubMed.General] PG
			WHERE	PG.PMID IN (
						SELECT PMID 
							FROM [Profile.Data].[Publication.Person.Include]
							WHERE PMID IS NOT NULL
						UNION
						SELECT PMID 
							FROM [Profile.Data].[Publication.Group.Include]
							WHERE PMID IS NOT NULL)
	   
	-- Add MPIDs to the publications temp table
	INSERT  INTO #Publications
            ( MPID ,
              EntityDate ,
			  Authors,
			  Reference ,
			  Source ,
              URL ,
              Title
            )
            SELECT  MPID ,
                    EntityDate ,
					Authors = REPLACE(authors, CHAR(11), '') ,
                    Reference = REPLACE( (CASE WHEN IsNull(article,'') <> '' THEN article + '. ' ELSE '' END)
										+ (CASE WHEN IsNull(pub,'') <> '' THEN pub + '. ' ELSE '' END)
										+ y
                                        + CASE WHEN y <> ''
                                                    AND vip <> '' THEN '; '
                                               ELSE ''
                                          END + vip
                                        + CASE WHEN y <> ''
                                                    OR vip <> '' THEN '.'
                                               ELSE ''
                                          END, CHAR(11), '') ,
                    Source = 'Custom' ,
                    URL = url,
                    Title = left((case when IsNull(article,'')<>'' then article when IsNull(pub,'')<>'' then pub else 'Untitled Publication' end),4000)
            FROM    ( SELECT    MPID ,
                                EntityDate ,
                                url ,
                                authors = CASE WHEN authors = '' THEN ''
                                               WHEN RIGHT(authors, 1) = '.'
                                               THEN LEFT(authors,
                                                         LEN(authors) - 1)
                                               ELSE authors
                                          END ,
                                article = CASE WHEN article = '' THEN ''
                                               WHEN RIGHT(article, 1) = '.'
                                               THEN LEFT(article,
                                                         LEN(article) - 1)
                                               ELSE article
                                          END ,
                                pub = CASE WHEN pub = '' THEN ''
                                           WHEN RIGHT(pub, 1) = '.'
                                           THEN LEFT(pub, LEN(pub) - 1)
                                           ELSE pub
                                      END ,
                                y ,
                                vip
                      FROM      ( SELECT    MPG.mpid ,
                                            EntityDate = MPG.publicationdt ,
                                            authors = CASE WHEN RTRIM(LTRIM(COALESCE(MPG.authors,
                                                              ''))) = ''
                                                           THEN ''
                                                           WHEN RIGHT(COALESCE(MPG.authors,
                                                              ''), 1) = '.'
                                                            THEN  COALESCE([Profile.Data].[fnPublication.MyPub.HighlightAuthors] (MPG.authors, p.FirstName, p.MiddleName, p.LastName),
                                                              '') + ' '
                                                           ELSE COALESCE([Profile.Data].[fnPublication.MyPub.HighlightAuthors] (MPG.authors, p.FirstName, p.MiddleName, p.LastName),
                                                              '') + '. '
                                                      END ,
                                            url = CASE WHEN COALESCE(MPG.url,
                                                              '') <> ''
                                                            AND LEFT(COALESCE(MPG.url,
                                                              ''), 4) = 'http'
                                                       THEN MPG.url
                                                       WHEN COALESCE(MPG.url,
                                                              '') <> ''
                                                       THEN 'http://' + MPG.url
                                                       ELSE ''
                                                  END ,
                                            article = LTRIM(RTRIM(COALESCE(MPG.articletitle,
                                                              ''))) ,
                                            pub = LTRIM(RTRIM(COALESCE(MPG.pubtitle,
                                                              ''))) ,
                                            y = CASE WHEN MPG.publicationdt > '1/1/1901'
                                                     THEN CONVERT(VARCHAR(50), YEAR(MPG.publicationdt))
                                                     ELSE ''
                                                END ,
                                            vip = COALESCE(MPG.volnum, '')
                                            + CASE WHEN COALESCE(MPG.issuepub,
                                                              '') <> ''
                                                   THEN '(' + MPG.issuepub
                                                        + ')'
                                                   ELSE ''
                                              END
                                            + CASE WHEN ( COALESCE(MPG.paginationpub,
                                                              '') <> '' )
                                                        AND ( COALESCE(MPG.volnum,
                                                              '')
                                                              + COALESCE(MPG.issuepub,
                                                              '') <> '' )
                                                   THEN ':'
                                                   ELSE ''
                                              END + COALESCE(MPG.paginationpub,
                                                             '')
                                  FROM      [Profile.Data].[Publication.MyPub.General] MPG
                                  INNER JOIN [Profile.Data].[Publication.Person.Include] PL ON MPG.mpid = PL.mpid
                                                           AND PL.mpid NOT LIKE 'DASH%'
                                                           AND PL.mpid NOT LIKE 'ISI%'
                                                           AND PL.pmid IS NULL
									join [Profile.Data].Person p on pl.PersonID = p.PersonID
                                ) T0
                    ) T0
 
	CREATE NONCLUSTERED INDEX idx_pmid on #publications(pmid)
	CREATE NONCLUSTERED INDEX idx_mpid on #publications(mpid)

	declare @baseURI varchar(255)
	select @baseURI = Value From [Framework.].Parameter where ParameterID = 'baseURI'
	select a.PmPubsAuthorID, a.pmid, a2p.personID, isnull(Lastname + ' ' + Initials, CollectiveName) as Name, case when nodeID is not null then'<a href="' + @baseURI + cast(i.nodeID as varchar(55)) + '">'+ Lastname + ' ' + Initials + '</a>' else isnull(Lastname + ' ' + Initials, CollectiveName) END as link into #tmpAuthorLinks from [Profile.Data].[Publication.PubMed.Author] a 
		left outer join [Profile.Data].[Publication.PubMed.Author2Person] a2p on a.PmPubsAuthorID = a2p.PmPubsAuthorID
		left outer join [RDF.Stage].InternalNodeMap i on a2p.PersonID = i.InternalID and i.class = 'http://xmlns.com/foaf/0.1/Person'

	select pmid, [Profile.Data].[fnPublication.Pubmed.ShortenAuthorLengthString](replace(replace(isnull(cast((
		select ', '+ link
		from #tmpAuthorLinks q
		where q.pmid = p.pmid
		order by PmPubsAuthorID
		for xml path(''), type
		) as nvarchar(max)),''), '&lt;' , '<'), '&gt;', '>')) s
		into #tmpPublicationLinks from #publications p where pmid is not null

	update g set g.Authors = t.s from #publications g
		join #tmpPublicationLinks t on g.PMID = t.PMID 

	----------------------------------------------------------------------
	-- Update the Publication.Entity.InformationResource table
	----------------------------------------------------------------------

	-- Determine which publications already exist
	UPDATE p
		SET p.EntityID = e.EntityID
		FROM #publications p, [Profile.Data].[Publication.Entity.InformationResource] e
		WHERE p.PMID = e.PMID and p.PMID is not null
	UPDATE p
		SET p.EntityID = e.EntityID
		FROM #publications p, [Profile.Data].[Publication.Entity.InformationResource] e
		WHERE p.MPID = e.MPID and p.MPID is not null
	CREATE NONCLUSTERED INDEX idx_entityid on #publications(EntityID)

	-- Deactivate old publications
	UPDATE e
		SET e.IsActive = 0
		FROM [Profile.Data].[Publication.Entity.InformationResource] e
		WHERE e.EntityID NOT IN (SELECT EntityID FROM #publications)

	-- Update the data for existing publications
	UPDATE e
		SET e.EntityDate = p.EntityDate,
			e.pmcid = p.pmcid,
			e.doi = p.doi,
			e.Authors = p.Authors,
			e.Reference = p.Reference,
			e.Source = p.Source,
			e.URL = p.URL,
			e.EntityName = p.Title,
			e.IsActive = 1,
			e.PubYear = year(p.EntityDate),
            e.YearWeight = (case when p.EntityDate is null then 0.5
                when year(p.EntityDate) <= 1901 then 0.5
                else power(cast(0.5 as float),cast(datediff(d,p.EntityDate,GetDate()) as float)/365.25/10)
                end)
		FROM #publications p, [Profile.Data].[Publication.Entity.InformationResource] e
		WHERE p.EntityID = e.EntityID and p.EntityID is not null

	-- Insert new publications
	INSERT INTO [Profile.Data].[Publication.Entity.InformationResource] (
			PMID,
			PMCID,
			doi,
			MPID,
			EntityName,
			EntityDate,
			Authors,
			Reference,
			Source,
			URL,
			IsActive,
			PubYear,
			YearWeight
		)
		SELECT 	PMID,
				PMCID,
				doi,
				MPID,
				Title,
				EntityDate,
				Authors,
				Reference,
				Source,
				URL,
				1 IsActive,
				PubYear = year(EntityDate),
				YearWeight = (case when EntityDate is null then 0.5
								when year(EntityDate) <= 1901 then 0.5
								else power(cast(0.5 as float),cast(datediff(d,EntityDate,GetDate()) as float)/365.25/10)
								end)
		FROM #publications
		WHERE EntityID IS NULL

 
	-- *******************************************************************
	-- *******************************************************************
	-- Update Authorship entities
	-- *******************************************************************
	-- *******************************************************************
 
 	----------------------------------------------------------------------
	-- Get a list of current Authorship records
	----------------------------------------------------------------------

	CREATE TABLE #Authorship
	(
		EntityDate DATETIME NULL ,
		authorRank INT NULL,
		numberOfAuthors INT NULL,
		authorNameAsListed VARCHAR(255) NULL,
		AuthorWeight FLOAT NULL,
		AuthorPosition VARCHAR(1) NULL,
		PubYear INT NULL ,
		YearWeight FLOAT NULL ,
		PersonID INT NULL ,
		InformationResourceID INT NULL,
		PMID INT NULL,
		IsActive BIT,
		EntityID INT,
		AuthorsString varchar(max)
	)
 
	INSERT INTO #Authorship (EntityDate, PersonID, InformationResourceID, PMID, IsActive)
		SELECT e.EntityDate, i.PersonID, e.EntityID, e.PMID, 1 IsActive
			FROM [Profile.Data].[Publication.Entity.InformationResource] e,
				[Profile.Data].[Publication.Person.Include] i
			WHERE e.PMID = i.PMID and e.PMID is not null
	INSERT INTO #Authorship (EntityDate, PersonID, InformationResourceID, PMID, IsActive)
		SELECT e.EntityDate, i.PersonID, e.EntityID, null PMID, 1 IsActive
			FROM [Profile.Data].[Publication.Entity.InformationResource] e,
				[Profile.Data].[Publication.Person.Include] i
			WHERE (e.MPID = i.MPID) and (e.MPID is not null) and (e.PMID is null)
	CREATE NONCLUSTERED INDEX idx_person_pmid ON #Authorship(PersonID, PMID)
	CREATE NONCLUSTERED INDEX idx_person_pub ON #Authorship(PersonID, InformationResourceID)

	UPDATE a
		SET	a.authorRank=p.authorRank,
			a.numberOfAuthors=p.numberOfAuthors,
			a.authorNameAsListed=p.authorNameAsListed, 
			a.AuthorWeight=p.AuthorWeight, 
			a.AuthorPosition=p.AuthorPosition,
			a.PubYear=p.PubYear,
			a.YearWeight=p.YearWeight
		FROM #Authorship a, [Profile.Cache].[Publication.PubMed.AuthorPosition]  p
		WHERE a.PersonID = p.PersonID and a.PMID = p.PMID and a.PMID is not null
	UPDATE #authorship
		SET authorWeight = 0.5
		WHERE authorWeight IS NULL
	UPDATE #authorship
		SET authorPosition = 'U'
		WHERE authorPosition IS NULL
	UPDATE #authorship
		SET PubYear = year(EntityDate)
		WHERE PubYear IS NULL
	UPDATE #authorship
		SET	YearWeight = (case when EntityDate is null then 0.5
							when year(EntityDate) <= 1901 then 0.5
							else power(cast(0.5 as float),cast(datediff(d,EntityDate,GetDate()) as float)/365.25/10)
							end)
		WHERE YearWeight IS NULL

		select pmid, personID, [Profile.Data].[fnPublication.Pubmed.ShortenAuthorLengthString](replace(replace(isnull(cast((
		select ', '+case when p.personID = q.personID then '<b>' + name + '</b>' else link end
		from #tmpAuthorLinks q
		where q.pmid = p.pmid
		order by PmPubsAuthorID
		for xml path(''), type
	) as nvarchar(max)),''), '&lt;' , '<'), '&gt;', '>')) s
	into #tmp2 from #Authorship p where pmid is not null

	update a set a.s = case when right(a.s,5) = 'et al' then a.s+'. '
								when g.AuthorListCompleteYN = 'N' then a.s+', et al. '
								when a.s <> '' then a.s+'. '
								else '' end
		from #tmp2 a join [Profile.Data].[Publication.PubMed.General] g on a.PMID = g.PMID


	update a set a.AuthorsString = b.s from #Authorship a join #tmp2 b on a.pmid = b.PMID and a.PersonID = b.PersonID
	----------------------------------------------------------------------
	-- Update the Publication.Authorship table
	----------------------------------------------------------------------

	-- Determine which authorships already exist
	UPDATE a
		SET a.EntityID = e.EntityID
		FROM #authorship a, [Profile.Data].[Publication.Entity.Authorship] e
		WHERE a.PersonID = e.PersonID and a.InformationResourceID = e.InformationResourceID
 	CREATE NONCLUSTERED INDEX idx_entityid on #authorship(EntityID)

	-- Deactivate old authorships
	UPDATE a
		SET a.IsActive = 0
		FROM [Profile.Data].[Publication.Entity.Authorship] a
		WHERE a.EntityID NOT IN (SELECT EntityID FROM #authorship)

	-- Update the data for existing authorships
	UPDATE e
		SET e.EntityDate = a.EntityDate,
			e.authorRank = a.authorRank,
			e.numberOfAuthors = a.numberOfAuthors,
			e.authorNameAsListed = a.authorNameAsListed,
			e.authorWeight = a.authorWeight,
			e.authorPosition = a.authorPosition,
			e.PubYear = a.PubYear,
			e.YearWeight = a.YearWeight,
			e.IsActive = 1,
			e.AuthorsString = a.AuthorsString
		FROM #authorship a, [Profile.Data].[Publication.Entity.Authorship] e
		WHERE a.EntityID = e.EntityID and a.EntityID is not null

	-- Insert new Authorships
	INSERT INTO [Profile.Data].[Publication.Entity.Authorship] (
			EntityDate,
			authorRank,
			numberOfAuthors,
			authorNameAsListed,
			authorWeight,
			authorPosition,
			PubYear,
			YearWeight,
			PersonID,
			InformationResourceID,
			IsActive,
			AuthorsString
		)
		SELECT 	EntityDate,
				authorRank,
				numberOfAuthors,
				authorNameAsListed,
				authorWeight,
				authorPosition,
				PubYear,
				YearWeight,
				PersonID,
				InformationResourceID,
				IsActive,
				AuthorsString
		FROM #authorship a
		WHERE EntityID IS NULL

	-- Assign an EntityName
	UPDATE [Profile.Data].[Publication.Entity.Authorship]
		SET EntityName = 'Authorship ' + CAST(EntityID as VARCHAR(50))
		WHERE EntityName is null
 
END
GO
PRINT N'Altering [Profile.Cache].[List.Export.UpdatePublications]...';


GO
ALTER PROCEDURE [Profile.Cache].[List.Export.UpdatePublications]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	SELECT *, ROW_NUMBER() OVER (PARTITION BY PersonID, EntityID ORDER BY PMID) k
		INTO #t
		FROM (
			SELECT p.PersonID, i.EntityID, FirstName, LastName, DisplayName, i.PMID, i.EntityDate, g.MedlineTA Source, i.EntityName Item, i.Reference, i.URL
				FROM [Profile.Cache].[Person] p 
					INNER JOIN [Profile.Data].[Publication.Entity.Authorship] a on p.PersonID = a.PersonID and a.IsActive = 1
					INNER JOIN [Profile.Data].[Publication.Entity.InformationResource] i on a.InformationResourceID = i.EntityID
					INNER JOIN [Profile.Data].[Publication.PubMed.General] g on i.PMID=g.PMID
				WHERE i.PMID IS NOT NULL
			UNION ALL
			SELECT p.PersonID, i.EntityID, FirstName, LastName, DisplayName, i.PMID, i.EntityDate, g.PubTitle Source, i.EntityName Item, i.Reference, i.URL
				FROM [Profile.Cache].[Person] p 
					INNER JOIN [Profile.Data].[Publication.Entity.Authorship] a on p.PersonID = a.PersonID and a.IsActive = 1
					INNER JOIN [Profile.Data].[Publication.Entity.InformationResource] i on a.InformationResourceID = i.EntityID
					INNER JOIN [Profile.Data].[Publication.MyPub.General] g on i.MPID=g.MPID
				WHERE i.PMID IS NULL AND i.MPID IS NOT NULL
		) t


	SELECT ISNULL(PersonID,-1) PersonID,
			ISNULL(ROW_NUMBER() OVER (PARTITION BY PersonID ORDER BY EntityDate, PMID, EntityID),-1) SortOrder,
			CAST(PersonID AS VARCHAR(50)) 
			+ ',"' + REPLACE(FirstName,'"','""') + '"'
			+ ',"' + REPLACE(LastName,'"','""') + '"'
			+ ',"' + REPLACE(DisplayName,'"','""') + '"'
			+ ',' + CAST(PMID AS VARCHAR(50))
			+ ',"' + CONVERT(VARCHAR(50), EntityDate, 101) + '"'
			+ ',"' + REPLACE(Source,'"','""') + '"'
			+ ',"' + REPLACE(Item,'"','""') + '"'
			+ ',"' + REPLACE(Reference,'"','""') + '"'
			+ ',"' + REPLACE(URL,'"','""') + '"'
			s
		INTO #p
		FROM #t
		WHERE k=1

	ALTER TABLE #p ADD PRIMARY KEY (PersonID, SortOrder)


	;WITH a AS (
		SELECT DISTINCT PersonID
		FROM #p
	)
	SELECT PersonID, SUBSTRING(Data,2,LEN(Data)) Data
		INTO #x
		FROM (
			SELECT PersonID, CAST((
					SELECT CHAR(10)+s
					FROM #p b
					WHERE b.PersonID=a.PersonID
					FOR XML PATH(''), TYPE
				) AS NVARCHAR(MAX)) Data
			FROM a
		) t

	
	TRUNCATE TABLE [Profile.Cache].[List.Export.Publications]

	INSERT INTO [Profile.Cache].[List.Export.Publications]
		SELECT * FROM #x

END
GO
PRINT N'Altering [Profile.Data].[Publication.MyPub.UpdatePublication]...';


GO
ALTER procedure [Profile.Data].[Publication.MyPub.UpdatePublication]
	@mpid nvarchar(50),
	@HMS_PUB_CATEGORY nvarchar(60) = '',
	@PUB_TITLE nvarchar(2000) = '',
	@ARTICLE_TITLE nvarchar(2000) = '',
	@CONF_EDITORS nvarchar(2000) = '',
	@CONF_LOC nvarchar(2000) = '',
	@EDITION nvarchar(30) = '',
	@PLACE_OF_PUB nvarchar(60) = '',
	@VOL_NUM nvarchar(30) = '',
	@PART_VOL_PUB nvarchar(15) = '',
	@ISSUE_PUB nvarchar(30) = '',
	@PAGINATION_PUB nvarchar(30) = '',
	@ADDITIONAL_INFO nvarchar(2000) = '',
	@PUBLISHER nvarchar(255) = '',
	@CONF_NM nvarchar(2000) = '',
	@CONF_DTS nvarchar(60) = '',
	@REPT_NUMBER nvarchar(35) = '',
	@CONTRACT_NUM nvarchar(35) = '',
	@DISS_UNIV_NM nvarchar(2000) = '',
	@NEWSPAPER_COL nvarchar(15) = '',
	@NEWSPAPER_SECT nvarchar(15) = '',
	@PUBLICATION_DT smalldatetime = '',
	@ABSTRACT varchar(max) = '',
	@AUTHORS varchar(max) = '',
	@URL varchar(1000) = '',
	@updated_by varchar(50) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	---------------------------------------------------
	-- Update the MyPub General information
	---------------------------------------------------
 
	UPDATE [Profile.Data].[Publication.MyPub.General] SET
		HmsPubCategory = @HMS_PUB_CATEGORY,
		PubTitle = @PUB_TITLE,
		ArticleTitle = @ARTICLE_TITLE,
		ConfEditors = @CONF_EDITORS,
		ConfLoc = @CONF_LOC,
		EDITION = @EDITION,
		PlaceOfPub = @PLACE_OF_PUB,
		VolNum = @VOL_NUM,
		PartVolPub = @PART_VOL_PUB,
		IssuePub = @ISSUE_PUB,
		PaginationPub = @PAGINATION_PUB,
		AdditionalInfo = @ADDITIONAL_INFO,
		PUBLISHER = @PUBLISHER,
		ConfNm = @CONF_NM,
		ConfDTs = @CONF_DTS,
		ReptNumber = @REPT_NUMBER,
		ContractNum = @CONTRACT_NUM,
		DissUnivNm = @DISS_UNIV_NM,
		NewspaperCol = @NEWSPAPER_COL,
		NewspaperSect = @NEWSPAPER_SECT,
		PublicationDT = @PUBLICATION_DT,
		ABSTRACT = @ABSTRACT,
		AUTHORS = @AUTHORS,
		URL = @URL,
		UpdatedBy = @updated_by,
		UpdatedDT = GetDate()
	WHERE mpid = @mpid
		and mpid not in (select mpid from [Profile.Data].[Publication.DSpace.MPID])
		and mpid not in (select mpid from [Profile.Data].[Publication.ISI.MPID])


	IF @@ROWCOUNT > 0
	BEGIN

		DECLARE @SQL NVARCHAR(MAX)

		---------------------------------------------------
		-- Update the InformationResource Entity
		---------------------------------------------------
	
		-- Get publication information
	
		CREATE TABLE #Publications
		(
			PMID INT NULL ,
			MPID NVARCHAR(50) NULL ,
			EntityDate DATETIME NULL ,
			Authors NVARCHAR(4000) NULL,
			Reference VARCHAR(MAX) NULL ,
			Source VARCHAR(25) NULL ,
			URL VARCHAR(1000) NULL ,
			Title VARCHAR(4000) NULL
		)

		INSERT  INTO #Publications
				( MPID ,
				  EntityDate ,
				  Authors,
				  Reference ,
				  Source ,
				  URL ,
				  Title
				)
				SELECT  MPID ,
						EntityDate ,
						Authors = REPLACE(authors, CHAR(11), '') ,
						Reference = REPLACE(--authors +
											(CASE WHEN IsNull(article,'') <> '' THEN article + '. ' ELSE '' END)
											+ (CASE WHEN IsNull(pub,'') <> '' THEN pub + '. ' ELSE '' END)
											+ y
											+ CASE WHEN y <> ''
														AND vip <> '' THEN '; '
												   ELSE ''
											  END + vip
											+ CASE WHEN y <> ''
														OR vip <> '' THEN '.'
												   ELSE ''
											  END, CHAR(11), '') ,
						Source = 'Custom' ,
						URL = url,
						Title = left((case when IsNull(article,'')<>'' then article when IsNull(pub,'')<>'' then pub else 'Untitled Publication' end),4000)
				FROM    ( SELECT    MPID ,
									EntityDate ,
									url ,
									authors = CASE WHEN authors = '' THEN ''
												   WHEN RIGHT(authors, 1) = '.'
												   THEN LEFT(authors,
															 LEN(authors) - 1)
												   ELSE authors
											  END ,
									article = CASE WHEN article = '' THEN ''
												   WHEN RIGHT(article, 1) = '.'
												   THEN LEFT(article,
															 LEN(article) - 1)
												   ELSE article
											  END ,
									pub = CASE WHEN pub = '' THEN ''
											   WHEN RIGHT(pub, 1) = '.'
											   THEN LEFT(pub, LEN(pub) - 1)
											   ELSE pub
										  END ,
									y ,
									vip
						  FROM      ( SELECT    MPG.mpid ,
												EntityDate = MPG.publicationdt ,
												authors = CASE WHEN RTRIM(LTRIM(COALESCE(MPG.authors,
																  ''))) = ''
															   THEN ''
															   WHEN RIGHT(COALESCE(MPG.authors,
																  ''), 1) = '.'
																THEN  COALESCE([Profile.Data].[fnPublication.MyPub.HighlightAuthors] (MPG.authors, p.FirstName, p.MiddleName, p.LastName),
																  '') + ' '
															   ELSE COALESCE([Profile.Data].[fnPublication.MyPub.HighlightAuthors] (MPG.authors, p.FirstName, p.MiddleName, p.LastName),
																  '') + '. '
														  END ,
												url = CASE WHEN COALESCE(MPG.url,
																  '') <> ''
																AND LEFT(COALESCE(MPG.url,
																  ''), 4) = 'http'
														   THEN MPG.url
														   WHEN COALESCE(MPG.url,
																  '') <> ''
														   THEN 'http://' + MPG.url
														   ELSE ''
													  END ,
												article = LTRIM(RTRIM(COALESCE(MPG.articletitle,
																  ''))) ,
												pub = LTRIM(RTRIM(COALESCE(MPG.pubtitle,
																  ''))) ,
												y = CASE WHEN MPG.publicationdt > '1/1/1901'
														 THEN CONVERT(VARCHAR(50), YEAR(MPG.publicationdt))
														 ELSE ''
													END ,
												vip = COALESCE(MPG.volnum, '')
												+ CASE WHEN COALESCE(MPG.issuepub,
																  '') <> ''
													   THEN '(' + MPG.issuepub
															+ ')'
													   ELSE ''
												  END
												+ CASE WHEN ( COALESCE(MPG.paginationpub,
																  '') <> '' )
															AND ( COALESCE(MPG.volnum,
																  '')
																  + COALESCE(MPG.issuepub,
																  '') <> '' )
													   THEN ':'
													   ELSE ''
												  END + COALESCE(MPG.paginationpub,
																 '')
									  FROM      [Profile.Data].[Publication.MyPub.General] MPG
									  join [Profile.Data].Person p on MPG.PersonID = p.PersonID
									  WHERE MPID = @mpid
									) T0
						) T0

		-- Update the entity record
		DECLARE @EntityID INT		
		UPDATE e
			SET e.EntityDate = p.EntityDate,
				e.Authors = p.Authors,
				e.Reference = p.Reference,
				e.Source = p.Source,
				e.URL = p.URL,
				@EntityID = e.EntityID
			FROM #publications p, [Profile.Data].[Publication.Entity.InformationResource] e
			WHERE p.MPID = e.MPID

		-- Update the RDF
		IF @EntityID IS NOT NULL
		BEGIN
			SELECT @SQL = ''
			SELECT @SQL = @SQL + 'EXEC [RDF.Stage].ProcessDataMap @DataMapID = '
								+CAST(DataMapID AS VARCHAR(50))
								+', @InternalIdIn = '
								+'''' + CAST(@EntityID AS VARCHAR(50)) + ''''
								+', @TurnOffIndexing=0, @SaveLog=0; '
				FROM [Ontology.].DataMap
				WHERE Class = 'http://vivoweb.org/ontology/core#InformationResource'
					AND NetworkProperty IS NULL
					AND Property IN (
										'http://www.w3.org/2000/01/rdf-schema#label',
										'http://profiles.catalyst.harvard.edu/ontology/prns#informationResourceReference',
										'http://profiles.catalyst.harvard.edu/ontology/prns#publicationDate',
										'http://profiles.catalyst.harvard.edu/ontology/prns#year'
									)
			EXEC sp_executesql @SQL
		END

		---------------------------------------------------
		-- Update the Authorship Entity
		---------------------------------------------------

		IF (@EntityID IS NOT NULL)
		BEGIN

			CREATE TABLE #Authorship
			(
				EntityDate DATETIME NULL ,
				authorRank INT NULL,
				numberOfAuthors INT NULL,
				authorNameAsListed VARCHAR(255) NULL,
				AuthorWeight FLOAT NULL,
				AuthorPosition VARCHAR(1) NULL,
				PubYear INT NULL ,
				YearWeight FLOAT NULL ,
				PersonID INT NULL ,
				InformationResourceID INT NULL,
				PMID INT NULL,
				IsActive BIT
			)

			INSERT INTO #Authorship (EntityDate, PersonID, InformationResourceID, PMID, IsActive)
				SELECT e.EntityDate, i.PersonID, e.EntityID, null PMID, 1 IsActive
					FROM [Profile.Data].[Publication.Entity.InformationResource] e,
						[Profile.Data].[Publication.Person.Include] i
					WHERE (e.MPID = i.MPID) and (e.MPID = @mpid) and (e.PMID is null)
		 
			UPDATE #authorship
				SET authorWeight = 0.5,
					authorPosition = 'U',
					PubYear = year(EntityDate),
					YearWeight = (case when EntityDate is null then 0.5
														when year(EntityDate) <= 1901 then 0.5
														else power(cast(0.5 as float),cast(datediff(d,EntityDate,GetDate()) as float)/365.25/10)
														end)

			-- Update the entity record
			SELECT @EntityID = NULL
			UPDATE e
				SET e.EntityDate = a.EntityDate,
					e.authorRank = a.authorRank,
					e.numberOfAuthors = a.numberOfAuthors,
					e.authorNameAsListed = a.authorNameAsListed,
					e.authorWeight = a.authorWeight,
					e.authorPosition = a.authorPosition,
					e.PubYear = a.PubYear,
					e.YearWeight = a.YearWeight,
					@EntityID = EntityID
				FROM #authorship a, [Profile.Data].[Publication.Entity.Authorship] e
				WHERE a.PersonID = e.PersonID and a.InformationResourceID = e.InformationResourceID

			-- Update the RDF
			/*
			IF @EntityID IS NOT NULL
			BEGIN
				SELECT @SQL = ''
				SELECT @SQL = @SQL + 'EXEC [RDF.Stage].ProcessDataMap @DataMapID = '
									+CAST(DataMapID AS VARCHAR(50))
									+', @InternalIdIn = '
									+'''' + CAST(@EntityID AS VARCHAR(50)) + ''''
									+', @TurnOffIndexing=0, @SaveLog=0; '
					FROM [Ontology.].DataMap
					WHERE Class = 'http://vivoweb.org/ontology/core#Authorship'
						AND NetworkProperty IS NULL
						AND Property IN (
											'http://www.w3.org/2000/01/rdf-schema#label',
											'http://profiles.catalyst.harvard.edu/ontology/prns#authorPosition',
											'http://profiles.catalyst.harvard.edu/ontology/prns#authorPositionWeight',
											'http://profiles.catalyst.harvard.edu/ontology/prns#authorshipWeight',
											'http://profiles.catalyst.harvard.edu/ontology/prns#numberOfAuthors',
											'http://vivoweb.org/ontology/core#authorRank'
										)
				EXEC sp_executesql @SQL
			END
			*/

		END

	END
 
END
GO
PRINT N'Altering [Profile.Module].[CustomViewAuthorInAuthorship.GetList]...';


GO
ALTER PROCEDURE [Profile.Module].[CustomViewAuthorInAuthorship.GetList]
	@NodeID bigint = NULL,
	@SessionID uniqueidentifier = NULL
AS
BEGIN

	DECLARE @SecurityGroupID BIGINT, @HasSpecialViewAccess BIT
	EXEC [RDF.Security].GetSessionSecurityGroup @SessionID, @SecurityGroupID OUTPUT, @HasSpecialViewAccess OUTPUT
	CREATE TABLE #SecurityGroupNodes (SecurityGroupNode BIGINT PRIMARY KEY)
	INSERT INTO #SecurityGroupNodes (SecurityGroupNode) EXEC [RDF.Security].GetSessionSecurityGroupNodes @SessionID, @NodeID


	declare @AuthorInAuthorship bigint
	select @AuthorInAuthorship = [RDF.].fnURI2NodeID('http://vivoweb.org/ontology/core#authorInAuthorship') 
	declare @LinkedInformationResource bigint
	select @LinkedInformationResource = [RDF.].fnURI2NodeID('http://vivoweb.org/ontology/core#linkedInformationResource') 


	select i.NodeID, p.EntityID, i.Value rdf_about, p.EntityName rdfs_label, 
		isnull(e.AuthorsString, p.Authors) + p.Reference prns_informationResourceReference, p.EntityDate prns_publicationDate,
		year(p.EntityDate) prns_year, p.pmid bibo_pmid, p.pmcid vivo_pmcid, p.doi bibo_doi, p.mpid prns_mpid, p.URL vivo_webpage, 
		isnull(b.PMCCitations, -1) as PMCCitations, isnull(Fields, '') as Fields, isnull(TranslationHumans , 0) as TranslationHumans, isnull(TranslationAnimals , 0) as TranslationAnimals, 
		isnull(TranslationCells , 0) as TranslationCells, isnull(TranslationPublicHealth , 0) as TranslationPublicHealth, isnull(TranslationClinicalTrial , 0) as TranslationClinicalTrial
	from [RDF.].[Triple] t
		inner join [RDF.].[Node] a
			on t.subject = @NodeID and t.predicate = @AuthorInAuthorship
				and t.object = a.NodeID
				and ((t.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (t.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (t.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)))
				and ((a.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (a.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (a.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)))
		inner join [RDF.].[Node] i
			on t.object = i.NodeID
				and ((i.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (i.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (i.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)))
		inner join [RDF.Stage].[InternalNodeMap] m
			on i.NodeID = m.NodeID
		inner join [Profile.Data].[Publication.Entity.Authorship] e
			on m.InternalID = e.EntityID
		inner join [Profile.Data].[Publication.Entity.InformationResource] p
			on e.InformationResourceID = p.EntityID
		left join [Profile.Data].[Publication.Pubmed.Bibliometrics] b on p.PMID = b.PMID
	order by p.EntityDate desc

END
GO
PRINT N'Altering [Profile.Module].[NetworkAuthorshipTimeline.Group.GetData]...';


GO
ALTER PROCEDURE [Profile.Module].[NetworkAuthorshipTimeline.Group.GetData]
	@NodeID BIGINT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @GroupID BIGINT
	SELECT @GroupID = CAST(m.InternalID AS INT)
		FROM [RDF.Stage].[InternalNodeMap] m, [RDF.].Node n
		WHERE m.Status = 3 AND m.ValueHash = n.ValueHash AND n.NodeID = @NodeID

    -- Insert statements for procedure here
	declare @gc varchar(max)

	declare @y table (
		y int,
		A int,
		B int
	)

	insert into @y (y,A,B)
		select n.n y, coalesce(t.A,0) A, coalesce(t.B,0) B
		from [Utility.Math].[N] left outer join (
			select (case when y < 1970 then 1970 else y end) y,
				sum(A) A,
				sum(B) B
			from (
				select pmid, pubyear y, 1 A, 0 B
				from (
					SELECT pmid, pubyear
					  FROM [Profile.Data].[vwGroup.Publication.Entity.AssociatedInformationResource] a
					  join [Profile.Data].[vwPublication.Entity.InformationResource] b on a.EntityID = b.EntityID
					  and a.GroupID = @GroupID
				) t
			) t
			group by y
		) t on n.n = t.y
		where n.n between year(getdate())-30 and year(getdate())

	declare @x int

	select @x = max(A+B)
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

		declare @d varchar(max)
		set @d = ''
		select @d = @d + cast(floor(0.5 + 100*A/@w) as varchar(50)) + ','
			from @y
			order by y
		set @d = left(@d,len(@d)-1) + '|'
		select @d = @d + cast(floor(0.5 + 100*B/@w) as varchar(50)) + ','
			from @y
			order by y
		set @d = left(@d,len(@d)-1)

		declare @c varchar(50)
		set @c = 'FB8072,80B1D3'
		--set @c = 'FB8072,B3DE69,80B1D3'
		--set @c = 'F96452,a8dc4f,68a4cc'
		--set @c = 'fea643,76cbbd,b56cb5'

		--select @v, @h, @d

		--set @gc = '//chart.googleapis.com/chart?chs=595x100&chf=bg,s,ffffff|c,s,ffffff&chxt=x,y&chxl=0:' + @h + '|1:' + @v + '&cht=bvs&chd=t:' + @d + '&chdl=First+Author|Middle or Unkown|Last+Author&chco='+@c+'&chbh=10'
		--set @gc = '//chart.googleapis.com/chart?chs=595x100&chf=bg,s,ffffff|c,s,ffffff&chxt=x,y&chxl=0:' + @h + '|1:' + @v + '&cht=bvs&chd=t:' + @d + '&chdl=Major+Topic|Minor+Topic&chco='+@c+'&chbh=10'
		set @gc = '//chart.googleapis.com/chart?chs=595x100&chf=bg,s,ffffff|c,s,ffffff&chxt=x,y&chxl=0:' + @h + '|1:' + @v + '&cht=bvs&chd=t:' + @d + '&chco='+@c+'&chbh=10'


		declare @asText varchar(max)
		set @asText = '<table style="width:592px"><tr><th>Year</th><th>Count</th></tr>'
		select @asText = @asText + '<tr><td style="text-align:center;">' + cast(y as varchar(50)) + '</td><td style="text-align:center;">' + cast(A + B as varchar(50)) + '</td></tr>'
			from @y
			where A + B > 0
			order by y 
		select @asText = @asText + '</table>'

		declare @alt varchar(max)
		select @alt = 'Bar chart showing ' + cast(sum(A + B) as varchar(50))+ ' publications over ' + cast(count(*) as varchar(50)) + ' distinct years, with a maximum of ' + cast(@x as varchar(50)) + ' publications in ' from @y where A + B > 0
		select @alt = @alt + cast(y as varchar(50)) + ' and '
			from @y
			where A + B = @x
			order by y 
		select @alt = left(@alt, len(@alt) - 4)

		select @gc gc, @alt alt, @asText asText --, @w w

		--select * from @y order by y

	end

END
GO
PRINT N'Altering [Profile.Data].[Publication.Entity.UpdateEntityOneGroup]...';


GO
ALTER PROCEDURE [Profile.Data].[Publication.Entity.UpdateEntityOneGroup]
	@GroupID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

 
	-- *******************************************************************
	-- *******************************************************************
	-- Update InformationResource entities
	-- *******************************************************************
	-- *******************************************************************

	CREATE TABLE #tmpEntityIDs(EntityID int primary key)
	insert into #tmpEntityIDs
	select EntityID from [Profile.Data].[Publication.Entity.InformationResource]
		where PMID in (	SELECT PMID 
						FROM [Profile.Data].[Publication.Group.Include]
						WHERE PMID IS NOT NULL AND GroupID = @GroupID)
			and IsActive = 0

	update [Profile.Data].[Publication.Entity.InformationResource] set IsActive = 1 
		where EntityID in (select EntityID from #tmpEntityIDs)

 
	----------------------------------------------------------------------
	-- Get a list of current publications
	----------------------------------------------------------------------
 
	CREATE TABLE #Publications
	(
		PMID INT NULL ,
		MPID NVARCHAR(50) NULL ,
		PMCID NVARCHAR(55) NULL,
		doi [varchar](100) NULL,				  
		EntityDate DATETIME NULL ,
		Authors NVARCHAR(4000) NULL,					  
		Reference NVARCHAR(MAX) NULL ,
		Source VARCHAR(25) NULL ,
		URL VARCHAR(1000) NULL ,
		Title NVARCHAR(4000) NULL
				   
	)
 
	-- Add PMIDs to the publications temp table
	INSERT  INTO #Publications
            ( PMID ,
			  PMCID,
              EntityDate ,
			  Authors,
              Reference ,
              Source ,
              URL ,
              Title
            )
            SELECT -- Get Pub Med pubs
                    PG.PMID ,
					PG.PMCID,
                    EntityDate = PG.PubDate,
					authors = case when right(PG.Authors,5) = 'et al' then PG.Authors+'. '
								when PG.AuthorListCompleteYN = 'N' then PG.Authors+', et al. '
								when PG.Authors <> '' then PG.Authors+'. '
								else '' end,				  
                    Reference = REPLACE([Profile.Cache].[fnPublication.Pubmed.General2Reference](PG.PMID,
                                                              PG.ArticleDay,
                                                              PG.ArticleMonth,
                                                              PG.ArticleYear,
                                                              PG.ArticleTitle,
                                                              PG.Authors,
                                                              PG.AuthorListCompleteYN,
                                                              PG.Issue,
                                                              PG.JournalDay,
                                                              PG.JournalMonth,
                                                              PG.JournalYear,
                                                              PG.MedlineDate,
                                                              PG.MedlinePgn,
                                                              PG.MedlineTA,
                                                              PG.Volume, 0),
                                        CHAR(11), '') ,
                    Source = 'PubMed',
                    URL = 'http://www.ncbi.nlm.nih.gov/pubmed/' + CAST(ISNULL(PG.pmid, '') AS VARCHAR(20)),
                    Title = left((case when IsNull(PG.ArticleTitle,'') <> '' then PG.ArticleTitle else 'Untitled Publication' end),4000)
            FROM    [Profile.Data].[Publication.PubMed.General] PG
			WHERE	PG.PMID IN (
						SELECT PMID 
						FROM [Profile.Data].[Publication.Group.Include]
						WHERE PMID IS NOT NULL AND GroupID = @GroupID
					)
					AND PG.PMID NOT IN (
						SELECT PMID
						FROM [Profile.Data].[Publication.Entity.InformationResource]
						WHERE PMID IS NOT NULL
					)
 
	-- Add MPIDs to the publications temp table
	INSERT  INTO #Publications
            ( MPID ,
              EntityDate ,
			  Authors,
			  Reference ,
			  Source ,
              URL ,
              Title
            )
            SELECT  MPID ,
                    EntityDate ,
					Authors = REPLACE(authors, CHAR(11), '') ,
 
                    Reference = REPLACE( (CASE WHEN IsNull(article,'') <> '' THEN article + '. ' ELSE '' END)
										+ (CASE WHEN IsNull(pub,'') <> '' THEN pub + '. ' ELSE '' END)
										+ y
                                        + CASE WHEN y <> ''
                                                    AND vip <> '' THEN '; '
                                               ELSE ''
                                          END + vip
                                        + CASE WHEN y <> ''
                                                    OR vip <> '' THEN '.'
                                               ELSE ''
                                          END, CHAR(11), '') ,
                    Source = 'Custom' ,
                    URL = url,
                    Title = left((case when IsNull(article,'')<>'' then article when IsNull(pub,'')<>'' then pub else 'Untitled Publication' end),4000)
            FROM    ( SELECT    MPID ,
                                EntityDate ,
                                url ,
                                authors = CASE WHEN authors = '' THEN ''
                                               WHEN RIGHT(authors, 1) = '.'
                                               THEN LEFT(authors,
                                                         LEN(authors) - 1)
                                               ELSE authors
                                          END ,
                                article = CASE WHEN article = '' THEN ''
                                               WHEN RIGHT(article, 1) = '.'
                                               THEN LEFT(article,
                                                         LEN(article) - 1)
                                               ELSE article
                                          END ,
                                pub = CASE WHEN pub = '' THEN ''
                                           WHEN RIGHT(pub, 1) = '.'
                                           THEN LEFT(pub, LEN(pub) - 1)
                                           ELSE pub
                                      END ,
                                y ,
                                vip
                      FROM      ( SELECT    MPG.mpid ,
                                            EntityDate = MPG.publicationdt ,
                                            authors = CASE WHEN RTRIM(LTRIM(COALESCE(MPG.authors,
                                                              ''))) = ''
                                                           THEN ''
                                                           WHEN RIGHT(COALESCE(MPG.authors,
                                                              ''), 1) = '.'
                                                            THEN  COALESCE(MPG.authors,
                                                              '') + ' '
                                                           ELSE COALESCE(MPG.authors,
                                                              '') + '. '
                                                      END ,
                                            url = CASE WHEN COALESCE(MPG.url,
                                                              '') <> ''
                                                            AND LEFT(COALESCE(MPG.url,
                                                              ''), 4) = 'http'
                                                       THEN MPG.url
                                                       WHEN COALESCE(MPG.url,
                                                              '') <> ''
                                                       THEN 'http://' + MPG.url
                                                       ELSE ''
                                                  END ,
                                            article = LTRIM(RTRIM(COALESCE(MPG.articletitle,
                                                              ''))) ,
                                            pub = LTRIM(RTRIM(COALESCE(MPG.pubtitle,
                                                              ''))) ,
                                            y = CASE WHEN MPG.publicationdt > '1/1/1901'
                                                     THEN CONVERT(VARCHAR(50), YEAR(MPG.publicationdt))
                                                     ELSE ''
                                                END ,
                                            vip = COALESCE(MPG.volnum, '')
                                            + CASE WHEN COALESCE(MPG.issuepub,
                                                              '') <> ''
                                                   THEN '(' + MPG.issuepub
                                                        + ')'
                                                   ELSE ''
                                              END
                                            + CASE WHEN ( COALESCE(MPG.paginationpub,
                                                              '') <> '' )
                                                        AND ( COALESCE(MPG.volnum,
                                                              '')
                                                              + COALESCE(MPG.issuepub,
                                                              '') <> '' )
                                                   THEN ':'
                                                   ELSE ''
                                              END + COALESCE(MPG.paginationpub,
                                                             '')
                                  FROM      [Profile.Data].[Publication.Group.MyPub.General] MPG
                                  INNER JOIN [Profile.Data].[Publication.Group.Include] PL ON MPG.mpid = PL.mpid
                                                           AND PL.mpid NOT LIKE 'DASH%'
                                                           AND PL.mpid NOT LIKE 'ISI%'
                                                           AND PL.pmid IS NULL
                                                           AND PL.GroupID = @GroupID
																 
									WHERE MPG.MPID NOT IN (
										SELECT MPID
										FROM [Profile.Data].[Publication.Entity.InformationResource]
										WHERE (MPID IS NOT NULL)
									)
                                ) T0
                    ) T0
 
	CREATE NONCLUSTERED INDEX idx_pmid on #publications(pmid)
	CREATE NONCLUSTERED INDEX idx_mpid on #publications(mpid)

	declare @baseURI varchar(255)
	select @baseURI = Value From [Framework.].Parameter where ParameterID = 'baseURI'
	select a.PmPubsAuthorID, a.pmid, a2p.personID, isnull(Lastname + ' ' + Initials, CollectiveName) as Name, case when nodeID is not null then'<a href="' + @baseURI + cast(i.nodeID as varchar(55)) + '">'+ Lastname + ' ' + Initials + '</a>' else isnull(Lastname + ' ' + Initials, CollectiveName) END as link into #tmpAuthorLinks from [Profile.Data].[Publication.PubMed.Author] a 
		join #publications p on a.pmid = p.pmid
		left outer join [Profile.Data].[Publication.PubMed.Author2Person] a2p on a.PmPubsAuthorID = a2p.PmPubsAuthorID
		left outer join [RDF.Stage].InternalNodeMap i on a2p.PersonID = i.InternalID and i.class = 'http://xmlns.com/foaf/0.1/Person'

	select pmid, [Profile.Data].[fnPublication.Pubmed.ShortenAuthorLengthString](replace(replace(isnull(cast((
		select ', '+ link
		from #tmpAuthorLinks q
		where q.pmid = p.pmid
		order by PmPubsAuthorID
		for xml path(''), type
		) as nvarchar(max)),''), '&lt;' , '<'), '&gt;', '>')) s
		into #tmpPublicationLinks from #publications p where pmid is not null

	update g set g.Authors = t.s from #publications g
		join #tmpPublicationLinks t on g.PMID = t.PMID 							  
							  
	----------------------------------------------------------------------
	-- Update the Publication.Entity.InformationResource table
	----------------------------------------------------------------------

	DECLARE @maxEntityId AS INT
	select @maxEntityId = MAX(cast(InternalID as int)) from [RDF.Stage].InternalNodeMap where class = 'http://vivoweb.org/ontology/core#InformationResource'  AND InternalType = 'InformationResource'
  
	-- Insert new publications
	INSERT INTO [Profile.Data].[Publication.Entity.InformationResource] (
			PMID,
			PMCID,
			MPID,
			EntityName,
			EntityDate,
		    Authors,
			Reference,
			Source,
			URL,
			IsActive,
			PubYear,
			YearWeight		   
		)
		SELECT 	PMID,
				PMCID,
				MPID,
				Title,
				EntityDate,
				Authors,			
				Reference,
				Source,
				URL,
				1 IsActive,
				PubYear = year(EntityDate),
				YearWeight = (case when EntityDate is null then 0.5
								when year(EntityDate) <= 1901 then 0.5
								else power(cast(0.5 as float),cast(datediff(d,EntityDate,GetDate()) as float)/365.25/10)
								end)
		FROM #publications

	-- *******************************************************************
	-- *******************************************************************
	-- Update RDF
	-- *******************************************************************
	-- *******************************************************************
	--------------------------------------------------------------
	-- Version 3 : Create stub RDF
	--------------------------------------------------------------
	CREATE TABLE #sql (
		i INT IDENTITY(0,1) PRIMARY KEY,
		s NVARCHAR(MAX)
	)
	INSERT INTO #sql (s)
		SELECT	'EXEC [RDF.Stage].ProcessDataMap '
					+'  @DataMapID = '+CAST(DataMapID AS VARCHAR(50))
					+', @InternalIdIn = '+InternalIdIn
					+', @TurnOffIndexing=0, @SaveLog=0; '
		FROM (
		  	SELECT DataMapID, '''SELECT CAST (EntityID AS VARCHAR(50)) FROM [Profile.Data].[Publication.Entity.InformationResource] WHERE EntityID > ' + CAST(@maxEntityId AS VARCHAR(50)) + '''' InternalIdIn
				FROM [Ontology.].DataMap
				WHERE class = 'http://vivoweb.org/ontology/core#InformationResource' 
					AND property IS NULL
					AND NetworkProperty IS NULL
			UNION ALL
			SELECT (Select DataMapID FROM [Ontology.].DataMap WHERE class = 'http://vivoweb.org/ontology/core#InformationResource' AND property IS NULL	AND NetworkProperty IS NULL) DataMapID,
				'''SELECT CAST (EntityID AS VARCHAR(50)) FROM [Profile.Data].[Publication.Entity.InformationResource] WHERE EntityID = ' + CAST(EntityID AS VARCHAR(50)) + '''' InternalIdIn
				FROM #tmpEntityIDs
			UNION ALL
			SELECT DataMapID, '''' + CAST(@GroupID AS VARCHAR(50)) + '''' InternalIdIn
				FROM [Ontology.].DataMap
				WHERE class = 'http://xmlns.com/foaf/0.1/Group'
					AND property = 'http://profiles.catalyst.harvard.edu/ontology/prns#associatedInformationResource'
					AND NetworkProperty IS NULL
		) t
		ORDER BY DataMapID

	DECLARE @s NVARCHAR(MAX)
	WHILE EXISTS (SELECT * FROM #sql)
	BEGIN
		SELECT @s = s
			FROM #sql
			WHERE i = (SELECT MIN(i) FROM #sql)
		print @s
		EXEC sp_executesql @s
		DELETE
			FROM #sql
			WHERE i = (SELECT MIN(i) FROM #sql)
	END
END
GO
PRINT N'Altering [Profile.Data].[Publication.Group.MyPub.UpdatePublication]...';


GO
ALTER  procedure [Profile.Data].[Publication.Group.MyPub.UpdatePublication]
	@mpid nvarchar(50),
	@HMS_PUB_CATEGORY nvarchar(60) = '',
	@PUB_TITLE nvarchar(2000) = '',
	@ARTICLE_TITLE nvarchar(2000) = '',
	@CONF_EDITORS nvarchar(2000) = '',
	@CONF_LOC nvarchar(2000) = '',
	@EDITION nvarchar(30) = '',
	@PLACE_OF_PUB nvarchar(60) = '',
	@VOL_NUM nvarchar(30) = '',
	@PART_VOL_PUB nvarchar(15) = '',
	@ISSUE_PUB nvarchar(30) = '',
	@PAGINATION_PUB nvarchar(30) = '',
	@ADDITIONAL_INFO nvarchar(2000) = '',
	@PUBLISHER nvarchar(255) = '',
	@CONF_NM nvarchar(2000) = '',
	@CONF_DTS nvarchar(60) = '',
	@REPT_NUMBER nvarchar(35) = '',
	@CONTRACT_NUM nvarchar(35) = '',
	@DISS_UNIV_NM nvarchar(2000) = '',
	@NEWSPAPER_COL nvarchar(15) = '',
	@NEWSPAPER_SECT nvarchar(15) = '',
	@PUBLICATION_DT smalldatetime = '',
	@ABSTRACT varchar(max) = '',
	@AUTHORS varchar(max) = '',
	@URL varchar(1000) = '',
	@updated_by varchar(50) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	---------------------------------------------------
	-- Update the MyPub General information
	---------------------------------------------------
 
	UPDATE [Profile.Data].[Publication.Group.MyPub.General] SET
		HmsPubCategory = @HMS_PUB_CATEGORY,
		PubTitle = @PUB_TITLE,
		ArticleTitle = @ARTICLE_TITLE,
		ConfEditors = @CONF_EDITORS,
		ConfLoc = @CONF_LOC,
		EDITION = @EDITION,
		PlaceOfPub = @PLACE_OF_PUB,
		VolNum = @VOL_NUM,
		PartVolPub = @PART_VOL_PUB,
		IssuePub = @ISSUE_PUB,
		PaginationPub = @PAGINATION_PUB,
		AdditionalInfo = @ADDITIONAL_INFO,
		PUBLISHER = @PUBLISHER,
		ConfNm = @CONF_NM,
		ConfDTs = @CONF_DTS,
		ReptNumber = @REPT_NUMBER,
		ContractNum = @CONTRACT_NUM,
		DissUnivNm = @DISS_UNIV_NM,
		NewspaperCol = @NEWSPAPER_COL,
		NewspaperSect = @NEWSPAPER_SECT,
		PublicationDT = @PUBLICATION_DT,
		ABSTRACT = @ABSTRACT,
		AUTHORS = @AUTHORS,
		URL = @URL,
		UpdatedBy = @updated_by,
		UpdatedDT = GetDate()
	WHERE mpid = @mpid
		and mpid not in (select mpid from [Profile.Data].[Publication.DSpace.MPID])
		and mpid not in (select mpid from [Profile.Data].[Publication.ISI.MPID])


	IF @@ROWCOUNT > 0
	BEGIN

		DECLARE @SQL NVARCHAR(MAX)

		---------------------------------------------------
		-- Update the InformationResource Entity
		---------------------------------------------------
	
		-- Get publication information
	
		CREATE TABLE #Publications
		(
			PMID INT NULL ,
			MPID NVARCHAR(50) NULL ,
			EntityDate DATETIME NULL ,
			Reference VARCHAR(MAX) NULL ,
			Source VARCHAR(25) NULL ,
			URL VARCHAR(1000) NULL ,
			Title VARCHAR(4000) NULL
		)

		INSERT  INTO #Publications
				( MPID ,
				  EntityDate ,
				  Reference ,
				  Source ,
				  URL ,
				  Title
				)
				SELECT  MPID ,
						EntityDate ,
						Reference = REPLACE(--authors
											 (CASE WHEN IsNull(article,'') <> '' THEN article + '. ' ELSE '' END)
											+ (CASE WHEN IsNull(pub,'') <> '' THEN pub + '. ' ELSE '' END)
											+ y
											+ CASE WHEN y <> ''
														AND vip <> '' THEN '; '
												   ELSE ''
											  END + vip
											+ CASE WHEN y <> ''
														OR vip <> '' THEN '.'
												   ELSE ''
											  END, CHAR(11), '') ,
						Source = 'Custom' ,
						URL = url,
						Title = left((case when IsNull(article,'')<>'' then article when IsNull(pub,'')<>'' then pub else 'Untitled Publication' end),4000)
				FROM    ( SELECT    MPID ,
									EntityDate ,
									url ,
									authors = CASE WHEN authors = '' THEN ''
												   WHEN RIGHT(authors, 1) = '.'
												   THEN LEFT(authors,
															 LEN(authors) - 1)
												   ELSE authors
											  END ,
									article = CASE WHEN article = '' THEN ''
												   WHEN RIGHT(article, 1) = '.'
												   THEN LEFT(article,
															 LEN(article) - 1)
												   ELSE article
											  END ,
									pub = CASE WHEN pub = '' THEN ''
											   WHEN RIGHT(pub, 1) = '.'
											   THEN LEFT(pub, LEN(pub) - 1)
											   ELSE pub
										  END ,
									y ,
									vip
						  FROM      ( SELECT    MPG.mpid ,
												EntityDate = MPG.publicationdt ,
												authors = CASE WHEN RTRIM(LTRIM(COALESCE(MPG.authors,
																  ''))) = ''
															   THEN ''
															   WHEN RIGHT(COALESCE(MPG.authors,
																  ''), 1) = '.'
																THEN  COALESCE(MPG.authors,
																  '') + ' '
															   ELSE COALESCE(MPG.authors,
																  '') + '. '
														  END ,
												url = CASE WHEN COALESCE(MPG.url,
																  '') <> ''
																AND LEFT(COALESCE(MPG.url,
																  ''), 4) = 'http'
														   THEN MPG.url
														   WHEN COALESCE(MPG.url,
																  '') <> ''
														   THEN 'http://' + MPG.url
														   ELSE ''
													  END ,
												article = LTRIM(RTRIM(COALESCE(MPG.articletitle,
																  ''))) ,
												pub = LTRIM(RTRIM(COALESCE(MPG.pubtitle,
																  ''))) ,
												y = CASE WHEN MPG.publicationdt > '1/1/1901'
														 THEN CONVERT(VARCHAR(50), YEAR(MPG.publicationdt))
														 ELSE ''
													END ,
												vip = COALESCE(MPG.volnum, '')
												+ CASE WHEN COALESCE(MPG.issuepub,
																  '') <> ''
													   THEN '(' + MPG.issuepub
															+ ')'
													   ELSE ''
												  END
												+ CASE WHEN ( COALESCE(MPG.paginationpub,
																  '') <> '' )
															AND ( COALESCE(MPG.volnum,
																  '')
																  + COALESCE(MPG.issuepub,
																  '') <> '' )
													   THEN ':'
													   ELSE ''
												  END + COALESCE(MPG.paginationpub,
																 '')
									  FROM      [Profile.Data].[Publication.Group.MyPub.General] MPG
									  WHERE MPID = @mpid
									) T0
						) T0

		-- Update the entity record
		DECLARE @EntityID INT		
		UPDATE e
			SET e.EntityDate = p.EntityDate,
				e.Reference = p.Reference,
				e.Source = p.Source,
				e.URL = p.URL,
				@EntityID = e.EntityID
			FROM #publications p, [Profile.Data].[Publication.Entity.InformationResource] e
			WHERE p.MPID = e.MPID

	END
 
END
GO
PRINT N'Altering [Profile.Module].[CustomViewAuthorInAuthorship.GetGroupList]...';


GO
ALTER PROCEDURE [Profile.Module].[CustomViewAuthorInAuthorship.GetGroupList]
	@NodeID bigint = NULL,
	@SessionID uniqueidentifier = NULL
AS
BEGIN

	DECLARE @SecurityGroupID BIGINT, @HasSpecialViewAccess BIT
	EXEC [RDF.Security].GetSessionSecurityGroup @SessionID, @SecurityGroupID OUTPUT, @HasSpecialViewAccess OUTPUT
	CREATE TABLE #SecurityGroupNodes (SecurityGroupNode BIGINT PRIMARY KEY)
	INSERT INTO #SecurityGroupNodes (SecurityGroupNode) EXEC [RDF.Security].GetSessionSecurityGroupNodes @SessionID, @NodeID


	declare @AssociatedInformationResource bigint
	select @AssociatedInformationResource = [RDF.].fnURI2NodeID('http://profiles.catalyst.harvard.edu/ontology/prns#associatedInformationResource') 


	select i.NodeID, p.EntityID, i.Value rdf_about, p.EntityName rdfs_label, 
		isnull(p.authors, '') + p.Reference prns_informationResourceReference, p.EntityDate prns_publicationDate,
		year(p.EntityDate) prns_year, p.pmid bibo_pmid, p.pmcid vivo_pmcid, p.doi bibo_doi, p.mpid prns_mpid, p.URL vivo_webpage,
		isnull(b.PMCCitations, -1) as PMCCitations, isnull(Fields, '') as Fields, isnull(TranslationHumans , 0) as TranslationHumans, isnull(TranslationAnimals , 0) as TranslationAnimals, 
		isnull(TranslationCells , 0) as TranslationCells, isnull(TranslationPublicHealth , 0) as TranslationPublicHealth, isnull(TranslationClinicalTrial , 0) as TranslationClinicalTrial
	from [RDF.].[Triple] t
		inner join [RDF.].[Node] a
			on t.subject = @NodeID and t.predicate = @AssociatedInformationResource
				and t.object = a.NodeID
				and ((t.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (t.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (t.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)))
				and ((a.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (a.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (a.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)))
		inner join [RDF.].[Node] i
			on t.object = i.NodeID
				and ((i.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (i.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (i.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)))
		inner join [RDF.Stage].[InternalNodeMap] m
			on i.NodeID = m.NodeID
		inner join [Profile.Data].[Publication.Entity.InformationResource] p
			on m.InternalID = p.EntityID
		left join [Profile.Data].[Publication.Pubmed.Bibliometrics] b on p.PMID = b.PMID
	order by p.EntityDate desc
END
GO
PRINT N'Altering [Framework.].[LoadInstallData]...';


GO
ALTER procedure [Framework.].[LoadInstallData]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

 DECLARE @x XML
 SELECT @x = ( SELECT TOP 1
                        Data
               FROM     [Framework.].[InstallData]
               ORDER BY InstallDataID DESC
             ) 

---------------------------------------------------------------
-- [Utility.Math]
---------------------------------------------------------------


-- [Utility.Math].N
; WITH   E00 ( N )
          AS ( SELECT   1
               UNION ALL
               SELECT   1
             ),
        E02 ( N )
          AS ( SELECT   1
               FROM     E00 a ,
                        E00 b
             ),
        E04 ( N )
          AS ( SELECT   1
               FROM     E02 a ,
                        E02 b
             ),
        E08 ( N )
          AS ( SELECT   1
               FROM     E04 a ,
                        E04 b
             ),
        E16 ( N )
          AS ( SELECT   1
               FROM     E08 a ,
                        E08 b
             ),
        E32 ( N )
          AS ( SELECT   1
               FROM     E16 a ,
                        E16 b
             ),
        cteTally ( N )
          AS ( SELECT   ROW_NUMBER() OVER ( ORDER BY N )
               FROM     E32
             )
    
    INSERT INTO [Utility.Math].N
    SELECT  N -1
    FROM    cteTally
    WHERE   N <= 100000 ; 
			 
---------------------------------------------------------------
-- [Framework.]
---------------------------------------------------------------
 
             
-- [Framework.].[Parameter]
TRUNCATE TABLE [Framework.].[Parameter]
INSERT INTO [Framework.].Parameter
	( ParameterID, Value )        
SELECT	R.x.value('ParameterID[1]', 'varchar(max)') ,
		R.x.value('Value[1]', 'varchar(max)')
FROM    ( SELECT
			@x.query
			('Import[1]/Table[@Name=''[Framework.].[Parameter]'']')
			x
		) t
CROSS APPLY x.nodes('//Row') AS R ( x )

  
       
-- [Framework.].[RestPath] 
INSERT INTO [Framework.].RestPath
        ( ApplicationName, Resolver )   
SELECT  R.x.value('ApplicationName[1]', 'varchar(max)') ,
        R.x.value('Resolver[1]', 'varchar(max)') 
FROM    ( SELECT
                    @x.query
                    ('Import[1]/Table[@Name=''[Framework.].[RestPath]'']')
                    x
        ) t
CROSS APPLY x.nodes('//Row') AS R ( x )

   
--[Framework.].[Job]
INSERT INTO [Framework.].Job
        ( JobID,
		  JobGroup,
          Step,
          IsActive,
          Script
        ) 
SELECT	Row_Number() OVER (ORDER BY (SELECT 1)),
		R.x.value('JobGroup[1]','varchar(max)'),
		R.x.value('Step[1]','varchar(max)'),
		R.x.value('IsActive[1]','varchar(max)'),
		R.x.value('Script[1]','varchar(max)')
FROM    ( SELECT
                  @x.query
                  ('Import[1]/Table[@Name=''[Framework.].[Job]'']')
                  x
      ) t
CROSS APPLY x.nodes('//Row') AS R ( x )

	
--[Framework.].[JobGroup]
INSERT INTO [Framework.].JobGroup
        ( JobGroup, Name, Type, Description ) 
SELECT	R.x.value('JobGroup[1]','varchar(max)'),
		R.x.value('Name[1]','varchar(max)'),
		R.x.value('Type[1]','varchar(max)'),
		R.x.value('Description[1]','varchar(max)')
FROM    ( SELECT
                  @x.query
                  ('Import[1]/Table[@Name=''[Framework.].[JobGroup]'']')
                  x
      ) t
CROSS APPLY x.nodes('//Row') AS R ( x )
       
  

---------------------------------------------------------------
-- [Ontology.]
---------------------------------------------------------------
 
 --[Ontology.].[ClassGroup]
 TRUNCATE TABLE [Ontology.].[ClassGroup]
 INSERT INTO [Ontology.].ClassGroup
         ( ClassGroupURI,
           SortOrder,
           IsVisible
         )
  SELECT  R.x.value('ClassGroupURI[1]', 'varchar(max)') ,
          R.x.value('SortOrder[1]', 'varchar(max)'),
          R.x.value('IsVisible[1]', 'varchar(max)')
  FROM    ( SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[Ontology.].[ClassGroup]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x ) 
  
 --[Ontology.].[ClassGroupClass]
 TRUNCATE TABLE [Ontology.].[ClassGroupClass]
 INSERT INTO [Ontology.].ClassGroupClass
         ( ClassGroupURI,
           ClassURI,
           SortOrder
         )
  SELECT  R.x.value('ClassGroupURI[1]', 'varchar(max)') ,
          R.x.value('ClassURI[1]', 'varchar(max)'),
          R.x.value('SortOrder[1]', 'varchar(max)')
  FROM    ( SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[Ontology.].[ClassGroupClass]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )

  
--[Ontology.].[ClassProperty]
INSERT INTO [Ontology.].ClassProperty
        ( ClassPropertyID,
          Class,
          NetworkProperty,
          Property,
          IsDetail,
          Limit,
          IncludeDescription,
          IncludeNetwork,
          SearchWeight,
          CustomDisplay,
          CustomEdit,
          ViewSecurityGroup,
          EditSecurityGroup,
          EditPermissionsSecurityGroup,
          EditExistingSecurityGroup,
          EditAddNewSecurityGroup,
          EditAddExistingSecurityGroup,
          EditDeleteSecurityGroup,
          MinCardinality,
          MaxCardinality,
          CustomDisplayModule,
          CustomEditModule
        )
SELECT  Row_Number() OVER (ORDER BY (SELECT 1)),
		R.x.value('Class[1]','varchar(max)'),
		R.x.value('NetworkProperty[1]','varchar(max)'),
		R.x.value('Property[1]','varchar(max)'),
		R.x.value('IsDetail[1]','varchar(max)'),
		R.x.value('Limit[1]','varchar(max)'),
		R.x.value('IncludeDescription[1]','varchar(max)'),
		R.x.value('IncludeNetwork[1]','varchar(max)'),
		R.x.value('SearchWeight[1]','varchar(max)'),
		R.x.value('CustomDisplay[1]','varchar(max)'),
		R.x.value('CustomEdit[1]','varchar(max)'),
		R.x.value('ViewSecurityGroup[1]','varchar(max)'),
		R.x.value('EditSecurityGroup[1]','varchar(max)'),
		R.x.value('EditPermissionsSecurityGroup[1]','varchar(max)'),
		R.x.value('EditExistingSecurityGroup[1]','varchar(max)'),
		R.x.value('EditAddNewSecurityGroup[1]','varchar(max)'),
		R.x.value('EditAddExistingSecurityGroup[1]','varchar(max)'),
		R.x.value('EditDeleteSecurityGroup[1]','varchar(max)'),
		R.x.value('MinCardinality[1]','varchar(max)'),
		R.x.value('MaxCardinality[1]','varchar(max)'),
		(case when CAST(R.x.query('CustomDisplayModule[1]/*') AS NVARCHAR(MAX))<>'' then R.x.query('CustomDisplayModule[1]/*') else NULL end),
		(case when CAST(R.x.query('CustomEditModule[1]/*') AS NVARCHAR(MAX))<>'' then R.x.query('CustomEditModule[1]/*') else NULL end)
  FROM    ( SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[Ontology.].[ClassProperty]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )

  
    --[Ontology.].[ClassPropertyCustom]
  INSERT INTO [Ontology.].ClassPropertyCustom
        ( _ClassPropertyID,
		  ClassPropertyCustomTypeID,
          Class,
          NetworkProperty,
          Property,
		  IncludeProperty,
          IsDetail,
          Limit,
          IncludeDescription,
          IncludeNetwork
        )
  SELECT  Row_Number() OVER (ORDER BY (SELECT 1) + 1000),
		R.x.value('ClassPropertyCustomTypeID[1]','varchar(max)'),
		R.x.value('Class[1]','varchar(max)'),
		R.x.value('NetworkProperty[1]','varchar(max)'),
		R.x.value('Property[1]','varchar(max)'),
		R.x.value('IncludeProperty[1]','varchar(max)'),
		R.x.value('IsDetail[1]','varchar(max)'),
		R.x.value('Limit[1]','varchar(max)'),
		R.x.value('IncludeDescription[1]','varchar(max)'),
		R.x.value('IncludeNetwork[1]','varchar(max)')
  FROM    ( SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[Ontology.].[ClassPropertyCustom]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )
  
  
  --[Ontology.].[DataMap]
  TRUNCATE TABLE [Ontology.].DataMap
  INSERT INTO [Ontology.].DataMap
          ( DataMapID,
			DataMapGroup ,
            IsAutoFeed ,
            Graph ,
            Class ,
            NetworkProperty ,
            Property ,
            MapTable ,
            sInternalType ,
            sInternalID ,
            cClass ,
            cInternalType ,
            cInternalID ,
            oClass ,
            oInternalType ,
            oInternalID ,
            oValue ,
            oDataType ,
            oLanguage ,
            oStartDate ,
            oStartDatePrecision ,
            oEndDate ,
            oEndDatePrecision ,
            oObjectType ,
            Weight ,
            OrderBy ,
            ViewSecurityGroup ,
            EditSecurityGroup
          )
  SELECT    Row_Number() OVER (ORDER BY (SELECT 1)),
			R.x.value('DataMapGroup[1]','varchar(max)'),
			R.x.value('IsAutoFeed[1]','varchar(max)'),
			R.x.value('Graph[1]','varchar(max)'),
			R.x.value('Class[1]','varchar(max)'),
			R.x.value('NetworkProperty[1]','varchar(max)'),
			R.x.value('Property[1]','varchar(max)'),
			R.x.value('MapTable[1]','varchar(max)'),
			R.x.value('sInternalType[1]','varchar(max)'),
			R.x.value('sInternalID[1]','varchar(max)'),
			R.x.value('cClass[1]','varchar(max)'),
			R.x.value('cInternalType[1]','varchar(max)'),
			R.x.value('cInternalID[1]','varchar(max)'),
			R.x.value('oClass[1]','varchar(max)'),
			R.x.value('oInternalType[1]','varchar(max)'),
			R.x.value('oInternalID[1]','varchar(max)'),
			R.x.value('oValue[1]','varchar(max)'),
			R.x.value('oDataType[1]','varchar(max)'),
			R.x.value('oLanguage[1]','varchar(max)'),
			R.x.value('oStartDate[1]','varchar(max)'),
			R.x.value('oStartDatePrecision[1]','varchar(max)'),
			R.x.value('oEndDate[1]','varchar(max)'),
			R.x.value('oEndDatePrecision[1]','varchar(max)'),
			R.x.value('oObjectType[1]','varchar(max)'),
			R.x.value('Weight[1]','varchar(max)'),
			R.x.value('OrderBy[1]','varchar(max)'),
			R.x.value('ViewSecurityGroup[1]','varchar(max)'),
			R.x.value('EditSecurityGroup[1]','varchar(max)')
  FROM    ( SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[Ontology.].[DataMap]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )
  
  
 -- [Ontology.].[Namespace]
 TRUNCATE TABLE [Ontology.].[Namespace]
 INSERT INTO [Ontology.].[Namespace]
        ( URI ,
          Prefix
        )
  SELECT  R.x.value('URI[1]', 'varchar(max)') ,
          R.x.value('Prefix[1]', 'varchar(max)')
  FROM    ( SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[Ontology.].[Namespace]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )
  

   --[Ontology.].[PropertyGroup]
   INSERT INTO [Ontology.].PropertyGroup
           ( PropertyGroupURI ,
             SortOrder ,
             [_PropertyGroupLabel]
           ) 
	SELECT	R.x.value('PropertyGroupURI[1]','varchar(max)'),
			R.x.value('SortOrder[1]','varchar(max)'),
			R.x.value('_PropertyGroupLabel[1]','varchar(max)')
	 FROM    ( SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[Ontology.].[PropertyGroup]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )
  
  
	--[Ontology.].[PropertyGroupProperty]
	INSERT INTO [Ontology.].PropertyGroupProperty
	        ( PropertyGroupURI ,
	          PropertyURI ,
	          SortOrder ,
	          CustomDisplayModule ,
	          CustomEditModule ,
	          [_TagName] ,
	          [_PropertyLabel]
	        ) 
	SELECT	R.x.value('PropertyGroupURI[1]','varchar(max)'),
			R.x.value('PropertyURI[1]','varchar(max)'),
			R.x.value('SortOrder[1]','varchar(max)'),
			(case when CAST(R.x.query('CustomDisplayModule[1]/*') AS NVARCHAR(MAX))<>'' then R.x.query('CustomDisplayModule[1]/*') else NULL end),
			(case when CAST(R.x.query('CustomEditModule[1]/*') AS NVARCHAR(MAX))<>'' then R.x.query('CustomEditModule[1]/*') else NULL end),
			R.x.value('_TagName[1]','varchar(max)'),
			R.x.value('_PropertyLabel[1]','varchar(max)')
	 FROM    ( SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[Ontology.].[PropertyGroupProperty]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )
  

---------------------------------------------------------------
-- [Ontology.Presentation]
---------------------------------------------------------------


 --[Ontology.Presentation].[XML]
 INSERT INTO [Ontology.Presentation].[XML]
         ( PresentationID,
			type ,
           subject ,
           predicate ,
           object ,
           presentationXML ,
           _SubjectNode ,
           _PredicateNode ,
           _ObjectNode
         )       
  SELECT  Row_Number() OVER (ORDER BY (SELECT 1)),
		  R.x.value('type[1]', 'varchar(max)') ,
          R.x.value('subject[1]', 'varchar(max)'),
          R.x.value('predicate[1]', 'varchar(max)'),
          R.x.value('object[1]', 'varchar(max)'),
          (case when CAST(R.x.query('presentationXML[1]/*') AS NVARCHAR(MAX))<>'' then R.x.query('presentationXML[1]/*') else NULL end) , 
          R.x.value('_SubjectNode[1]', 'varchar(max)'),
          R.x.value('_PredicateNode[1]', 'varchar(max)'),
          R.x.value('_ObjectNode[1]', 'varchar(max)')
  FROM    ( SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[Ontology.Presentation].[XML]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )

  
---------------------------------------------------------------
-- [RDF.Security]
---------------------------------------------------------------
             
 -- [RDF.Security].[Group]
 TRUNCATE TABLE [RDF.Security].[Group]
 INSERT INTO [RDF.Security].[Group]
 
         ( SecurityGroupID ,
           Label ,
           HasSpecialViewAccess ,
           HasSpecialEditAccess ,
           Description
         )
 SELECT   R.x.value('SecurityGroupID[1]', 'varchar(max)') ,
          R.x.value('Label[1]', 'varchar(max)'),
          R.x.value('HasSpecialViewAccess[1]', 'varchar(max)'),
          R.x.value('HasSpecialEditAccess[1]', 'varchar(max)'),
          R.x.value('Description[1]', 'varchar(max)')
  FROM    ( SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[RDF.Security].[Group]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x ) 



---------------------------------------------------------------
-- [Utility.NLP]
---------------------------------------------------------------
   
	--[Utility.NLP].[ParsePorterStemming]
	INSERT INTO [Utility.NLP].ParsePorterStemming
	        ( Step, Ordering, phrase1, phrase2 ) 
	SELECT	R.x.value('Step[1]','varchar(max)'),
			R.x.value('Ordering[1]','varchar(max)'), 
			R.x.value('phrase1[1]','varchar(max)'), 
			R.x.value('phrase2[1]','varchar(max)')
	 FROM    ( SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[Utility.NLP].[ParsePorterStemming]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )
	
	--[Utility.NLP].[StopWord]
	INSERT INTO [Utility.NLP].StopWord
	        ( word, stem, scope ) 
	SELECT	R.x.value('word[1]','varchar(max)'),
			R.x.value('stem[1]','varchar(max)'),
			R.x.value('scope[1]','varchar(max)')
	 FROM    ( SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[Utility.NLP].[StopWord]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )
  
	--[Utility.NLP].[Thesaurus.Source]
	INSERT INTO [Utility.NLP].[Thesaurus.Source]
	        ( Source, SourceName ) 
	SELECT	R.x.value('Source[1]','varchar(max)'),
			R.x.value('SourceName[1]','varchar(max)')
	 FROM    ( SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[Utility.NLP].[Thesaurus.Source]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )


---------------------------------------------------------------
-- [User.Session]
---------------------------------------------------------------

  --[User.Session].Bot		
  INSERT INTO [User.Session].Bot  ( UserAgent )
   SELECT	R.x.value('UserAgent[1]','varchar(max)') 
	 FROM    ( SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[User.Session].Bot'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )
  
  
  
---------------------------------------------------------------
-- [Direct.]
---------------------------------------------------------------
   
  --[Direct.].[Sites]
  INSERT INTO [Direct.].[Sites]
          ( SiteID ,
            BootstrapURL ,
            SiteName ,
            QueryURL ,
            SortOrder ,
            IsActive
          )
  SELECT	R.x.value('SiteID[1]','varchar(max)'),
			R.x.value('BootstrapURL[1]','varchar(max)'),
			R.x.value('SiteName[1]','varchar(max)'),
			R.x.value('QueryURL[1]','varchar(max)'),
			R.x.value('SortOrder[1]','varchar(max)'),
			R.x.value('IsActive[1]','varchar(max)')
	 FROM    ( SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[Direct.].[Sites]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )
	
	
---------------------------------------------------------------
-- [Profile.Data]
---------------------------------------------------------------
 
    --[Profile.Data].[Publication.Type]		
  INSERT INTO [Profile.Data].[Publication.Type]
          ( pubidtype_id, name, sort_order )
           
   SELECT	R.x.value('pubidtype_id[1]','varchar(max)'),
			R.x.value('name[1]','varchar(max)'),
			R.x.value('sort_order[1]','varchar(max)')
	 FROM    (SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[Profile.Data].[Publication.Type]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )
   
  --[Profile.Data].[Publication.MyPub.Category]
  TRUNCATE TABLE [Profile.Data].[Publication.MyPub.Category]
  INSERT INTO [Profile.Data].[Publication.MyPub.Category]
          ( [HmsPubCategory] ,
            [CategoryName]
          ) 
   SELECT	R.x.value('HmsPubCategory[1]','varchar(max)'),
			R.x.value('CategoryName[1]','varchar(max)')
	 FROM    (SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[Profile.Data].[Publication.MyPub.Category]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )
  
 ---------------------------------------------------------------
-- [ORCID.]
---------------------------------------------------------------
  
	INSERT INTO [ORCID.].[REF_Permission]
		(
			[PermissionScope],
			[PermissionDescription],
			[MethodAndRequest],
			[SuccessMessage],
			[FailedMessage]
		)
   SELECT	R.x.value('PermissionScope[1]','varchar(max)'),
			R.x.value('PermissionDescription[1]','varchar(max)'),
			R.x.value('MethodAndRequest[1]','varchar(max)'),
			R.x.value('SuccessMessage[1]','varchar(max)'),
			R.x.value('FailedMessage[1]','varchar(max)')
	 FROM    (SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[ORCID.].[REF_Permission]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )


	INSERT INTO [ORCID.].[REF_PersonStatusType]
		(
			[StatusDescription]
		)
   SELECT	R.x.value('StatusDescription[1]','varchar(max)')
	 FROM    (SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[ORCID.].[REF_PersonStatusType]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )


	INSERT INTO [ORCID.].[REF_RecordStatus]
		(
			[RecordStatusID],
			[StatusDescription]
		)
   SELECT	R.x.value('RecordStatusID[1]','varchar(max)'),
			R.x.value('StatusDescription[1]','varchar(max)')
	 FROM    (SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[ORCID.].[REF_RecordStatus]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )


	INSERT INTO [ORCID.].[REF_Decision]
		(
			[DecisionDescription],
			[DecisionDescriptionLong]
		)
   SELECT	R.x.value('DecisionDescription[1]','varchar(max)'),
			R.x.value('DecisionDescriptionLong[1]','varchar(max)')
	 FROM    (SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[ORCID.].[REF_Decision]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )

	INSERT INTO [ORCID.].[REF_WorkExternalType]
		(
			[WorkExternalType],
			[WorkExternalDescription]
		)
   SELECT	R.x.value('WorkExternalType[1]','varchar(max)'),
			R.x.value('WorkExternalDescription[1]','varchar(max)')
	 FROM    (SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[ORCID.].[REF_WorkExternalType]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )


	INSERT INTO [ORCID.].[RecordLevelAuditType]
		(
			[AuditType]
		)
   SELECT	R.x.value('AuditType[1]','varchar(max)')
	 FROM    (SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[ORCID.].[RecordLevelAuditType]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )



	INSERT INTO [ORCID.].[DefaultORCIDDecisionIDMapping]
		(
			[SecurityGroupID],
			[DefaultORCIDDecisionID]
		)
   SELECT	R.x.value('SecurityGroupID[1]','varchar(max)'),
			R.x.value('DefaultORCIDDecisionID[1]','varchar(max)')
	 FROM    (SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[ORCID.].[DefaultORCIDDecisionIDMapping]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )

   ---------------------------------------------------------------
-- [Profile.Module].[GenericRDF.*]
---------------------------------------------------------------
	INSERT INTO [Profile.Module].[GenericRDF.Plugins]
		(
			[Name],
			[EnabledForPerson],
			[EnabledForGroup],
			[Label],
			[PropertyGroupURI],
			[CustomDisplayModule],
			[CustomEditModule]
		)
   SELECT	R.x.value('Name[1]','varchar(max)'),
			R.x.value('EnabledForPerson[1]','int'),
			R.x.value('EnabledForGroup[1]','int'),
			R.x.value('Label[1]','varchar(max)'),
			R.x.value('PropertyGroupURI[1]','varchar(max)'),
			R.x.value('CustomDisplayModule[1]','varchar(max)'),
			R.x.value('CustomEditModule[1]','varchar(max)')
	 FROM    (SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[Profile.Module].[GenericRDF.Plugins]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )


   ---------------------------------------------------------------
-- [Profile.Import].[PRNSWebservice.*]
---------------------------------------------------------------
	INSERT INTO [Profile.Import].[PRNSWebservice.Options]
		(
			[job],
			[url],
			[options],
			[logLevel],
			[batchSize],
			[GetPostDataProc],
			[ImportDataProc]
		)
   SELECT	R.x.value('job[1]','varchar(max)'),
			R.x.value('url[1]','varchar(max)'),
			R.x.value('options[1]','varchar(max)'),
			R.x.value('logLevel[1]','int'),
			R.x.value('batchSize[1]','int'),
			R.x.value('GetPostDataProc[1]','varchar(max)'),
			R.x.value('ImportDataProc[1]','varchar(max)')
	 FROM    (SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[Profile.Import].[PRNSWebservice.Options]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )

  -- Use to generate select lists for new tables
  -- SELECT   'R.x.value(''' + c.name +  '[1]'',' + '''varchar(max)'')'+ ',' ,* 
  -- FROM sys.columns c 
  -- JOIN  sys.types t ON t.system_type_id = c.system_type_id 
  -- WHERE object_id IN (SELECT object_id FROM sys.tables WHERE name = 'Publication.MyPub.Category') 
  -- AND T.NAME<>'sysname'ORDER BY c.column_id
	 
END
GO
PRINT N'Altering [Profile.Import].[GoogleWebservice.ParseGeocodeResults]...';


GO

ALTER PROCEDURE [Profile.Import].[GoogleWebservice.ParseGeocodeResults]
	@BatchID varchar(100) = '',
	@RowID int = -1,
	@LogID int = -1,
	@URL varchar (500) = '',
	@Data varchar(max)
AS
BEGIN
	SET NOCOUNT ON;	
	declare @x xml, @status varchar(100), @errorText varchar(max), @lat varchar(20), @lng varchar(20), @location_type varchar(100)

	begin try
		set @x = cast(@data	as xml)
	end try
	begin catch
		set @status = 'XML Parsing Error'
		set @errorText = ERROR_MESSAGE()
	end catch

	if @x is not null
	BEGIN
		select @status = nref.value('status[1]','varchar(100)'),
		@errorText = nref.value('error_message[1]','varchar(max)'),
		@lat = nref.value('result[1]/geometry[1]/location[1]/lat[1]','varchar(20)'),
		@lng = nref.value('result[1]/geometry[1]/location[1]/lng[1]','varchar(20)'),
		@location_type = nref.value('result[1]/geometry[1]/location_type[1]','varchar(100)')
		from @x.nodes('//GeocodeResponse[1]') as R(nref)
	END

	IF @status = 'OK' 
	BEGIN
		UPDATE t SET t.Latitude = @lat, t.Longitude = @lng, t.GeoScore = case when @location_type = 'ROOFTOP' then 9 when @location_type = 'RANGE_INTERPOLATED' then 6 when @location_type = 'GEOMETRIC_CENTER' then 4 else 3 end
			FROM [Profile.Data].Person t
			JOIN [Profile.Import].[PRNSWebservice.Options] o ON o.job = 'geocode'
			AND @URL = o.url + REPLACE(REPLACE(t.AddressString, '#', '' ), ' ', '+') + '&sensor=false' + isnull('&key=' + options, '') 
			AND isnull(t.GeoScore, 0) < 10
		update [Profile.Import].[PRNSWebservice.Log] set ResultCount = @@ROWCOUNT where LogID = @LogID
	END
	ELSE 
	BEGIN
		if @LogID > 0
		begin
			select @LogID = isnull(@LogID, -1) from [Profile.Import].[PRNSWebservice.Log] where BatchID = @BatchID and RowID = @RowID
		end

		if @LogID > 0
			update [Profile.Import].[PRNSWebservice.Log] set Success = 0, HttpResponse = @Data, ErrorText = isnull(@status, '') + ' : ' + isnull(@errorText, '') where LogID = @LogID
		else
			insert into [Profile.Import].[PRNSWebservice.Log] (Job, BatchID, RowID, URL, HttpResponse, Success, ErrorText) Values ('Geocode', @BatchID, @RowID, @URL, @Data, 0, isnull(@status, '') + ' : ' + isnull(@errorText, ''))
	END
END
GO
PRINT N'Altering [Profile.Data].[Publication.Pubmed.GetPMIDsforBibliometrics]...';


GO
ALTER PROCEDURE [Profile.Data].[Publication.Pubmed.GetPMIDsforBibliometrics]
	@Job varchar(55) = 'Bibliometrics',
	@BatchID varchar(100)
AS
BEGIN
	SET NOCOUNT ON;	

	CREATE TABLE #tmp (LogID INT, BatchID VARCHAR(100), RowID INT, HttpMethod VARCHAR(10), URL VARCHAR(500), PostData VARCHAR(MAX)) 

	Create table #tmp2(pmid int primary key)
	insert into #tmp2
	SELECT pmid
		FROM [Profile.Data].[Publication.PubMed.Disambiguation]
		WHERE pmid IS NOT NULL 
		UNION   
	SELECT pmid
		FROM [Profile.Data].[Publication.Person.Include]
		WHERE pmid IS NOT NULL 

	declare @c int,	@BatchSize int, @rowsCount int, @URL varchar(500), @logLevel int
	select @c = count(1) from #tmp2
	--select @batchID = NEWID()
	select @URL = URL, @BatchSize = batchSize, @logLevel = logLevel from [Profile.Import].[PRNSWebservice.Options] where job = @Job
	insert into #tmp(LogID, BatchID, RowID, HttpMethod, URL, PostData)
	select -1, @batchID batchID, n, 'POST', @URL, (
	select pmid "PMID" FROM #tmp2 order by pmid offset n * @BatchSize ROWS FETCH NEXT @BatchSize ROWS ONLY FOR XML path(''), ELEMENTS, ROOT('PMIDS')) x
	from [Utility.Math].N where n <= @c / @BatchSize

	select @rowsCount = @@ROWCOUNT

	Update [Profile.Import].[PRNSWebservice.Log.Summary]  set RecordsCount = @c, RowsCount = @rowsCount where BatchID = @BatchID

	DECLARE @LogIDTable TABLE (LogID int, RowID int)
	IF @logLevel = 1
	BEGIN
		INSERT INTO [Profile.Import].[PRNSWebservice.Log] (Job, BatchID, RowID, HttpMethod, URL)
		OUTPUT inserted.LogID, Inserted.RowID into @LogIDTable
		SELECT 'bibliometrics', BatchID, RowID, HttpMethod, URL FROM #tmp
		UPDATE t SET t.LogID = l.LogID FROM #tmp t JOIN @LogIDTable l ON t.RowID = l.RowID
	END
	ELSE IF @logLevel = 2
	BEGIN
		INSERT INTO [Profile.Import].[PRNSWebservice.Log] (Job, BatchID, RowID, HttpMethod, URL, PostData)
		OUTPUT inserted.LogID, Inserted.RowID into @LogIDTable
		SELECT 'bibliometrics', BatchID, RowID, HttpMethod, URL, PostData FROM #tmp
		UPDATE t SET t.LogID = l.LogID FROM #tmp t JOIN @LogIDTable l ON t.RowID = l.RowID
	END

	SELECT * FROM #tmp
END
GO
PRINT N'Altering [Profile.Import].[GoogleWebservice.GetGeocodeAPIData]...';


GO

ALTER PROCEDURE [Profile.Import].[GoogleWebservice.GetGeocodeAPIData]	 
AS
BEGIN
	SET NOCOUNT ON;	

	CREATE TABLE #tmp (LogID INT, BatchID VARCHAR(100), RowID INT IDENTITY, HttpMethod VARCHAR(10), URL VARCHAR(500), PostData VARCHAR(MAX)) 

	INSERT INTO #tmp(URL) 
	SELECT DISTINCT addressstring
	  FROM [Profile.Data].Person
	 WHERE (ISNULL(latitude ,0)=0
 			OR geoscore = 0)
	and addressstring<>''
	and IsActive = 1

	DECLARE @bid AS VARCHAR(100)
	SET @bid = NEWID()
	UPDATE t SET
		t.LogID = -1,
		t.BatchID = @bid, 
		t.HttpMethod = 'GET',
		t.URL = o.url + REPLACE(REPLACE(t.URL, '#', '' ), ' ', '+') + '&sensor=false' + isnull('&key=' + apikey, '') 
			FROM #tmp t
			JOIN [Profile.Import].[PRNSWebservice.Options] o ON o.job = 'geocode'

	IF EXISTS (SELECT 1 FROM [Profile.Import].[PRNSWebservice.Options] WHERE job = 'geocode' AND logLevel > 0)
	BEGIN
		DECLARE @LogIDTable TABLE (LogID int, RowID int)
		INSERT INTO [Profile.Import].[PRNSWebservice.Log] (Job, BatchID, RowID, HttpMethod, URL)
		OUTPUT inserted.LogID, Inserted.RowID into @LogIDTable
		SELECT 'Geocode', BatchID, RowID, HttpMethod, URL FROM #tmp

		UPDATE t SET t.LogID = l.LogID FROM #tmp t JOIN @LogIDTable l ON t.RowID = l.RowID
	END

	SELECT * FROM #tmp
END
GO
PRINT N'Altering [Profile.Import].[PRNSWebservice.AddLog]...';


GO
ALTER PROCEDURE [Profile.Import].[PRNSWebservice.AddLog]
	@logID BIGINT = -1,
	@batchID varchar(100) = null,
	@rowID int = -1,
	@Job varchar(55),
	@action VARCHAR(200),
	@actionText varchar(max) = null,
	@newLogID BIGINT OUTPUT
AS
BEGIN
	DECLARE @LogLevel INT
	SELECT @LogLevel = LogLevel FROM [Profile.Import].[PRNSWebservice.Options] WHERE Job=@Job

	IF @LogLevel > 0 OR @action = 'Error'
	BEGIN 
		IF @logID < 0
		BEGIN
			SELECT @logID = ISNULL(LogID, -1) FROM [Profile.Import].[PRNSWebservice.Log] WHERE BatchID = @batchID AND RowID = @rowID

			if @logID < 0
			BEGIN
				DECLARE @LogIDTable TABLE (logID BIGINT)
				INSERT INTO [Profile.Import].[PRNSWebservice.Log] (Job, BatchID, RowID)
				OUTPUT Inserted.LogID INTO @LogIDTable
				VALUES (@job, @batchID, @rowID)
				SELECT @logID = LogID from @LogIDTable
			END
		END

		IF @action='StartService'
			BEGIN
				UPDATE [Profile.Import].[PRNSWebservice.Log]
				   SET ServiceCallStart = GETDATE()
				 WHERE LogID = @logID
			END
		IF @action='EndService'
			BEGIN
				UPDATE [Profile.Import].[PRNSWebservice.Log]
				   SET ServiceCallEnd = GETDATE()
				 WHERE LogID = @logID
			END
		IF @action='RowComplete'
			BEGIN
				UPDATE [Profile.Import].[PRNSWebservice.Log]
				   SET ProcessEnd  =GETDATE(),
					   Success= isnull(Success, 1)
				 WHERE LogID = @logID
			END
		IF @action='Error'
			BEGIN
				UPDATE [Profile.Import].[PRNSWebservice.Log]
				   SET ErrorText = isnull(ErrorText + ' ', '') + @actionText,
					   ProcessEnd  =GETDATE(),
					   Success=0
				 WHERE LogID = @logID
			END
	END
	Select @newLogID = @logID
END
GO
PRINT N'Altering [Profile.Import].[PRNSWebservice.ImportData]...';


GO
ALTER PROCEDURE [Profile.Import].[PRNSWebservice.ImportData]
	@Job varchar(55),
	@BatchID varchar(100) = '',
	@RowID int = -1,
	@HttpResponseCode int = -1,
	@LogID int = -1,
	@URL varchar (500) = '',
	@Data varchar(max)
AS
BEGIN
	if EXISTS (SELECT 1 FROM [Profile.Import].[PRNSWebservice.Options] WHERE job = @Job AND logLevel = 2) OR @HttpResponseCode <> 200
	begin
		if @LogID > 0
		begin
			select @LogID = isnull(@LogID, -1) from [Profile.Import].[PRNSWebservice.Log] where BatchID = @BatchID and RowID = @RowID
		end

		if @LogID > 0
			update [Profile.Import].[PRNSWebservice.Log] set HttpResponseCode = @HttpResponseCode, 
															 HttpResponse = @Data, 
															 Success = Case when @HttpResponseCode = 200 then null else 0 end 
				where LogID = @LogID
		else
			insert into [Profile.Import].[PRNSWebservice.Log] (Job, BatchID, RowID, URL, HttpResponseCode, HttpResponse, Success) Values (@Job, @BatchID, @RowID, @URL, @HttpResponseCode, @Data, Case when @HttpResponseCode = 200 then null else 0 end)
	end


	if @HttpResponseCode = 200
	begin
		declare @proc varchar(100), @sql nvarchar(2000)
		select @proc = ImportDataProc from [Profile.Import].[PRNSWebservice.Options] where job = @job
		if @proc is null
		BEGIN
			RAISERROR('Job doesn''t exist', 16, -1)
			return
		END

		exec @proc @data=@data, @URL=@URL, @BatchID=@BatchID, @RowID=@RowID, @LogID=@LogID, @Job=@Job
	END
END
GO
PRINT N'Altering [Profile.Import].[PRNSWebservice.GetPostData]...';


GO
ALTER PROCEDURE [Profile.Import].[PRNSWebservice.GetPostData]
	@Job varchar(55)
AS
BEGIN
	DECLARE @batchID UNIQUEIDENTIFIER, @logLevel int, @proc varchar(100)

	select @batchID = NEWID()
	select @proc = GetPostDataProc, @logLevel = logLevel from [Profile.Import].[PRNSWebservice.Options] where job = @job

  	IF @logLevel >= 0
	BEGIN
		INSERT INTO [Profile.Import].[PRNSWebservice.Log.Summary]  (Job, BatchID, JobStart)
		SELECT @Job, @BatchID, getdate()
	END

	if @proc is null
	BEGIN
		RAISERROR('Job doesn''t exist', 16, -1)
		return
	END

	exec @proc @Job=@Job, @BatchID=@BatchID
END
GO
PRINT N'Altering [Framework.].[CreateInstallData]...';


GO
ALTER procedure [Framework.].[CreateInstallData]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	declare @x xml

	select @x = (
		select
			(
				select
					--------------------------------------------------------
					-- [Framework.]
					--------------------------------------------------------
					(
						select	'[Framework.].[Parameter]' 'Table/@Name',
								(
									select	ParameterID 'ParameterID', 
											Value 'Value'
									from [Framework.].[Parameter]
									for xml path('Row'), type
								) 'Table'
						for xml path(''), type
					),
					(
						select	'[Framework.].[RestPath]' 'Table/@Name',
								(
									select	ApplicationName 'ApplicationName',
											Resolver 'Resolver'
									from [Framework.].[RestPath]
									for xml path('Row'), type
								) 'Table'
						for xml path(''), type
					),
					(
						select	'[Framework.].[Job]' 'Table/@Name',
								(
									select	JobGroup 'JobGroup',
											Step 'Step',
											IsActive 'IsActive',
											Script 'Script'
									from [Framework.].[Job]
									for xml path('Row'), type
								) 'Table'
						for xml path(''), type
					),
					(
						select	'[Framework.].[JobGroup]' 'Table/@Name',
								(
									SELECT  JobGroup 'JobGroup',
											Name 'Name',
											Type 'Type',
											Description 'Description'	
									from [Framework.].JobGroup
									for xml path('Row'), type
								) 'Table'
						for xml path(''), type
					),
					--------------------------------------------------------
					-- [Ontology.]
					--------------------------------------------------------
					(
						select	'[Ontology.].[ClassGroup]' 'Table/@Name',
								(
									select	ClassGroupURI 'ClassGroupURI',
											SortOrder 'SortOrder',
											IsVisible 'IsVisible'
									from [Ontology.].[ClassGroup]
									for xml path('Row'), type
								) 'Table'
						for xml path(''), type
					),
					(
						select	'[Ontology.].[ClassGroupClass]' 'Table/@Name',
								(
									select	ClassGroupURI 'ClassGroupURI',
											ClassURI 'ClassURI',
											SortOrder 'SortOrder'
									from [Ontology.].[ClassGroupClass]
									for xml path('Row'), type
								) 'Table'
						for xml path(''), type
					),
					(
						select	'[Ontology.].[ClassProperty]' 'Table/@Name',
								(
									select	Class 'Class',
											NetworkProperty 'NetworkProperty',
											Property 'Property',
											IsDetail 'IsDetail',
											Limit 'Limit',
											IncludeDescription 'IncludeDescription',
											IncludeNetwork 'IncludeNetwork',
											SearchWeight 'SearchWeight',
											CustomDisplay 'CustomDisplay',
											CustomEdit 'CustomEdit',
											ViewSecurityGroup 'ViewSecurityGroup',
											EditSecurityGroup 'EditSecurityGroup',
											EditPermissionsSecurityGroup 'EditPermissionsSecurityGroup',
											EditExistingSecurityGroup 'EditExistingSecurityGroup',
											EditAddNewSecurityGroup 'EditAddNewSecurityGroup',
											EditAddExistingSecurityGroup 'EditAddExistingSecurityGroup',
											EditDeleteSecurityGroup 'EditDeleteSecurityGroup',
											MinCardinality 'MinCardinality',
											MaxCardinality 'MaxCardinality',
											CustomDisplayModule 'CustomDisplayModule',
											CustomEditModule 'CustomEditModule'
									from [Ontology.].ClassProperty
									for xml path('Row'), type
								) 'Table'
						for xml path(''), type
					),
					(
						select	'[Ontology.].[ClassPropertyCustom]' 'Table/@Name',
								(
									select	
											ClassPropertyCustomTypeID 'ClassPropertyCustomTypeID',
											Class 'Class',
											NetworkProperty 'NetworkProperty',
											Property 'Property',
											IncludeProperty 'IncludeProperty',
											Limit 'Limit',
											IncludeNetwork 'IncludeNetwork',
											IncludeDescription 'IncludeDescription',
											IsDetail 'IsDetail'
									from [Ontology.].ClassPropertyCustom
									for xml path('Row'), type
								) 'Table'
						for xml path(''), type
					),
					(
						select	'[Ontology.].[DataMap]' 'Table/@Name',
						
								(
									select  DataMapGroup 'DataMapGroup',
											IsAutoFeed 'IsAutoFeed',
											Graph 'Graph',
											Class 'Class',
											NetworkProperty 'NetworkProperty',
											Property 'Property',
											MapTable 'MapTable',
											sInternalType 'sInternalType',
											sInternalID 'sInternalID',
											cClass 'cClass',
											cInternalType 'cInternalType',
											cInternalID 'cInternalID',
											oClass 'oClass',
											oInternalType 'oInternalType',
											oInternalID 'oInternalID',
											oValue 'oValue',
											oDataType 'oDataType',
											oLanguage 'oLanguage',
											oStartDate 'oStartDate',
											oStartDatePrecision 'oStartDatePrecision',
											oEndDate 'oEndDate',
											oEndDatePrecision 'oEndDatePrecision',
											oObjectType 'oObjectType',
											Weight 'Weight',
											OrderBy 'OrderBy',
											ViewSecurityGroup 'ViewSecurityGroup',
											EditSecurityGroup 'EditSecurityGroup'
									from [Ontology.].[DataMap]
									for xml path('Row'), type
								) 'Table'
						for xml path(''), type
					),
					(
						select	'[Ontology.].[Namespace]' 'Table/@Name',
								(
									select	URI 'URI',
											Prefix 'Prefix'
									from [Ontology.].[Namespace]
									for xml path('Row'), type
								) 'Table'
						for xml path(''), type
					),
					(
						select	'[Ontology.].[PropertyGroup]' 'Table/@Name',
								(
									select	PropertyGroupURI 'PropertyGroupURI',
											SortOrder 'SortOrder',
											_PropertyGroupLabel '_PropertyGroupLabel'
									from [Ontology.].[PropertyGroup]
									for xml path('Row'), type
								) 'Table'
						for xml path(''), type
					),
					(
						select	'[Ontology.].[PropertyGroupProperty]' 'Table/@Name',
								(
									select	PropertyGroupURI 'PropertyGroupURI',
											PropertyURI 'PropertyURI',
											SortOrder 'SortOrder',
											CustomDisplayModule 'CustomDisplayModule',
											CustomEditModule 'CustomEditModule',
											_TagName '_TagName',
											_PropertyLabel '_PropertyLabel'
									from [Ontology.].[PropertyGroupProperty]
									for xml path('Row'), type
								) 'Table'
						for xml path(''), type
					),
					--------------------------------------------------------
					-- [Ontology.Presentation]
					--------------------------------------------------------
					(
						select	'[Ontology.Presentation].[XML]' 'Table/@Name',
								(
									select	type 'type',
											subject 'subject',
											predicate 'predicate',
											object 'object',
											presentationXML 'presentationXML'
									from [Ontology.Presentation].[XML]
									for xml path('Row'), type
								) 'Table'
						for xml path(''), type
					),
					--------------------------------------------------------
					-- [RDF.Security]
					--------------------------------------------------------
					(
						select	'[RDF.Security].[Group]' 'Table/@Name',
								(
									select	SecurityGroupID 'SecurityGroupID',
											Label 'Label',
											HasSpecialViewAccess 'HasSpecialViewAccess',
											HasSpecialEditAccess 'HasSpecialEditAccess',
											Description 'Description'
									from [RDF.Security].[Group]
									for xml path('Row'), type
								) 'Table'
						for xml path(''), type
					),
					--------------------------------------------------------
					-- [Utility.NLP]
					--------------------------------------------------------
					(
						select	'[Utility.NLP].[ParsePorterStemming]' 'Table/@Name',
								(
									select	step 'Step',
											Ordering 'Ordering',
											phrase1 'phrase1',
											phrase2 'phrase2'
									from [Utility.NLP].ParsePorterStemming
									for xml path('Row'), type
								) 'Table'
						for xml path(''), type
					),
					(
						select	'[Utility.NLP].[StopWord]' 'Table/@Name',
								(
									select	word 'word',
											stem 'stem',
											scope 'scope'
									from [Utility.NLP].[StopWord]
									for xml path('Row'), type
								) 'Table'
						for xml path(''), type
					),
					(
						select	'[Utility.NLP].[Thesaurus.Source]' 'Table/@Name',
								(
									select	Source 'Source',
											SourceName 'SourceName'
									from [Utility.NLP].[Thesaurus.Source]
									for xml path('Row'), type
								) 'Table'
						for xml path(''), type
					),
					--------------------------------------------------------
					-- [User.Session]
					--------------------------------------------------------
					(
						select	'[User.Session].Bot' 'Table/@Name',
							(
								SELECT UserAgent 'UserAgent' 
								  FROM [User.Session].Bot
				  					for xml path('Row'), type
			   				) 'Table'  
						for xml path(''), type
					),
					--------------------------------------------------------
					-- [Direct.]
					--------------------------------------------------------
					(
						select	'[Direct.].[Sites]' 'Table/@Name',
							(
								SELECT SiteID 'SiteID',
										BootstrapURL 'BootstrapURL',
										SiteName 'SiteName',
										QueryURL 'QueryURL',
										SortOrder 'SortOrder',
										IsActive 'IsActive'  
								  FROM [Direct.].[Sites] 
			 					for xml path('Row'), type
					 		) 'Table'   
						for xml path(''), TYPE
					),
					--------------------------------------------------------
					-- [Profile.Data]
					--------------------------------------------------------
					(
						select	'[Profile.Data].[Publication.Type]' 'Table/@Name',
							(
								SELECT	pubidtype_id 'pubidtype_id',
										name 'name',
										sort_order 'sort_order'
								  FROM [Profile.Data].[Publication.Type]
				  					for xml path('Row'), type
			   				) 'Table'  
						for xml path(''), type
					),
					(
						select	'[Profile.Data].[Publication.MyPub.Category]' 'Table/@Name',
							(
								SELECT	HmsPubCategory 'HmsPubCategory',
										CategoryName 'CategoryName'
								  FROM [Profile.Data].[Publication.MyPub.Category]
				  					for xml path('Row'), type
							) 'Table'  
						for xml path(''), type
					),
					--------------------------------------------------------
					-- [ORCID.]
					--------------------------------------------------------
					(
						select '[ORCID.].[REF_Permission]' 'Table/@Name',
						(
							SELECT	PermissionScope 'PermissionScope', 
									PermissionDescription 'PermissionDescription', 
									MethodAndRequest 'MethodAndRequest',
									SuccessMessage 'SuccessMessage',
									FailedMessage 'FailedMessage'
								from [ORCID.].[REF_Permission]
									for xml path('Row'), type
						) 'Table'  
						for xml path(''), type
					),
					(
						select '[ORCID.].[REF_PersonStatusType]' 'Table/@Name',
						(
							SELECT	StatusDescription 'StatusDescription'
								from [ORCID.].[REF_PersonStatusType]
									for xml path('Row'), type
						) 'Table'  
						for xml path(''), type
					),
					(
						select '[ORCID.].[REF_WorkExternalType]' 'Table/@Name',
						(
							SELECT	WorkExternalType 'WorkExternalType',
									WorkExternalDescription 'WorkExternalDescription'
								from [ORCID.].[REF_WorkExternalType]
									for xml path('Row'), type
						) 'Table'  
						for xml path(''), type
					),
					(
						select '[ORCID.].[REF_RecordStatus]' 'Table/@Name',
						(
							SELECT	RecordStatusID 'RecordStatusID',
									StatusDescription, 'StatusDescription'
								from [ORCID.].[REF_RecordStatus]
									for xml path('Row'), type
						) 'Table'  
						for xml path(''), type
					),
					(
						select '[ORCID.].[REF_Decision]' 'Table/@Name',
						(
							SELECT	DecisionDescription 'DecisionDescription',
									DecisionDescriptionLong 'DecisionDescriptionLong'
								from [ORCID.].[REF_Decision]
									for xml path('Row'), type
						) 'Table'  
						for xml path(''), type
					),
					(
						select '[ORCID.].[RecordLevelAuditType]' 'Table/@Name',
						(
							SELECT	AuditType 'AuditType'
								from [ORCID.].[RecordLevelAuditType]
									for xml path('Row'), type
						) 'Table'  
						for xml path(''), type
					),
					(
						select '[ORCID.].[DefaultORCIDDecisionIDMapping]' 'Table/@Name',
						(
							SELECT	SecurityGroupID 'SecurityGroupID',
									DefaultORCIDDecisionID 'DefaultORCIDDecisionID'
								from [ORCID.].[DefaultORCIDDecisionIDMapping]
									for xml path('Row'), type
						) 'Table'  
						for xml path(''), type
					),
					--------------------------------------------------------
					-- [Profile.Module].[GenericRDF.Plugins]
					--------------------------------------------------------					
					(
						select '[Profile.Module].[GenericRDF.Plugins]' 'Table/@Name',
						(
							SELECT	Name 'Name',
									EnabledForPerson 'EnabledForPerson',
									EnabledForGroup 'EnabledForGroup',
									Label 'Label',
									PropertyGroupURI 'PropertyGroupURI',
									[CustomDisplayModule] 'CustomDisplayModule',
									[CustomEditModule] 'CustomEditModule'
								from [Profile.Module].[GenericRDF.Plugins]
									for xml path('Row'), type
						) 'Table'  
						for xml path(''), type
					),
 				    ---------------------------------------------------------------
					-- [Profile.Import].[PRNSWebservice.*]
					---------------------------------------------------------------
					(					(
						select '[Profile.Import].[PRNSWebservice.Options]' 'Table/@Name',
						(
							SELECT	job 'job',
									url 'url',
									options 'options',
									logLevel 'logLevel',
									batchSize 'batchSize',
									GetPostDataProc 'GetPostDataProc',
									ImportDataProc 'ImportDataProc'
								from [Profile.Import].[PRNSWebservice.Options]
									for xml path('Row'), type
						) 'Table'  
						for xml path(''), type
					)
				)
				for xml path(''), type
			) 'Import'
		for xml path(''), type
	)


	insert into [Framework.].[InstallData] (Data)
		select @x


   --Use to generate select lists for new tables
   --SELECT    c.name +  ' ''' + name + ''','
   --FROM sys.columns c  
   --WHERE object_id IN (SELECT object_id FROM sys.tables WHERE name = 'Publication.MyPub.Category')  

END
GO
PRINT N'Altering [Profile.Data].[Funding.GetPersonFunding]...';


GO

ALTER PROCEDURE [Profile.Data].[Funding.GetPersonFunding]
	@PersonID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT
		ISNULL(a.Abstract,'') Abstract,
		ISNULL(a.AgreementLabel,'') AgreementLabel,
		ISNULL(a.EndDate,'1/1/1900') EndDate,
		ISNULL(a.Source,'') Source,
		ISNULL(a.FundingID,'') FundingID,
		ISNULL(a.FundingID2,'') FundingID2,
		ISNULL(a.GrantAwardedBy,'') GrantAwardedBy,
		ISNULL(r.FundingRoleID,'') FundingRoleID,
		ISNULL(r.PersonID,'') PersonID,
		ISNULL(a.PrincipalInvestigatorName,'') PrincipalInvestigatorName,
		ISNULL(r.RoleDescription,'') RoleDescription,
		ISNULL(r.RoleLabel,'') RoleLabel,
		ISNULL(a.StartDate,'1/1/1900') StartDate,
		'' SponsorAwardID
	FROM [Profile.Data].[Funding.Role] r 
		INNER JOIN [Profile.Data].[Funding.Agreement] a
			ON r.FundingAgreementID = a.FundingAgreementID
				AND r.PersonID = @PersonID
	ORDER BY StartDate desc, EndDate desc, FundingID

END
GO
PRINT N'Altering [Profile.Data].[Group.Manager.DeleteManager]...';


GO
ALTER PROCEDURE [Profile.Data].[Group.Manager.DeleteManager]
	-- Group
	@GroupID INT=NULL, 
	@GroupNodeID BIGINT=NULL,
	@GroupURI VARCHAR(400)=NULL,
	-- User
	@UserID INT=NULL,
	@UserNodeID BIGINT=NULL,
	@UserURI VARCHAR(400)=NULL,
	-- Other
	@SessionID UNIQUEIDENTIFIER=NULL, 
	@Error BIT=NULL OUTPUT 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	/*
	
	This stored procedure deletes a Group Manager.
	Specify:
	1) A Group by either GroupID, NodeID or URI.
	2) A User by UserID, NodeID, or URI.
	
	*/
	
	SELECT @Error = 0

	-------------------------------------------------
	-- Validate and prepare variables
	-------------------------------------------------
	
	-- Convert URIs and NodeIDs to GroupID
 	IF (@GroupNodeID IS NULL) AND (@GroupURI IS NOT NULL)
		SELECT @GroupNodeID = [RDF.].fnURI2NodeID(@GroupURI)
 	IF (@GroupID IS NULL) AND (@GroupNodeID IS NOT NULL)
		SELECT @GroupID = CAST(m.InternalID AS INT)
			FROM [RDF.Stage].[InternalNodeMap] m, [RDF.].Node n
			WHERE m.Status = 3 AND m.ValueHash = n.ValueHash AND n.NodeID = @GroupNodeID
	IF @GroupNodeID IS NULL
		SELECT @GroupNodeID = NodeID
			FROM [RDF.Stage].InternalNodeMap
			WHERE Class = 'http://xmlns.com/foaf/0.1/Group' AND InternalType = 'Group' AND InternalID = @GroupID

	-- Convert URIs and NodeIDs to UserID
 	IF (@UserNodeID IS NULL) AND (@UserURI IS NOT NULL)
		SELECT @UserNodeID = [RDF.].fnURI2NodeID(@UserURI)
 	IF (@UserID IS NULL) AND (@UserNodeID IS NOT NULL)
		SELECT @UserID = CAST(m.InternalID AS INT)
			FROM [RDF.Stage].[InternalNodeMap] m, [RDF.].Node n
			WHERE m.Status = 3 AND m.ValueHash = n.ValueHash AND n.NodeID = @UserNodeID
	IF @UserNodeID IS NULL
		SELECT @UserNodeID = NodeID
			FROM [RDF.Stage].InternalNodeMap
			WHERE Class = 'http://profiles.catalyst.harvard.edu/ontology/prns#User' AND InternalType = 'User' AND InternalID = @UserID

	-- Check that both a GroupID and a UserID exist
	IF (@GroupID IS NULL) OR (@UserID IS NULL)
		RETURN;

	-------------------------------------------------
	-- Delete the manager
	-------------------------------------------------

	DELETE
		FROM [Profile.Data].[Group.Manager]
		WHERE GroupID=@GroupID AND UserID=@UserID

	DECLARE @hasGroupManagerNodeID BIGINT
	SELECT @hasGroupManagerNodeID = [RDF.].fnURI2NodeID('http://profiles.catalyst.harvard.edu/ontology/prns#hasGroupManager')

	IF (@GroupNodeID IS NOT NULL) AND (@UserNodeID IS NOT NULL)
		DELETE
			FROM [RDF.].[Triple]
			WHERE Subject = @GroupNodeID AND Predicate = @hasGroupManagerNodeID AND Object = @UserNodeID

	EXEC [Profile.Data].[Group.UpdateSecurityMembership]

END
GO
PRINT N'Altering [Profile.Data].[Person.GetUnGeocodedAddresses]...';


GO
ALTER PROCEDURE [Profile.Data].[Person.GetUnGeocodedAddresses]	 
AS
BEGIN
	SET NOCOUNT ON;	

SELECT DISTINCT addressstring
  FROM [Profile.Data].Person
 WHERE (ISNULL(latitude ,0)=0
 		OR geoscore = 0)
and addressstring<>''
and IsActive = 1


END
GO
PRINT N'Altering [Profile.Data].[Publication.Pubmed.ParseBibliometricResults]...';


GO
ALTER PROCEDURE [Profile.Data].[Publication.Pubmed.ParseBibliometricResults]
	@Job varchar(55) = '',
	@BatchID varchar(100) = '',
	@RowID int = -1,
	@LogID int = -1,
	@URL varchar (500) = '',
	@Data varchar(max)
AS
BEGIN
	create table #tmp(
		pmid int primary key,
		PMCCitations int,
		MedlineTA varchar(255),
		TranslationAnimals int,
		TranslationCells int,
		TranslationHumans int,
		TranslationPublicHealth int,
		TranslationClinicalTrial int
	)

	CREATE TABLE #tmpJournalHeading(
		[MedlineTA] [varchar](255) NOT NULL,
		[BroadJournalHeading] [varchar](100) NOT NULL,
		[Weight] [float] NULL,
		[DisplayName] [varchar](100) NULL,
		[Abbreviation] [varchar](50) NULL,
		[Color] [varchar](6) NULL,
		[Angle] [float] NULL,
		[Arc] [float] NULL,
	PRIMARY KEY CLUSTERED 
	(
		[MedlineTA] ASC,
		[BroadJournalHeading] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	)

	declare @x xml
	select @x = cast(@Data as xml)

	insert into #tmp
	select t.x.value('PMID[1]', 'int') as PMID,
	t.x.value('PMCCitations[1]', 'int') as PMCCitations,
	t.x.value('MedlineTA[1]', 'varchar(255)') as MedlineTA,
	t.x.value('TranslationAnimals[1]', 'int') as TranslationAnimals,
	t.x.value('TranslationCells[1]', 'int') as TranslationCells,
	t.x.value('TranslationHumans[1]', 'int') as TranslationHumans,
	t.x.value('TranslationPublicHealth[1]', 'int') as TranslationPublicHealth,
	t.x.value('TranslationClinicalTrial[1]', 'int') as TranslationClinicalTrial
	from @x.nodes('/Bibliometrics/ArticleSummary') t(x)

	insert into #tmpJournalHeading (MedlineTA, BroadJournalHeading, DisplayName, Abbreviation, Color, Angle, Arc)
		select 
		t.x.value('MedlineTA[1]', 'varchar(255)') as MedlineTA,
		t.x.value('BroadJournalHeading[1]', 'varchar(100)') as BroadJournalHeading,
	--	t.x.value('Weight[1]', 'float') as Weight,
		t.x.value('DisplayName[1]', 'varchar(100)') as DisplayName,
		t.x.value('Abbreviation[1]', 'varchar(50)') as Abbreviation,
		t.x.value('Color[1]', 'varchar(6)') as Color,
		t.x.value('Angle[1]', 'float') as Angle,
		t.x.value('Arc[1]', 'float') as Arc
		from @x.nodes('/Bibliometrics/JournalHeading') t(x)

	;with counts as (
		select MedlineTA, count(*) c from #tmpJournalHeading
		Group by MedlineTA
	)
	update a set a.weight = 1.0 / c from #tmpJournalHeading a join counts b on a.MedlineTA = b.MedlineTA

	delete from [Profile.Data].[Publication.Pubmed.JournalHeading] where MedlineTA in (select MedlineTA from #tmpJournalHeading)
	insert into [Profile.Data].[Publication.Pubmed.JournalHeading] select * from #tmpJournalHeading

	delete from [Profile.Data].[Publication.Pubmed.Bibliometrics] where PMID in (select pmid from #tmp)

	;
	with abbs as (
		SELECT t2.MedlineTA, weight, STUFF((SELECT '|' + CAST([Abbreviation] AS varchar) + ',' + CAST([Color] as varchar) +  ',' + CAST(DisplayName as varchar)  FROM [Profile.Data].[Publication.Pubmed.JournalHeading] t1  where t1.MedlineTA =t2.MedlineTA FOR XML PATH('')), 1 ,1, '') AS ValueList
		FROM #tmpJournalHeading t2
		GROUP BY t2.MedlineTA, t2.Weight
	)
	insert into [Profile.Data].[Publication.Pubmed.Bibliometrics] 
		(PMID, PMCCitations, MedlineTA, Fields, TranslationHumans, TranslationAnimals, TranslationCells, TranslationPublicHealth, TranslationClinicalTrial)
	select PMID, PMCCitations, a.MedlineTA, ValueList , TranslationHumans, TranslationAnimals, TranslationCells, TranslationPublicHealth, TranslationClinicalTrial
		from #tmp a left join abbs b on a.MedlineTA = b.MedlineTA

END
GO
PRINT N'Altering [Profile.Import].[PRNSWebservice.CheckForErrors]...';


GO

ALTER PROCEDURE [Profile.Import].[PRNSWebservice.CheckForErrors]
	@BatchID varchar(100)
AS
BEGIN
	DECLARE @ErrorCount int
	select @ErrorCount = count(*) from  [Profile.Import].[PRNSWebservice.Log] WHERE BatchID = @BatchID AND Success = 0
	UPDATE [Profile.Import].[PRNSWebservice.Log.Summary] set JobEnd = GETDATE(), ErrorCount = @ErrorCount WHERE BatchID = @BatchID
	IF @ErrorCount > 0
		RAISERROR('%i Errors recorded in [Profile.Import].[PRNSWebservice.Log] for BatchID %s',16,1, @ErrorCount, @BatchID);
END
GO
PRINT N'Altering [Profile.Module].[NetworkAuthorshipTimeline.Concept.GetData]...';


GO
ALTER PROCEDURE [Profile.Module].[NetworkAuthorshipTimeline.Concept.GetData]
	@NodeID BIGINT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @DescriptorName NVARCHAR(255)
 	SELECT @DescriptorName = d.DescriptorName
		FROM [RDF.Stage].[InternalNodeMap] m, [RDF.].Node n,
			[Profile.Data].[Concept.Mesh.Descriptor] d
		WHERE m.Status = 3 AND m.ValueHash = n.ValueHash AND n.NodeID = @NodeID
			AND m.InternalID = d.DescriptorUI

    -- Insert statements for procedure here
	declare @gc varchar(max)

	declare @y table (
		y int,
		A int,
		B int
	)

	insert into @y (y,A,B)
		select n.n y, coalesce(t.A,0) A, coalesce(t.B,0) B
		from [Utility.Math].[N] left outer join (
			select (case when y < 1970 then 1970 else y end) y,
				sum(A) A,
				sum(B) B
			from (
				select pmid, pubyear y, (case when w = 1 then 1 else 0 end) A, (case when w < 1 then 1 else 0 end) B
				from (
					select distinct pmid, pubyear, topicweight w
					from [Profile.Cache].[Concept.Mesh.PersonPublication]
					where meshheader = @DescriptorName
				) t
			) t
			group by y
		) t on n.n = t.y
		where n.n between year(getdate())-30 and year(getdate())

	declare @x int

	select @x = max(A+B)
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

		declare @d varchar(max)
		set @d = ''
		select @d = @d + cast(floor(0.5 + 100*A/@w) as varchar(50)) + ','
			from @y
			order by y
		set @d = left(@d,len(@d)-1) + '|'
		select @d = @d + cast(floor(0.5 + 100*B/@w) as varchar(50)) + ','
			from @y
			order by y
		set @d = left(@d,len(@d)-1)

		declare @c varchar(50)
		set @c = 'FB8072,80B1D3'
		--set @c = 'FB8072,B3DE69,80B1D3'
		--set @c = 'F96452,a8dc4f,68a4cc'
		--set @c = 'fea643,76cbbd,b56cb5'

		--select @v, @h, @d

		--set @gc = '//chart.googleapis.com/chart?chs=595x100&chf=bg,s,ffffff|c,s,ffffff&chxt=x,y&chxl=0:' + @h + '|1:' + @v + '&cht=bvs&chd=t:' + @d + '&chdl=First+Author|Middle or Unkown|Last+Author&chco='+@c+'&chbh=10'
		set @gc = '//chart.googleapis.com/chart?chs=595x100&chf=bg,s,ffffff|c,s,ffffff&chxt=x,y&chxl=0:' + @h + '|1:' + @v + '&cht=bvs&chd=t:' + @d + '&chdl=Major+Topic|Minor+Topic&chco='+@c+'&chbh=10'


		declare @asText varchar(max)
		set @asText = '<table style="width:592px"><tr><th>Year</th><th>Major Topic</th><th>Minor Topic</th><th>Total</th></tr>'
		select @asText = @asText + '<tr><td style="text-align:center;">' + cast(y as varchar(50)) + '</td><td style="text-align:center;">' + cast(A as varchar(50)) + '</td><td style="text-align:center;">' + cast(B as varchar(50)) + '</td><td>' + cast(A + B as varchar(50)) + '</td></tr>'
			from @y
			where A + B > 0
			order by y 
		select @asText = @asText + '</table>'

		declare @alt varchar(max)
		select @alt = 'Bar chart showing ' + cast(sum(A + B) as varchar(50))+ ' publications over ' + cast(count(*) as varchar(50)) + ' distinct years, with a maximum of ' + cast(@x as varchar(50)) + ' publications in ' from @y where A + B > 0
		select @alt = @alt + cast(y as varchar(50)) + ' and '
			from @y
			where A + B = @x
			order by y 
		select @alt = left(@alt, len(@alt) - 4)

		select @gc gc, @alt alt, @asText asText --, @w w

		--select * from @y order by y

	end

END
GO
PRINT N'Altering [Profile.Module].[NetworkAuthorshipTimeline.Person.GetData]...';


GO
ALTER PROCEDURE [Profile.Module].[NetworkAuthorshipTimeline.Person.GetData]
	@NodeID BIGINT,
	@ShowAuthorPosition BIT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

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
	end

END
GO
PRINT N'Altering [RDF.].[GetDataRDF]...';


GO
ALTER PROCEDURE [RDF.].[GetDataRDF]
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
	INSERT INTO #SecurityGroupNodes (SecurityGroupNode) EXEC [RDF.Security].GetSessionSecurityGroupNodes @SessionID, @Subject
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
PRINT N'Creating [Profile.Data].[Publication.Pubmed.ParsePubmedBookArticle]...';


GO
CREATE procedure [Profile.Data].[Publication.Pubmed.ParsePubmedBookArticle]
	@pmid int,
	@mpid varchar(50)
AS
BEGIN
	SET NOCOUNT ON;
	update [Profile.Data].[Publication.PubMed.AllXML] set ParseDT = GETDATE() where pmid = @pmid

	DECLARE @ErrMsg nvarchar(4000), @ErrSeverity int,@proc VARCHAR(200),@date DATETIME,@auditid UNIQUEIDENTIFIER 
	SELECT @proc = OBJECT_NAME(@@PROCID),@date=GETDATE() 	

	if not exists (select 1 from [Profile.Data].[vwPublication.PubMed.AllXML.PubmedBookArticle] where pmid = @pmid)
	begin
		set @ErrMsg =  'Error in [Profile.Data].[Publication.Pubmed.ParsePubmedBookArticle] pmid ' + cast(@pmid as varchar(50)) + ' does not exist'
		RAISERROR(@ErrMsg, 16, 1)
	end

	create table #authors (
		ValidYN varchar(1),
		LastName varchar(100),
		FirstName varchar(100),
		ForeName varchar(100),
		Suffix varchar(20),
		Initials varchar(20),
		Affiliation varchar(max))
			
	insert into #authors
	select
		nref.value('@ValidYN','varchar(1)') ValidYN, 
		nref.value('LastName[1]','varchar(100)') LastName, 
		nref.value('FirstName[1]','varchar(100)') FirstName,
		nref.value('ForeName[1]','varchar(100)') ForeName,
		nref.value('Suffix[1]','varchar(20)') Suffix,
		nref.value('Initials[1]','varchar(20)') Initials,
		COALESCE(nref.value('AffiliationInfo[1]/Affiliation[1]','varchar(1000)'),
			nref.value('Affiliation[1]','varchar(max)')) Affiliation
	from [Profile.Data].[Publication.PubMed.AllXML] cross apply x.nodes('//AuthorList[@Type="authors"]/Author') as R(nref) 
	where pmid = @pmid

	declare @authors varchar(max)
	select @authors = isnull(cast((
		select ', '+lastname+' '+initials
		from #authors q
		--order by PmPubsAuthorID
		for xml path(''), type
	) as nvarchar(max)),'') 

	if len(@authors) > 2
	select @authors = SUBSTRING(@authors, 3, len(@authors) - 2)
	
	BEGIN TRY
	BEGIN TRANSACTION
		if exists (select 1 from [Profile.Data].[Publication.MyPub.General] where pmid=@pmid)
		begin
			update a set 
				HmsPubCategory = b.HmsPubCategory,
				a.PubTitle = b.PubTitle,
				a.ArticleTitle = b.ArticleTitle,
				a.PlaceOfPub = b.PlaceOfPub,
				a.Publisher = b.Publisher,
				a.PublicationDT = b.PublicationDT,
				a.Authors = isnull(@authors, ''),
				URL = 'https://www.ncbi.nlm.nih.gov/pubmed/' + cast(@pmid as varchar(50))
			from [Profile.Data].[Publication.MyPub.General] a
			join [Profile.Data].[vwPublication.PubMed.AllXML.PubmedBookArticle] b
			on a.PMID = @pmid and b.PMID = @pmid
		end 
		else 
		begin
			insert into [Profile.Data].[Publication.MyPub.General] (MPID, PMID, HmsPubCategory, PubTitle, ArticleTitle, PlaceOfPub, Publisher, PublicationDT, Authors, URL)
			select @mpid, PMID, HmsPubCategory, PubTitle, ArticleTitle, PlaceOfPub, Publisher, PublicationDT, isnull(@authors, ''), 'https://www.ncbi.nlm.nih.gov/pubmed/' + cast(@pmid as varchar(50)) from [Profile.Data].[vwPublication.PubMed.AllXML.PubmedBookArticle] where pmid = @pmid
		end

	COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		--Check success
		IF @@TRANCOUNT > 0  ROLLBACK
		SELECT @date=GETDATE()
		EXEC [Profile.Cache].[Process.AddAuditUpdate] @auditid=@auditid OUTPUT,@ProcessName =@proc,@ProcessEndDate=@date,@error = 1,@insert_new_record=1
		--Raise an error with the details of the exception
		SELECT @ErrMsg = ERROR_MESSAGE(), @ErrSeverity = ERROR_SEVERITY()
		RAISERROR(@ErrMsg, @ErrSeverity, 1)
	END CATCH
END
GO
PRINT N'Creating [Profile.Data].[Publication.Pubmed.UpdateAuthor2Person]...';


GO
CREATE Procedure [Profile.Data].[Publication.Pubmed.UpdateAuthor2Person]
	@UseStagePMIDs bit = 0,
	@PMID int = null
AS 
BEGIN
	create table #tmp (
		PMPubsAuthorID int,
		PersonID int not null,
		PMID int not null)
	ALTER TABLE #tmp add primary key (PersonID, PMID)

	if @pmid is not null
		insert into #tmp (personID, PMID) select distinct PersonID, PMID from [Profile.Data].[Publication.Person.Include] where pmid = @PMID
	else if @UseStagePMIDs = 1
		insert into #tmp (personID, PMID) select distinct PersonID, PMID from [Profile.Data].[Publication.Person.Include] where pmid in (select pmid from [Profile.Data].[Publication.PubMed.General.Stage])
	else 
		insert into #tmp (personID, PMID) select distinct PersonID, PMID from [Profile.Data].[Publication.Person.Include] where pmid is not null

	create table #t (PMPubsAuthorID int primary key not null)
	insert into #t select PMPubsAuthorID from [Profile.Data].[Publication.PubMed.Author] 

	update b set b.PMPubsAuthorID = a.PMPubsAuthorID from [Profile.Data].[Publication.PubMed.Author] a 
		join #t i on a.PmPubsAuthorID = i.PMPubsAuthorID
		join #tmp b
		on a.PMID = b.PMID
		and b.PMPubsAuthorID is null
		join [Profile.Data].Person c
		on b.PersonID = c.PersonID
		and a.LastName = c.LastName
		and a.ForeName = c.FirstName + ' ' + MiddleName
		and c.IsActive = 1

	delete from #t where PMPubsAuthorID in (select PMPubsAuthorID from #tmp)

	update b set b.PMPubsAuthorID = a.PMPubsAuthorID from [Profile.Data].[Publication.PubMed.Author] a 
		join #t i on a.PmPubsAuthorID = i.PMPubsAuthorID
		join #tmp b
		on a.PMID = b.PMID
		and b.PMPubsAuthorID is null
		join [Profile.Data].Person c
		on b.PersonID = c.PersonID
		and a.LastName = c.LastName
		and a.ForeName = c.FirstName
		and (substring(Initials,2,1) = substring(c.MiddleName, 1, 1))
		and c.IsActive = 1

	delete from #t where PMPubsAuthorID in (select PMPubsAuthorID from #tmp)

	update b set b.PMPubsAuthorID = a.PMPubsAuthorID from [Profile.Data].[Publication.PubMed.Author] a 
		join #t i on a.PmPubsAuthorID = i.PMPubsAuthorID
		join #tmp b
		on a.PMID = b.PMID
		and b.PMPubsAuthorID is null
		join [Profile.Data].Person c
		on b.PersonID = c.PersonID
		and a.LastName = c.LastName
		and (substring(forename, 1, 1) = substring(c.firstname, 1, 1) )
		and (substring(Initials,2,1) = substring(c.MiddleName, 1, 1))
		and c.IsActive = 1

	delete from #t where PMPubsAuthorID in (select PMPubsAuthorID from #tmp)

	update b set b.PMPubsAuthorID = a.PMPubsAuthorID from [Profile.Data].[Publication.PubMed.Author] a 
		join #t i on a.PmPubsAuthorID = i.PMPubsAuthorID
		join #tmp b
		on a.PMID = b.PMID
		and b.PMPubsAuthorID is null
		join [Profile.Data].Person c
		on b.PersonID = c.PersonID
		and a.LastName = c.LastName
		and (substring(forename, 1, 1) = substring(c.firstname, 1, 1) )
		and (len(initials) = 1 or MiddleName = '')
		and c.IsActive = 1

	delete from #t where PMPubsAuthorID in (select PMPubsAuthorID from #tmp)

	update b set b.PMPubsAuthorID = a.PMPubsAuthorID from [Profile.Data].[Publication.PubMed.Author] a 
		join #t i on a.PmPubsAuthorID = i.PMPubsAuthorID
		join #tmp b
		on a.PMID = b.PMID
		and b.PMPubsAuthorID is null
		join [Profile.Data].Person c
		on b.PersonID = c.PersonID
		and a.LastName = c.LastName
		and c.IsActive = 1

	if @pmid is not null
	BEGIN
		delete a from [Profile.Data].[Publication.PubMed.Author2Person] a 
			join [Profile.Data].[Publication.PubMed.Author] b on a.PmPubsAuthorID = b.PmPubsAuthorID and b.pmid = @PMID
		insert into [Profile.Data].[Publication.PubMed.Author2Person] (PMPubsAuthorID, PersonID ) select PMPubsAuthorID, PersonID from #tmp where PMPubsAuthorID is not null
	END
	else if @UseStagePMIDs = 1
	BEGIN
		delete a from [Profile.Data].[Publication.PubMed.Author2Person] a 
			join [Profile.Data].[Publication.PubMed.Author] b on a.PmPubsAuthorID = b.PmPubsAuthorID
			join [Profile.Data].[Publication.PubMed.General.Stage] s on b.PMID = s.PMID
		insert into [Profile.Data].[Publication.PubMed.Author2Person] (PMPubsAuthorID, PersonID ) select PMPubsAuthorID, PersonID from #tmp where PMPubsAuthorID is not null
	END
	else 
	BEGIN
		truncate table [Profile.Data].[Publication.PubMed.Author2Person]
		insert into [Profile.Data].[Publication.PubMed.Author2Person] (PMPubsAuthorID, PersonID ) select PMPubsAuthorID, PersonID from #tmp where PMPubsAuthorID is not null
	END
END
GO
PRINT N'Creating [Profile.Import].[PRNSWebservice.Funding.GetPersonInfoForDisambiguation]...';


GO
CREATE PROCEDURE [Profile.Import].[PRNSWebservice.Funding.GetPersonInfoForDisambiguation] 
	@Job varchar(55),
	@BatchID varchar(100)
AS
BEGIN
	SET NOCOUNT ON;
	CREATE TABLE #tmp (LogID INT, BatchID VARCHAR(100), RowID INT, HttpMethod VARCHAR(10), URL VARCHAR(500), PostData xml) 

	DECLARE  --@search XML,
				@batchcount INT,
				--@threshold FLOAT,
				@baseURI NVARCHAR(max),
				@orcidNodeID NVARCHAR(max),
				@BatchSize int,
				@URL varchar(500),
				@logLevel int,
				@rows int,
				@rowsCount int

	select @URL = URL, @BatchSize = batchSize, @logLevel = logLevel from [Profile.Import].[PRNSWebservice.Options] where job = @Job

	SELECT @baseURI = [Value] FROM [Framework.].[Parameter] WHERE [ParameterID] = 'baseURI'
	SELECT @orcidNodeID = NodeID from [RDF.].Node where Value = 'http://vivoweb.org/ontology/core#orcidId'
	
	SELECT personID, ROW_NUMBER() OVER (ORDER BY personID) AS rownum INTO #personIDs FROM [Profile.Data].Person p
	WHERE IsActive = 1 and not exists (select 1 from [Profile.Data].[Funding.DisambiguationSettings] s where s.PersonID = p.PersonID and enabled = 0)

	SELECT @rows = count(*) FROM #personIDs

	insert into #tmp(LogID, BatchID, RowID, HttpMethod, URL, PostData)
	select -1, @batchID batchID, n, 'POST', @URL, (
		SELECT (
			select p2.personid as PersonID, 
			ISNULL(RTRIM(firstname),'')  "Name/First",
			ISNULL(RTRIM(middlename),'') "Name/Middle",
			ISNULL(RTRIM(p2.lastname),'') "Name/Last",
			ISNULL(RTRIM(suffix),'')     "Name/Suffix",
			d.cnt "LocalDuplicateNames",
			(SELECT DISTINCT ISNULL(LTRIM(ISNULL(emailaddress,p2.emailaddr)),'') Email
					FROM [Profile.Data].[Person.Affiliation] pa
					WHERE pa.personid = p2.personid
				FOR XML PATH(''),TYPE) AS "EmailList",
			(SELECT distinct Organization as Org FROM [Profile.Data].[Funding.DisambiguationOrganizationMapping] m
				JOIN [Profile.Data].[Person.Affiliation] pa
				on m.InstitutionID = pa.InstitutionID 
					or m.InstitutionID is null
				where pa.PersonID = p2.PersonID
				FOR XML PATH(''),ROOT('OrgList'),TYPE),
			(SELECT PMID
					FROM [Profile.Data].[Publication.Person.Add]
					WHERE personid =p2.personid
				FOR XML PATH(''),ROOT('PMIDAddList'),TYPE),
			(SELECT PMID
				FROM [Profile.Data].[Publication.Person.Include]
					WHERE personid =p2.personid
				FOR XML PATH(''),ROOT('PMIDIncludeList'),TYPE),
			(SELECT PMID
				FROM [Profile.Data].[Publication.Person.Exclude]
					WHERE personid =p2.personid
				FOR XML PATH(''),ROOT('PMIDExcludeList'),TYPE),
			(SELECT FundingID FROM [Profile.Data].[Funding.Add] ad
				join [Profile.Data].[Funding.Agreement] ag
					on ad.FundingAgreementID = ag.FundingAgreementID
					and ag.Source = 'NIH'
					WHERE ad.PersonID = p2.PersonID
				FOR XML PATH(''),ROOT('GrantsAddList'),TYPE),
			(SELECT FundingID FROM [Profile.Data].[Funding.Add] ad
				join [Profile.Data].[Funding.Agreement] ag
					on ad.FundingAgreementID = ag.FundingAgreementID
					and ag.Source = 'NIH'
					WHERE ad.PersonID = p2.PersonID
				FOR XML PATH(''),ROOT('GrantsAddList'),TYPE),
			(SELECT FundingID FROM [Profile.Data].[Funding.Delete]
					WHERE Source = 'NIH' and PersonID = p2.PersonID
				FOR XML PATH(''),ROOT('GrantsDeleteList'),TYPE),
			(SELECT @baseURI + CAST(i.NodeID AS VARCHAR) 
				FOR XML PATH(''),ROOT('URI'),TYPE),
			(select n.Value as '*' from [RDF.].Node n join
					[RDF.].Triple t  on n.NodeID = t.Object
					and t.Subject = i.NodeID
					and t.Predicate = @orcidNodeID
				FOR XML PATH(''),ROOT('ORCID'),TYPE)
		FROM [Profile.Data].Person p2 
		  LEFT JOIN ( SELECT [Utility.NLP].[fnNamePart1](firstname)F,
				lastname,
				COUNT(*)cnt
				FROM [Profile.Data].Person 
				GROUP BY [Utility.NLP].[fnNamePart1](firstname), 
					lastname
				)d ON d.f = [Utility.NLP].[fnNamePart1](p2.firstname)
					AND d.lastname = p2.lastname
					AND p2.IsActive = 1 
			LEFT JOIN [RDF.Stage].[InternalNodeMap] i
			ON [InternalType] = 'Person' AND [Class] = 'http://xmlns.com/foaf/0.1/Person' AND [InternalID] = CAST(p2.personid AS VARCHAR(50))
				JOIN #personIDs p3 on p2.personID = p3.personID
		  order by p3.PersonID offset n * @BatchSize ROWS FETCH NEXT @BatchSize ROWS ONLY for xml path('Person'), root('FindFunding'), type) as X
	  ) x
	from [Utility.Math].N where n <= @rows / @BatchSize

	select @rowsCount = @@ROWCOUNT

	Update [Profile.Import].[PRNSWebservice.Log.Summary]  set RecordsCount = @rows, RowsCount = @rowsCount where BatchID = @BatchID

	DECLARE @LogIDTable TABLE (LogID int, RowID int)
	IF @logLevel = 1
	BEGIN
		INSERT INTO [Profile.Import].[PRNSWebservice.Log] (Job, BatchID, RowID, HttpMethod, URL)
		OUTPUT inserted.LogID, Inserted.RowID into @LogIDTable
		SELECT @job, BatchID, RowID, HttpMethod, URL FROM #tmp
		UPDATE t SET t.LogID = l.LogID FROM #tmp t JOIN @LogIDTable l ON t.RowID = l.RowID
	END
	ELSE IF @logLevel = 2
	BEGIN
		INSERT INTO [Profile.Import].[PRNSWebservice.Log] (Job, BatchID, RowID, HttpMethod, URL, PostData)
		OUTPUT inserted.LogID, Inserted.RowID into @LogIDTable
		SELECT @job, BatchID, RowID, HttpMethod, URL, convert(varchar(max), PostData) FROM #tmp
		UPDATE t SET t.LogID = l.LogID FROM #tmp t JOIN @LogIDTable l ON t.RowID = l.RowID
	END

	Truncate table [Profile.Data].[Funding.DisambiguationResults]
	SELECT LogID, BatchID, RowID, HttpMethod, URL, convert(varchar(max), PostData) FROM #tmp
END
GO
PRINT N'Creating [Profile.Import].[PRNSWebservice.Funding.ParseDisambiguationXML]...';


GO
CREATE PROCEDURE [Profile.Import].[PRNSWebservice.Funding.ParseDisambiguationXML]
	@Job varchar(55) = '',
	@BatchID varchar(100) = '',
	@RowID int = -1,
	@LogID int = -1,
	@URL varchar (500) = '',
	@Data varchar(max)
AS
BEGIN
	SET NOCOUNT ON;	

	BEGIN TRY 
		declare @rowsCount int
		declare @xml xml
		set @xml = cast(@Data as xml)

		Insert into [Profile.Data].[Funding.DisambiguationResults]
		(PersonID, FundingID, GrantAwardedBy, StartDate, EndDate, PrincipalInvestigatorName,
			AgreementLabel, Abstract, Source, FundingID2, RoleLabel)
		select nref.value('@PersonID','varchar(max)') PersonID,
		sref.value('FundingID[1]','varchar(max)') FundingID,
		sref.value('GrantAwardedBy[1]','varchar(max)') GrantAwardedBy,
		sref.value('StartDate[1]','varchar(max)') StartDate,
		sref.value('EndDate[1]','varchar(max)') EndDate,
		sref.value('PrincipalInvestigatorName[1]','varchar(max)') PrincipalInvestigatorName,
		sref.value('AgreementLabel[1]','varchar(max)') AgreementLabel,
		sref.value('Abstract[1]','varchar(max)') Abstract,
		sref.value('Source[1]','varchar(max)') Source,
		sref.value('FundingID2[1]','varchar(max)') FundingID2,
		sref.value('RoleLabel[1]','varchar(max)') RoleLabel
		from @xml.nodes('//PersonList[1]/Person') as R(nref)
		cross apply R.nref.nodes('Funding') as S(sref)
		
		select @rowsCount = @@ROWCOUNT
		if @logID > 0
			update [Profile.Import].[PRNSWebservice.Log] set ResultCount = @rowsCount where LogID = @logID
	END TRY
	BEGIN CATCH
		declare @errorMessage varchar(max)
		select @errorMessage = Error_Message()

		if @LogID < 0
		begin
			select @LogID = isnull(LogID, -1) from [Profile.Import].[PRNSWebservice.Log] where BatchID = @BatchID and RowID = @RowID
		end
		select @logid
		if @LogID > 0
			update [Profile.Import].[PRNSWebservice.Log] set Success = 0, HttpResponse = @Data, ErrorText = @errorMessage where LogID = @LogID
		else
			insert into [Profile.Import].[PRNSWebservice.Log] (Job, BatchID, RowID, URL, HttpResponse, Success, ErrorText) Values (@Job, @BatchID, @RowID, @URL, @Data, 0, @errorMessage)
	END CATCH	
END
GO
PRINT N'Creating [Profile.Import].[PRNSWebservice.PubMed.GetAllPMIDs]...';


GO
CREATE PROCEDURE [Profile.Import].[PRNSWebservice.PubMed.GetAllPMIDs]
	@Job varchar(55),
	@BatchID varchar(100)
AS
BEGIN
	SET NOCOUNT ON;	

	DECLARE  @baseURI NVARCHAR(max),
			@URL varchar(500),
			@logLevel int, 
			@rowsCount int

select @URL = URL, @logLevel = logLevel from [Profile.Import].[PRNSWebservice.Options] where job = @Job


	DECLARE @GetOnlyNewXML BIT
	select @GetOnlyNewXML = case when options = 'GetOnlyNewXML=True' then 1 else 0 end from [Profile.Import].[PRNSWebservice.Options] where job = @Job

	CREATE TABLE #tmp (LogID INT, BatchID VARCHAR(100), RowID INT, HttpMethod VARCHAR(10), URL VARCHAR(500), PostData VARCHAR(MAX)) 

	
	IF @GetOnlyNewXML = 1 
	-- ONLY GET XML FOR NEW Publications
		BEGIN
			INSERT INTO #tmp(RowID) 
			SELECT distinct pmid
				FROM [Profile.Data].[Publication.PubMed.Disambiguation]
				WHERE pmid NOT IN(SELECT PMID FROM [Profile.Data].[Publication.PubMed.General])
				AND pmid IS NOT NULL AND pmid not in (select pmid from [Profile.Data].[Publication.PubMed.DisambiguationExclude])
		END
	ELSE 
	-- FULL REFRESH
		BEGIN
			INSERT INTO #tmp(RowID) 
			SELECT distinct pmid
				FROM [Profile.Data].[Publication.PubMed.Disambiguation]
				WHERE pmid IS NOT NULL AND pmid not in (select pmid from [Profile.Data].[Publication.PubMed.DisambiguationExclude]) 
				UNION   
			SELECT distinct pmid
				FROM [Profile.Data].[Publication.Person.Include]
				WHERE pmid IS NOT NULL AND pmid not in (select pmid from [Profile.Data].[Publication.PubMed.DisambiguationExclude]) 
		END 


	UPDATE t SET
		t.LogID = -1,
		t.BatchID = @BatchID, 
		t.HttpMethod = 'POST',
		t.URL = o.url,
		t.PostData = '<PMID>' + cast(RowID as varchar(100)) + '</PMID>'
			FROM #tmp t
			JOIN [Profile.Import].[PRNSWebservice.Options] o ON o.job = 'GetPubMedXML'
	select @rowsCount = @@ROWCOUNT

	Update [Profile.Import].[PRNSWebservice.Log.Summary]  set RecordsCount = @rowsCount, RowsCount = @rowsCount where BatchID = @BatchID

	DECLARE @LogIDTable TABLE (LogID int, RowID int)
	IF @logLevel = 1
	BEGIN
		INSERT INTO [Profile.Import].[PRNSWebservice.Log] (Job, BatchID, RowID, HttpMethod, URL)
		OUTPUT inserted.LogID, Inserted.RowID into @LogIDTable
		SELECT @Job, @BatchID, RowID, 'POST', @URL FROM #tmp
		UPDATE t SET t.LogID = l.LogID FROM #tmp t JOIN @LogIDTable l ON t.RowID = l.RowID
	END
	ELSE IF @logLevel = 2
	BEGIN
		INSERT INTO [Profile.Import].[PRNSWebservice.Log] (Job, BatchID, RowID, HttpMethod, URL, PostData)
		OUTPUT inserted.LogID, Inserted.RowID into @LogIDTable
		SELECT @Job, @BatchID, RowID, 'POST', @URL, cast(PostData as varchar(max)) FROM #tmp
		UPDATE t SET t.LogID = l.LogID FROM #tmp t JOIN @LogIDTable l ON t.RowID = l.RowID
	END

	SELECT * FROM #tmp
END
GO
PRINT N'Creating [Profile.Import].[PRNSWebservice.PubMed.GetPersonInfoForDisambiguation]...';


GO
CREATE PROCEDURE [Profile.Import].[PRNSWebservice.PubMed.GetPersonInfoForDisambiguation] 
	@Job varchar(55) = 'PubMedDisambiguation_GetPubs',
	@BatchID varchar(100)
AS
BEGIN
SET nocount  ON;
 
 
DECLARE  @search XML,
            @batchcount INT,
            @threshold FLOAT,
            @baseURI NVARCHAR(max),
			@orcidNodeID NVARCHAR(max),
			@BatchSize int,
			@URL varchar(500),
			@logLevel int

select @URL = URL, @BatchSize = batchSize, @logLevel = logLevel from [Profile.Import].[PRNSWebservice.Options] where job = @Job

--SET Custom Threshold based on internal Institutional Logic, default is .98
SELECT @threshold = .98

--SELECT @batchID=NEWID()

SELECT @baseURI = [Value] FROM [Framework.].[Parameter] WHERE [ParameterID] = 'baseURI'
SELECT @orcidNodeID = NodeID from [RDF.].Node where Value = 'http://vivoweb.org/ontology/core#orcidId'

CREATE TABLE #tmp (LogID INT, RowID INT not null primary key, PostData XML) 

insert into #tmp (LogID, RowID, PostData)
SELECT -1, personid, 
                   (SELECT ISNULL(RTRIM(firstname),'')  "Name/First",
                                          ISNULL(RTRIM(middlename),'') "Name/Middle",
                                          ISNULL(RTRIM(p.lastname),'') "Name/Last",
                                          ISNULL(RTRIM(suffix),'')     "Name/Suffix",
                                          CASE 
                                                 WHEN a.n IS NOT NULL OR b.n IS NOT NULL 
                                                          /*  Below is example of a custom piece of logic to alter the disambiguation by telling the disambiguation service
                                                            to Require First Name usage in the algorithm for faculty who are lower in rank */
                                                      OR facultyranksort > 4 
                                                      THEN 'true'
                                                ELSE 'false'
                                          END "RequireFirstName",
                                          d.cnt                                                                              "LocalDuplicateNames",
                                          @threshold                                                                   "MatchThreshold",
                                          (SELECT DISTINCT ISNULL(LTRIM(ISNULL(emailaddress,p.emailaddr)),'') Email
                                                      FROM [Profile.Data].[Person.Affiliation] pa
                                                WHERE pa.personid = p.personid
                                                FOR XML PATH(''),TYPE) AS "EmailList",
                                          (SELECT Affiliation
                                                      FROM [Profile.Data].[Publication.PubMed.DisambiguationAffiliation]
                                                FOR XML PATH(''),TYPE) AS "AffiliationList",
                                          (SELECT PMID
                                             FROM [Profile.Data].[Publication.Person.Add]
                                            WHERE personid =p2.personid
                                        FOR XML PATH(''),ROOT('PMIDAddList'),TYPE),
                                          (SELECT PMID
                                             FROM [Profile.Data].[Publication.Person.Exclude]
                                            WHERE personid =p2.personid
                                        FOR XML PATH(''),ROOT('PMIDExcludeList'),TYPE),
                                          (SELECT @baseURI + CAST(i.NodeID AS VARCHAR) 
                                        FOR XML PATH(''),ROOT('URI'),TYPE),
										  (select n.Value as '*' from [RDF.].Node n join
											[RDF.].Triple t  on n.NodeID = t.Object
											and t.Subject = i.NodeID
											and t.Predicate = @orcidNodeID
										FOR XML PATH(''),ROOT('ORCID'),TYPE)
                              FROM [Profile.Data].Person p
                                       LEFT JOIN ( 
                                                
                                                         --case 1
                                                            SELECT LEFT(firstname,1)  f,
                                                                              LEFT(middlename,1) m,
                                                                              lastname,
                                                                              COUNT(* )          n
                                                              FROM [Profile.Data].Person
                                                            GROUP BY LEFT(firstname,1),
                                                                              LEFT(middlename,1),
                                                                              lastname
                                                            HAVING COUNT(* ) > 1
                                                      )A ON a.lastname = p.lastname
                                                        AND a.f=LEFT(firstname,1)
                                                        AND a.m = LEFT(middlename,1)
                              LEFT JOIN (               
 
                                                      --case 2
                                                      SELECT LEFT(firstname,1) f,
                                                                        lastname,
                                                                        COUNT(* )         n
                                                        FROM [Profile.Data].Person
                                                      GROUP BY LEFT(firstname,1),
                                                                        lastname
                                                      HAVING COUNT(* ) > 1
                                                                        AND SUM(CASE 
                                                                                                       WHEN middlename = '' THEN 1
                                                                                                      ELSE 0
                                                                                                END) > 0
                                                                                                
                                                )B ON b.f = LEFT(firstname,1)
                                                  AND b.lastname = p.lastname
                              LEFT JOIN ( SELECT [Utility.NLP].[fnNamePart1](firstname)F,
                                                                                          lastname,
                                                                                          COUNT(*)cnt
                                                                              FROM [Profile.Data].Person 
                                                                         GROUP BY [Utility.NLP].[fnNamePart1](firstname), 
                                                                                          lastname
                                                                  )d ON d.f = [Utility.NLP].[fnNamePart1](p2.firstname)
                                                                        AND d.lastname = p2.lastname

                              LEFT JOIN [RDF.Stage].[InternalNodeMap] i
								 ON [InternalType] = 'Person' AND [Class] = 'http://xmlns.com/foaf/0.1/Person' AND [InternalID] = CAST(p2.personid AS VARCHAR(50))                             
                         WHERE p.personid = p2.personid
                        
                        FOR XML PATH(''),ROOT('FindPMIDs')) XML--as xml)
  --INTO #batch
  FROM [Profile.Data].vwperson  p2 where PersonID not in (select PersonID from [Profile.Data].[Publication.Pubmed.DisambiguationSettings] where Enabled = 0)

  select @BatchSize = @@ROWCOUNT

	Update [Profile.Import].[PRNSWebservice.Log.Summary]  set RecordsCount = @BatchSize, RowsCount = @BatchSize  where BatchID = @BatchID

	DECLARE @LogIDTable TABLE (LogID int, RowID int)
	IF @logLevel = 1
	BEGIN
		INSERT INTO [Profile.Import].[PRNSWebservice.Log] (Job, BatchID, RowID, HttpMethod, URL)
		OUTPUT inserted.LogID, Inserted.RowID into @LogIDTable
		SELECT @Job, @BatchID, RowID, 'POST', @URL FROM #tmp
		UPDATE t SET t.LogID = l.LogID FROM #tmp t JOIN @LogIDTable l ON t.RowID = l.RowID
	END
	ELSE IF @logLevel = 2
	BEGIN
		INSERT INTO [Profile.Import].[PRNSWebservice.Log] (Job, BatchID, RowID, HttpMethod, URL, PostData)
		OUTPUT inserted.LogID, Inserted.RowID into @LogIDTable
		SELECT @Job, @BatchID, RowID, 'POST', @URL, cast(PostData as varchar(max)) FROM #tmp
		UPDATE t SET t.LogID = l.LogID FROM #tmp t JOIN @LogIDTable l ON t.RowID = l.RowID
	END

	select LogID, cast(@batchID as varchar(100)) as BatchID, RowID, 'POST' as HttpMethod, @URL as URL, cast(PostData as varchar(max)) from #tmp
END
GO
PRINT N'Creating [Profile.Import].[PRNSWebservice.PubMed.ImportDisambiguationResults]...';


GO
CREATE PROCEDURE [Profile.Import].[PRNSWebservice.PubMed.ImportDisambiguationResults] 
	@Job varchar(55) = '',
	@BatchID varchar(100) = '',
	@RowID int = -1,
	@LogID int = -1,
	@URL varchar (500) = '',
	@Data varchar(max)
AS
BEGIN
	SET NOCOUNT ON;	
	
	declare @x xml
	select @x = cast(@Data as xml)


	BEGIN TRY
		BEGIN TRAN		 
			  declare @rowsCount int
			  --delete from [Profile.Data].[Publication.PubMed.Disambiguation] where personid = @RowID				 
			  -- Add publications_include records
			  INSERT INTO [Profile.Data].[Publication.PubMed.Disambiguation] (personid,pmid)
			  SELECT @RowID,
					 D.element.value('.','INT') pmid		 
				FROM @x.nodes('//PMID') AS D(element)
			   WHERE NOT EXISTS(SELECT TOP 1 * FROM [Profile.Data].[Publication.PubMed.Disambiguation]	 dp WHERE personid = @RowID and dp.pmid = D.element.value('.','INT'))	
			   select @rowsCount = @@ROWCOUNT
			   if @logID > 0
			       update [Profile.Import].[PRNSWebservice.Log] set ResultCount = @rowsCount where LogID = @logID

		
		COMMIT
	END TRY
	BEGIN CATCH
		DECLARE @ErrMsg nvarchar(4000), @ErrSeverity int
		--Check success
		IF @@TRANCOUNT > 0  ROLLBACK

		-- Raise an error with the details of the exception
		SELECT @ErrMsg = '[Profile.Import].[PRNSWebservice.PubMed.ImportDisambiguationResults]' + ERROR_MESSAGE(),
					 @ErrSeverity = ERROR_SEVERITY()

		RAISERROR(@ErrMsg, @ErrSeverity, 1)
			 
	END CATCH				
END
GO
PRINT N'Creating [Profile.Import].[Publication.Pubmed.AddPubMedXML]...';


GO
CREATE PROCEDURE [Profile.Import].[PRNSWebservice.Pubmed.AddPubMedXML]
	@Job varchar(55) = '',
	@BatchID varchar(100) = '',
	@RowID int = -1,
	@LogID int = -1,
	@URL varchar (500) = '',
	@Data varchar(max)
AS
BEGIN
	SET NOCOUNT ON;	

	BEGIN TRY 	 
		IF ISNULL(@Data,'')='' 
		BEGIN
			DELETE FROM [Profile.Data].[Publication.PubMed.Disambiguation] WHERE pmid = @RowID AND NOT EXISTS (SELECT 1 FROM [Profile.Data].[Publication.Person.Add]  pa WHERE pa.pmid = @RowID)
			RETURN
		END
 
		-- Remove existing pmid record
		DELETE FROM [Profile.Data].[Publication.PubMed.AllXML] WHERE pmid = @RowID
		
		-- Add Pub Med XML	
		INSERT INTO [Profile.Data].[Publication.PubMed.AllXML](pmid,X) VALUES(@RowID,CAST(@Data AS XML))		
		RETURN
	END TRY
	BEGIN CATCH
		declare @errorMessage varchar(max)
		select @errorMessage = Error_Message()

		if @LogID < 0
		begin
			select @LogID = isnull(LogID, -1) from [Profile.Import].[PRNSWebservice.Log] where BatchID = @BatchID and RowID = @RowID
		end
		select @logid
		if @LogID > 0
			update [Profile.Import].[PRNSWebservice.Log] set Success = 0, HttpResponse = @Data, ErrorText = @errorMessage where LogID = @LogID
		else
			insert into [Profile.Import].[PRNSWebservice.Log] (Job, BatchID, RowID, URL, HttpResponse, Success, ErrorText) Values (@Job, @BatchID, @RowID, @URL, @Data, 0, @errorMessage)
	END CATCH	
END
GO
PRINT N'Creating [RDF.].[GetPresentationXMLByType]...';


GO
CREATE PROCEDURE [RDF.].[GetPresentationXMLByType]
@subjectType varchar(max)=NULL, @predicate BIGINT=NULL, @objectType varchar(max)=NULL, @PresentationXML XML=NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	declare @typeID bigint
	select @typeID = [RDF.].fnURI2NodeID('http://www.w3.org/1999/02/22-rdf-syntax-ns#type')

	select @subjectType = null where @subjectType = '0'
	select @predicate = null where @predicate = 0
	select @objectType = null where @objectType = '0'

	create table #subjectTypes ( st bigint)
	create table #objectTypes (ot bigint)

	insert into #subjectTypes
		SELECT Split.a.value('.', 'VARCHAR(100)')
		FROM ( select CAST('<c>' + REPLACE(@subjectType, ',', '</c><c>') + '</c>' as XML) as A) AS A CROSS APPLY A.nodes ('/c') AS Split(a); 

	if @objectType is not null
		insert into #objectTypes
			SELECT Split.a.value('.', 'VARCHAR(100)')
			FROM ( select CAST('<c>' + REPLACE(@objectType, ',', '</c><c>') + '</c>' as XML) as A) AS A CROSS APPLY A.nodes ('/c') AS Split(a); 

	/* --This is cleaner for SQL Server 2016 and above

	insert into #subjectTypes SELECT cast(value as bigint) from string_split(@subjectType, ',')
	if @objectType is not null
		insert into #objectTypes SELECT cast(value as bigint) from string_split(@objectType, ',')
	*/

	declare @SecurityGroupListXML xml
	select @SecurityGroupListXML = NULL

	declare @NetworkNode bigint
	declare @ConnectionNode bigint
	select	@NetworkNode = [RDF.].fnURI2NodeID('http://profiles.catalyst.harvard.edu/ontology/prns#Network'),
			@ConnectionNode = [RDF.].fnURI2NodeID('http://profiles.catalyst.harvard.edu/ontology/prns#Connection')


	-------------------------------------------------------------------------------
	-- Determine the PresentationType (P = profile, N = network, C = connection)
	-------------------------------------------------------------------------------

	declare @PresentationType char(1)
	select @PresentationType = (case when @objectType is not null AND @predicate is not null AND @subjectType is not null then 'C'
									when @predicate is not null AND @subjectType is not null then 'N'
									when @subjectType is not null then 'P'
									else NULL end)


	-------------------------------------------------------------------------------
	-- Get the PresentationID based on type
	-------------------------------------------------------------------------------

	declare @PresentationID int
	select @PresentationID = (
			select top 1 PresentationID
				from [Ontology.Presentation].[XML]
				where type = IsNull(@PresentationType,'P')
					AND	(_SubjectNode IS NULL
							OR _SubjectNode in (select * from #subjectTypes)
						)
					AND	(_PredicateNode IS NULL
							OR _PredicateNode = @predicate
						)
					AND	(_ObjectNode IS NULL
							OR _ObjectNode in (select * from #objectTypes)
						)
				order by	(case when _ObjectNode is null then 1 else 0 end),
							(case when _PredicateNode is null then 1 else 0 end),
							(case when _SubjectNode is null then 1 else 0 end),
							PresentationID
		)

	-------------------------------------------------------------------------------
	-- Get the PropertyListXML based on type
	-------------------------------------------------------------------------------

	declare @PropertyListXML xml

	-- View properties
	select @PropertyListXML = (
		select PropertyGroupURI "@URI", _PropertyGroupLabel "@Label", SortOrder "@SortOrder", x.query('.')
		from (
			select PropertyGroupURI, _PropertyGroupLabel, SortOrder,
			(
				select	a.URI "@URI", 
						a.TagName "@TagName", 
						a.Label "@Label", 
						p.SortOrder "@SortOrder",
						(case when a.CustomDisplay = 1 then 'true' else 'false' end) "@CustomDisplay",
						cast(a.CustomDisplayModule as xml)
				from [ontology.].PropertyGroupProperty p, (
					select NodeID,
						max(URI) URI, 
						max(TagName) TagName, 
						max(Label) Label,
						max(CustomDisplay) CustomDisplay,
						max(CustomDisplayModule) CustomDisplayModule
					from (
							select
								c._PropertyNode NodeID,
								c.Property URI,
								c._TagName TagName,
								c._PropertyLabel Label,
								cast(c.CustomDisplay as tinyint) CustomDisplay,
								IsNull(cast(c.CustomDisplayModule as nvarchar(max)),cast(p.CustomDisplayModule as nvarchar(max))) CustomDisplayModule
							from [Ontology.].ClassProperty c
								left outer join [Ontology.].PropertyGroupProperty p
								on c.Property = p.PropertyURI
							where c._ClassNode in (
								select * from #subjectTypes where @predicate is null and @objectType is null
								union all
								select @NetworkNode
									where @subjectType is not null and @predicate is not null and @objectType is null
								union all
								select @ConnectionNode
									where @subjectType is not null and @predicate is not null and @objectType is not null
							)
							and 1 = (case	when c._NetworkPropertyNode is null and @predicate is null then 1
											when c._NetworkPropertyNode is null and @predicate is not null and @objectType is null and c._ClassNode = @NetworkNode then 1
											when c._NetworkPropertyNode is null and @predicate is not null and @objectType is not null and c._ClassNode = @ConnectionNode then 1
											when c._NetworkPropertyNode = @predicate and @objectType is not null then 1
											else 0 end)
							and (c.CustomDisplay = 0 OR (c.CustomDisplay = 1 and c.CustomDisplayModule is not null))
						) t
					group by NodeID
				) a
				where p._PropertyNode = a.NodeID and p._PropertyGroupNode = g._PropertyGroupNode
				order by p.SortOrder
				for xml path('Property'), type
			) x
			from [ontology.].PropertyGroup g
		) t
		where x is not null
		order by SortOrder
		for xml path('PropertyGroup'), type
	)

	-------------------------------------------------------------------------------
	-- Combine the PresentationXML with property information
	-------------------------------------------------------------------------------

	select @PresentationXML = (
		select
			PresentationXML.value('Presentation[1]/@PresentationClass[1]','varchar(max)') "@PresentationClass",
			PresentationXML.value('Presentation[1]/PageOptions[1]/@Columns[1]','varchar(max)') "PageOptions/@Columns",
			PresentationXML.query('Presentation[1]/WindowName[1]'),
			PresentationXML.query('Presentation[1]/PageColumns[1]'),
			PresentationXML.query('Presentation[1]/PageTitle[1]'),
			PresentationXML.query('Presentation[1]/PageBackLinkName[1]'),
			PresentationXML.query('Presentation[1]/PageBackLinkURL[1]'),
			PresentationXML.query('Presentation[1]/PageSubTitle[1]'),
			PresentationXML.query('Presentation[1]/PageDescription[1]'),
			PresentationXML.query('Presentation[1]/PanelTabType[1]'),
			PresentationXML.query('Presentation[1]/PanelList[1]'),
			PresentationXML.query('Presentation[1]/ExpandRDFList[1]'),
			@PropertyListXML "PropertyList",
			@SecurityGroupListXML "SecurityGroupList"
		from [Ontology.Presentation].[XML]
		where presentationid = @PresentationID
		for xml path('Presentation'), type
	)
	
	select @PresentationXML PresentationXML

END
GO
PRINT N'Creating [RDF.Security].[CanEditNode]...';


GO
CREATE PROCEDURE [RDF.Security].[CanEditNode] (
	@NodeID	bigint,
	@SessionID UNIQUEIDENTIFIER=NULL
) 
AS
BEGIN
	DECLARE @SecurityGroupID BIGINT, @HasSpecialViewAccess BIT, @HasSpecialEditAccess BIT
	EXEC [RDF.Security].GetSessionSecurityGroup @SessionID, @SecurityGroupID OUTPUT, @HasSpecialViewAccess OUTPUT, @HasSpecialEditAccess OUTPUT
	CREATE TABLE #SecurityGroupNodes (SecurityGroupNode BIGINT PRIMARY KEY)
	INSERT INTO #SecurityGroupNodes (SecurityGroupNode) EXEC [RDF.Security].GetSessionSecurityGroupNodes @SessionID, @NodeID
	DECLARE @CanEdit BIT
	SELECT @CanEdit = 0
	SELECT @CanEdit = 1
		FROM [RDF.].Node
		WHERE NodeID = @NodeID
			AND ( (EditSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (EditSecurityGroup > 0 AND @HasSpecialEditAccess = 1) OR (EditSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)) )

	select @CanEdit as CanEdit
END
GO
PRINT N'Altering [Profile.Data].[Publication.Pubmed.ParsePubMedXML]...';


GO
ALTER procedure [Profile.Data].[Publication.Pubmed.ParsePubMedXML]
	@pmid int
AS
BEGIN
	SET NOCOUNT ON;

	CREATE TABLE #General(
		[PMID] [int] NOT NULL,
		[PMCID] [nvarchar](55) NULL,
		[Owner] [varchar](50) NULL,
		[Status] [varchar](50) NULL,
		[PubModel] [varchar](50) NULL,
		[Volume] [varchar](255) NULL,
		[Issue] [varchar](255) NULL,
		[MedlineDate] [varchar](255) NULL,
		[JournalYear] [varchar](50) NULL,
		[JournalMonth] [varchar](50) NULL,
		[JournalDay] [varchar](50) NULL,
		[JournalTitle] [varchar](1000) NULL,
		[ISOAbbreviation] [varchar](100) NULL,
		[MedlineTA] [varchar](1000) NULL,
		[ArticleTitle] [varchar](4000) NULL,
		[MedlinePgn] [varchar](255) NULL,
		[AbstractText] [text] NULL,
		[ArticleDateType] [varchar](50) NULL,
		[ArticleYear] [varchar](10) NULL,
		[ArticleMonth] [varchar](10) NULL,
		[ArticleDay] [varchar](10) NULL,
		[Affiliation] [varchar](8000) NULL,
		[AuthorListCompleteYN] [varchar](1) NULL,
		[GrantListCompleteYN] [varchar](1) NULL,
		[PubDate] [datetime] NULL,
		[Authors] [varchar](4000) NULL,
		[doi] [varchar](100) NULL,
	PRIMARY KEY CLUSTERED 
	(
		[PMID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]


	CREATE TABLE #Author(
		[PmPubsAuthorID] [int] IDENTITY(1,1) NOT NULL,
		[PMID] [int] NOT NULL,
		[ValidYN] [varchar](1) NULL,
		[LastName] [varchar](100) NULL,
		[FirstName] [varchar](100) NULL,
		[ForeName] [varchar](100) NULL,
		[Suffix] [varchar](20) NULL,
		[Initials] [varchar](20) NULL,
		[Affiliation] [varchar](8000) NULL,
		[CollectiveName] [nvarchar](1000) NULL,
		[ORCID] [varchar](50) NULL,
		[ExistingPmPubsAuthorID] [int] NULL,
		[ValueHash] [varbinary](32) NULL,
		PRIMARY KEY CLUSTERED 
	(
		[PmPubsAuthorID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]


	CREATE TABLE #Mesh(
		[PMID] [int] NOT NULL,
		[DescriptorName] [varchar](255) NOT NULL,
		[QualifierName] [varchar](255) NOT NULL,
		[MajorTopicYN] [char](1) NULL,
	PRIMARY KEY CLUSTERED 
	(
		[PMID] ASC,
		[DescriptorName] ASC,
		[QualifierName] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]


	
	--*** general ***
	insert into #General (pmid, Owner, Status, PubModel, Volume, Issue, MedlineDate, JournalYear, JournalMonth, JournalDay, JournalTitle, ISOAbbreviation, MedlineTA, ArticleTitle, MedlinePgn, AbstractText, ArticleDateType, ArticleYear, ArticleMonth, ArticleDay, Affiliation, AuthorListCompleteYN, GrantListCompleteYN,PMCID, DOI)
		select pmid, 
			nref.value('MedlineCitation[1]/@Owner[1]','varchar(50)') Owner,
			nref.value('MedlineCitation[1]/@Status[1]','varchar(50)') Status,
			nref.value('MedlineCitation[1]/Article[1]/@PubModel','varchar(50)') PubModel,
			nref.value('MedlineCitation[1]/Article[1]/Journal[1]/JournalIssue[1]/Volume[1]','varchar(255)') Volume,
			nref.value('MedlineCitation[1]/Article[1]/Journal[1]/JournalIssue[1]/Issue[1]','varchar(255)') Issue,
			nref.value('MedlineCitation[1]/Article[1]/Journal[1]/JournalIssue[1]/PubDate[1]/MedlineDate[1]','varchar(255)') MedlineDate,
			nref.value('MedlineCitation[1]/Article[1]/Journal[1]/JournalIssue[1]/PubDate[1]/Year[1]','varchar(50)') JournalYear,
			nref.value('MedlineCitation[1]/Article[1]/Journal[1]/JournalIssue[1]/PubDate[1]/Month[1]','varchar(50)') JournalMonth,
			nref.value('MedlineCitation[1]/Article[1]/Journal[1]/JournalIssue[1]/PubDate[1]/Day[1]','varchar(50)') JournalDay,
			nref.value('MedlineCitation[1]/Article[1]/Journal[1]/Title[1]','varchar(1000)') JournalTitle,
			nref.value('MedlineCitation[1]/Article[1]/Journal[1]/ISOAbbreviation[1]','varchar(100)') ISOAbbreviation,
			nref.value('MedlineCitation[1]/MedlineJournalInfo[1]/MedlineTA[1]','varchar(1000)') MedlineTA,
			nref.value('MedlineCitation[1]/Article[1]/ArticleTitle[1]','nvarchar(4000)') ArticleTitle,
			nref.value('MedlineCitation[1]/Article[1]/Pagination[1]/MedlinePgn[1]','varchar(255)') MedlinePgn,
			nref.value('MedlineCitation[1]/Article[1]/Abstract[1]/AbstractText[1]','varchar(max)') AbstractText,
			nref.value('MedlineCitation[1]/Article[1]/ArticleDate[1]/@DateType[1]','varchar(50)') ArticleDateType,
			NULLIF(nref.value('MedlineCitation[1]/Article[1]/ArticleDate[1]/Year[1]','varchar(10)'),'') ArticleYear,
			NULLIF(nref.value('MedlineCitation[1]/Article[1]/ArticleDate[1]/Month[1]','varchar(10)'),'') ArticleMonth,
			NULLIF(nref.value('MedlineCitation[1]/Article[1]/ArticleDate[1]/Day[1]','varchar(10)'),'') ArticleDay,
			Affiliation = COALESCE(nref.value('MedlineCitation[1]/Article[1]/AuthorList[1]/Author[1]/AffiliationInfo[1]/Affiliation[1]','varchar(8000)'),
				nref.value('MedlineCitation[1]/Article[1]/AuthorList[1]/Author[1]/Affiliation[1]','varchar(8000)'),
				nref.value('MedlineCitation[1]/Article[1]/Affiliation[1]','varchar(8000)')) ,
			nref.value('MedlineCitation[1]/Article[1]/AuthorList[1]/@CompleteYN[1]','varchar(1)') AuthorListCompleteYN,
			nref.value('MedlineCitation[1]/Article[1]/GrantList[1]/@CompleteYN[1]','varchar(1)') GrantListCompleteYN,
			--PMCID=COALESCE(nref.value('(OtherID[@Source="NLM" and text()[contains(.,"PMC")]])[1]', 'varchar(55)'), nref.value('(OtherID[@Source="NLM"][1])','varchar(55)'))
			nref.value('PubmedData[1]/ArticleIdList[1]/ArticleId[@IdType="pmc"][1]', 'varchar(100)') pmcid,
			nref.value('PubmedData[1]/ArticleIdList[1]/ArticleId[@IdType="doi"][1]', 'varchar(100)') doi
		from [Profile.Data].[Publication.PubMed.AllXML] cross apply x.nodes('//PubmedArticle[1]') as R(nref)
		where PMID = @pmid

		update #General
		set MedlineDate = (case when right(MedlineDate,4) like '20__' then ltrim(rtrim(right(MedlineDate,4)+' '+left(MedlineDate,len(MedlineDate)-4))) else null end)
		where MedlineDate is not null and MedlineDate not like '[0-9][0-9][0-9][0-9]%'

		
		update #General
		set PubDate = [Profile.Data].[fnPublication.Pubmed.GetPubDate](medlinedate,journalyear,journalmonth,journalday,articleyear,articlemonth,articleday)


	--*** authors ***
	insert into #Author (pmid, ValidYN, LastName, FirstName, ForeName, CollectiveName, Suffix, Initials, ORCID, Affiliation)
		select pmid, 
			nref.value('@ValidYN','varchar(1)') ValidYN, 
			nref.value('LastName[1]','nvarchar(100)') LastName, 
			nref.value('FirstName[1]','nvarchar(100)') FirstName,
			nref.value('ForeName[1]','nvarchar(100)') ForeName,
			nref.value('CollectiveName[1]', 'nvarchar(100)') CollectiveName,
			nref.value('Suffix[1]','nvarchar(20)') Suffix,
			nref.value('Initials[1]','nvarchar(20)') Initials,
			nref.value('Identifier[@Source="ORCID"][1]', 'varchar(50)') ORCID,
			COALESCE(nref.value('AffiliationInfo[1]/Affiliation[1]','varchar(1000)'),
				nref.value('Affiliation[1]','varchar(max)')) Affiliation

		from [Profile.Data].[Publication.PubMed.AllXML] cross apply x.nodes('//AuthorList/Author') as R(nref)
		where PMID = @pmid
		

	
		update #Author set orcid = replace(ORCID, 'http://orcid.org/', '')
		update #Author set orcid = replace(ORCID, 'https://orcid.org/', '')
		update #Author SET ORCID =  SUBSTRING(ORCID, 1, 4) + '-' + SUBSTRING(ORCID, 5, 4) + '-' + SUBSTRING(ORCID, 9, 4) + '-' + SUBSTRING(ORCID, 13, 4) where ORCID is not null and len(ORCID) = 16
		update #Author SET ORCID = LTRIM(RTRIM(ORCID))

		update #Author set valueHash = HASHBYTES('SHA1', cast(pmid as varchar(100)) + '|||' + isnull(LastName, '') + '|||' + isnull(ValidYN, '') + '|||' + isnull(FirstName, '') + '|||' + isnull(ForeName, '') + '|||' + isnull(Suffix, '') + '|||' + isnull(Initials, '') + '|||' + isnull(CollectiveName, '') + '|||' + isnull(ORCID, '') + '|||' + isnull(Affiliation, ''))

	--*** general (authors) ***

	create table #a (pmid int primary key, authors nvarchar(4000))
	insert into #a(pmid,authors)
		select pmid,
			(case	when len(s) < 3990 then s
					when charindex(',',reverse(left(s,3990)))>0 then
						left(s,3990-charindex(',',reverse(left(s,3990))))+', et al'
					else left(s,3990)
					end) authors
		from (
			select pmid, substring(s,3,len(s)) s
			from (
				select pmid, isnull(cast((
					select isnull(', '+lastname+' '+initials, ', '+CollectiveName)
					from #Author q
					where q.pmid = p.pmid
					order by PmPubsAuthorID
					for xml path(''), type
				) as nvarchar(max)),'') s
				from #General p
			) t
		) t

	--[10132 in 00:00:01]
	update g
		set g.authors = isnull(a.authors,'')
		from #General g, #a a
		where g.pmid = a.pmid
	update #General
		set authors = ''
		where authors is null
		
		
		
	--*** mesh ***
	insert into #Mesh (pmid, DescriptorName, QualifierName, MajorTopicYN)
		select pmid, DescriptorName, IsNull(QualifierName,''), max(MajorTopicYN)
		from (
			select pmid, 
				nref.value('@MajorTopicYN[1]','varchar(1)') MajorTopicYN, 
				nref.value('.','varchar(255)') DescriptorName,
				null QualifierName
			from [Profile.Data].[Publication.PubMed.AllXML]
				cross apply x.nodes('//MeshHeadingList/MeshHeading/DescriptorName') as R(nref)
			where PMID = @pmid
			union all
			select pmid, 
				nref.value('@MajorTopicYN[1]','varchar(1)') MajorTopicYN, 
				nref.value('../DescriptorName[1]','varchar(255)') DescriptorName,
				nref.value('.','varchar(255)') QualifierName
			from [Profile.Data].[Publication.PubMed.AllXML]
				cross apply x.nodes('//MeshHeadingList/MeshHeading/QualifierName') as R(nref)
			where PMID = @pmid
		) t where DescriptorName is not null
		group by pmid, DescriptorName, QualifierName

		
	--******************************************************************
	--******************************************************************
	--*** Update General
	--******************************************************************
	--******************************************************************

	update g
		set 
			g.pmid=a.pmid,
			g.pmcid=a.pmcid,
			g.doi = a.doi,
			g.Owner=a.Owner,
			g.Status=a.Status,
			g.PubModel=a.PubModel,
			g.Volume=a.Volume,
			g.Issue=a.Issue,
			g.MedlineDate=a.MedlineDate,
			g.JournalYear=a.JournalYear,
			g.JournalMonth=a.JournalMonth,
			g.JournalDay=a.JournalDay,
			g.JournalTitle=a.JournalTitle,
			g.ISOAbbreviation=a.ISOAbbreviation,
			g.MedlineTA=a.MedlineTA,
			g.ArticleTitle=a.ArticleTitle,
			g.MedlinePgn=a.MedlinePgn,
			g.AbstractText=a.AbstractText,
			g.ArticleDateType=a.ArticleDateType,
			g.ArticleYear=a.ArticleYear,
			g.ArticleMonth=a.ArticleMonth,
			g.ArticleDay=a.ArticleDay,
			g.Affiliation=a.Affiliation,
			g.AuthorListCompleteYN=a.AuthorListCompleteYN,
			g.GrantListCompleteYN=a.GrantListCompleteYN,
			g.PubDate = a.PubDate,
			g.Authors = a.Authors
		from [Profile.Data].[Publication.PubMed.General] (nolock) g
			inner join #General a
				on g.pmid = a.pmid
				
	insert into [Profile.Data].[Publication.PubMed.General] (pmid, pmcid, Owner, Status, PubModel, Volume, Issue, MedlineDate, JournalYear, JournalMonth, JournalDay, JournalTitle, ISOAbbreviation, MedlineTA, ArticleTitle, MedlinePgn, AbstractText, ArticleDateType, ArticleYear, ArticleMonth, ArticleDay, Affiliation, AuthorListCompleteYN, GrantListCompleteYN, PubDate, Authors, doi)
		select pmid, pmcid, Owner, Status, PubModel, Volume, Issue, MedlineDate, JournalYear, JournalMonth, JournalDay, JournalTitle, ISOAbbreviation, MedlineTA, ArticleTitle, MedlinePgn, AbstractText, ArticleDateType, ArticleYear, ArticleMonth, ArticleDay, Affiliation, AuthorListCompleteYN, GrantListCompleteYN, PubDate, Authors, doi
			from #General
			where pmid not in (select pmid from [Profile.Data].[Publication.PubMed.General])
	
	
	--******************************************************************
	--******************************************************************
	--*** Update Authors
	--******************************************************************
	--******************************************************************
	update a set a.ExistingPmPubsAuthorID = b.PmPubsAuthorID 
		from #Author a 
			join [Profile.Data].[Publication.PubMed.Author] b
			on a.ValueHash = b.ValueHash

	select PmPubsAuthorID into #DeletedAuthors from [Profile.Data].[Publication.PubMed.Author] where PMID = @pmid
		and PmPubsAuthorID not in (select ExistingPmPubsAuthorID from #Author)

	delete from [Profile.Data].[Publication.PubMed.Author2Person] where PmPubsAuthorID in (select PmPubsAuthorID from #DeletedAuthors)

	delete from [Profile.Data].[Publication.PubMed.Author] where PmPubsAuthorID in (select PmPubsAuthorID from #DeletedAuthors)
	insert into [Profile.Data].[Publication.PubMed.Author] (pmid, ValidYN, LastName, FirstName, ForeName, CollectiveName, Suffix, Initials, ORCID, Affiliation, ValueHash)
		select pmid, ValidYN, LastName, FirstName, ForeName, CollectiveName, Suffix, Initials, ORCID, Affiliation, ValueHash
		from #Author where ExistingPmPubsAuthorID is null
		order by PmPubsAuthorID

	exec [Profile.Data].[Publication.Pubmed.UpdateAuthor2Person] @pmid = @pmid
	
	--******************************************************************
	--******************************************************************
	--*** Update MeSH
	--******************************************************************
	--******************************************************************


	--*** mesh ***
	delete from [Profile.Data].[Publication.PubMed.Mesh] where pmid = @pmid
	--[16593 in 00:00:11]
	insert into [Profile.Data].[Publication.PubMed.Mesh]
		select * from #Mesh
	--[86375 in 00:00:17]

		
		
		
	--*** investigators ***
	delete from [Profile.Data].[Publication.PubMed.Investigator] where pmid = @pmid
	insert into [Profile.Data].[Publication.PubMed.Investigator] (pmid, LastName, FirstName, ForeName, Suffix, Initials, Affiliation)
		select pmid, 
			nref.value('LastName[1]','varchar(100)') LastName, 
			nref.value('FirstName[1]','varchar(100)') FirstName,
			nref.value('ForeName[1]','varchar(100)') ForeName,
			nref.value('Suffix[1]','varchar(20)') Suffix,
			nref.value('Initials[1]','varchar(20)') Initials,
			COALESCE(nref.value('AffiliationInfo[1]/Affiliation[1]','varchar(1000)'),
				nref.value('Affiliation[1]','varchar(1000)')) Affiliation
		from [Profile.Data].[Publication.PubMed.AllXML] cross apply x.nodes('//InvestigatorList/Investigator') as R(nref)
		where pmid = @pmid
		

	--*** pubtype ***
	delete from [Profile.Data].[Publication.PubMed.PubType] where pmid = @pmid
	insert into [Profile.Data].[Publication.PubMed.PubType] (pmid, PublicationType)
		select * from (
			select distinct pmid, nref.value('.','varchar(100)') PublicationType
			from [Profile.Data].[Publication.PubMed.AllXML]
				cross apply x.nodes('//PublicationTypeList/PublicationType') as R(nref)
			where pmid = @pmid
		) t where PublicationType is not null


	--*** chemicals
	delete from [Profile.Data].[Publication.PubMed.Chemical] where pmid = @pmid
	insert into [Profile.Data].[Publication.PubMed.Chemical] (pmid, NameOfSubstance)
		select * from (
			select distinct pmid, nref.value('.','varchar(255)') NameOfSubstance
			from [Profile.Data].[Publication.PubMed.AllXML]
				cross apply x.nodes('//ChemicalList/Chemical/NameOfSubstance') as R(nref)
			where pmid = @pmid
		) t where NameOfSubstance is not null


	--*** databanks ***
	delete from [Profile.Data].[Publication.PubMed.Databank] where pmid = @pmid
	insert into [Profile.Data].[Publication.PubMed.Databank] (pmid, DataBankName)
		select * from (
			select distinct pmid, 
				nref.value('.','varchar(100)') DataBankName
			from [Profile.Data].[Publication.PubMed.AllXML]
				cross apply x.nodes('//DataBankList/DataBank/DataBankName') as R(nref)
			where pmid = @pmid
		) t where DataBankName is not null


	--*** accessions ***
	delete from [Profile.Data].[Publication.PubMed.Accession] where pmid = @pmid
	insert into [Profile.Data].[Publication.PubMed.Accession] (pmid, DataBankName, AccessionNumber)
		select * from (
			select distinct pmid, 
				nref.value('../../DataBankName[1]','varchar(100)') DataBankName,
				nref.value('.','varchar(50)') AccessionNumber
			from [Profile.Data].[Publication.PubMed.AllXML]
				cross apply x.nodes('//DataBankList/DataBank/AccessionNumberList/AccessionNumber') as R(nref)
			where pmid = @pmid
		) t where DataBankName is not null and AccessionNumber is not null


	--*** keywords ***
	delete from [Profile.Data].[Publication.PubMed.Keyword] where pmid = @pmid
	insert into [Profile.Data].[Publication.PubMed.Keyword] (pmid, Keyword, MajorTopicYN)
		select pmid, Keyword, max(MajorTopicYN)
		from (
			select pmid, 
				nref.value('.','varchar(895)') Keyword,
				nref.value('@MajorTopicYN','varchar(1)') MajorTopicYN
			from [Profile.Data].[Publication.PubMed.AllXML]
				cross apply x.nodes('//KeywordList/Keyword') as R(nref)
			where pmid = @pmid
		) t where Keyword is not null
		group by pmid, Keyword


	--*** grants ***
	delete from [Profile.Data].[Publication.PubMed.Grant] where pmid = @pmid
	insert into [Profile.Data].[Publication.PubMed.Grant] (pmid, GrantID, Acronym, Agency)
		select pmid, GrantID, max(Acronym), max(Agency)
		from (
			select pmid, 
				nref.value('GrantID[1]','varchar(100)') GrantID, 
				nref.value('Acronym[1]','varchar(50)') Acronym,
				nref.value('Agency[1]','varchar(1000)') Agency
			from [Profile.Data].[Publication.PubMed.AllXML]
				cross apply x.nodes('//GrantList/Grant') as R(nref)
			where pmid = @pmid
		) t where GrantID is not null
		group by pmid, GrantID


	--******************************************************************
	--******************************************************************
	--*** Update parse date
	--******************************************************************
	--******************************************************************

	update [Profile.Data].[Publication.PubMed.AllXML] set ParseDT = GetDate() where pmid = @pmid
END
GO
PRINT N'Altering [Profile.Data].[Publication.Pubmed.ParseALLPubMedXML]...';


GO
ALTER procedure [Profile.Data].[Publication.Pubmed.ParseALLPubMedXML]
AS
BEGIN
	SET NOCOUNT ON;

	--*** general ***
	truncate table [Profile.Data].[Publication.PubMed.General.Stage]
	insert into [Profile.Data].[Publication.PubMed.General.Stage] (pmid, Owner, Status, PubModel, Volume, Issue, MedlineDate, JournalYear, JournalMonth, JournalDay, JournalTitle, ISOAbbreviation, MedlineTA, ArticleTitle, MedlinePgn, AbstractText, ArticleDateType, ArticleYear, ArticleMonth, ArticleDay, Affiliation, AuthorListCompleteYN, GrantListCompleteYN,PMCID, DOI)
		select pmid, 
			nref.value('MedlineCitation[1]/@Owner[1]','varchar(50)') Owner,
			nref.value('MedlineCitation[1]/@Status[1]','varchar(50)') Status,
			nref.value('MedlineCitation[1]/Article[1]/@PubModel','varchar(50)') PubModel,
			nref.value('MedlineCitation[1]/Article[1]/Journal[1]/JournalIssue[1]/Volume[1]','varchar(255)') Volume,
			nref.value('MedlineCitation[1]/Article[1]/Journal[1]/JournalIssue[1]/Issue[1]','varchar(255)') Issue,
			nref.value('MedlineCitation[1]/Article[1]/Journal[1]/JournalIssue[1]/PubDate[1]/MedlineDate[1]','varchar(255)') MedlineDate,
			nref.value('MedlineCitation[1]/Article[1]/Journal[1]/JournalIssue[1]/PubDate[1]/Year[1]','varchar(50)') JournalYear,
			nref.value('MedlineCitation[1]/Article[1]/Journal[1]/JournalIssue[1]/PubDate[1]/Month[1]','varchar(50)') JournalMonth,
			nref.value('MedlineCitation[1]/Article[1]/Journal[1]/JournalIssue[1]/PubDate[1]/Day[1]','varchar(50)') JournalDay,
			nref.value('MedlineCitation[1]/Article[1]/Journal[1]/Title[1]','varchar(1000)') JournalTitle,
			nref.value('MedlineCitation[1]/Article[1]/Journal[1]/ISOAbbreviation[1]','varchar(100)') ISOAbbreviation,
			nref.value('MedlineCitation[1]/MedlineJournalInfo[1]/MedlineTA[1]','varchar(1000)') MedlineTA,
			nref.value('MedlineCitation[1]/Article[1]/ArticleTitle[1]','nvarchar(4000)') ArticleTitle,
			nref.value('MedlineCitation[1]/Article[1]/Pagination[1]/MedlinePgn[1]','varchar(255)') MedlinePgn,
			nref.value('MedlineCitation[1]/Article[1]/Abstract[1]/AbstractText[1]','varchar(max)') AbstractText,
			nref.value('MedlineCitation[1]/Article[1]/ArticleDate[1]/@DateType[1]','varchar(50)') ArticleDateType,
			NULLIF(nref.value('MedlineCitation[1]/Article[1]/ArticleDate[1]/Year[1]','varchar(10)'),'') ArticleYear,
			NULLIF(nref.value('MedlineCitation[1]/Article[1]/ArticleDate[1]/Month[1]','varchar(10)'),'') ArticleMonth,
			NULLIF(nref.value('MedlineCitation[1]/Article[1]/ArticleDate[1]/Day[1]','varchar(10)'),'') ArticleDay,
			Affiliation = COALESCE(nref.value('MedlineCitation[1]/Article[1]/AuthorList[1]/Author[1]/AffiliationInfo[1]/Affiliation[1]','varchar(8000)'),
				nref.value('MedlineCitation[1]/Article[1]/AuthorList[1]/Author[1]/Affiliation[1]','varchar(8000)'),
				nref.value('MedlineCitation[1]/Article[1]/Affiliation[1]','varchar(8000)')) ,
			nref.value('MedlineCitation[1]/Article[1]/AuthorList[1]/@CompleteYN[1]','varchar(1)') AuthorListCompleteYN,
			nref.value('MedlineCitation[1]/Article[1]/GrantList[1]/@CompleteYN[1]','varchar(1)') GrantListCompleteYN,
			--PMCID=COALESCE(nref.value('(OtherID[@Source="NLM" and text()[contains(.,"PMC")]])[1]', 'varchar(55)'), nref.value('(OtherID[@Source="NLM"][1])','varchar(55)'))
			nref.value('PubmedData[1]/ArticleIdList[1]/ArticleId[@IdType="pmc"][1]', 'varchar(100)') pmcid,
			nref.value('PubmedData[1]/ArticleIdList[1]/ArticleId[@IdType="doi"][1]', 'varchar(100)') doi
		from [Profile.Data].[Publication.PubMed.AllXML] cross apply x.nodes('//PubmedArticle[1]') as R(nref)
		where ParseDT is null and x is not null

		update [Profile.Data].[Publication.PubMed.General.Stage]
		set MedlineDate = (case when right(MedlineDate,4) like '20__' then ltrim(rtrim(right(MedlineDate,4)+' '+left(MedlineDate,len(MedlineDate)-4))) else null end)
		where MedlineDate is not null and MedlineDate not like '[0-9][0-9][0-9][0-9]%'

		
		update [Profile.Data].[Publication.PubMed.General.Stage]
		set PubDate = [Profile.Data].[fnPublication.Pubmed.GetPubDate](medlinedate,journalyear,journalmonth,journalday,articleyear,articlemonth,articleday)


	--*** authors ***
	truncate table [Profile.Data].[Publication.PubMed.Author.Stage]
	insert into [Profile.Data].[Publication.PubMed.Author.Stage] (pmid, ValidYN, LastName, FirstName, ForeName, CollectiveName, Suffix, Initials, ORCID, Affiliation)
		select pmid, 
			nref.value('@ValidYN','varchar(1)') ValidYN, 
			nref.value('LastName[1]','nvarchar(100)') LastName, 
			nref.value('FirstName[1]','nvarchar(100)') FirstName,
			nref.value('ForeName[1]','nvarchar(100)') ForeName,
			nref.value('CollectiveName[1]', 'nvarchar(100)') CollectiveName,
			nref.value('Suffix[1]','nvarchar(20)') Suffix,
			nref.value('Initials[1]','nvarchar(20)') Initials,
			nref.value('Identifier[@Source="ORCID"][1]', 'varchar(50)') ORCID,
			COALESCE(nref.value('AffiliationInfo[1]/Affiliation[1]','varchar(1000)'),
				nref.value('Affiliation[1]','varchar(max)')) Affiliation

		from [Profile.Data].[Publication.PubMed.AllXML] cross apply x.nodes('//AuthorList/Author') as R(nref)
		where pmid in (select pmid from [Profile.Data].[Publication.PubMed.General.Stage])
		

	
		update [Profile.Data].[Publication.PubMed.Author.Stage] set orcid = replace(ORCID, 'http://orcid.org/', '')
		update [Profile.Data].[Publication.PubMed.Author.Stage] set orcid = replace(ORCID, 'https://orcid.org/', '')
		update [Profile.Data].[Publication.PubMed.Author.Stage] SET ORCID =  SUBSTRING(ORCID, 1, 4) + '-' + SUBSTRING(ORCID, 5, 4) + '-' + SUBSTRING(ORCID, 9, 4) + '-' + SUBSTRING(ORCID, 13, 4) where ORCID is not null and len(ORCID) = 16
		update [Profile.Data].[Publication.PubMed.Author.Stage] SET ORCID = LTRIM(RTRIM(ORCID))

		update [Profile.Data].[Publication.PubMed.Author.Stage] set valueHash = HASHBYTES('SHA1', cast(pmid as varchar(100)) + '|||' + isnull(LastName, '') + '|||' + isnull(ValidYN, '') + '|||' + isnull(FirstName, '') + '|||' + isnull(ForeName, '') + '|||' + isnull(Suffix, '') + '|||' + isnull(Initials, '') + '|||' + isnull(CollectiveName, '') + '|||' + isnull(ORCID, '') + '|||' + isnull(Affiliation, ''))

	--*** general (authors) ***

	create table #a (pmid int primary key, authors nvarchar(4000))
	insert into #a(pmid,authors)
		select pmid,
			(case	when len(s) < 3990 then s
					when charindex(',',reverse(left(s,3990)))>0 then
						left(s,3990-charindex(',',reverse(left(s,3990))))+', et al'
					else left(s,3990)
					end) authors
		from (
			select pmid, substring(s,3,len(s)) s
			from (
				select pmid, isnull(cast((
					select isnull(', '+lastname+' '+initials, ', '+CollectiveName)
					from [Profile.Data].[Publication.PubMed.Author.Stage] q
					where q.pmid = p.pmid
					order by PmPubsAuthorID
					for xml path(''), type
				) as nvarchar(max)),'') s
				from [Profile.Data].[Publication.PubMed.General.Stage] p
			) t
		) t

	--[10132 in 00:00:01]
	update g
		set g.authors = isnull(a.authors,'')
		from [Profile.Data].[Publication.PubMed.General.Stage] g, #a a
		where g.pmid = a.pmid
	update [Profile.Data].[Publication.PubMed.General.Stage]
		set authors = ''
		where authors is null
		
		
		
	--*** mesh ***
	truncate table [Profile.Data].[Publication.PubMed.Mesh.Stage]
	insert into [Profile.Data].[Publication.PubMed.Mesh.Stage] (pmid, DescriptorName, QualifierName, MajorTopicYN)
		select pmid, DescriptorName, IsNull(QualifierName,''), max(MajorTopicYN)
		from (
			select pmid, 
				nref.value('@MajorTopicYN[1]','varchar(1)') MajorTopicYN, 
				nref.value('.','varchar(255)') DescriptorName,
				null QualifierName
			from [Profile.Data].[Publication.PubMed.AllXML]
				cross apply x.nodes('//MeshHeadingList/MeshHeading/DescriptorName') as R(nref)
			where pmid in (select pmid from [Profile.Data].[Publication.PubMed.General.Stage])
			union all
			select pmid, 
				nref.value('@MajorTopicYN[1]','varchar(1)') MajorTopicYN, 
				nref.value('../DescriptorName[1]','varchar(255)') DescriptorName,
				nref.value('.','varchar(255)') QualifierName
			from [Profile.Data].[Publication.PubMed.AllXML]
				cross apply x.nodes('//MeshHeadingList/MeshHeading/QualifierName') as R(nref)
			where pmid in (select pmid from [Profile.Data].[Publication.PubMed.General.Stage])
		) t where DescriptorName is not null
		group by pmid, DescriptorName, QualifierName

		
	--******************************************************************
	--******************************************************************
	--*** Update General
	--******************************************************************
	--******************************************************************

	update g
		set 
			g.pmid=a.pmid,
			g.pmcid=a.pmcid,
			g.doi = a.doi,
			g.Owner=a.Owner,
			g.Status=a.Status,
			g.PubModel=a.PubModel,
			g.Volume=a.Volume,
			g.Issue=a.Issue,
			g.MedlineDate=a.MedlineDate,
			g.JournalYear=a.JournalYear,
			g.JournalMonth=a.JournalMonth,
			g.JournalDay=a.JournalDay,
			g.JournalTitle=a.JournalTitle,
			g.ISOAbbreviation=a.ISOAbbreviation,
			g.MedlineTA=a.MedlineTA,
			g.ArticleTitle=a.ArticleTitle,
			g.MedlinePgn=a.MedlinePgn,
			g.AbstractText=a.AbstractText,
			g.ArticleDateType=a.ArticleDateType,
			g.ArticleYear=a.ArticleYear,
			g.ArticleMonth=a.ArticleMonth,
			g.ArticleDay=a.ArticleDay,
			g.Affiliation=a.Affiliation,
			g.AuthorListCompleteYN=a.AuthorListCompleteYN,
			g.GrantListCompleteYN=a.GrantListCompleteYN,
			g.PubDate = a.PubDate,
			g.Authors = a.Authors
		from [Profile.Data].[Publication.PubMed.General] (nolock) g
			inner join [Profile.Data].[Publication.PubMed.General.Stage] a
				on g.pmid = a.pmid
				
	insert into [Profile.Data].[Publication.PubMed.General] (pmid, pmcid, Owner, Status, PubModel, Volume, Issue, MedlineDate, JournalYear, JournalMonth, JournalDay, JournalTitle, ISOAbbreviation, MedlineTA, ArticleTitle, MedlinePgn, AbstractText, ArticleDateType, ArticleYear, ArticleMonth, ArticleDay, Affiliation, AuthorListCompleteYN, GrantListCompleteYN, PubDate, Authors, doi)
		select pmid, pmcid, Owner, Status, PubModel, Volume, Issue, MedlineDate, JournalYear, JournalMonth, JournalDay, JournalTitle, ISOAbbreviation, MedlineTA, ArticleTitle, MedlinePgn, AbstractText, ArticleDateType, ArticleYear, ArticleMonth, ArticleDay, Affiliation, AuthorListCompleteYN, GrantListCompleteYN, PubDate, Authors, doi
			from [Profile.Data].[Publication.PubMed.General.Stage]
			where pmid not in (select pmid from [Profile.Data].[Publication.PubMed.General])
	
	
	--******************************************************************
	--******************************************************************
	--*** Update Authors
	--******************************************************************
	--******************************************************************
	update a set a.ExistingPmPubsAuthorID = b.PmPubsAuthorID 
		from [Profile.Data].[Publication.PubMed.Author.Stage] a 
			join [Profile.Data].[Publication.PubMed.Author] b
			on a.ValueHash = b.ValueHash

	select PmPubsAuthorID into #DeletedAuthors from [Profile.Data].[Publication.PubMed.Author] where PMID in (select PMID from [Profile.Data].[Publication.PubMed.General.Stage])
		and PmPubsAuthorID not in (select ExistingPmPubsAuthorID from [Profile.Data].[Publication.PubMed.Author.Stage])

	delete from [Profile.Data].[Publication.PubMed.Author2Person] where PmPubsAuthorID in (select PmPubsAuthorID from #DeletedAuthors)

	delete from [Profile.Data].[Publication.PubMed.Author] where PmPubsAuthorID in (select PmPubsAuthorID from #DeletedAuthors)
	insert into [Profile.Data].[Publication.PubMed.Author] (pmid, ValidYN, LastName, FirstName, ForeName, CollectiveName, Suffix, Initials, ORCID, Affiliation, ValueHash)
		select pmid, ValidYN, LastName, FirstName, ForeName, CollectiveName, Suffix, Initials, ORCID, Affiliation, ValueHash
		from [Profile.Data].[Publication.PubMed.Author.Stage] where ExistingPmPubsAuthorID is null
		order by PmPubsAuthorID

	exec [Profile.Data].[Publication.Pubmed.UpdateAuthor2Person] @UseStagePMIDs = 1

	--******************************************************************
	--******************************************************************
	--*** Update MeSH
	--******************************************************************
	--******************************************************************


	--*** mesh ***
	delete from [Profile.Data].[Publication.PubMed.Mesh] where pmid in (select pmid from [Profile.Data].[Publication.PubMed.General.Stage])
	--[16593 in 00:00:11]
	insert into [Profile.Data].[Publication.PubMed.Mesh]
		select * from [Profile.Data].[Publication.PubMed.Mesh.Stage]
	--[86375 in 00:00:17]

		
		
		
	--*** investigators ***
	delete from [Profile.Data].[Publication.PubMed.Investigator] where pmid in (select pmid from [Profile.Data].[Publication.PubMed.General.Stage])
	insert into [Profile.Data].[Publication.PubMed.Investigator] (pmid, LastName, FirstName, ForeName, Suffix, Initials, Affiliation)
		select pmid, 
			nref.value('LastName[1]','varchar(100)') LastName, 
			nref.value('FirstName[1]','varchar(100)') FirstName,
			nref.value('ForeName[1]','varchar(100)') ForeName,
			nref.value('Suffix[1]','varchar(20)') Suffix,
			nref.value('Initials[1]','varchar(20)') Initials,
			COALESCE(nref.value('AffiliationInfo[1]/Affiliation[1]','varchar(1000)'),
				nref.value('Affiliation[1]','varchar(1000)')) Affiliation
		from [Profile.Data].[Publication.PubMed.AllXML] cross apply x.nodes('//InvestigatorList/Investigator') as R(nref)
		where pmid in (select pmid from [Profile.Data].[Publication.PubMed.General.Stage])
		

	--*** pubtype ***
	delete from [Profile.Data].[Publication.PubMed.PubType] where pmid in (select pmid from [Profile.Data].[Publication.PubMed.General.Stage])
	insert into [Profile.Data].[Publication.PubMed.PubType] (pmid, PublicationType)
		select * from (
			select distinct pmid, nref.value('.','varchar(100)') PublicationType
			from [Profile.Data].[Publication.PubMed.AllXML]
				cross apply x.nodes('//PublicationTypeList/PublicationType') as R(nref)
			where pmid in (select pmid from [Profile.Data].[Publication.PubMed.General.Stage])
		) t where PublicationType is not null


	--*** chemicals
	delete from [Profile.Data].[Publication.PubMed.Chemical] where pmid in (select pmid from [Profile.Data].[Publication.PubMed.General.Stage])
	insert into [Profile.Data].[Publication.PubMed.Chemical] (pmid, NameOfSubstance)
		select * from (
			select distinct pmid, nref.value('.','varchar(255)') NameOfSubstance
			from [Profile.Data].[Publication.PubMed.AllXML]
				cross apply x.nodes('//ChemicalList/Chemical/NameOfSubstance') as R(nref)
			where pmid in (select pmid from [Profile.Data].[Publication.PubMed.General.Stage])
		) t where NameOfSubstance is not null


	--*** databanks ***
	delete from [Profile.Data].[Publication.PubMed.Databank] where pmid in (select pmid from [Profile.Data].[Publication.PubMed.General.Stage])
	insert into [Profile.Data].[Publication.PubMed.Databank] (pmid, DataBankName)
		select * from (
			select distinct pmid, 
				nref.value('.','varchar(100)') DataBankName
			from [Profile.Data].[Publication.PubMed.AllXML]
				cross apply x.nodes('//DataBankList/DataBank/DataBankName') as R(nref)
			where pmid in (select pmid from [Profile.Data].[Publication.PubMed.General.Stage])
		) t where DataBankName is not null


	--*** accessions ***
	delete from [Profile.Data].[Publication.PubMed.Accession] where pmid in (select pmid from [Profile.Data].[Publication.PubMed.General.Stage])
	insert into [Profile.Data].[Publication.PubMed.Accession] (pmid, DataBankName, AccessionNumber)
		select * from (
			select distinct pmid, 
				nref.value('../../DataBankName[1]','varchar(100)') DataBankName,
				nref.value('.','varchar(50)') AccessionNumber
			from [Profile.Data].[Publication.PubMed.AllXML]
				cross apply x.nodes('//DataBankList/DataBank/AccessionNumberList/AccessionNumber') as R(nref)
			where pmid in (select pmid from [Profile.Data].[Publication.PubMed.General.Stage])
		) t where DataBankName is not null and AccessionNumber is not null


	--*** keywords ***
	delete from [Profile.Data].[Publication.PubMed.Keyword] where pmid in (select pmid from [Profile.Data].[Publication.PubMed.General.Stage])
	insert into [Profile.Data].[Publication.PubMed.Keyword] (pmid, Keyword, MajorTopicYN)
		select pmid, Keyword, max(MajorTopicYN)
		from (
			select pmid, 
				nref.value('.','varchar(895)') Keyword,
				nref.value('@MajorTopicYN','varchar(1)') MajorTopicYN
			from [Profile.Data].[Publication.PubMed.AllXML]
				cross apply x.nodes('//KeywordList/Keyword') as R(nref)
			where pmid in (select pmid from [Profile.Data].[Publication.PubMed.General.Stage])
		) t where Keyword is not null
		group by pmid, Keyword


	--*** grants ***
	delete from [Profile.Data].[Publication.PubMed.Grant] where pmid in (select pmid from [Profile.Data].[Publication.PubMed.General.Stage])
	insert into [Profile.Data].[Publication.PubMed.Grant] (pmid, GrantID, Acronym, Agency)
		select pmid, GrantID, max(Acronym), max(Agency)
		from (
			select pmid, 
				nref.value('GrantID[1]','varchar(100)') GrantID, 
				nref.value('Acronym[1]','varchar(50)') Acronym,
				nref.value('Agency[1]','varchar(1000)') Agency
			from [Profile.Data].[Publication.PubMed.AllXML]
				cross apply x.nodes('//GrantList/Grant') as R(nref)
			where pmid in (select pmid from [Profile.Data].[Publication.PubMed.General.Stage])
		) t where GrantID is not null
		group by pmid, GrantID


	--******************************************************************
	--******************************************************************
	--*** Update parse date
	--******************************************************************
	--******************************************************************

	update [Profile.Data].[Publication.PubMed.AllXML] set ParseDT = GetDate() where pmid in (select pmid from [Profile.Data].[Publication.PubMed.General.Stage])
END
GO
PRINT N'Creating [Profile.Data].[Publication.Pubmed.AddPubmedBookArticle]...';


GO
CREATE procedure [Profile.Data].[Publication.Pubmed.AddPubmedBookArticle]
	@pmid int,
	@personID int
AS
BEGIN
	DECLARE @ErrMsg nvarchar(4000), @ErrSeverity int,@proc VARCHAR(200),@date DATETIME,@auditid UNIQUEIDENTIFIER 
	SELECT @proc = OBJECT_NAME(@@PROCID),@date=GETDATE() 	

	declare @mpid varchar(50)
	if exists (select 1 from [Profile.Data].[Publication.MyPub.General] where pmid=@pmid)
	begin
		select @mpid = mpid from [Profile.Data].[Publication.MyPub.General] where pmid=@pmid
	end
	else
	begin
		SET @mpid = cast(NewID() as nvarchar(50))
		exec [Profile.Data].[Publication.Pubmed.ParsePubmedBookArticle] @pmid=@pmid, @mpid=@mpid
	end

	DECLARE @pubid nvarchar(50)
	SET @pubid = cast(NewID() as nvarchar(50))


	BEGIN TRY
	BEGIN TRANSACTION
		INSERT INTO [Profile.Data].[Publication.Person.Include]
				( PubID, PersonID,   MPID )
	 
			VALUES (@pubid, @PersonID, @mpid)

		INSERT INTO [Profile.Data].[Publication.Person.Add]
				( PubID, PersonID,   MPID )
			VALUES (@pubid, @PersonID, @mpid)
	COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		--Check success
		IF @@TRANCOUNT > 0  ROLLBACK
		SELECT @date=GETDATE()
		EXEC [Profile.Cache].[Process.AddAuditUpdate] @auditid=@auditid OUTPUT,@ProcessName =@proc,@ProcessEndDate=@date,@error = 1,@insert_new_record=1
		--Raise an error with the details of the exception
		SELECT @ErrMsg = ERROR_MESSAGE(), @ErrSeverity = ERROR_SEVERITY()
		RAISERROR(@ErrMsg, @ErrSeverity, 1)
	END CATCH


END
GO
PRINT N'Refreshing [Profile.Data].[fnPublication.Person.GetPublications]...';


GO
EXECUTE sp_refreshsqlmodule N'[Profile.Data].[fnPublication.Person.GetPublications]';


GO
PRINT N'Refreshing [ORCID.].[AuthorInAuthorshipForORCID.GetList]...';


GO
EXECUTE sp_refreshsqlmodule N'[ORCID.].[AuthorInAuthorshipForORCID.GetList]';


GO
PRINT N'Refreshing [Profile.Module].[CustomViewAuthorInAuthorship.GetJournalHeadings]...';


GO
EXECUTE sp_refreshsqlmodule N'[Profile.Module].[CustomViewAuthorInAuthorship.GetJournalHeadings]';


GO
PRINT N'Refreshing [Profile.Data].[Publication.Pubmed.LoadDisambiguationResults]...';


GO
EXECUTE sp_refreshsqlmodule N'[Profile.Data].[Publication.Pubmed.LoadDisambiguationResults]';


GO
PRINT N'Refreshing [Edit.Module].[CustomEditAssociatedInformationResource.GetList]...';


GO
EXECUTE sp_refreshsqlmodule N'[Edit.Module].[CustomEditAssociatedInformationResource.GetList]';


GO
PRINT N'Refreshing [Edit.Module].[CustomEditAuthorInAuthorship.GetList]...';


GO
EXECUTE sp_refreshsqlmodule N'[Edit.Module].[CustomEditAuthorInAuthorship.GetList]';


GO
PRINT N'Refreshing [Profile.Cache].[Concept.Mesh.UpdateJournal]...';


GO
EXECUTE sp_refreshsqlmodule N'[Profile.Cache].[Concept.Mesh.UpdateJournal]';


GO
PRINT N'Refreshing [Profile.Data].[Publication.GetGroupMemberPublications]...';


GO
EXECUTE sp_refreshsqlmodule N'[Profile.Data].[Publication.GetGroupMemberPublications]';


GO
PRINT N'Refreshing [Profile.Data].[Group.Member.AddUpdateMember]...';


GO
EXECUTE sp_refreshsqlmodule N'[Profile.Data].[Group.Member.AddUpdateMember]';


GO
PRINT N'Refreshing [Profile.Data].[Group.Member.DeleteMember]...';


GO
EXECUTE sp_refreshsqlmodule N'[Profile.Data].[Group.Member.DeleteMember]';


GO
PRINT N'Refreshing [Profile.Data].[Publication.SetGroupOption]...';


GO
EXECUTE sp_refreshsqlmodule N'[Profile.Data].[Publication.SetGroupOption]';


GO
PRINT N'Refreshing [Profile.Cache].[Publication.PubMed.UpdateAuthorPosition]...';


GO
EXECUTE sp_refreshsqlmodule N'[Profile.Cache].[Publication.PubMed.UpdateAuthorPosition]';


GO
PRINT N'Refreshing [Profile.Data].[Publication.Pubmed.AddOneAuthorPosition]...';


GO
EXECUTE sp_refreshsqlmodule N'[Profile.Data].[Publication.Pubmed.AddOneAuthorPosition]';


GO
PRINT N'Refreshing [Profile.Data].[Publication.GetPersonPublications3]...';


GO
EXECUTE sp_refreshsqlmodule N'[Profile.Data].[Publication.GetPersonPublications3]';


GO
PRINT N'Refreshing [Profile.Data].[Publication.GetPersonPublications2]...';


GO
EXECUTE sp_refreshsqlmodule N'[Profile.Data].[Publication.GetPersonPublications2]';


GO
PRINT N'Refreshing [Profile.Data].[Concept.Mesh.GetPublications]...';


GO
EXECUTE sp_refreshsqlmodule N'[Profile.Data].[Concept.Mesh.GetPublications]';


GO
PRINT N'Refreshing [Profile.Module].[ConnectionDetails.Person.HasResearchArea.GetData]...';


GO
EXECUTE sp_refreshsqlmodule N'[Profile.Module].[ConnectionDetails.Person.HasResearchArea.GetData]';


GO
PRINT N'Refreshing [Profile.Module].[ConnectionDetails.Person.CoAuthorOf.GetData]...';


GO
EXECUTE sp_refreshsqlmodule N'[Profile.Module].[ConnectionDetails.Person.CoAuthorOf.GetData]';


GO
PRINT N'Refreshing [Profile.Data].[Publication.PubMed.GetAllPMIDs]...';


GO
EXECUTE sp_refreshsqlmodule N'[Profile.Data].[Publication.PubMed.GetAllPMIDs]';


GO
PRINT N'Refreshing [Profile.Module].[NetworkTimeline.Person.CoAuthorOf.GetData]...';


GO
EXECUTE sp_refreshsqlmodule N'[Profile.Module].[NetworkTimeline.Person.CoAuthorOf.GetData]';


GO
PRINT N'Refreshing [Profile.Module].[NetworkTimeline.Person.HasResearchArea.GetData]...';


GO
EXECUTE sp_refreshsqlmodule N'[Profile.Module].[NetworkTimeline.Person.HasResearchArea.GetData]';


GO
PRINT N'Refreshing [Profile.Data].[Publication.GetPersonPublications]...';


GO
EXECUTE sp_refreshsqlmodule N'[Profile.Data].[Publication.GetPersonPublications]';


GO
PRINT N'Refreshing [Search.Cache].[Public.GetConnection]...';


GO
EXECUTE sp_refreshsqlmodule N'[Search.Cache].[Public.GetConnection]';


GO
PRINT N'Refreshing [Search.Cache].[Private.GetConnection]...';


GO
EXECUTE sp_refreshsqlmodule N'[Search.Cache].[Private.GetConnection]';


GO
PRINT N'Refreshing [Search.].[GetConnection]...';


GO
EXECUTE sp_refreshsqlmodule N'[Search.].[GetConnection]';


GO
PRINT N'Refreshing [Profile.Data].[Publication.Group.Pubmed.AddPublication]...';


GO
EXECUTE sp_refreshsqlmodule N'[Profile.Data].[Publication.Group.Pubmed.AddPublication]';


GO
PRINT N'Refreshing [Profile.Data].[Publication.Pubmed.AddPublication]...';


GO
EXECUTE sp_refreshsqlmodule N'[Profile.Data].[Publication.Pubmed.AddPublication]';


GO
PRINT N'Checking existing data against newly created constraints';


GO
ALTER TABLE [Profile.Data].[Publication.PubMed.Author] WITH CHECK CHECK CONSTRAINT [FK_pm_pubs_authors_pm_pubs_general];

ALTER TABLE [Profile.Data].[Publication.PubMed.PubType] WITH CHECK CHECK CONSTRAINT [FK_pm_pubs_pubtypes_pm_pubs_general];

ALTER TABLE [Profile.Data].[Publication.PubMed.Keyword] WITH CHECK CHECK CONSTRAINT [FK_pm_pubs_keywords_pm_pubs_general];

ALTER TABLE [Profile.Data].[Publication.PubMed.Accession] WITH CHECK CHECK CONSTRAINT [FK_pm_pubs_accessions_pm_pubs_general];

ALTER TABLE [Profile.Data].[Publication.PubMed.Databank] WITH CHECK CHECK CONSTRAINT [FK_pm_pubs_databanks_pm_pubs_general];

ALTER TABLE [Profile.Data].[Publication.PubMed.Chemical] WITH CHECK CHECK CONSTRAINT [FK_pm_pubs_chemicals_pm_pubs_general];

ALTER TABLE [Profile.Data].[Publication.PubMed.Mesh] WITH CHECK CHECK CONSTRAINT [FK_pm_pubs_mesh_pm_pubs_general];

ALTER TABLE [Profile.Data].[Publication.PubMed.Investigator] WITH CHECK CHECK CONSTRAINT [FK_pm_pubs_investigators_pm_pubs_general];

ALTER TABLE [Profile.Data].[Publication.PubMed.Grant] WITH CHECK CHECK CONSTRAINT [FK_pm_pubs_grants_pm_pubs_general];

ALTER TABLE [Profile.Data].[Publication.Person.Include] WITH CHECK CHECK CONSTRAINT [FK_publications_include_pm_pubs_general];


GO
PRINT N'Update complete.';


GO

