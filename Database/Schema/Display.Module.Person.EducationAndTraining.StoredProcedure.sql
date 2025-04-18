SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Person.EducationAndTraining]
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
		select n1.Value as Institution, n2.value as Location, n3.value as Degree, n4.value as CompletionDate, n5.value as Field, t0.SortOrder From [RDF.].Triple t0
			join [RDF.].Node n on t0.Object = n.NodeID
			and t0.subject=@Subject and t0.Predicate = @Predicate
			left join [RDF.].Triple t1 on t0.Object = t1.Subject and t1.Predicate = [RDF.].fnURI2NodeID('http://profiles.catalyst.harvard.edu/ontology/prns#trainingAtOrganization')
			left join [RDF.].Node n1 on t1.Object = n1.NodeID
			left join [RDF.].Triple t2 on t0.Object = t2.Subject and t2.Predicate = [RDF.].fnURI2NodeID('http://profiles.catalyst.harvard.edu/ontology/prns#trainingLocation')
			left join [RDF.].Node n2 on t2.Object = n2.NodeID
			left join [RDF.].Triple t3 on t0.Object = t3.Subject and t3.Predicate = [RDF.].fnURI2NodeID('http://vivoweb.org/ontology/core#degreeEarned')
			left join [RDF.].Node n3 on t3.Object = n3.NodeID
			left join [RDF.].Triple t4 on t0.Object = t4.Subject and t4.Predicate = [RDF.].fnURI2NodeID('http://profiles.catalyst.harvard.edu/ontology/prns#endDate')
			left join [RDF.].Node n4 on t4.Object = n4.NodeID
			left join [RDF.].Triple t5 on t0.Object = t5.Subject and t5.Predicate = [RDF.].fnURI2NodeID('http://vivoweb.org/ontology/core#majorField')
			left join [RDF.].Node n5 on t5.Object = n5.NodeID
			for json path, ROOT ('module_data'))
END
GO
