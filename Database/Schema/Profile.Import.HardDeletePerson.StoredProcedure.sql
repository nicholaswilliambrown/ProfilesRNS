SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Profile.Import].[HardDeletePerson]
	@PersonID int
AS
BEGIN
	declare @userID int, @nodeId bigint, @userNodeID bigint
	select @userID = userID from [User.Account].[User] where personID = @personID
	select @nodeId = nodeid from [RDF.Stage].InternalNodeMap where InternalID = cast(@PersonID as varchar(50)) and class = 'http://xmlns.com/foaf/0.1/Person'
	select @userNodeID = nodeid from [RDF.Stage].InternalNodeMap where InternalID = cast(@userID as varchar(50)) and class = 'http://profiles.catalyst.harvard.edu/ontology/prns#User'
	delete from [Profile.Cache].[Concept.Mesh.Person] where PersonID = @personID
	delete from [Profile.Cache].[Concept.Mesh.PersonPublication] where PersonID = @personID
	delete from [Profile.Cache].[List.Export.Publications] where PersonID = @personID
	delete from [Profile.Cache].[Person] where PersonID = @personID
	delete from [Profile.Cache].[Person.Affiliation] where PersonID = @personID
	delete from [Profile.Cache].[Person.PhysicalNeighbor] where PersonID = @personID
	delete from [Profile.Cache].[Person.PhysicalNeighbor] where [NeighborID] = @personID
	delete from [Profile.Cache].[Person.SimilarPerson] where PersonID = @personID
	delete from [Profile.Cache].[Person.SimilarPerson] where [SimilarPersonID] = @personID
	delete from [Profile.Cache].[Publication.PubMed.AuthorPosition] where PersonID = @personID
	delete from [Profile.Cache].[SNA.Coauthor] where PersonID1 = @personID
	delete from [Profile.Cache].[SNA.Coauthor] where PersonID2 = @personID
	delete from [Profile.Cache].[SNA.Coauthor.Betweenness] where PersonID = @personID
	delete from [Profile.Cache].[SNA.Coauthor.Distance] where PersonID1 = @personID
	delete from [Profile.Cache].[SNA.Coauthor.Distance] where PersonID2 = @personID
	delete from [Profile.Cache].[SNA.Coauthor.Reach] where PersonID = @personID
	--delete from [Profile.Data].[ClinicalTrial.Person.Add] where PersonID = @personID
	--delete from [Profile.Data].[ClinicalTrial.Person.Exclude] where PersonID = @personID
	--delete from [Profile.Data].[ClinicalTrial.Person.Include] where PersonID = @personID
	delete from [Profile.Data].[Funding.Add] where PersonID = @personID
	delete from [Profile.Data].[Funding.Delete] where PersonID = @personID
	delete from [Profile.Data].[Funding.DisambiguationResults] where PersonID = @personID
	delete from [Profile.Data].[Funding.DisambiguationSettings] where PersonID = @personID
	delete from [Profile.Data].[Funding.Role] where PersonID = @personID
	delete from [Profile.Data].[Group.Admin] where UserID = @userID
	delete from [Profile.Data].[Group.Member] where UserID = @userID
	delete from [Profile.Data].[List.Admin] where UserID = @userID
	delete from [Profile.Data].[List.General] where UserID = @userID
	delete from [Profile.Data].[List.Member] where UserID = @userID
	--delete from [Profile.Data].[List.SavedLists.Member] where ListID in (select listID from [Profile.Data].[List.SavedLists.General] where UserID = @userID)
	--delete from [Profile.Data].[List.SavedLists.General] where UserID = @userID
	--delete from [Profile.Data].[Person.AlternateEmail] where PersonID = @personID
	--delete from [Profile.Data].[Person.AlternateName] where PersonID = @personID
	delete from [Profile.Data].[Person.FilterRelationship] where PersonID = @personID
	delete from [Profile.Data].[Person.MediaLinks] where PersonID = @personID
	delete from [Profile.Data].[Person.Photo] where PersonID = @personID
	delete from [Profile.Data].[Person.Websites] where PersonID = @personID
	delete from [Profile.Data].[Publication.Entity.Authorship] where PersonID = @personID
	delete from [Profile.Data].[Publication.Person.Add] where PersonID = @personID
	delete from [Profile.Data].[Publication.Person.Exclude] where PersonID = @personID
	delete from [Profile.Data].[Publication.Person.Include] where PersonID = @personID
	delete from [Profile.Data].[Publication.MyPub.General] where PersonID = @personID
	delete from [Profile.Data].[Publication.PubMed.Author2Person] where PersonID = @personID
	delete from [Profile.Data].[Publication.PubMed.Disambiguation] where PersonID = @personID
	delete from [Profile.Data].[Publication.Pubmed.DisambiguationSettings] where PersonID = @personID
	delete from [Profile.Module].[GenericRDF.Data] where nodeID = @nodeId
	delete from [RDF.].[Alias] where nodeID = @nodeId
	delete from [RDF.Security].[Member] where UserID = @userID
	delete from [RDF.Security].[NodeProperty] where nodeID = @nodeId
	delete from [RDF.Stage].[InternalNodeMap] where class = 'http://xmlns.com/foaf/0.1/Person' and internalID = cast(@personID as varchar(max))
	delete from [RDF.Stage].[InternalNodeMap] where class = 'http://profiles.catalyst.harvard.edu/ontology/prns#User' and internalID = cast(@userID as varchar(max))
	delete from [Search.Cache].[Private.NodeClass] where nodeID = @nodeId
	delete from [Search.Cache].[Private.NodeExpand] where nodeID = @nodeId
	delete from [Search.Cache].[Private.NodeMap] where nodeID = @nodeId
	delete from [Search.Cache].[Private.NodePrefix] where nodeID = @nodeId
	delete from [Search.Cache].[Private.NodeRDF] where nodeID = @nodeId
	delete from [Search.Cache].[Private.NodeSummary] where nodeID = @nodeId
	delete from [Search.Cache].[Public.NodeClass] where nodeID = @nodeId
	delete from [Search.Cache].[Private.NodeSummary] where nodeID = @nodeId
	delete from [Search.Cache].[Public.NodeClass] where nodeID = @nodeId
	delete from [Search.Cache].[Public.NodeExpand] where nodeID = @nodeId
	delete from [Search.Cache].[Public.NodeMap] where nodeID = @nodeId
	delete from [Search.Cache].[Public.NodePrefix] where nodeID = @nodeId
	delete from [Search.Cache].[Public.NodeRDF] where nodeID = @nodeId
	delete from [Search.Cache].[Public.NodeSummary] where nodeID = @nodeId
	delete from [User.Account].[DefaultProxy] where UserID = @userID
	delete from [User.Account].[DesignatedProxy] where UserID = @userID
	delete from [User.Account].[DesignatedProxy] where ProxyForUserID = @userID
	delete from [User.Account].[Relationship] where PersonID = @personID
	delete from [User.Account].[Relationship] where UserID = @userID
	delete from [RDF.].[Triple] where subject in (@nodeId, @userNodeID) or Object in (@nodeId, @userNodeID)
	delete from [RDF.].Node where nodeID in (@nodeId, @userNodeID)
	delete from [User.Account].[User] where PersonID = @personID
	delete from [Profile.Data].[Person.Affiliation] where PersonID = @personID
	delete from [Profile.Data].[Person] where PersonID = @PersonID
END
GO
