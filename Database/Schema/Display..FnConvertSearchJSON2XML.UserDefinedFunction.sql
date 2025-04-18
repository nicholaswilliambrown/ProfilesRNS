SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Function [Display.].[FnConvertSearchJSON2XML]
	(@JSON varchar(max),
	@EverythingSearch bit = 0)
	returns varchar(max)
AS
BEGIN

	/*
	select  [Display.].[FnConvertSearchJSON2XML](
	'{
		"Keyword": "keyword text here",
		"KeywordExact": false,
		"LastName": "lastname text here",
		"FirstName": "FirstName text here",
		"Institution": 1229480,
		"InstitutionExcept" : false,
		"Department": 1229206,
		"DepartmentExcept": false,
		"FacultyType": [ 65970, 65968, 65967 ],
		"OtherOptions" : [65978, 65976],
		"Offset": 0,
		"Count": 15,
		"Sort": "Relevance"
	}')
*/


		declare @j table([key] varchar(max), [value] varchar(max), [type] int)
		insert into @j
		select * from openjson(@json)


		declare @keyword nvarchar(max), @keywordExact varchar(max), @Lastname nvarchar(max), @FirstName nvarchar(max), @Institution varchar(max), @InstitutionExcept varchar(max), @Department varchar(max), @DepartmentExcept varchar(max), @FacultyType varchar(max), @OtherOptions varchar(max), @Offset int, @count int, @sort varchar(max)

		select @keyword = [value] from @j where [key] = 'keyword'
		select @keywordExact = [value] from @j where [key] = 'keywordExact'
		select @Lastname = [value] from @j where [key] = 'Lastname'
		select @FirstName = [value] from @j where [key] = 'FirstName'
		select @Institution = [value] from @j where [key] = 'Institution'
		select @InstitutionExcept = [value] from @j where [key] = 'InstitutionExcept'
		select @Department = [value] from @j where [key] = 'Department'
		select @DepartmentExcept = [value] from @j where [key] = 'DepartmentExcept'
		select @FacultyType = [value] from @j where [key] = 'FacultyType'
		select @OtherOptions = [value] from @j where [key] = 'OtherOptions'
		select @Offset = [value] from @j where [key] = 'Offset'
		select @count = [value] from @j where [key] = 'count'
		select @sort = [value] from @j where [key] = 'sort'

		declare @f table([key] varchar(max), [value] varchar(max), [type] int)
		insert into @f select * from openjson(@FacultyType)

		declare @o table([key] varchar(max), [value] varchar(max), [type] int)
		insert into @o select * from openjson(@OtherOptions)

		declare @searchFilters varchar(max)
		set @searchFilters = ''

		declare @basePath varchar(max)
		select @basePath = Value from [Framework.].Parameter where ParameterID = 'basePath'

		if isnull(@FirstName, '') <> ''
		BEGIN
			select @searchFilters = '<SearchFilter Property="http://xmlns.com/foaf/0.1/firstName" MatchType="Left">' + @FirstName + '</SearchFilter>'
		END
		if isnull(@Lastname, '') <> ''
		BEGIN
			select @searchFilters = @searchFilters + '<SearchFilter Property="http://xmlns.com/foaf/0.1/lastName" MatchType="Left">' + @LastName + '</SearchFilter>'
		END
		if isnull(@institution, '') <> ''
		BEGIN
			select @InstitutionExcept = case when @InstitutionExcept = 'false' then '0' else '1' end
			select @searchFilters = @searchFilters + '<SearchFilter IsExclude="' + @InstitutionExcept + '" Property="http://profiles.catalyst.harvard.edu/ontology/prns#personInPrimaryPosition" Property2="http://vivoweb.org/ontology/core#positionInOrganization" MatchType="Exact">'
			+ @basePath + '/profile/' + @institution  + '</SearchFilter>'
		END
		if isnull(@department, '') <> ''
		BEGIN
			select @DepartmentExcept = case when @DepartmentExcept = 'false' then '0' else '1' end
			select @searchFilters = @searchFilters + '<SearchFilter IsExclude="' + @DepartmentExcept + '" Property="http://profiles.catalyst.harvard.edu/ontology/prns#personInPrimaryPosition" Property2="http://profiles.catalyst.harvard.edu/ontology/prns#positionInDepartment" MatchType="Exact">'
			+ @basePath + '/profile/' + @Department  + '</SearchFilter>'
		END
		/*
		if isnull(@division, '') <> ''
		BEGIN
			select @searchFilters = @searchFilters + '<SearchFilter IsExclude="0" Property="http://profiles.catalyst.harvard.edu/ontology/prns#personInPrimaryPosition" Property2="http://profiles.catalyst.harvard.edu/ontology/prns#positionInDivision" MatchType="Exact">'
			+ @basePath + '/profile/' + cast(NodeID as varchar(max)) + '</SearchFilter>' from [RDF.Stage].InternalNodeMap where InternalID = cast(@DivisionID as varchar(max)) AND InternalType = 'Division'
		END
		*/
		declare @i int = 0
		if exists (select 1 from @f)
		BEGIN
			select @searchFilters = @searchFilters + '<SearchFilter Property="http://profiles.catalyst.harvard.edu/ontology/prns#hasFacultyRank" MatchType="In">'
			select @i = max([key])  from @f
			while @i >=0
			BEGIN
					select @searchFilters = @searchFilters + '<Item>' + @basePath + '/profile/' + [Value] + '</Item>' from @f where [key] = @i
					select @i = @i - 1
			END
			select @searchFilters = @searchFilters + '</SearchFilter>'
		END
		if exists (select 1 from @o)
		BEGIN
			select @i = max([key])  from @o
			while @i >=0
			BEGIN
					select @searchFilters = @searchFilters + '<SearchFilter Property="http://profiles.catalyst.harvard.edu/ontology/prns#hasPersonFilter" MatchType="Exact">' + @basePath + '/profile/' + [Value] + '</SearchFilter>' from @o where [key] = @i
					select @i = @i - 1
			END
		END
		if @searchFilters <> ''
		BEGIN
			select @searchFilters = '<SearchFiltersList>' + @searchFilters + '</SearchFiltersList>'
		END


		declare @SearchOpts varchar(max)
		set @SearchOpts =
			'<SearchOptions>
				<MatchOptions>
					<SearchString ExactMatch="' + @keywordExact + '">' + @keyword + '</SearchString>'
					+ @searchFilters +
					'<ClassURI>http://xmlns.com/foaf/0.1/Person</ClassURI>
				</MatchOptions>
				<OutputOptions>
					<Offset>' + cast (isnull(@Offset, 0) as varchar(50)) + '</Offset>
					<Limit>' + cast (isnull(@count, 0) as varchar(50)) + '</Limit>
				</OutputOptions>	
			</SearchOptions>'


	return @SearchOpts
END
GO
