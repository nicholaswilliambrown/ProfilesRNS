SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [Display.Module].[CoauthorSimilar.Map]
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
	select @personID = 0

	declare @relativeBasePath varchar(100)
	select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'

	DECLARE  @f  TABLE(
		PersonID INT,
		display_name NVARCHAR(255),
		latitude FLOAT,
		longitude FLOAT,
		address1 NVARCHAR(1000),
		address2 NVARCHAR(1000),
		URI VARCHAR(400)
	)
 
	IF @Predicate = [RDF.].fnURI2NodeID('http://profiles.catalyst.harvard.edu/ontology/prns#coAuthorOf')
	BEGIN
		select @personID = [RDF.].[fnNodeID2PersonID](@Subject)
		insert into @f (PersonID) 
		SELECT DISTINCT PersonID
			FROM  [Profile.Data].[Publication.Person.Include]
			WHERE pmid IN (SELECT pmid
								FROM [Profile.Data].[Publication.Person.Include]
								WHERE PersonID = @PersonID
									AND pmid IS NOT NULL)
	END 


	ELSE IF @Predicate = [RDF.].fnURI2NodeID('http://profiles.catalyst.harvard.edu/ontology/prns#similarTo')
	BEGIN
		select @personID = [RDF.].[fnNodeID2PersonID](@Subject)
		insert into @f (PersonID) Values (@personID)
		insert into @f (PersonID) 
			SELECT SimilarPersonID FROM [Profile.Cache].[Person.SimilarPerson] WHERE PersonID = @PersonID
	END
	ELSE IF @Predicate = [RDF.].fnURI2NodeID('http://profiles.catalyst.harvard.edu/ontology/prns#hasConnection')
	BEGIN
		declare @groupID int
		select @groupID = cast(internalID as int) from [RDF.Stage].InternalNodeMap where NodeID = @Subject and Class = 'http://xmlns.com/foaf/0.1/Group'
		insert into @f (PersonID) 
			select PersonID from [Profile.Data].[Group.Member] a join [Profile.Cache].[Person] b on a.userID = b.UserID where GroupID = @groupID
	END

	update f 
		set f.display_name = p.displayname,
			f.latitude = p.Latitude,
			f.longitude = p.Longitude,
			f.address1 = CASE WHEN p.addressstring LIKE '%,%' THEN LEFT(p.addressstring,CHARINDEX(',',p.addressstring) - 1)ELSE p.addressstring END,
			f.address2 = REPLACE(SUBSTRING(p.addressstring,CHARINDEX(',',p.addressstring) + 1, LEN(p.addressstring)),', USA',''),
			URI= @relativeBasePath + isnull(DefaultApplication, '') + PreferredPath
		from @f f
		join [Profile.Cache].Person p on f.PersonID = p.PersonID

	delete from @f where latitude IS NULL OR longitude IS NULL OR URI is null
 
	IF (SELECT COUNT(*) FROM @f) = 1
		IF (SELECT personid from @f)=@PersonID
			DELETE FROM @f
 
	declare @json1 nvarchar(max), @json2 nvarchar(max)
	select @json1 = (SELECT PersonID, 
			display_name,
			CONVERT(DECIMAL(18,5),latitude) latitude,
			CONVERT(DECIMAL(18,5),longitude) longitude,
			address1,
			address2,
			URI
		FROM @f
		ORDER BY address1,
			address2,
			display_name
			for json path, ROOT ('people'))


		select @json2 = (SELECT DISTINCT	a.latitude	x1,
						CONVERT(DECIMAL(18,5),a.longitude)	y1,
						CONVERT(DECIMAL(18,5),d.latitude)	x2,
						CONVERT(DECIMAL(18,5),d.longitude)	y2,
						CONVERT(DECIMAL(18,5),a.PersonID)	a,
						CONVERT(DECIMAL(18,5),d.PersonID)	b,
						(CASE 
							 WHEN a.PersonID = @PersonID
								OR d.PersonID = @PersonID THEN 1
							 ELSE 0
						 END) is_person,
						a.URI u1,
						d.URI u2
			FROM @f a,
					 [Profile.Data].[Publication.Person.Include] b,
					 [Profile.Data].[Publication.Person.Include] c,
					 @f d
		 WHERE a.PersonID = b.PersonID
			 AND b.pmid = c.pmid
			 AND b.PersonID < c.PersonID
			 AND c.PersonID = d.PersonID
			 for json path, ROOT ('connections'))

		 select @json = (select JSON_QUERY(@json1, '$.people') as people, JSON_QUERY(@json2, '$.connections')as connections for json path, WITHOUT_ARRAY_WRAPPER)
		 select @json = (select JSON_QUERY(@json, '$') as module_data for json path, WITHOUT_ARRAY_WRAPPER)
END

GO
