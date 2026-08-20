USE HCProfileOpenSource_Localhost;
GO

CREATE OR ALTER procedure [Profile.Module].[NetworkRadial.List.GetCoAuthorsForSavedLists]
	@ListIDs VARCHAR(255),
	@MaxNodes int = 150,
	@SessionID UNIQUEIDENTIFIER=NULL,
	@OutputFormat VARCHAR(50)='JSON'
AS
BEGIN
	SET NOCOUNT ON;
CREATE TABLE #ListIDs(grp int, ListID int primary key, [Name] [varchar](max), rollDept int, rollInst int, includeInternal int, includeExternal int, fill varchar(7), border varchar(7))

;with lid1 as (
    SELECT Split.a.value('.', 'VARCHAR(100)') ListID
    FROM ( select CAST('<c>' + REPLACE(@ListIDs, ',', '</c><c>') + '</c>' as XML) as A) AS A CROSS APPLY A.nodes ('/c') AS Split(a)
     ), lid2 as (
 select substring(ListID, 0, len(listID) - 1) as ListID,
     case when ListID like '%d%' then 1 else 0 end as rollDept,
     case when ListID like '%i%' then 1 else 0 end as rollInst,
     case when ListID like '%1' or ListID like '%3' then 1 else 0 end as externalConnection,
     case when ListID like '%2' or ListID like '%3' then 1 else 0 end as internalConnection
 from lid1 where listID like '%[pid][0123]'
 union
 select ListID,
     0 as rollDept,
     0 as rollInst,
     1 as externalConnection,
     1 as internalConnection
 from lid1 where listID not like '%[pid][0123]'
     )
 insert into #ListIDs(ListID, Name, rollDept, rollInst, includeInternal, includeExternal)
select b.ListID, b.Name, l.rollDept, l.rollInst, internalConnection, externalConnection from lid2 l
                                                                                                 join [Profile.Data].[List.SavedLists.General] b
on l.ListID = b.ListID


;with a as (
    select *, ROW_NUMBER() OVER (ORDER BY rollInst, rollDept, grp) AS RN from #ListIDs
)
update a set a.grp = rn - 1



UPDATE #ListIDs set fill = '#4E79A7', border = '#000000' where grp = 0
UPDATE #ListIDs set fill = '#F28E2B', border = '#000000' where grp = 1
UPDATE #ListIDs set fill = '#E15759', border = '#000000' where grp = 2
UPDATE #ListIDs set fill = '#76B7B2', border = '#000000' where grp = 3
UPDATE #ListIDs set fill = '#59A14F', border = '#000000' where grp = 4
UPDATE #ListIDs set fill = '#EDC948', border = '#000000' where grp = 5
UPDATE #ListIDs set fill = '#B07AA1', border = '#000000' where grp = 6
UPDATE #ListIDs set fill = '#FF9DA7', border = '#000000' where grp = 7
UPDATE #ListIDs set fill = '#9C755F', border = '#000000' where grp = 8
UPDATE #ListIDs set fill = '#BAB0AC', border = '#000000' where grp = 9

-- Limit this to 10 groups, we may want to revisit this in the future.
DELETE FROM #ListIDs WHERE grp > 9


create table #people (personID int, grp int, institution int, department int, bucketID int)

    insert into #people(PersonID, grp)
select PersonID, case when min(rollDept + rollInst) = 0 then -1 else min(grp) end From [Profile.Data].[List.SavedLists.Member] a
    join #ListIDs b on a.ListID = b.ListID
group by personID

update a set a.institution = case when rollInst = 1 then InstitutionID else null end, a.department = case when rollDept = 1 then DepartmentID else null end from #people a
		join #ListIDs b
on a.grp = b.grp
    join [Profile.Data].[Person.Affiliation] c
    on a.personID = c.PersonID and IsPrimary = 1

create table #buckets (bucketID int identity(0,1), sort int, grpIDs varchar(max), grp int, personID int, institutionID int, departmentID int, label varchar(max), tooltip varchar(max), description varchar(max), firstname varchar(max), lastname varchar(max), numPeople int, numPubs int, URI varchar(max))


    insert into #buckets (grp, institutionID, departmentID) select distinct grp, institution, department from #people where grp >= 0
    insert into #buckets (personID) select distinct personID from #people where grp = -1

