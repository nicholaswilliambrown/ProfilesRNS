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
