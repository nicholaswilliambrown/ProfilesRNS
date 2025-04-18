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
