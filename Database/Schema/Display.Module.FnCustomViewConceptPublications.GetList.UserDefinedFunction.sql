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
