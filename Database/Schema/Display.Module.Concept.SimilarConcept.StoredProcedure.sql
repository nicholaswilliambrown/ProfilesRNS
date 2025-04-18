SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [Display.Module].[Concept.SimilarConcept]
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @DescriptorName NVARCHAR(255)
 	SELECT @DescriptorName = d.DescriptorName
		FROM [RDF.Stage].[InternalNodeMap] m, [RDF.].Node n,
			[Profile.Data].[Concept.Mesh.Descriptor] d
		WHERE m.Status = 3 AND m.ValueHash = n.ValueHash AND n.NodeID = @Subject
			AND m.InternalID = d.DescriptorUI

	declare @relativeBasePath varchar(55)
	select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'

	;with a as (
		select SimilarConcept DescriptorName, Weight, SortOrder
		from [Profile.Cache].[Concept.Mesh.SimilarConcept]
		where meshheader = @DescriptorName
	), b as (
		select top 10 DescriptorName, Weight, (select count(*) from a) TotalRecords, SortOrder
		from a
	)
	select @json = (select b.*,  @relativeBasePath + isnull(DefaultApplication, '') + URL URL from b b join [Profile.Cache].[Concept.Mesh.URL] c on b.DescriptorName = c.DescriptorName for json path, ROOT ('module_data'))
END

GO
