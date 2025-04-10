SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[Concept.TopPeople]
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

	select @json = (select top 5 round(weight, 2) weight, lastname + ', ' + firstname Name, @relativeBasePath + isnull(DefaultApplication, '') + PreferredPath URL from [Profile.Cache].[Concept.Mesh.Person] a
	join [Profile.Cache].Person b on a.PersonID = b.PersonID and b.IsActive = 1
	and MeshHeader = 'adult' order by weight desc for json path, ROOT ('module_data'))
END
GO
