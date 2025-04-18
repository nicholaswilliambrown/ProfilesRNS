SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[Person.Similar.Top5]
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
	select @personID = personID, @ExploreLink = @relativeBasePath + isnull(DefaultApplication, '') + PreferredPath + '/Network/SimilarTo' from [Profile.Cache].Person where NodeID =@Subject

	declare @count int
	select @count = count (*) from [Profile.Cache].[Person.SimilarPerson] where personID = @personID

	if @count = 0
	BEGIN
		select @json = null
		return
	END


	select @json = (select top 5 isnull(LastName, '') + isnull(', ' + firstname, '') Label, @relativeBasePath + isnull(DefaultApplication, '') + PreferredPath URL, ROW_NUMBER() OVER (ORDER BY Weight desc) Sort 
		from [Profile.Cache].[Person.SimilarPerson] a join [Profile.Cache].Person b on a.SimilarPersonID = b.PersonID and a.PersonID = @PersonID order by Weight desc for json path, ROOT ('Connections'))
	select @json = (Select 'Similar People' Title, @ExploreLink ExploreLink, @Count [Count], JSON_QUERY(@json, '$.Connections')as Connections  for json path, ROOT ('module_data'))
END
GO
