SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[Concept.PreloadLabel]
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN


	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	declare @baseURI nvarchar(400)
	select @baseURI = value from [Framework.].Parameter where ParameterID = 'baseURI'


	------------------------------------------------------------
	-- Convert the NodeID to a DescriptorUI
	------------------------------------------------------------

	DECLARE @DescriptorUI VARCHAR(50)
	SELECT @DescriptorUI = m.InternalID
		FROM [RDF.Stage].[InternalNodeMap] m, [RDF.].Node n
		WHERE m.Status = 3 AND m.ValueHash = n.ValueHash AND n.NodeID = @Subject
 
	IF @DescriptorUI IS NULL
	BEGIN
		SELECT cast(null as xml) DescriptorXML WHERE 1=0
		RETURN
	END

	declare @name varchar(255), @definition varchar(max)
	select @name = DescriptorName from [Profile.Data].[Concept.Mesh.Descriptor] where DescriptorUI = @DescriptorUI

	select @json = (select @name label  for json path, WITHOUT_ARRAY_WRAPPER)
	select @json = (select JSON_QUERY(@json, '$') as module_data for json path, WITHOUT_ARRAY_WRAPPER)

END
GO
