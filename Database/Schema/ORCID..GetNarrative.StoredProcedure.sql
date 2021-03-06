SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  Create PROCEDURE [ORCID.].[GetNarrative]
	@Subject BIGINT -- = 147559
AS
BEGIN

	SELECT TOP (200) 
		[ORCID.].[DefaultORCIDDecisionIDMapping].DefaultORCIDDecisionID, 
		ObjectValue AS Overview
	FROM            
		[RDF.].vwTripleValue LEFT JOIN [ORCID.].[DefaultORCIDDecisionIDMapping] ON [RDF.].vwTripleValue.ViewSecurityGroup = [ORCID.].[DefaultORCIDDecisionIDMapping].SecurityGroupID
	WHERE        
		(Subject = @Subject) 
		AND (PredicateValue = N'http://vivoweb.org/ontology/core#overview')

END
GO
