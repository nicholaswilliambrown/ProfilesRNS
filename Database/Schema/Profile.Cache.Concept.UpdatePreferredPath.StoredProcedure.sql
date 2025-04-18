SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [Profile.Cache].[Concept.UpdatePreferredPath]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	CREATE TABLE #tmpURL(
		[DescriptorName] [varchar](255) NOT NULL Primary key,
		[NodeID] [bigint] NULL,
		[DescriptorUI] [varchar](10) NOT NULL,
		[URL] [varchar](553) NULL,
		[DefaultApplication] [varchar](50) NULL,
	)

	insert into #tmpURL([DescriptorName], [DescriptorUI]) select [DescriptorName], [DescriptorUI] from [Profile.Data].[Concept.Mesh.Descriptor]

	update a set a.NodeID = m.NodeID from #tmpURL a join [RDF.Stage].[InternalNodeMap] m on a.DescriptorUI = m.InternalID and m.Status = 3

	update a set a.DefaultApplication = '/' + b.DefaultApplication, a.URL = '/' + AliasType + '/' + AliasID  from #tmpURL a join [RDF.].Alias b on a.NodeID = b.NodeID and b.Preferred = 1

	update #tmpURL set DefaultApplication = '/display', URL = '/' + cast(NodeID as varchar(50))

	truncate table [Profile.Cache].[Concept.Mesh.URL]

	insert into [Profile.Cache].[Concept.Mesh.URL] select * from #tmpURL
END
GO
