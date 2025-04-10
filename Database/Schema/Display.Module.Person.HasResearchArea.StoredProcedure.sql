SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[Person.HasResearchArea]
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN
		declare @relativeBasePath varchar(55), @PersonID int, @PersonPerferredPath varchar(max)
		select @PersonID = personID, @PersonPerferredPath = isnull(DefaultApplication, '') + PreferredPath from [Profile.Cache].Person where NodeID = @subject
		select @relativeBasePath = value from [Framework.].Parameter where ParameterID = 'relativeBasePath'

		select @json = (
			select MeshHeader as Name, NumPubsThis, NumPubsAll, [Weight], NTILE(5) OVER (ORDER BY p.weight) CloudSize, LastPublicationYear LastPubYear, (select top 1 SemanticGroupName from [Profile.Data].[Concept.Mesh.SemanticGroup] g where u.DescriptorUI = g.[DescriptorUI]) SemanticGroupName, (select SemanticGroupName from [Profile.Data].[Concept.Mesh.SemanticGroup] g where u.DescriptorUI = g.[DescriptorUI] for json path) SemanticGroups, @relativeBasePath + isnull(DefaultApplication, '') + URL URL, @relativeBasePath + @PersonPerferredPath + '/Network/ResearchAreas' + URL WhyURL from [Profile.Cache].[Concept.Mesh.Person] p  join [Profile.Cache].[Concept.Mesh.URL] u on p.MeshHeader = u.DescriptorName
			where personID = @PersonID
		 for json path, root('module_data'))
END
GO
