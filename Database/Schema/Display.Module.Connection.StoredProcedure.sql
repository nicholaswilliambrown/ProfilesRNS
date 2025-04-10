SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Connection]
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN
	declare @label bigint = [RDF.].fnURI2NodeID('http://www.w3.org/2000/01/rdf-schema#label')
	select @json = (
		select s.Value subject_label, isnull((select AliasType  + '/' + AliasID from [RDF.].Alias where NodeID = @subject and Preferred = 1) , '/' + cast(@subject as varchar(50))) subject_path
			,p.Value predicate_label
			, o.Value object_label, isnull((select AliasType  + '/' + AliasID from [RDF.].Alias where NodeID = @object and Preferred = 1) , '/' + cast(@object as varchar(50))) object_path
			,CONVERT(DECIMAL(18,2),ROUND(t.Weight, 2)) as weight from [RDF.].Triple t
			join [RDF.].Triple ts on t.Subject = @subject and t.object = @object and t.Predicate = @predicate
				and ts.Subject = t.Subject and ts.predicate= @label
			join [RDF.].Node s on ts.Object = s.nodeID
			join [RDF.].Triple tp on tp.Subject = t.Predicate and tp.predicate= @label
			join [RDF.].Node p on p.NodeID = tp.Object
			join [RDF.].Triple tob on tob.Subject = t.Object and tob.predicate= @label
			join [RDF.].Node o on o.NodeID = tob.Object
		for json path, ROOT ('module_data')
	)
END
GO
