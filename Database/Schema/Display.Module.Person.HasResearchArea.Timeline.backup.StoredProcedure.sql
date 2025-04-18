SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[Person.HasResearchArea.Timeline.backup]
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN
	declare @personID int
	select @personID = [RDF.].[fnNodeID2PersonID](@Subject)

 
declare @relativeBasePath varchar(max)
select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'

;with a as (
		select top 20 MeshHeader, cast(FirstPublicationYear as int) FirstPublicationYear, cast(LastPublicationYear as int) LastPublicationYear, NumPubsThis, Weight, URL, DefaultApplication from [Profile.Cache].[Concept.Mesh.Person] z join [Profile.Cache].[Concept.Mesh.URL] y on z.MeshHeader = y.DescriptorName where personID = @PersonID order by Weight desc
	), b as (
		select min(FirstPublicationYear)-1 a, max(LastPublicationYear)+1 b,
			cast(cast('1/1/'+cast(min(FirstPublicationYear)-1 as varchar(10)) as datetime) as float) f,
			cast(cast('1/1/'+cast(max(LastPublicationYear)+1 as varchar(10)) as datetime) as float) g
		from a
	), c as (
		select  a.MeshHeader, PubDate from [Profile.Cache].[Concept.Mesh.PersonPublication] x join a a on x.MeshHeader = a.MeshHeader where personID = @PersonID
	), d as (
		select c.MeshHeader, (cast(pubdate as float)-f)/(g-f) x
		from c, b
	), e as  (
		select MeshHEader, min(x) MinX, max(x) MaxX, avg(x) AvgX
		from d
		group by MeshHEader
	), f as (
		select *, cast(a + (b - a) * AvgX  as int) AvgYear, cast(((b - a) * AvgX - cast((b - a) * AvgX  as int)) * 12 + 1 as int) as AvgMonth  from e, b
	)
	--select * from e
	select @json = (select a MinDisplayYear, b MaxDisplayYear
			, (select a.MeshHeader, a.FirstPublicationYear, a.LastPublicationYear, a.NumPubsThis NumPubs, @relativeBasePath + isnull(defaultApplication, '') + URL as URL, Weight, MinX, MaxX, AvgX, AvgYear, AvgMonth
					, (select x from d d where d.MeshHeader = a.MeshHeader for json path) xvals from a a join f f  on a.MeshHeader = f.MeshHeader for json path) Concepts 
					from b for json path, WITHOUT_ARRAY_WRAPPER) 
	select @json = (select JSON_QUERY(@json, '$') as module_data for json path, WITHOUT_ARRAY_WRAPPER)
END
GO
