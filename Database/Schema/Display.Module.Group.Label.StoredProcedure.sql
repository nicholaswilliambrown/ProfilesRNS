SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Group.Label]
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
	declare @ln bigint, @label nvarchar(max)
	select @ln = object from [RDF.].Triple where subject = @Subject and predicate = [RDF.].fnURI2NodeID('http://www.w3.org/2000/01/rdf-schema#label')
	select @label = value from [RDF.].Node where nodeID = @ln
	
	declare @relativeBasePath varchar(55)
	select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'

	declare @url varchar(max)
	select @URL = @relativeBasePath + '/display/' + cast(@Subject as varchar(50))

	declare @GroupID int, @GroupSize int
	select @GroupID = cast(InternalID as int) from [RDF.Stage].InternalNodeMap where nodeID = @Subject and Class = 'http://xmlns.com/foaf/0.1/Group'
	select @GroupSize = count(*) from [Profile.Data].[Group.Member] a join [Profile.Cache].Person p
		on a.UserID = p.UserID and a.IsActive = 1 and p.IsActive = 1 and GroupID = @GroupID

	select @json = (select @label label, @url URL, @GroupSize groupSize for json path, WITHOUT_ARRAY_WRAPPER)
	select @json = (select JSON_QUERY(@json, '$') as module_data for json path, WITHOUT_ARRAY_WRAPPER)
END
GO
