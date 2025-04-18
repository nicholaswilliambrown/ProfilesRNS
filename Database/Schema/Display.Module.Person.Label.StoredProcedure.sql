SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Display.Module].[Person.Label]
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN
	declare @SubjectPath varchar(max), @relativeBasePath varchar(100)
	select @relativeBasePath = Value from [Framework.].Parameter where ParameterID = 'relativeBasePath'

	select @json = (Select FirstName, LastName, DisplayName, @relativeBasePath + isnull(DefaultApplication, '') + PreferredPath as PreferredPath, PersonID, NodeID from [Profile.Cache].Person where NodeID = @subject for json path, ROOT ('module_data'))
END
GO
