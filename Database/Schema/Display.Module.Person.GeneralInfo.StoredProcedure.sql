SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Person.GeneralInfo]
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN
	DECLARE @SecurityGroupID BIGINT, @HasSpecialViewAccess BIT, @HasSecurityGroupNodes BIT
	EXEC [RDF.Security].GetSessionSecurityGroup @SessionID, @SecurityGroupID OUTPUT, @HasSpecialViewAccess OUTPUT
	CREATE TABLE #SecurityGroupNodes (SecurityGroupNode BIGINT PRIMARY KEY)
	INSERT INTO #SecurityGroupNodes (SecurityGroupNode) select * from [RDF.Security].fnGetSessionSecurityGroupNodes(@SessionID, @Subject)

	DECLARE @PhotoPredicateID BIGINT
	SELECT @PhotoPredicateID = _PropertyNode FROM [Ontology.].ClassProperty WHERE Property = 'http://profiles.catalyst.harvard.edu/ontology/prns#mainImage'
	DECLARE @PhotoViewSecurityGroup BIGINT, @PhotoNodeID BIGINT
	SELECT @PhotoViewSecurityGroup = isnull(ViewSecurityGroup, -100), @PhotoNodeID = Object from [RDF.].Triple where Subject = @Subject AND Predicate = @PhotoPredicateID
	declare @PhotoURL varchar(max)
	set @PhotoURL = null
	IF (@PhotoViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (@PhotoViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (@PhotoViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes))
	BEGIN
		select @PhotoURL = Value from [RDF.].Node where NodeID = @PhotoNodeID
	END


	DECLARE @EmailEncryptedPredicateID BIGINT
	SELECT @EmailEncryptedPredicateID = _PropertyNode FROM [Ontology.].ClassProperty WHERE Property = 'http://profiles.catalyst.harvard.edu/ontology/prns#emailEncrypted'
	DECLARE @EmailEncryptedSecurityGroup BIGINT, @EmailEncryptedNodeID BIGINT
	SELECT @EmailEncryptedSecurityGroup = isnull(ViewSecurityGroup, -100), @EmailEncryptedNodeID = Object from [RDF.].Triple where Subject = @Subject AND Predicate = @EmailEncryptedPredicateID
	declare @EmailEncrypted nvarchar(max)
	set @EmailEncrypted = null
	IF (@EmailEncryptedSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (@EmailEncryptedSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (@EmailEncryptedSecurityGroup IN (SELECT * FROM #SecurityGroupNodes))
	BEGIN
		select @EmailEncrypted = Value from [RDF.].Node where NodeID = @EmailEncryptedNodeID
	END

	DECLARE @EmailPredicateID BIGINT
	SELECT @EmailPredicateID = _PropertyNode FROM [Ontology.].ClassProperty WHERE Property = 'http://vivoweb.org/ontology/core#Email'
	DECLARE @EmailSecurityGroup BIGINT, @EmailNodeID BIGINT
	SELECT @EmailSecurityGroup = isnull(ViewSecurityGroup, -100), @EmailNodeID = Object from [RDF.].Triple where Subject = @Subject AND Predicate = @EmailPredicateID
	declare @Email varchar(max)
	set @Email = null
	IF (@EmailSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (@EmailSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (@EmailSecurityGroup IN (SELECT * FROM #SecurityGroupNodes))
	BEGIN
		select @Email = Value from [RDF.].Node where NodeID = @EmailNodeID
	END

	DECLARE @ORCIDPredicateID BIGINT
	SELECT @ORCIDPredicateID = _PropertyNode FROM [Ontology.].ClassProperty WHERE Property = 'http://vivoweb.org/ontology/core#orcidId'
	DECLARE @ORCIDSecurityGroup BIGINT, @ORCIDNodeID BIGINT
	SELECT @ORCIDSecurityGroup = isnull(ViewSecurityGroup, -100), @ORCIDNodeID = Object from [RDF.].Triple where Subject = @Subject AND Predicate = @ORCIDPredicateID
	declare @ORCID varchar(max)
	set @ORCID = null
	IF (@ORCIDSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (@ORCIDSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (@ORCIDSecurityGroup IN (SELECT * FROM #SecurityGroupNodes))
	BEGIN
		select @ORCID = Value from [RDF.].Node where NodeID = @ORCIDNodeID
	END

	declare @supportHTML nvarchar(max)
	select @supportHTML = HTML 
			from [Profile.Cache].Person a 
		join [Profile.Module].[Support.Map] b 
			on nodeID = @subject 
			and a.InstitutionName = b.Institution
			and (b.department is null or b.department = '' or a.DepartmentName = b.Department)
		join [Profile.Module].[Support.HTML] c
			on b.SupportID = c.SupportID 

	-- This is only needed to handle odd data at Harvard
	set @supportHTML = replace(@supportHTML, '<script>document.write(''@'');</script>', '@')

	declare @personID int
	select @personID = personID from [Profile.Cache].Person where NodeID =@Subject
	declare @a nvarchar(max)
	select @a = (Select SortOrder, Title, InstititutionName as InstitutionName, DepartmentName, DivisionName, FacultyRank from [Profile.Cache].[Person.Affiliation] where personID = @PersonID for JSON path, Root ('Affiliation'))
	select @json = (Select FirstName, LastName, DisplayName, AddressLine1, AddressLine2, AddressLine3, AddressLine4, Phone, Fax, @EmailEncrypted EmailEncrypted, @Email Email, @ORCID ORCID, @PhotoURL as ImageURL, JSON_QUERY(@a, '$.Affiliation')as Affiliation, @supportHTML SupportHTML
		from [Profile.Cache].Person
		where NodeID = @subject
		for json path, ROOT ('module_data'))
END
GO
