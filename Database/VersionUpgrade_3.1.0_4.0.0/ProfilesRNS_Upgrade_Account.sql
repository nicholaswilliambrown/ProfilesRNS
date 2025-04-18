/*
Run this script on:

        Profiles 3.1.0   -  This database will be modified

to synchronize it with:

        Profiles 4.0.0

You are recommended to back up your database before running this script

This script updates permissions for the App_Profiles10 database user. 
If you use a different user to connect your Profiles application to your 
Profiles Database, you should modify the user name in this script.

*/

GRANT EXEC ON [Display.].[GetActivity] TO App_Profiles10
GRANT EXEC ON [Display.].[GetDataRDF] TO App_Profiles10
GRANT EXEC ON [Display.].[GetDataURLs] TO App_Profiles10
GRANT EXEC ON [Display.].[GetJson] TO App_Profiles10
GRANT EXEC ON [Display.].[GetLatestActivityIDs] TO App_Profiles10
GRANT EXEC ON [Display.].[GetPageParams] TO App_Profiles10
GRANT EXEC ON [Display.].[Search.Params] TO App_Profiles10
GRANT EXEC ON [Display.].[SearchEverything] TO App_Profiles10
GRANT EXEC ON [Display.].[SearchPeople] TO App_Profiles10
GRANT EXEC ON [Display.].[SearchWhy] TO App_Profiles10
GRANT EXEC ON [Display.Lists].[UpdateLists] TO App_Profiles10
GRANT EXEC ON [Display.Module].[AwardReceipt.GeneralInfo] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Coauthor.Cluster] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Coauthor.Connection] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Coauthor.Timeline] TO App_Profiles10
GRANT EXEC ON [Display.Module].[CoauthorSimilar.Map] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Concept.GeneralInfo] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Concept.PreloadLabel] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Concept.Publications] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Concept.SimilarConcept] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Concept.TopJournals] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Concept.TopPeople] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Connection] TO App_Profiles10
GRANT EXEC ON [Display.Module].[GenericPropertyList] TO App_Profiles10
GRANT EXEC ON [Display.Module].[GenericRDF.FeaturedPresentations] TO App_Profiles10
GRANT EXEC ON [Display.Module].[GenericRDF.FeaturedVideos] TO App_Profiles10
GRANT EXEC ON [Display.Module].[GenericRDF.Plugin] TO App_Profiles10
GRANT EXEC ON [Display.Module].[GenericRDF.Twitter] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Group.AboutUs] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Group.AssociatedInformationResource] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Group.AssociatedInformationResource.All] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Group.AssociatedInformationResource.Cited] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Group.AssociatedInformationResource.Discussed] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Group.AssociatedInformationResource.Oldest] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Group.Cluster] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Group.ContactInformation] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Group.ContributingRole] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Group.FeaturedPresentations] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Group.FeaturedVideos] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Group.Label] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Group.MainImage] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Group.MediaLinks] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Group.Overview] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Group.Twitter] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Group.Webpage] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Group.Welcome] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Literal] TO App_Profiles10
GRANT EXEC ON [Display.Module].[NetworkList] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Person.AuthorInAuthorship] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Person.AuthorInAuthorship.All] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Person.AuthorInAuthorship.Cited] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Person.AuthorInAuthorship.Discussed] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Person.AuthorInAuthorship.Oldest] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Person.AwardOrHonor] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Person.ClinicalTrialRole] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Person.Coauthor.Top5] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Person.Concept.Top5] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Person.EducationAndTraining] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Person.FreetextKeyword] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Person.GeneralInfo] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Person.HasCoAuthor.Why] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Person.HasMemberRole] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Person.HasResearchArea] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Person.HasResearchArea.Timeline] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Person.HasResearchArea.Why] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Person.Label] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Person.MediaLinks] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Person.PhysicalNeighbour.Top5] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Person.ResearcherRole] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Person.SameDepartment.Top5] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Person.Similar.Top5] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Person.Similar.Why] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Person.Websites] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Publication.Authors] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Publication.Concepts] TO App_Profiles10
GRANT EXEC ON [Display.Module].[Publication.GeneralInfo] TO App_Profiles10
GRANT EXEC ON [Display.Module].[SimilarPeople.Connection] TO App_Profiles10
GRANT EXEC ON [Display.Module].[UnmatchedType] TO App_Profiles10
GRANT EXEC ON [Profile.Cache].[Person.UpdatePreferredPath] TO App_Profiles10
GRANT EXEC ON [Profile.Cache].[Concept.UpdatePreferredPath] TO App_Profiles10
GRANT EXEC ON [Profile.Data].[Group.GetPhotos] TO App_Profiles10



GRANT EXECUTE ON [Display.].[FnConvertSearchJSON2XML] TO App_Profiles10
GRANT EXECUTE ON [Display.Module].[FnCustomViewAssociatedInformationResource.GetList] TO App_Profiles10
GRANT EXECUTE ON [Display.Module].[FnCustomViewAuthorInAuthorship.GetJournalHeadings] TO App_Profiles10
GRANT EXECUTE ON [Display.Module].[FnCustomViewAuthorInAuthorship.GetList] TO App_Profiles10
GRANT EXECUTE ON [Display.Module].[FnCustomViewConceptPublications.GetList] TO App_Profiles10
GRANT EXECUTE ON [Display.Module].[FnNetworkAuthorshipTimeline.Concept.GetData] TO App_Profiles10
GRANT EXECUTE ON [Display.Module].[FnNetworkAuthorshipTimeline.Person.GetData] TO App_Profiles10
GRANT EXECUTE ON [Display.Module].[FnNetworkRadial.GetData] TO App_Profiles10