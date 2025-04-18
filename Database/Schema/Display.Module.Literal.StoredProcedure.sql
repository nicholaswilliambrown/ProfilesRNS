SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Literal]
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN
	select @json = (select t.sortOrder, n.value from [RDF.].Triple t
		join [RDF.].Node n 
		on Subject = @Subject and Predicate = @Predicate and Object = NodeID for json path, ROOT ('module_data'))
END
GO
