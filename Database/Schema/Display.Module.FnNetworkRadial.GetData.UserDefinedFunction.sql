SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Function [Display.Module].[FnNetworkRadial.GetData]
	(@PersonNodeID bigint = NULL,
	@GroupNodeID bigint = NULL,
	@ListUserID int = NULL)
	returns varchar(max)
AS
BEGIN


	declare @result varchar(max)		
	DECLARE @PersonID1 INT, @GroupID INT
	declare @network table(personID int not null, distance int not null, numberofpaths int, weight float, w2 float, lastname nvarchar(max), firstname nvarchar(max), p int, k int, nodeid bigint, uri varchar(400), PreferredPath varchar(400), nodeindex int)
	declare @network2 table (id1 int not null, id2 int not null, n int, w float, y1 int, y2 int, k int, n1 bigint, n2 bigint, u1 varchar(400), u2 varchar(400), connectionURI varchar(400), ni1 int, ni2 int)


	if @PersonNodeID is not null
	BEGIN

		SELECT @PersonID1 = CAST(m.InternalID AS INT)
		FROM [RDF.Stage].[InternalNodeMap] m, [RDF.].Node n
		WHERE m.Status = 3 AND m.ValueHash = n.ValueHash AND n.NodeID = @PersonNodeID
		insert into @network
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
						cast('' as varchar(400)) PreferredPath,
						0 nodeindex
			--INTO #network 
			FROM ( 
							SELECT personid, 
											distance, 
											numberofpaths, 
											weight, 
											w2, 
											p.lastname, 
											p.firstname, 
											p.numpublications p, 
											ROW_NUMBER() OVER (PARTITION BY distance ORDER BY w2 DESC) k 
								FROM [Profile.Cache].Person p
								JOIN ( SELECT *, ROW_NUMBER() OVER (PARTITION BY personid2 ORDER BY distance, w2 DESC) k 
										FROM (
											SELECT personid2, 1 distance, n numberofpaths, w weight, w w2 
												FROM [Profile.Cache].[SNA.Coauthor]  
												WHERE personid1 = @personid1
											UNION ALL 
												SELECT b.personid2, 2 distance, b.n numberofpaths, b.w weight,a.w*b.w w2 
												FROM [Profile.Cache].[SNA.Coauthor] a JOIN [Profile.Cache].[SNA.Coauthor] b ON a.personid2 = b.personid1 
												WHERE a.personid1 = @personid1  
											UNION ALL 
												SELECT @personid1 personid2, 0 distance, 1 numberofpaths, 1 weight, 1 w2 
										) t 
									) t ON p.personid = t.personid2 
								WHERE k = 1  AND p.IsActive = 1
						) t 
			WHERE k <= 80 
		ORDER BY distance, k
	END
 
	ELSE IF @GroupNodeID is not null
	BEGIN

		SET @PersonID1 = -1

		SELECT @GroupID = CAST(m.InternalID AS INT)
			FROM [RDF.Stage].[InternalNodeMap] m, [RDF.].Node n
			WHERE m.Status = 3 AND m.ValueHash = n.ValueHash AND n.NodeID = @GroupNodeID
 
		insert into @network
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
						cast('' as varchar(400)) PreferredPath,
						0 nodeindex
			FROM ( 
							SELECT p.personid, 
											1 as distance, 
											0 as numberofpaths, 
											0 as weight, 
											0.5 as w2, 
											p.lastname, 
											p.firstname, 
											p.numpublications p, 
											ROW_NUMBER() OVER (ORDER BY p.PersonID DESC) k 
								FROM [Profile.Cache].Person p
								JOIN [Profile.Data].[vwGroup.Member] g
								on p.PersonID = g.PersonID
								  AND p.IsActive = 1
								  and g.GroupID = @GroupID
						) t 
			--WHERE k <= 80 
		ORDER BY distance, k
	END


 



	
	--UPDATE n
		/*SET n.NodeID = m.NodeID, n.URI = p.Value + cast(m.NodeID as varchar(50))
		FROM @network n, [RDF.Stage].InternalNodeMap m, [Framework.].Parameter p
		WHERE p.ParameterID = 'baseURI' AND m.InternalHash = [RDF.].fnValueHash(null,null,'http://xmlns.com/foaf/0.1/Person^^Person^^'+cast(n.PersonID as varchar(50)))*/
 

 	declare @relativeBasePath varchar(100)
	select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'

	update n set n.nodeid = p.NodeID,
		n.uri = @relativeBasePath + isnull(DefaultApplication, '') + p.PreferredPath,
		n.PreferredPath = p.PreferredPath
		from @network n
			join [Profile.Cache].Person p
			on n.personID = p.PersonID

	DELETE FROM @network WHERE IsNull(URI,'') = ''	
	
	UPDATE a
		SET a.nodeindex = b.ni
		FROM @network a, (
			SELECT *, row_number() over (order by distance desc, k desc)-1 ni
			FROM @network
		) b
		WHERE a.personid = b.personid


	insert into @network2
	SELECT c.personid1 id1, c.personid2	id2, c.n, CAST(c.w AS VARCHAR) w, 
			(CASE WHEN YEAR(firstpubdate)<1980 THEN 1980 ELSE YEAR(firstpubdate) END) y1, 
			(CASE WHEN YEAR(lastpubdate)<1980 THEN 1980 ELSE YEAR(lastpubdate) END) y2,
			(case when c.personid1 = @personid1 or c.personid2 = @personid1 then 1 else 0 end) k,
			a.nodeid n1, b.nodeid n2, a.uri u1, b.uri u2, a.uri + '/Network/CoAuthors' + b.PreferredPath, a.nodeindex ni1, b.nodeindex ni2
		from @network a
			JOIN @network b on a.personid < b.personid  
			JOIN [Profile.Cache].[SNA.Coauthor] c ON a.personid = c.personid1 and b.personid = c.personid2  
 
	;with a as (
		select id1, id2, w, k from @network2
		union all
		select id2, id1, w, k from @network2
	), b as (
		select a.*, row_number() over (partition by a.id1 order by a.w desc, a.id2) s
		from a, 
			(select id1 from a group by id1 having max(k) = 0) b,
			(select id1 from a group by id1 having max(k) > 0) c
		where a.id1 = b.id1 and a.id2 = c.id1
	)
	update n
		set n.k = 2
		from @network2 n, b
		where (n.id1 = b.id1 and n.id2 = b.id2 and b.s = 1) or (n.id1 = b.id2 and n.id2 = b.id1 and b.s = 1)
 
	update n
		set n.k = 3
		from @network2 n, (
			select *, row_number() over (order by k desc, w desc) r 
			from @network2 
		) r
		where n.id1=r.id1 and n.id2=r.id2 and n.k=0 and r.r<=360
 
		declare @j1 nvarchar(max), @j2 nvarchar(max)
		SELECT @j1 = (select personID id, nodeid, uri, distance d, p pubs, firstname fn, lastname ln, CONVERT(DECIMAL(18,7),w2) w2 from @network order by nodeindex for json path, Root('NetworkPeople'))
		select @j2 = (select ni2 source, ni1 target, n, CONVERT(DECIMAL(18,5),w) w, id1, id2, y1, y2, n1 nodeid1, n2 nodeid2, u1 uri1, u2 uri2, connectionURI FROM @network2 WHERE k > 0 ORDER BY ni2, ni1 for json path, Root('NetworkCoAuthors'))
		select @result = (select JSON_QUERY(@j1, '$.NetworkPeople') as NetworkPeople, JSON_QUERY(@j2, '$.NetworkCoAuthors')as NetworkCoAuthors for json path, ROOT ('module_data'))
		

/*
		SELECT @result = 
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
				FROM @network
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
				FROM @network2
				WHERE k > 0
				ORDER BY ni2, ni1
				FOR XML PATH(''),TYPE
			) as VARCHAR(MAX)),''),2,9999999)
			+']'+CHAR(10)
			+'}'

 */

	return @result
END
GO
