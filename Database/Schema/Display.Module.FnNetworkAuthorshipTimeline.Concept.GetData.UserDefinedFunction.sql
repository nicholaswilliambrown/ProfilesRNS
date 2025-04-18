SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [Display.Module].[FnNetworkAuthorshipTimeline.Concept.GetData]
	(@NodeID BIGINT)
	returns varchar(max)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	DECLARE @DescriptorName NVARCHAR(255)
 	SELECT @DescriptorName = d.DescriptorName
		FROM [RDF.Stage].[InternalNodeMap] m, [RDF.].Node n,
			[Profile.Data].[Concept.Mesh.Descriptor] d
		WHERE m.Status = 3 AND m.ValueHash = n.ValueHash AND n.NodeID = @NodeID
			AND m.InternalID = d.DescriptorUI

	declare @result varchar(max) = ''

 
    -- Insert statements for procedure here
	declare @gc varchar(max)

	declare @y table (
		y int,
		A int,
		B int,
		C int,
		T int
	)

	insert into @y (y,A,B,C,T)
		select n.n y, 0 A, 0 B, 0 C, coalesce(t.T,0) T
		from [Utility.Math].[N] left outer join (
			select (case when y < 1970 then 1970 else y end) y,
				count(*) T
			from (
				select year(coalesce(a.entitydate,'1/1/1970')) y
				from [Profile.Data].[Publication.PubMed.Mesh] m
					join [Profile.Data].[Publication.Entity.InformationResource] a on  m.descriptorname = @DescriptorName and m.PMID = a.PMID and a.IsActive = 1
			) t
			group by y
		) t on n.n = t.y
		where n.n between year(getdate())-30 and year(getdate())

	declare @x int

	--select @x = max(A+B+C)
	--	from @y

	select @x = max(T)
		from @y

	if coalesce(@x,0) > 0
	begin
		declare @v varchar(1000)
		declare @z int
		declare @k int
		declare @i int

		set @z = power(10,floor(log(@x)/log(10)))
		set @k = floor(@x/@z)
		if @x > @z*@k
			select @k = @k + 1
		if @k > 5
			select @k = floor(@k/2.0+0.5), @z = @z*2

		set @v = ''
		set @i = 0
		while @i <= @k
		begin
			set @v = @v + '|' + cast(@z*@i as varchar(50))
			set @i = @i + 1
		end
		set @v = '|0|'+cast(@x as varchar(50))
		--set @v = '|0|50|100'

		declare @h varchar(1000)
		set @h = ''
		select @h = @h + '|' + (case when y % 2 = 1 then '' else ''''+right(cast(y as varchar(50)),2) end)
			from @y
			order by y 

		declare @w float
		--set @w = @k*@z
		set @w = @x

		declare @c varchar(50)
		declare @d varchar(max)
		set @d = ''

		select @result = (select y, t from @y order by y desc for json path, ROOT ('Timeline'))
	end
	return @result
END
GO
