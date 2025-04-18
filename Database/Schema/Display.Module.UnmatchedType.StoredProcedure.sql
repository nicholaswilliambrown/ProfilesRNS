SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[UnmatchedType]
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN

	declare @rdf table (
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
			SortOrder int,
			URL nvarchar(max),
			PropertyGroupLabel varchar(max),
			PropertyGroupSort int,
			PropertyGroupInnerSort int
		)

		insert into @rdf(uri, subject, predicate, object, showSummary, property, tagName, propertyLabel, Language, DataType, Value,	ObjectType, SortOrder)
		exec [Display.].[GetDataRDF] @subject=@Subject,@predicate=@Predicate,@object=@object,@SessionID=null,@Expand=0,@limit=1

		delete from @rdf where predicate = [RDF.].fnURI2NodeID('http://www.w3.org/1999/02/22-rdf-syntax-ns#type')

		update r set r.URL = r.Value, r.value = n.Value from @rdf r join 
			[RDF.].Triple t on r.object = t.Subject and r.ObjectType = 0
			join [RDF.].Node n on t.predicate = [RDF.].fnURI2NodeID('http://www.w3.org/2000/01/rdf-schema#label') and t.Object = n.NodeID

		update r set r.PropertyGroupLabel = pg._PropertyGroupLabel, r.PropertyGroupSort = pg.SortOrder, r.PropertyGroupInnerSort = isnull(pgp.sortOrder, 1000) from @rdf r left join 
			[Ontology.].PropertyGroupProperty pgp on r.predicate = pgp._PropertyNode
			join [Ontology.].PropertyGroup pg on isnull(pgp._PropertyGroupNode, [RDF.].fnURI2NodeID('http://profiles.catalyst.harvard.edu/ontology/prns#PropertyGroupOverview')) = pg._PropertyGroupNode

		select PropertyLabel, Value, URL, PropertyGroupSort, PropertyGroupLabel, PropertyGroupInnerSort From @rdf

	select @json = (select PropertyLabel, Value, URL, PropertyGroupSort, PropertyGroupLabel, PropertyGroupInnerSort From @rdf as module_data for json path)
END
GO
