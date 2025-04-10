SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Group.AssociatedInformationResource]
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
	select @GroupID = cast(InternalID as int) from [RDF.Stage].InternalNodeMap where nodeID = @Subject and Class = 'http://xmlns.com/foaf/0.1/Group'

	declare @publications nvarchar(max), @timeline nvarchar(max), @fieldSummary nvarchar(max), @pubsCount int, @personID int
	select @pubsCount = count(*) from [Profile.Data].[Publication.Group.Include] where GroupID = @GroupID
	select @publications = [Display.Module].[FnCustomViewAssociatedInformationResource.GetList](@GroupID, null, 50, 'N')
	--select @timeline = [Display.Module].[FnNetworkAuthorshipTimeline.Person.GetData](@subject,0)
	--select @fieldSummary = [Display.Module].[FnCustomViewAuthorInAuthorship.GetJournalHeadings](@subject, @personID, null)

	--select @json = (select @publications Publications for json path, ROOT ('module_data'))
	select @json = (select @pubsCount as PublicationsCount, JSON_QUERY(@publications, '$.Publications')as Publications, JSON_QUERY(@timeline, '$.Timeline')as Timeline, JSON_QUERY(@fieldSummary, '$.FieldSummary')as FieldSummary for json path, ROOT ('module_data'))
END
GO
