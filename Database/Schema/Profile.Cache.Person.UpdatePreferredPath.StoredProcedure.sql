SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [Profile.Cache].[Person.UpdatePreferredPath]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
 
	Update p set p.NodeID = i.NodeID from [Profile.Cache].[Person] p
		join [RDF.Stage].InternalNodeMap i
		on HASHBYTES('sha1',N'"'+CAST(N'http://xmlns.com/foaf/0.1/Person^^Person'+N'^^'+cast(p.PersonID as varchar(50)) AS NVARCHAR(4000))+N'"') = InternalHash and p.NodeID is null

	update p set p.PreferredPath = case when AliasType is null then '/' + cast(p.NodeID as varchar(50)) when AliasType = '' then '/' + AliasID else '/' + AliasType + '/' + AliasID end ,
		p.DefaultApplication = isnull(case when a.DefaultApplication = '' then '' else '/' + a.DefaultApplication end, '/display')
		from [Profile.Cache].[Person] p 
			left join [RDF.].Alias a
			on p.NodeID = a.NodeID and a.Preferred = 1
END
GO
