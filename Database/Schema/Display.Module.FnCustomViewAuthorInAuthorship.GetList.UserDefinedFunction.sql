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