update p set p.bucketID = b.bucketID From #people p
	join #buckets b on (p.grp = b.grp and isnull(p.department, -1) = isnull(b.departmentID, -1) AND isnull(p.institution, -1) = isnull(b.institutionID, -1))  or (p.grp = -1 AND p.personID = b.personID)


; with counts as (
    select bucketID, count(*) as numPeople, sum(c.NumPublications) as numPubs from #people p
                                                                                       join [Profile.Cache].Person c on p.personID = c.PersonID
  group by p.bucketID
      )
update b set b.numPeople = c.numPeople, b.numPubs = c.NumPubs from #buckets b
			join counts c on b.bucketID = c.bucketID

update b set label = InstitutionName + ' (' + case when numPeople = 1 then '1 person)' else cast(numPeople as varchar(50)) + ' people)' end from #buckets b join [Profile.Data].[Organization.Institution] i on b.institutionID = i.InstitutionID
update b set label = DepartmentName + ' (' + case when numPeople = 1 then '1 person)' else cast(numPeople as varchar(50)) + ' people)' end from #buckets b join [Profile.Data].[Organization.Department] i on b.DepartmentID = i.DepartmentID
update #buckets set tooltip = label, description = label where institutionid is not null or departmentID is not null
update b set firstname = p.firstname, lastname = p.LastName, label = p.lastname + ' ' + substring(p.firstname, 1, 1), tooltip = p.DisplayName, description = p.DisplayName from #buckets b join [Profile.Data].Person p on b.personID = p.PersonID



UPDATE n
SET /*n.NodeID = m.NodeID,*/ n.URI = p.Value + cast(m.NodeID as varchar(50))
    FROM #buckets n, [RDF.Stage].InternalNodeMap m, [Framework.].Parameter p
WHERE p.ParameterID = 'baseURI' AND m.InternalHash = [RDF.].fnValueHash(null,null,'http://xmlns.com/foaf/0.1/Person^^Person^^'+cast(n.PersonID as varchar(50)))

