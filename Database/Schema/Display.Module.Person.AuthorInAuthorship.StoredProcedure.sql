SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Person.AuthorInAuthorship]
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
	declare @publications nvarchar(max), @timeline nvarchar(max), @fieldSummary nvarchar(max), @pubsCount int, @personID int
	select @personID = [RDF.].[fnNodeID2PersonID](@Subject)
	select @pubsCount = count(*) from [Profile.Data].[Publication.Entity.Authorship] where IsActive = 1 and personID = @personID
	select @publications = [Display.Module].[FnCustomViewAuthorInAuthorship.GetList](@personID, null, 25, 'N')
	select @timeline = [Display.Module].[FnNetworkAuthorshipTimeline.Person.GetData](@subject,0)
	select @fieldSummary = [Display.Module].[FnCustomViewAuthorInAuthorship.GetJournalHeadings](@subject, @personID, null)

	select @json = (select @pubsCount as PublicationsCount, JSON_QUERY(@publications, '$.Publications')as Publications, JSON_QUERY(@timeline, '$.Timeline')as Timeline, JSON_QUERY(@fieldSummary, '$.FieldSummary')as FieldSummary for json path, ROOT ('module_data'))
END
GO
