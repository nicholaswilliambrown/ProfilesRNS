SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[Person.AuthorInAuthorship.Oldest]
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
	declare @publications nvarchar(max), @personID int
	select @personID = [RDF.].[fnNodeID2PersonID](@Subject)
	select @publications = [Display.Module].[FnCustomViewAuthorInAuthorship.GetList](@personID, null, 25, 'O')
	select @json = (select JSON_QUERY(@publications, '$.Publications')as Publications for json path, ROOT ('module_data'))
END
GO
