SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[Person.HasResearchArea.Timeline.Test]
	@Subject bigint
AS
BEGIN
declare @sTime datetime 
select @sTime = GETDATE()

	declare @personID int, @json nvarchar(max)
	select @personID = [RDF.].[fnNodeID2PersonID](@Subject)

 
declare @relativeBasePath varchar(max)
select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'
select DATEDIFF(ms, GETDATE(), @sTime)


create table #a (i int primary key not null, [MeshHeader] nvarchar(255), FirstPublicationYear int, LastPublicationYear int, NumPubsThis int, Weight float, URL varchar(533), DefaultApplication varchar(55), MinX float, MaxX float, AvgX float, AvgYear int, AvgMonth int)
insert into #a (i, MeshHeader, FirstPublicationYear, LastPublicationYear, NumPubsThis, Weight, URL, DefaultApplication)  select top 20 ROW_NUMBER() over (order  by weight desc), MeshHeader, cast(FirstPublicationYear as int) FirstPublicationYear, cast(LastPublicationYear as int) LastPublicationYear, NumPubsThis, Weight, URL, DefaultApplication from [Profile.Cache].[Concept.Mesh.Person] z join [Profile.Cache].[Concept.Mesh.URL] y on z.MeshHeader = y.DescriptorName where personID = @PersonID order by Weight desc

declare @a int, @b int, @f int, @g int
select @a = min(FirstPublicationYear)-1, 
		@b = max(LastPublicationYear)+1,
		@f = cast(cast('1/1/'+cast(min(FirstPublicationYear)-1 as varchar(10)) as datetime) as float),
		@g = cast(cast('1/1/'+cast(max(LastPublicationYear)+1 as varchar(10)) as datetime) as float)
		from #a

create table #d (i int not null, x float)
insert into #d(i, x) select a.i, (cast(pubdate as float)-@f)/(@g-@f) from [Profile.Cache].[Concept.Mesh.PersonPublication] x join #a a on x.MeshHeader = a.MeshHeader where personID = @PersonID

; with e as  (
		select i, min(x) MinX, max(x) MaxX, avg(x) AvgX
		from #d
		group by i)
update a set a.MinX = e.MinX, a.MaxX = e.MaxX, a.AvgX = e.AvgX, a.AvgMonth = cast(((@b - @a) * e.AvgX - cast((@b - @a) * e.AvgX  as int)) * 12 + 1 as int), a.AvgYear = cast(@a + (@b - @a) * e.AvgX  as int)  from #a a join e e  on a.i = e.i

	select @json = (select @a MinDisplayYear, @b MaxDisplayYear
			, (select a.MeshHeader, a.FirstPublicationYear, a.LastPublicationYear, a.NumPubsThis NumPubs, @relativeBasePath + isnull(defaultApplication, '') + URL as URL, Weight, MinX, MaxX, AvgX, AvgYear, AvgMonth
					, (select x from #d d where d.i = a.i for json path) xvals from #a a for json path) Concepts 
					for json path, WITHOUT_ARRAY_WRAPPER) 
	select DATEDIFF(ms, GETDATE(), @sTime)
	select @json = (select JSON_QUERY(@json, '$') as module_data for json path, WITHOUT_ARRAY_WRAPPER)
		select DATEDIFF(ms, GETDATE(), @sTime)
select @json
END
GO