;with a as
          (
              select b.personID, i.grp, i.Name from #buckets b
                                                        join [Profile.Data].[List.SavedLists.Member] m
 on b.personID = m.PersonID
     join #ListIDs i
     on i.ListID = m.ListID
     ), g as
     (
 select PersonID, STUFF((
     SELECT ', ' + cast(a.grp as varchar(5))
     FROM a
     WHERE (PersonID = ungrouped.PersonID)
     FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
         ,1,2,'') AS grp,
     STUFF((
     SELECT ', ' + cast(a.Name as varchar(max))
     FROM a
     WHERE (PersonID = ungrouped.PersonID)
     FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
         ,1,2,'') AS listnames
 from a ungrouped group by personID
     )
update b set b.grpIDs = g.grp, b.tooltip = b.tooltip + '(' + listnames + ')' ,b.description = b.description + '(' + listnames + ')' From #buckets b join g g on b.personID = g.personID

update #buckets set grpIDs = grp where grp is not null

create table #edges (edgeID int identity, source int, target int, sourcesort int, targetsort int, n int, w float, y1 int, y2 int)

    insert into #edges (source, target, n, w, y1, y2)
select a.bucketID source, b.bucketID target, sum(n) n, sum(w) w,YEAR(min(FirstPubDate)) y1, YEAR(max(lastPubDate)) y2
       --into #network2
from #people a
    join #people b on a.bucketID < b.bucketID
    join [Profile.Cache].[SNA.Coauthor] c on a.personID = c.personID1  and b.personID = c.personID2
group by a.bucketID, b.bucketID

update #edges set y1 = 1980 where y1 < 1980
update #edges set y2 = 1980 where y2 < 1980

    if exists (select 1 from #ListIDs where includeInternal  = 0 or includeExternal = 0)
BEGIN
		;with bucketToGrp as (
    select b.bucketID, l.grp From #buckets b
                                      join [Profile.Data].[List.SavedLists.Member] m on b.personID = m.PersonID
             join #ListIDs l on l.ListID = m.ListID
         union
select bucketID, grp from #buckets where grp is not null
    ), displayEdge as (
			select edgeID, /*, b1.grp, b2.grp, l1.includeExternal, l1.includeInternal, l2.includeExternal, l2.includeInternal, */
				sum(case when b1.grp <> b2.grp then l1.includeExternal + l2.includeExternal else l1.includeInternal end) as displayEdge
				From #edges e
				join bucketToGrp b1 on e.source = b1.bucketID
				join bucketToGrp b2 on e.target = b2.bucketID
				join #ListIDs l1 on b1.grp = l1.grp
				join #ListIDs l2 on b2.grp = l2.grp
				group by edgeID
		)
delete from #edges where edgeID in (select edgeID from displayEdge where displayEdge = 0)

END

select source bucketID, /*sum(w),*/ row_number() over (order by sum(w) desc) - 1 as sort into #bucketRank from (
                                                                                                                   select source, w from #edges
                                                                                                                   union
                                                                                                                   select target, w from #edges
                                                                                                                   union
                                                                                                                   select BucketID, 0 from #buckets) t
group by source
--order by sum(w) desc
delete from #edges where source in (select bucketID from #bucketRank where sort >= @MaxNodes) or target in (select bucketID from #bucketRank where sort >= @MaxNodes)
delete from #buckets where bucketID in (select bucketID from #bucketRank where sort >= @MaxNodes)

update b set b.sort = r.sort from #buckets b join #bucketRank r on b.bucketID = r.bucketID
update e set e.sourcesort = r1.sort, e.targetsort = r2.sort from #edges e join #bucketRank r1 on e.source = r1.bucketID join #bucketRank r2 on e.target = r2.bucketID

;with e2 as (
    select edgeID, ceiling (10.0 * percent_rank() over (order by w)) / 2 w from #edges
)
update e set e.w = e2.w from #edges e join e2 e2 on e.edgeID = e2.edgeID
update #edges set w = 0.5 where w = 0


    IF @OutputFormat = 'JSON'
BEGIN
SELECT
    replace('{'+CHAR(10)
                +'"Groups":['+CHAR(10)
                +SUBSTRING(ISNULL(CAST((
                SELECT	',{'
                +'"Name":"'+cast(Name as varchar(500))+'",'
                +'"border":"'+ border +'",'
                +'"fill":"'+ fill +'"'
                +'}'+CHAR(10)
                FROM #ListIDs
                ORDER BY grp
                FOR XML PATH(''),TYPE
                ) as VARCHAR(MAX)),''),2,9999999)
                +'],'+CHAR(10)
                +'"Nodes":['+CHAR(10)
                +SUBSTRING(ISNULL(CAST((
                SELECT	',{'
                +'"id":'+cast(bucketID as varchar(50))+','
                + case when uri is not null then '"uri":"'+uri+'",' else '' end
                +'"grp":['+cast(grpIDs as varchar(50))+'],'
                +'"pubs":'+cast(numPubs as varchar(50))+','
                +'"label":"'+label+'",'
                +'"tooltip":"'+tooltip+'",'
                +'"description":"'+description+'",'
                + case when firstname is not null then '"fn":"'+firstname+'",' else '' end
                + case when lastname is not null then '"ln":"'+lastname+'",' else '' end
                +'"w2":'+ '0.5'
                +'}'+CHAR(10)
                FROM #buckets
                ORDER BY sort
                FOR XML PATH(''),TYPE
                ) as VARCHAR(MAX)),''),2,9999999)
                +'],'+CHAR(10)
                +'"Edges":['+CHAR(10)
                +SUBSTRING(ISNULL(CAST((
                SELECT	',{'
                +'"source":'+cast(sourcesort as varchar(50))+','
                +'"target":'+cast(targetsort as varchar(50))+','
                +'"n":'+cast(n as varchar(50))+','
                +'"w":'+cast(w as varchar(50))+','
                +'"y1":'+cast(y1 as varchar(50))+','
                +'"y2":'+cast(y2 as varchar(50))
                +'}'+CHAR(10)
                FROM #edges
                ORDER BY source, target
                FOR XML PATH(''),TYPE
                ) as VARCHAR(MAX)),''),2,9999999)
                +']'+CHAR(10)
                +'}', '&amp;', '&') JSON
END

/*
	select * from #ListIDs
	select * From #buckets
	select * from #edges
*/
END;
GO

CREATE OR ALTER PROCEDURE [Profile.Module].[GetDisplayColors]
	@Count INT=NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
create table #colors(sortOrder int, color varchar(20))

    insert into #colors (sortORder, color) values (0, '#4E79A7')
	insert into #colors (sortORder, color) values (1, '#F28E2B')
	insert into #colors (sortORder, color) values (2, '#E15759')
	insert into #colors (sortORder, color) values (3, '#76B7B2')
	insert into #colors (sortORder, color) values (4, '#59A14F')
	insert into #colors (sortORder, color) values (5, '#EDC948')
	insert into #colors (sortORder, color) values (6, '#B07AA1')
	insert into #colors (sortORder, color) values (7, '#FF9DA7')
	insert into #colors (sortORder, color) values (8, '#9C755F')
	insert into #colors (sortORder, color) values (9, '#BAB0AC')


select color from #colors where sortOrder < @count
END;
GO

CREATE OR ALTER PROCEDURE [Profile.Data].[List.AddRemove.CoAuthors]
	@UserID int,
	@Action varchar(55),
	@Size int output
AS
BEGIN

	SELECT DISTINCT personID2 as PersonID into #coauthors FROM [Profile.Data].[List.Member] m
	JOIN [Profile.Cache].[SNA.Coauthor] c
	ON m.PersonID = c.PersonID1
	AND m.UserID = @UserID
	AND c.PersonID2 NOT IN (SELECT PersonID FROM [Profile.Data].[List.Member] m2 WHERE m2.UserID = @UserID)	

		-- Add or Remove
	IF (@Action = 'Add')
	BEGIN
		BEGIN TRANSACTION
			--DELETE FROM #coauthors WHERE PersonID in (SELECT PersonID FROM [Profile.Data].[List.Member] WHERE UserID = @UserID)
			INSERT INTO [Profile.Data].[List.Member] (UserID, PersonID)
				SELECT @UserID, PersonID from #coauthors

			-- Update list size
			SELECT @Size =  COUNT(*) FROM [Profile.Data].[List.Member] WHERE UserID=@UserID
			UPDATE [Profile.Data].[List.General] SET Size = @Size WHERE UserID = @UserID
		COMMIT TRANSACTION
	END
		-- Add or Remove
	IF (@Action = 'Replace')
	BEGIN
		BEGIN TRANSACTION
			DELETE FROM [Profile.Data].[List.Member] WHERE UserID = @UserID
			INSERT INTO [Profile.Data].[List.Member] (UserID, PersonID)
			SELECT @UserID, PersonID from #coauthors

			-- Update list size
			SELECT @Size =  COUNT(*) FROM [Profile.Data].[List.Member] WHERE UserID=@UserID
			UPDATE [Profile.Data].[List.General] SET Size = @Size WHERE UserID = @UserID
		COMMIT TRANSACTION
	END	
END;
GO
CREATE OR ALTER PROCEDURE [Profile.Data].[List.SavedLists.AddUpdateList]
	@ListID [int] = -1,
	@Action varchar(55),
	@UserID [int] = -1,
	@Name varchar(max) = ''
AS
BEGIN
	-- Actions: Save( name), Replace, Rename (name), Delete (), 
	insert into [Debug.].DebugLog (Date, ProcedureName, LocationID, Message) values (GETDATE(), '[Profile.Data].[List.SavedLists.AddUpdateList]', 1, 'ListID: ' + cast (@listID as varchar(50)) + '    Action: ' + @Action + '     UserID: ' + Cast(@UserID as varchar(50)) + '    Name: ' + @Name)
	DECLARE @Size int

	IF @Action = 'Save' AND @UserID <> -1
	BEGIN
		SELECT @Size = isnull(Size, 0)
			FROM [Profile.Data].[List.General]
			WHERE UserID = @UserID

		BEGIN TRANSACTION
			DECLARE @ListIDTable TABLE (ListID int)
			INSERT INTO [Profile.Data].[List.SavedLists.General] (UserID, Name, CreateDate, UpdatedDate, Size)
				OUTPUT inserted.ListID into @ListIDTable
				VALUES(@UserID, @Name, GETDATE(), GETDATE(), @Size)

			INSERT INTO [Profile.Data].[List.SavedLists.Member] (ListID, PersonID) 
				SELECT ListID, PersonID FROM [Profile.Data].[List.Member] a JOIN @ListIDTable b
				ON a.UserID = @UserID
		COMMIT TRANSACTION
	END

	ELSE IF @Action = 'Replace' AND @UserID <> -1 AND @ListID <> -1
	BEGIN
		SELECT @Size = isnull(Size, 0)
			FROM [Profile.Data].[List.General]
			WHERE UserID = @UserID
		BEGIN TRANSACTION
			UPDATE [Profile.Data].[List.SavedLists.General] SET Size = @Size, UpdatedDate =  GETDATE() WHERE ListID = @ListID
			DELETE FROM [Profile.Data].[List.SavedLists.Member] WHERE ListID = @ListID
			INSERT INTO [Profile.Data].[List.SavedLists.Member] (ListID, PersonID) 
				SELECT @ListID, PersonID FROM [Profile.Data].[List.Member] a WHERE a.UserID = @UserID
		COMMIT TRANSACTION
	END

	IF @Action = 'Rename' AND @ListID <> -1 AND @Name <> ''
	BEGIN
		UPDATE [Profile.Data].[List.SavedLists.General] SET Name = @Name, UpdatedDate =  GETDATE() WHERE ListID = @ListID
	END

	IF @Action = 'Delete' AND @ListID <> -1
	BEGIN
		BEGIN TRANSACTION
			DELETE FROM [Profile.Data].[List.SavedLists.General] WHERE ListID = @ListID
			DELETE FROM [Profile.Data].[List.SavedLists.Member] WHERE ListID = @ListID
		COMMIT TRANSACTION
	END
END;
GO

CREATE OR ALTER PROCEDURE [Profile.Data].[List.SavedLists.GetLists]
	@UserID int,
	@ListIDs varchar(max) = null
AS
BEGIN
	if @ListIDs is not null
	BEGIN
		select b.ListID, b.Name from (
		SELECT Split.a.value('.', 'VARCHAR(100)') ListID
			FROM ( select CAST('<c>' + REPLACE(@ListIDs, ',', '</c><c>') + '</c>' as XML) as A) AS A CROSS APPLY A.nodes ('/c') AS Split(a)) i
			join [Profile.Data].[List.SavedLists.General] b
			on i.ListID = b.ListID
			and b.UserID = @UserID
	END
	ELSE 
	BEGIN
		SELECT [ListID]
			  ,[Name]
			  ,[CreateDate]
			  ,[UpdatedDate]
			  ,[Size]
		  FROM [Profile.Data].[List.SavedLists.General]
		  WHERE UserID = @UserID
	  END
END;
GO

CREATE OR ALTER PROCEDURE [Profile.Data].[List.SavedLists.ModifyActiveList]
	@ListID [int] = 0,
	@ListIDs varchar(max) = '',
	@UserID [int],
	@Action varchar(55),
	@Size INT=NULL OUTPUT
AS
BEGIN

	CREATE TABLE #ListIDs (ListID INT PRIMARY KEY)
	IF @ListID <> 0 INSERT INTO #ListIDs SELECT @ListID
	ELSE
	BEGIN
		DECLARE @xListIDs xml
		SET @xListIDs = CAST('<ID>' + REPLACE(@ListIDs, ',', '</ID><ID>') + '</ID>' as xml)
		INSERT INTO #ListIDs SELECT x.element.value ('.', 'INT') from @xListIDs.nodes('//ID') as x(element)
	END


	IF @Action = 'Replace'
	BEGIN
		BEGIN TRANSACTION
			DELETE FROM [Profile.Data].[List.Member] WHERE UserID = @UserID
			INSERT INTO [Profile.Data].[List.Member] (UserID, PersonID) 
				SELECT DISTINCT @UserID, PersonID FROM [Profile.Data].[List.SavedLists.Member] WHERE ListID IN (SELECT ListID from #ListIDs)

			SELECT @Size =  COUNT(*) FROM [Profile.Data].[List.Member] WHERE UserID=@UserID
			UPDATE [Profile.Data].[List.General] SET Size = @Size WHERE UserID = @UserID
		COMMIT TRANSACTION
	END

	IF @Action = 'Add'
	BEGIN
		BEGIN TRANSACTION
			--DELETE FROM [Profile.Data].[List.Member] WHERE UserID = @UserID
			INSERT INTO [Profile.Data].[List.Member] (UserID, PersonID) 
				SELECT DISTINCT @UserID, PersonID FROM [Profile.Data].[List.SavedLists.Member] 
				WHERE ListID IN (SELECT ListID from #ListIDs) AND PersonID NOT IN (SELECT PersonID from [Profile.Data].[List.Member] WHERE UserID = @UserID)

			SELECT @Size =  COUNT(*) FROM [Profile.Data].[List.Member] WHERE UserID=@UserID
			UPDATE [Profile.Data].[List.General] SET Size = @Size WHERE UserID = @UserID
		COMMIT TRANSACTION
	END

	IF @Action = 'Remove'
	BEGIN
		BEGIN TRANSACTION
			--DELETE FROM [Profile.Data].[List.Member] WHERE UserID = @UserID
			DELETE FROM [Profile.Data].[List.Member] WHERE UserID = @UserID AND PersonID IN (SELECT PersonID from [Profile.Data].[List.SavedLists.Member] WHERE ListID IN (SELECT ListID from #ListIDs))

			SELECT @Size =  COUNT(*) FROM [Profile.Data].[List.Member] WHERE UserID=@UserID
			UPDATE [Profile.Data].[List.General] SET Size = @Size WHERE UserID = @UserID
		COMMIT TRANSACTION
	END

	IF @Action = 'RemoveNotInAny'
	BEGIN
		BEGIN TRANSACTION
			--DELETE FROM [Profile.Data].[List.Member] WHERE UserID = @UserID
			DELETE FROM [Profile.Data].[List.Member] WHERE UserID = @UserID AND PersonID NOT IN (SELECT PersonID from [Profile.Data].[List.SavedLists.Member] WHERE ListID IN (SELECT ListID from #ListIDs))

			SELECT @Size =  COUNT(*) FROM [Profile.Data].[List.Member] WHERE UserID=@UserID
			UPDATE [Profile.Data].[List.General] SET Size = @Size WHERE UserID = @UserID
		COMMIT TRANSACTION
	END

	IF @Action = 'RemoveNotInAll'
	BEGIN
		BEGIN TRANSACTION
			DECLARE @noOfLists int 
			SELECT @noOfLists = COUNT(1) FROM #ListIDs
			SELECT PersonID INTO #Intersection FROM [Profile.Data].[List.SavedLists.Member] a JOIN #ListIDs b
				ON a.ListID = b.ListID GROUP BY PersonID
				HAVING COUNT(*) = @noOfLists

			--DELETE FROM [Profile.Data].[List.Member] WHERE UserID = @UserID
			DELETE FROM [Profile.Data].[List.Member] WHERE UserID = @UserID AND PersonID NOT IN (SELECT PersonID from #Intersection)

			SELECT @Size =  COUNT(*) FROM [Profile.Data].[List.Member] WHERE UserID=@UserID
			UPDATE [Profile.Data].[List.General] SET Size = @Size WHERE UserID = @UserID
		COMMIT TRANSACTION
	END
END;
GO
