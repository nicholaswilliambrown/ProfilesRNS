SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[NetworkList]
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN
	-------------------------------------------------------------------------------
	-- Get the RDF to assess which modules should be displayed
	-------------------------------------------------------------------------------
	create table #rdf(
		uri nvarchar(400),
		subject bigint,
		predicate bigint,
		object bigint,
		showSummary bit,
		property nvarchar(400),
		tagName nvarchar(1000),
		propertyLabel nvarchar(400),
		Language nvarchar(255),
		DataType nvarchar(255),
		Value nvarchar(max),
		ObjectType bit,
		SortOrder int
	)

	--TODO CONVERT [RDF.Security].[GetSessionSecurityGroupNodes] to function and add back into GetDataRDF
	insert into #rdf
	exec [Display.].[GetDataRDF] @subject=@subject,@predicate=@predicate,@SessionID=@SessionID,@Expand=0

	declare @connections nvarchar(max)
	select @connections = (select Value, SortOrder from #RDF where predicate = [RDF.].[fnURI2NodeID] ('http://profiles.catalyst.harvard.edu/ontology/prns#hasConnection') for json path, ROOT ('Connections'))
	declare @label nvarchar(max), @predicateLabel nvarchar(max), @predicateLabelNode bigint
	select @label = value from #rdf where predicate = [RDF.].[fnURI2NodeID] ('http://www.w3.org/2000/01/rdf-schema#label')
	select @predicateLabelNode = object from [RDF.].Triple where subject = @Predicate and predicate = [RDF.].fnURI2NodeID('http://www.w3.org/2000/01/rdf-schema#label') and ViewSecurityGroup = -1
	select @predicateLabel = value from [RDF.].Node where NodeID = @predicateLabelNode and ViewSecurityGroup = -1

	select @json = (
		select @label as label, @predicateLabel as predicate_label, JSON_QUERY(@connections, '$.Connections')as Connections
		for json path, ROOT ('module_data')
	)
END
GO
