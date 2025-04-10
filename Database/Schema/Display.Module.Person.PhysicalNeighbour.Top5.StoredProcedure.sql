SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Person.PhysicalNeighbour.Top5]
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN
	declare @personID int, @relativeBasePath varchar(55), @ExploreLink varchar(1000)
	select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'
	select @personID = personID, @ExploreLink = @relativeBasePath + isnull(DefaultApplication, '') + PreferredPath + '/Network/ResearchAreas' from [Profile.Cache].Person where NodeID =@Subject
/*	select top 5 MyNeighbors as Label, @relativeBasePath + isnull(DefaultApplication, '') + PreferredPath URL, ROW_NUMBER() OVER (ORDER BY Distance) Sort  from [Profile.Cache].[Person.PhysicalNeighbor] a 
		join [Profile.Cache].Person b
		on a.NeighborID = b.PersonID
		and a.PersonID = @personID
*/
	if not exists (select  1 from [Profile.Cache].[Person.PhysicalNeighbor] where PersonID = @personID)
	BEGIN
		select @json = null
		return
	END


	select @json = (select top 5 MyNeighbors as Label, @relativeBasePath + isnull(DefaultApplication, '') + PreferredPath URL, ROW_NUMBER() OVER (ORDER BY Distance) Sort  from [Profile.Cache].[Person.PhysicalNeighbor] a 
		join [Profile.Cache].Person b
		on a.NeighborID = b.PersonID
		and a.PersonID = @personID
			ORDER by Distance for json path, ROOT ('Connections'))
	select @json = (Select 'Physical Neighbors' Title, JSON_QUERY(@json, '$.Connections')as Connections  for json path, ROOT ('module_data'))
END
GO
