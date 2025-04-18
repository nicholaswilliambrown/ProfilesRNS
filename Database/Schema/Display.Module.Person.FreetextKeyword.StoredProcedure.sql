SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Person.FreetextKeyword]
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
	select @json = (select SortOrder, Value from [RDF.].Triple t
	join [RDF.].Node n on t.Object = n.NodeID and t.Predicate = @Predicate and subject = @Subject
	for json path, ROOT ('module_data'))
END
GO
