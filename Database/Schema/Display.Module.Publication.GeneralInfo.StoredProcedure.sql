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
