SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Group.ContactInformation]
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
	declare @ln bigint, @label nvarchar(max)
	select @ln = object from [RDF.].Triple where subject = @Subject and predicate = [RDF.].fnURI2NodeID('http://vivoweb.org/ontology/core#contactInformation')
	select @label = value from [RDF.].Node where nodeID = @ln

	select @json = (select @label label for json path, WITHOUT_ARRAY_WRAPPER)
	select @json = (select JSON_QUERY(@json, '$') as module_data for json path, WITHOUT_ARRAY_WRAPPER)
END
GO
