SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Display.Module].[GenericRDF.Plugin]
	@pluginName varchar(55) = null,
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@count int = 50,
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN
	declare @name varchar(55), @dataType varchar(4)
	select @name = Name, @dataType = dataType from [Profile.Module].[GenericRDF.Plugins] where _PropertyNode = @Predicate

	if @dataType = 0 -- String
	BEGIN
		select @json = (
			SELECT
				data from [Profile.Module].[GenericRDF.Data] where name = @name and NodeID = @Subject
				for json path, ROOT ('module_data'))
	END

	else if @dataType = 1 -- String
	BEGIN
		select @json = (
			SELECT
				JSON_QUERY(data, '$') as data from [Profile.Module].[GenericRDF.Data] where name = @name and NodeID = @Subject
				for json path, ROOT ('module_data'))
	END
	else 
	BEGIN
		select @json = (
			SELECT
				@subject Subject, @Predicate Predicate, @tagname tagname, @name name, @pluginName pluginName
				for json path, ROOT ('module_data'))
	END
END
GO
