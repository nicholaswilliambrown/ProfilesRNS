SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Group.Webpage]
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
	declare @GroupID int
	select @GroupID = cast(InternalID as int) from [RDF.Stage].InternalNodeMap where nodeID = 179407 and Class = 'http://xmlns.com/foaf/0.1/Group'

	select @json = (select URL, WebPageTitle, SortOrder from [Profile.Data].[Group.Websites] where GroupID = @GroupID
			for json path, ROOT ('module_data'))
END
GO
