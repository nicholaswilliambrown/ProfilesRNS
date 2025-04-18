SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [Display.Module].[GenericRDF.FeaturedPresentations]
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN

	SET NOCOUNT ON;
	select @json = (
		SELECT
			data from [Profile.Module].[GenericRDF.Data] where name = 'FeaturedPresentations' and NodeID = @Subject
			for json path, ROOT ('module_data'))
END
GO
