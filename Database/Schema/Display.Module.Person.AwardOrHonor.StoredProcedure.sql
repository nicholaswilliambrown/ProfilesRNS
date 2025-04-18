SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Person.AwardOrHonor]
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@count int = 50,
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN
	select @json = (
		select n1.Value as StartYear, n2.value as EndYear, n3.value as Name, n4.value as Institution, t0.SortOrder From [RDF.].Triple t0
			join [RDF.].Node n on t0.Object = n.NodeID
			and t0.subject=@Subject and t0.Predicate = @Predicate
			left join [RDF.].Triple t1 on t0.Object = t1.Subject and t1.Predicate = [RDF.].fnURI2NodeID('http://profiles.catalyst.harvard.edu/ontology/prns#startDate')
			left join [RDF.].Node n1 on t1.Object = n1.NodeID
			left join [RDF.].Triple t2 on t0.Object = t2.Subject and t2.Predicate = [RDF.].fnURI2NodeID('http://profiles.catalyst.harvard.edu/ontology/prns#endDate')
			left join [RDF.].Node n2 on t2.Object = n2.NodeID
			left join [RDF.].Triple t3 on t0.Object = t3.Subject and t3.Predicate = [RDF.].fnURI2NodeID('http://www.w3.org/2000/01/rdf-schema#label')
			left join [RDF.].Node n3 on t3.Object = n3.NodeID
			left join [RDF.].Triple t4 on t0.Object = t4.Subject and t4.Predicate = [RDF.].fnURI2NodeID('http://profiles.catalyst.harvard.edu/ontology/prns#awardConferredBy')
			left join [RDF.].Node n4 on t4.Object = n4.NodeID
			for json path, ROOT ('module_data'))
END
GO
