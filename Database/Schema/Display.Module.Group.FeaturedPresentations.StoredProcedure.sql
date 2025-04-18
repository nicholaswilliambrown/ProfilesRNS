SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[Group.FeaturedPresentations]
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

	DECLARE @SubjectValue nvarchar(max), @PredicateValue nvarchar(max), @ObjectValue nvarchar(max)
	select @SubjectValue = value from [RDF.].Node where NodeID = @Subject
	select @PredicateValue = value from [RDF.].Node where NodeID = @Predicate
	select @ObjectValue = value from [RDF.].Node where NodeID = @object

	select @json = (select @SubjectValue SubjectValue, @PredicateValue PredicateValue, @ObjectValue ObjectValue for json path, WITHOUT_ARRAY_WRAPPER)
	select @json = (select JSON_QUERY(@json, '$') as module_data for json path, WITHOUT_ARRAY_WRAPPER)
END
GO
