SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Person.Websites]
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
	declare @personID int
	select @personID = [RDF.].[fnNodeID2PersonID](@Subject)

	select @json = (select URL, WebPageTitle, SortOrder from [Profile.Data].[Person.Websites] where PersonID = @PersonID
	for json path, ROOT ('module_data'))
END
GO
