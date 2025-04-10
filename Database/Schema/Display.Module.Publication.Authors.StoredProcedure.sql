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
