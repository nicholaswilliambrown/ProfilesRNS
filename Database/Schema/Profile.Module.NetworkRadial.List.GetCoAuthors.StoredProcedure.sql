SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [Profile.Module].[NetworkRadial.List.GetCoAuthors]
	@UserID BIGINT,
	@SessionID UNIQUEIDENTIFIER=NULL,
	@OutputFormat VARCHAR(50)='JSON'
AS
BEGIN
	SET NOCOUNT ON;	

	--declare @ListID bigint
	--select @ListID=12
 
	SELECT TOP 120
					personid,
					distance,
					numberofpaths,
					weight,
					w2,
					lastname,
					firstname,
					p,
					k,
					cast(-1 as bigint) nodeid,
					cast('' as varchar(400)) uri,
					0 nodeindex
		INTO #network 
		FROM ( 
						SELECT p.personid, 
										1 as distance, 
										0 as numberofpaths, 
										0 as weight, 
										0.5 as w2, 
										p.lastname, 
										p.firstname, 
										p.numpublications p, 
										ROW_NUMBER() OVER (ORDER BY p.numpublications DESC) k 
							FROM [Profile.Cache].Person p
							JOIN [Profile.Data].[List.Member] g
							on p.PersonID = g.PersonID
							  AND p.IsActive = 1
							  and g.UserID = @UserID
					) t 
		--WHERE k <= 80 
	ORDER BY distance, k

	--UPDATE #network set distance = 0 where k = 1
	
	UPDATE n
		SET n.NodeID = m.NodeID, n.URI = p.Value + cast(m.NodeID as varchar(50))
		FROM #network n, [RDF.Stage].InternalNodeMap m, [Framework.].Parameter p
		WHERE p.ParameterID = 'baseURI' AND m.InternalHash = [RDF.].fnValueHash(null,null,'http://xmlns.com/foaf/0.1/Person^^Person^^'+cast(n.PersonID as varchar(50)))
 
	DELETE FROM #network WHERE IsNull(URI,'') = ''	


	UPDATE a
		SET a.nodeindex = b.ni
		FROM #network a, (
			SELECT *, row_number() over (order by distance desc, k desc)-1 ni
			FROM #network
		) b
		WHERE a.personid = b.personid

/*
	SELECT c.personid1 id1, c.personid2	id2, c.n, CAST(c.w AS VARCHAR) w, 
			(CASE WHEN YEAR(firstpubdate)<1980 THEN 1980 ELSE YEAR(firstpubdate) END) y1, 
			(CASE WHEN YEAR(lastpubdate)<1980 THEN 1980 ELSE YEAR(lastpubdate) END) y2,
			0 k,
			a.nodeid n1, b.nodeid n2, a.uri u1, b.uri u2, a.nodeindex ni1, b.nodeindex ni2
		into #network2
		from #network a
			JOIN #network b on a.personid < b.personid  
			JOIN [Profile.Cache].[SNA.Coauthor] c ON a.personid = c.personid1 and b.personid = c.personid2  
 
	;with a as (
		select id1, id2, w, k from #network2
		union all
		select id2, id1, w, k from #network2
	), b as (
		select a.*, row_number() over (partition by a.id1 order by a.w desc, a.id2) s
		from a, 
			(select id1 from a group by id1 having max(k) = 0) b,
			(select id1 from a group by id1 having max(k) > 0) c
		where a.id1 = b.id1 and a.id2 = c.id1
	)
	update n
		set n.k = 2
		from #network2 n, b
		where (n.id1 = b.id1 and n.id2 = b.id2 and b.s = 1) or (n.id1 = b.id2 and n.id2 = b.id1 and b.s = 1)
 
	update n
		set n.k = 3
		from #network2 n, (
			select *, row_number() over (order by k desc, w desc) r 
			from #network2 
		) r
		where n.id1=r.id1 and n.id2=r.id2 and n.k=0 and r.r<=360
 */


 	SELECT top 360 c.personid1 id1, c.personid2	id2, c.n, CAST(c.w AS VARCHAR) w, 
			(CASE WHEN YEAR(firstpubdate)<1980 THEN 1980 ELSE YEAR(firstpubdate) END) y1, 
			(CASE WHEN YEAR(lastpubdate)<1980 THEN 1980 ELSE YEAR(lastpubdate) END) y2,
			1 k,
			a.nodeid n1, b.nodeid n2, a.uri u1, b.uri u2, a.nodeindex ni1, b.nodeindex ni2
		into #network2
		from #network a
			JOIN #network b on a.personid < b.personid  
			JOIN [Profile.Cache].[SNA.Coauthor] c ON a.personid = c.personid1 and b.personid = c.personid2  
		order by c.w desc

	IF @OutputFormat = 'XML'
	BEGIN
		SELECT (
			SELECT (
				SELECT personid "@id", nodeid "@nodeid", uri "@uri", distance "@d", p "@pubs", firstname "@fn", lastname "@ln", cast(w2 as varchar(50)) "@w2"
				FROM #network
				FOR XML PATH('NetworkPerson'),ROOT('NetworkPeople'),TYPE
			), (
				SELECT id1 "@id1", id2 "@id2", n "@n", cast(w as varchar(50)) "@w", y1 "@y1", y2 "@y2",
					n1 "@nodeid1", n2 "@nodeid2", u1 "@uri1", u2 "@uri2"
				FROM #network2
				--WHERE k > 0
				FOR XML PATH('NetworkCoAuthor'),ROOT('NetworkCoAuthors'),TYPE
			)
			FOR XML PATH('LocalNetwork'), TYPE) [XML]
	END

	IF @OutputFormat = 'JSON'
	BEGIN
		SELECT
			'{'+CHAR(10)
			+'"NetworkPeople":['+CHAR(10)
			+SUBSTRING(ISNULL(CAST((
				SELECT	',{'
						+'"id":'+cast(personid as varchar(50))+','
						+'"nodeid":'+cast(nodeid as varchar(50))+','
						+'"uri":"'+uri+'",'
						+'"d":'+cast(distance as varchar(50))+',' 
						+'"pubs":'+cast(p as varchar(50))+',' 
						+'"fn":"'+firstname+'",' 
						+'"ln":"'+lastname+'",'
						+'"w2":'+cast(w2 as varchar(50))
						+'}'+CHAR(10)
				FROM #network
				ORDER BY nodeindex
				FOR XML PATH(''),TYPE
			) as VARCHAR(MAX)),''),2,9999999)
			+'],'+CHAR(10)
			+'"NetworkCoAuthors":['+CHAR(10)
			+SUBSTRING(ISNULL(CAST((
				SELECT	',{'
						+'"source":'+cast(ni2 as varchar(50))+','
						+'"target":'+cast(ni1 as varchar(50))+','
						+'"n":'+cast(n as varchar(50))+','
						+'"w":'+cast(w as varchar(50))+',' 
						+'"id1":'+cast(id1 as varchar(50))+','
						+'"id2":'+cast(id2 as varchar(50))+','
						+'"y1":'+cast(y1 as varchar(50))+',' 
						+'"y2":'+cast(y2 as varchar(50))+',' 
						+'"nodeid1":'+cast(n1 as varchar(50))+','
						+'"nodeid2":'+cast(n2 as varchar(50))+','
						+'"uri1":"'+u1+'",'
						+'"uri2":"'+u2+'"'
						+'}'+CHAR(10)
				FROM #network2
				ORDER BY ni2, ni1
				FOR XML PATH(''),TYPE
			) as VARCHAR(MAX)),''),2,9999999)
			+']'+CHAR(10)
			+'}' JSON
	END  
END


GO
