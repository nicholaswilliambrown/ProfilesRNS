SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [Display.Module].[FnNetworkAuthorshipTimeline.Person.GetData]
	(@NodeID BIGINT, @ShowAuthorPosition BIT = 0)
	returns varchar(max)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	declare @result varchar(max) = '{"Timeline":[]}'

	DECLARE @PersonID INT
 	SELECT @PersonID = CAST(m.InternalID AS INT)
		FROM [RDF.Stage].[InternalNodeMap] m, [RDF.].Node n
		WHERE m.Status = 3 AND m.ValueHash = n.ValueHash AND n.NodeID = @NodeID
 
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
		select n.n y, coalesce(t.A,0) A, coalesce(t.B,0) B, coalesce(t.C,0) C, coalesce(t.T,0) T
		from [Utility.Math].[N] left outer join (
			select (case when y < 1970 then 1970 else y end) y,
				sum(case when r in ('F','S') then 1 else 0 end) A,
				sum(case when r not in ('F','S','L') then 1 else 0 end) B,
				sum(case when r in ('L') then 1 else 0 end) C,
				count(*) T
			from (
				select coalesce(p.AuthorPosition,'U') r, year(coalesce(p.pubdate,m.publicationdt,'1/1/1970')) y
				from [Profile.Data].[Publication.Person.Include] a
					left outer join [Profile.Cache].[Publication.PubMed.AuthorPosition] p on a.pmid = p.pmid and p.personid = a.personid
					left outer join [Profile.Data].[Publication.MyPub.General] m on a.mpid = m.mpid
				where a.personid = @PersonID
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
/*
		if @ShowAuthorPosition = 0
		begin
			select @d = @d + cast(floor(0.5 + 100*T/@w) as varchar(50)) + ','
				from @y
				order by y
			set @d = left(@d,len(@d)-1)

			--set @c = 'AC1B30'
			set @c = '80B1D3'
			set @gc = '//chart.googleapis.com/chart?chs=595x100&chf=bg,s,ffffff|c,s,ffffff&chxt=x,y&chxl=0:' + @h + '|1:' + @v + '&cht=bvs&chd=t:' + @d + '&chdl=Publications&chco='+@c+'&chbh=10'
		end
		else
		begin
			select @d = @d + cast(floor(0.5 + 100*A/@w) as varchar(50)) + ','
				from @y
				order by y
			set @d = left(@d,len(@d)-1) + '|'
			select @d = @d + cast(floor(0.5 + 100*B/@w) as varchar(50)) + ','
				from @y
				order by y
			set @d = left(@d,len(@d)-1) + '|'
			select @d = @d + cast(floor(0.5 + 100*C/@w) as varchar(50)) + ','
				from @y
				order by y
			set @d = left(@d,len(@d)-1)

			set @c = 'FB8072,B3DE69,80B1D3'
			set @gc = '//chart.googleapis.com/chart?chs=595x100&chf=bg,s,ffffff|c,s,ffffff&chxt=x,y&chxl=0:' + @h + '|1:' + @v + '&cht=bvs&chd=t:' + @d + '&chdl=First+Author|Middle or Unkown|Last+Author&chco='+@c+'&chbh=10'
		end
		
		declare @asText varchar(max)
		set @asText = '<table style="width:592px"><tr><th>Year</th><th>Publications</th></tr>'
		select @asText = @asText + '<tr><td style="text-align:center;">' + cast(y as varchar(50)) + '</td><td style="text-align:center;">' + cast(t as varchar(50)) + '</td></tr>'
			from @y
			where t > 0
			order by y 
		select @asText = @asText + '</table>'
		
			declare @alt varchar(max)
		select @alt = 'Bar chart showing ' + cast(sum(t) as varchar(50))+ ' publications over ' + cast(count(*) as varchar(50)) + ' distinct years, with a maximum of ' + cast(@x as varchar(50)) + ' publications in ' from @y where t > 0
		select @alt = @alt + cast(y as varchar(50)) + ' and '
			from @y
			where t = @x
			order by y 
		select @alt = left(@alt, len(@alt) - 4)


		select @gc gc, @alt alt, @asText asText --, @w w
		*/

		select @result = (select y, t from @y order by y desc for json path, ROOT ('Timeline'))
	end
	return @result
END
GO
