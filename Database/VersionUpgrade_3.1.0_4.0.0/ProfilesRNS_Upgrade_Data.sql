/*
Run this script on:

        Profiles 3.1.0   -  This database will be modified

to synchronize it with:

        Profiles 4.0.0

You are recommended to back up your database before running this script

Details of which objects have changed can be found in the release notes.
If you have made changes to existing tables or stored procedures in profiles, you may need to merge changes individually. 

This upgrade consists of 9 Scripts. They must be run in the following order:

ProfilesRNS_Upgrade_Schema_CREATE_SCHEMA.sql
ProfilesRNS_Upgrade_Schema_ALTER_Tables.sql
ProfilesRNS_Upgrade_Schema_CREATE_Tables.sql
ProfilesRNS_Upgrade_Schema_ALTER_Functions.sql
ProfilesRNS_Upgrade_Schema_CREATE_Functions.sql
ProfilesRNS_Upgrade_Schema_ALTER_Procedures.sql
ProfilesRNS_Upgrade_Schema_CREATE_Procedures.sql
ProfilesRNS_Upgrade_Data.sql
ProfilesRNS_Upgrade_Account.sql

This script is number 8 of 9
*/



/** 
*
* update Fields column in Bibliometrics table 
*
* If you are updating the database, but keeping a version 3.1.0 application you should skip the next two queries. 
*
**/
;with a as (
select pmid, outerOrdinal, value, ordinal from (select pmid, value v, ordinal as outerOrdinal from [Profile.Data].[Publication.Pubmed.Bibliometrics] cross apply string_Split(Fields, '|',1)) t cross apply string_Split(v, ',',1))
, b as (select a.pmid, a.outerOrdinal, a.value Abbreviation, b.value Color, c.value BroadJournalHeading from a a join a b on a.pmid = b.pmid and a.outerordinal = b.outerordinal and a.ordinal = 1 and b.ordinal = 2 join a c on a.pmid = c.pmid and a.outerOrdinal = c.outerOrdinal and c.ordinal = 3)
update x  set Fields = (select BroadJournalHeading, Color, Abbreviation from b y where x.pmid = y.pmid for json path, root ('Fields')) from  [Profile.Data].[Publication.Pubmed.Bibliometrics] x
GO

update [Profile.Import].[PRNSWebservice.Options] set ImportDataProc = '[Profile.Import].[PRNSWebservice.Pubmed.ParseBibliometricResults]' where job = 'bibliometrics'


/*****
*
* If you have added any Plugins you will need to write additional queries for them
*
* The value should be 1 when data is stored as JSON and should be 0 when data should be returned to the UI as a test string.
*
*****/
update [Profile.Module].[GenericRDF.Plugins]  set dataType = 0 where name in ('FeaturedPresentations', 'Twitter')
update [Profile.Module].[GenericRDF.Plugins]  set dataType = 1 where name in ('FeaturedVideos')
GO
UPDATE a SET a._PropertyNode = b.NodeID 
	FROM [Profile.Module].[GenericRDF.Plugins] a 
	JOIN [RDF.].Node b ON [RDF.].fnValueHash(null, null, 'http://profiles.catalyst.harvard.edu/ontology/plugins#' + name) = ValueHash
GO

/**
*
* Add Relative Base Path parameter to the [Framework.].Parameter table
*
**/

INSERT INTO [Framework.].[Parameter] (ParameterID, Value) 
select 'relativeBasePath', case when CHARINDEX('/', Value, 9) = 0 then '' else substring(Value, CHARINDEX('/', Value, 9) + 1, len(Value) - CHARINDEX('/', Value, 9)) end FROM [Framework.].[Parameter] WHERE ParameterID = 'basePath'
GO


/**
*
* [Display.] Tables
*
**/

INSERT [Display.].[Activity.Log.MethodDetails] ([methodName], [Property], [label]) VALUES (N'Profiles.Edit.Utilities.DataIO.AddPublication', NULL, N'added a publication from $JournalTitle')
GO
INSERT [Display.].[Activity.Log.MethodDetails] ([methodName], [Property], [label]) VALUES (N'Profiles.Edit.Modules.CustomEditAuthorInAuthorship.DataIO.AddVerifyPublications', NULL, N'added a publication from $JournalTitle')
GO
INSERT [Display.].[Activity.Log.MethodDetails] ([methodName], [Property], [label]) VALUES (N'Profiles.Edit.Modules.CustomEditAuthorInAuthorship.DataIO.AddPubmedBookArticle', NULL, N'added a publication from $JournalTitle')
GO
INSERT [Display.].[Activity.Log.MethodDetails] ([methodName], [Property], [label]) VALUES (N'Profiles.Edit.Utilities.DataIO.AddUpdateFunding', NULL, N'added a research activity or funding: $AgreementLabel')
GO
INSERT [Display.].[Activity.Log.MethodDetails] ([methodName], [Property], [label]) VALUES (N'Profiles.Edit.Utilities.DataIO.AddCustomPublication', NULL, N'added a custom publication')
GO
INSERT [Display.].[Activity.Log.MethodDetails] ([methodName], [Property], [label]) VALUES (N'[Profile.Data].[Funding.LoadDisambiguationResults]', NULL, N'has a research activity or funding: $AgreementLabel')
GO
INSERT [Display.].[Activity.Log.MethodDetails] ([methodName], [Property], [label]) VALUES (N'[resnav_people_profileslabs].[dbo].[UpdatePubMedDisambiguation]', NULL, N'has a new publication from $JournalTitle')
GO
INSERT [Display.].[Activity.Log.MethodDetails] ([methodName], [Property], [label]) VALUES (N'Profiles.Edit.Utilities.DataIO.SaveImage', NULL, N'added a profile image')
GO
INSERT [Display.].[Activity.Log.MethodDetails] ([methodName], [Property], [label]) VALUES (N'Profiles.Edit.Utilities.DataIO.AddAward', NULL, N'added an award')
GO
INSERT [Display.].[Activity.Log.MethodDetails] ([methodName], [Property], [label]) VALUES (N'Profiles.Edit.Utilities.DataIO.UpdateLiteral', N'http://vivoweb.org/ontology/core#overview', N'updated their overview')
GO
INSERT [Display.].[Activity.Log.MethodDetails] ([methodName], [Property], [label]) VALUES (N'Profiles.Edit.Utilities.DataIO.AddLiteral', N'http://vivoweb.org/ontology/core#freetextKeyword', N'added a keyword')
GO
INSERT [Display.].[Activity.Log.MethodDetails] ([methodName], [Property], [label]) VALUES (N'Profiles.Edit.Utilities.DataIO.AddLiteral', N'http://vivoweb.org/ontology/core#overview', N'added an overview')
GO
INSERT [Display.].[Activity.Log.MethodDetails] ([methodName], [Property], [label]) VALUES (N'Profiles.Edit.Utilities.DataIO.AddEducationalTraining', NULL, N'added $param1 into education and training')
GO
INSERT [Display.].[Activity.Log.MethodDetails] ([methodName], [Property], [label]) VALUES (N'Profiles.Edit.Utilities.DataIO.UpdateSecuritySetting', N'http://profiles.catalyst.harvard.edu/ontology/plugins#FeaturedPresentations', N'made featured presentations public')
GO
INSERT [Display.].[Activity.Log.MethodDetails] ([methodName], [Property], [label]) VALUES (N'Profiles.Edit.Utilities.DataIO.UpdateSecuritySetting', N'http://profiles.catalyst.harvard.edu/ontology/plugins#FeaturedVideos', N'made featured videos public')
GO
INSERT [Display.].[Activity.Log.MethodDetails] ([methodName], [Property], [label]) VALUES (N'Profiles.Edit.Utilities.DataIO.UpdateSecuritySetting', N'http://profiles.catalyst.harvard.edu/ontology/plugins#Twitter', N'made twitter public')
GO
INSERT [Display.].[Activity.Log.MethodDetails] ([methodName], [Property], [label]) VALUES (N'Profiles.Edit.Utilities.DataIO.UpdateSecuritySetting', N'http://profiles.catalyst.harvard.edu/ontology/prns#hasClinicalTrialRole', N'made clinical trials public')
GO
INSERT [Display.].[Activity.Log.MethodDetails] ([methodName], [Property], [label]) VALUES (N'Profiles.Edit.Utilities.DataIO.UpdateSecuritySetting', N'http://profiles.catalyst.harvard.edu/ontology/prns#mainImage', N'made their profile image public')
GO
INSERT [Display.].[Activity.Log.MethodDetails] ([methodName], [Property], [label]) VALUES (N'Profiles.Edit.Utilities.DataIO.UpdateSecuritySetting', N'http://profiles.catalyst.harvard.edu/ontology/prns#mediaLinks', N'made media links public')
GO
INSERT [Display.].[Activity.Log.MethodDetails] ([methodName], [Property], [label]) VALUES (N'Profiles.Edit.Utilities.DataIO.UpdateSecuritySetting', N'http://vivoweb.org/ontology/core#authorInAuthorship', N'made publications public')
GO
INSERT [Display.].[Activity.Log.MethodDetails] ([methodName], [Property], [label]) VALUES (N'Profiles.Edit.Utilities.DataIO.UpdateSecuritySetting', N'http://vivoweb.org/ontology/core#awardOrHonor', N'made awards and honors public')
GO
INSERT [Display.].[Activity.Log.MethodDetails] ([methodName], [Property], [label]) VALUES (N'Profiles.Edit.Utilities.DataIO.UpdateSecuritySetting', N'http://vivoweb.org/ontology/core#educationalTraining', N'made education and training public')
GO
INSERT [Display.].[Activity.Log.MethodDetails] ([methodName], [Property], [label]) VALUES (N'Profiles.Edit.Utilities.DataIO.UpdateSecuritySetting', N'http://vivoweb.org/ontology/core#freetextKeyword', N'made keywords public')
GO
INSERT [Display.].[Activity.Log.MethodDetails] ([methodName], [Property], [label]) VALUES (N'Profiles.Edit.Utilities.DataIO.UpdateSecuritySetting', N'http://vivoweb.org/ontology/core#hasMemberRole', N'made group membership public')
GO
INSERT [Display.].[Activity.Log.MethodDetails] ([methodName], [Property], [label]) VALUES (N'Profiles.Edit.Utilities.DataIO.UpdateSecuritySetting', N'http://vivoweb.org/ontology/core#hasResearcherRole', N'made research activity or funding public')
GO
INSERT [Display.].[Activity.Log.MethodDetails] ([methodName], [Property], [label]) VALUES (N'Profiles.Edit.Utilities.DataIO.UpdateSecuritySetting', N'http://vivoweb.org/ontology/core#orcidId', N'made their ORCID public')
GO
INSERT [Display.].[Activity.Log.MethodDetails] ([methodName], [Property], [label]) VALUES (N'Profiles.Edit.Utilities.DataIO.UpdateSecuritySetting', N'http://vivoweb.org/ontology/core#overview', N'made their overview public')
GO
INSERT [Display.].[Activity.Log.MethodDetails] ([methodName], [Property], [label]) VALUES (N'Profiles.Edit.Utilities.DataIO.UpdateSecuritySetting', N'http://vivoweb.org/ontology/core#webpage', N'made websites public')
GO
INSERT [Display.].[Activity.Log.MethodDetails] ([methodName], [Property], [label]) VALUES (N'Profiles.Edit.Utilities.DataIO.UpdateSecuritySetting', N'http://vivoweb.org/ontology/core#freetextKeyword', N'made keywords public')
GO
INSERT [Display.].[Activity.Log.MethodDetails] ([methodName], [Property], [label]) VALUES (N'Profiles.Edit.Utilities.DataIO.UpdateSecuritySetting', N'http://orng.info/ontology/orng#hasYouTube', N'made featured videos public')
GO


INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://www.w3.org/2000/01/rdf-schema#label', 0, N'Person.GeneralInfo', N'[Display.Module].[Person.GeneralInfo]', N'data', 1, NULL, NULL, NULL, NULL, 0, 1, N'P', N'http://xmlns.com/foaf/0.1/Person', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://vivoweb.org/ontology/core#authorInAuthorship', 0, N'Person.AuthorInAuthorship', N'[Display.Module].[Person.AuthorInAuthorship]', N'data', 1, N'Bibliographic', N'selected publications', NULL, N'main', 81, 0, N'P', N'http://xmlns.com/foaf/0.1/Person', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://vivoweb.org/ontology/core#overview', 0, N'Person.Overview', N'[Display.Module].[Literal]', N'data', 1, N'Overview', N'overview', NULL, N'main', 41, 0, N'P', N'http://xmlns.com/foaf/0.1/Person', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://profiles.catalyst.harvard.edu/ontology/prns#coAuthorOf', 0, N'Person.CoAuthors', N'[Display.Module].[Person.Coauthor.Top5]', N'pNetworks', 1, NULL, N'Co-Authors', N'People in Profiles who have published with this person', N'RHS', 2, 0, N'P', N'http://xmlns.com/foaf/0.1/Person', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://vivoweb.org/ontology/core#freetextKeyword', 0, N'Person.FreetextKeyword', N'[Display.Module].[Person.FreetextKeyword]', N'data', 1, N'Overview', N'keywords', NULL, N'main', 42, 0, N'P', N'http://xmlns.com/foaf/0.1/Person', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://profiles.catalyst.harvard.edu/ontology/prns#similarTo', 0, N'Person.Similar', N'[Display.Module].[Person.Similar.Top5]', N'pNetworks', 1, NULL, N'Similar People', N'People who share similar concepts with this person', N'RHS', 3, 0, N'P', N'http://xmlns.com/foaf/0.1/Person', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://vivoweb.org/ontology/core#hasResearchArea', 0, N'Person.Concept', N'[Display.Module].[Person.Concept.Top5]', N'pNetworks', 1, NULL, N'Concepts', N'Derived automatically from this person''s publications', N'RHS', 1, 0, N'P', N'http://xmlns.com/foaf/0.1/Person', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://vivoweb.org/ontology/core#webpage', 0, N'Person.Websites', N'[Display.Module].[Person.Websites]', N'data', 1, N'Overview', N'webpage', NULL, N'main', 43, 0, N'P', N'http://xmlns.com/foaf/0.1/Person', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://profiles.catalyst.harvard.edu/ontology/prns#mediaLinks', 0, N'Person.MediaLinks', N'[Display.Module].[Person.MediaLinks]', N'data', 1, N'Overview', N'media links', NULL, N'main', 44, 0, N'P', N'http://xmlns.com/foaf/0.1/Person', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://vivoweb.org/ontology/core#educationalTraining', 0, N'Person.EducationAndTraining', N'[Display.Module].[Person.EducationAndTraining]', N'data', 1, N'Biography', N'education and training', NULL, N'main', 31, 0, N'P', N'http://xmlns.com/foaf/0.1/Person', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://vivoweb.org/ontology/core#awardOrHonor', 0, N'Person.AwardOrHonor', N'[Display.Module].[Person.AwardOrHonor]', N'data', 1, N'Biography', N'awards and honors', NULL, N'main', 32, 0, N'P', N'http://xmlns.com/foaf/0.1/Person', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://vivoweb.org/ontology/core#hasResearcherRole', 0, N'Person.ResearcherRole', N'[Display.Module].[Person.ResearcherRole]', N'data', 1, N'Research', N'research activities and funding', NULL, N'main', 61, 0, N'P', N'http://xmlns.com/foaf/0.1/Person', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://profiles.catalyst.harvard.edu/ontology/prns#hasClinicalTrialRole', 0, N'Person.ClinicalTrialRole', N'[Display.Module].[Person.ClinicalTrialRole]', N'data', 1, N'Research', N'clinical trials', NULL, N'main', 62, 0, N'P', N'http://xmlns.com/foaf/0.1/Person', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://profiles.catalyst.harvard.edu/ontology/plugins#FeaturedPresentations', 0, N'Person.FeaturedPresentations', N'[Display.Module].[GenericRDF.FeaturedPresentations]', N'data', 1, N'Featured Content', N'featured presentations', NULL, N'main', 71, 0, N'P', N'http://xmlns.com/foaf/0.1/Person', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://profiles.catalyst.harvard.edu/ontology/plugins#FeaturedVideos', 0, N'Person.FeaturedVideos', N'[Display.Module].[GenericRDF.FeaturedVideos]', N'data', 1, N'Featured Content', N'featured videos', NULL, N'main', 72, 0, N'P', N'http://xmlns.com/foaf/0.1/Person', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://profiles.catalyst.harvard.edu/ontology/plugins#Twitter', 0, N'Person.Twitter', N'[Display.Module].[GenericRDF.Twitter]', N'data', 1, N'Featured Content', N'twitter', NULL, N'main', 73, 0, N'P', N'http://xmlns.com/foaf/0.1/Person', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://profiles.catalyst.harvard.edu/ontology/prns#hasConnection', 0, N'Coauthor.Connection', N'[Display.Module].[Coauthor.Connection]', N'data', 0, NULL, NULL, NULL, NULL, NULL, 0, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://profiles.catalyst.harvard.edu/ontology/prns#coAuthorOf', NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://profiles.catalyst.harvard.edu/ontology/prns#connectionWeight', 0, N'Connection', N'[Display.Module].[Connection]', NULL, 0, NULL, NULL, NULL, NULL, NULL, 0, N'C', NULL, NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://profiles.catalyst.harvard.edu/ontology/prns#connectionWeight', 0, N'Person.HasCoAuthor.Why', N'[Display.Module].[Person.HasCoAuthor.Why]', N'data', 0, NULL, NULL, NULL, NULL, NULL, 0, N'C', N'http://xmlns.com/foaf/0.1/Person', N'http://profiles.catalyst.harvard.edu/ontology/prns#coAuthorOf', N'http://xmlns.com/foaf/0.1/Person')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://profiles.catalyst.harvard.edu/ontology/prns#connectionWeight', 0, N'Person.Similar.Why', N'[Display.Module].[Person.Similar.Why]', N'data', 0, NULL, NULL, NULL, NULL, NULL, 0, N'C', N'http://xmlns.com/foaf/0.1/Person', N'http://profiles.catalyst.harvard.edu/ontology/prns#similarTo', N'http://xmlns.com/foaf/0.1/Person')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://profiles.catalyst.harvard.edu/ontology/prns#connectionWeight', 0, N'Person.HasResearchArea.Why', N'[Display.Module].[Person.HasResearchArea.Why]', N'data', 0, NULL, NULL, NULL, NULL, NULL, 0, N'C', N'http://xmlns.com/foaf/0.1/Person', N'http://vivoweb.org/ontology/core#hasResearchArea', N'http://www.w3.org/2004/02/skos/core#Concept')
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, NULL, null, N'NetworkList', N'[Display.Module].[NetworkList]', NULL, 0, NULL, NULL, NULL, NULL, NULL, 0, N'N', NULL, NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, NULL, null, N'NetworkList', N'[Display.Module].[NetworkList]', NULL, 0, NULL, NULL, NULL, NULL, NULL, 0, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://profiles.catalyst.harvard.edu/ontology/prns#coAuthorOf', NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, NULL, null, N'NetworkList', N'[Display.Module].[NetworkList]', NULL, 0, NULL, NULL, NULL, NULL, NULL, 0, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://profiles.catalyst.harvard.edu/ontology/prns#similarTo', NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, NULL, null, N'NetworkList', N'[Display.Module].[NetworkList]', NULL, 0, NULL, NULL, NULL, NULL, NULL, 0, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://vivoweb.org/ontology/core#hasResearchArea', NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://vivoweb.org/ontology/core#hasMemberRole', 0, N'Person.HasMemberRole', N'[Display.Module].[Person.HasMemberRole]', N'data', 1, N'Affiliation', N'groups', NULL, N'main', 21, 0, N'P', N'http://xmlns.com/foaf/0.1/Person', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, NULL, null, N'Coauthor.Map', N'[Display.Module].[CoauthorSimilar.Map]', N'map', 0, NULL, NULL, NULL, NULL, NULL, 0, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://profiles.catalyst.harvard.edu/ontology/prns#coAuthorOf', NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, NULL, null, N'Coauthor.Cluster', N'[Display.Module].[Coauthor.Cluster]', N'radial', 0, NULL, NULL, NULL, NULL, NULL, 0, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://profiles.catalyst.harvard.edu/ontology/prns#coAuthorOf', NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, NULL, null, N'Coauthor.Cluster', N'[Display.Module].[Coauthor.Cluster]', N'cluster', 0, NULL, NULL, NULL, NULL, NULL, 0, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://profiles.catalyst.harvard.edu/ontology/prns#coAuthorOf', NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, NULL, null, N'Coauthor.Timeline', N'[Display.Module].[Coauthor.Timeline]', N'timeline', 0, NULL, NULL, NULL, NULL, NULL, 0, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://profiles.catalyst.harvard.edu/ontology/prns#coAuthorOf', NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, NULL, null, N'SimilarPeople.Connection', N'[Display.Module].[SimilarPeople.Connection]', N'list', 0, NULL, NULL, NULL, NULL, NULL, 0, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://profiles.catalyst.harvard.edu/ontology/prns#similarTo', NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, NULL, null, N'CoauthorSimilar.Map', N'[Display.Module].[CoauthorSimilar.Map]', N'map', 0, NULL, NULL, NULL, NULL, NULL, 0, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://profiles.catalyst.harvard.edu/ontology/prns#similarTo', NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, NULL, null, N'SimilarPeople.Connection', N'[Display.Module].[SimilarPeople.Connection]', N'details', 0, NULL, NULL, NULL, NULL, NULL, 0, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://profiles.catalyst.harvard.edu/ontology/prns#similarTo', NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, NULL, null, N'Person.HasResearchArea', N'[Display.Module].[Person.HasResearchArea]', N'cloud', 0, NULL, NULL, NULL, NULL, NULL, 0, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://vivoweb.org/ontology/core#hasResearchArea', NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, NULL, null, N'NetworkList', N'[Display.Module].[NetworkList]', N'categories', 0, NULL, NULL, NULL, NULL, NULL, 0, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://vivoweb.org/ontology/core#hasResearchArea', NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, NULL, null, N'Person.HasResearchArea.Timeline', N'[Display.Module].[Person.HasResearchArea.Timeline]', N'timeline', 0, NULL, NULL, NULL, NULL, NULL, 0, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://vivoweb.org/ontology/core#hasResearchArea', NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, NULL, null, N'NetworkList', N'[Display.Module].[NetworkList]', N'details', 0, NULL, NULL, NULL, NULL, NULL, 0, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://vivoweb.org/ontology/core#hasResearchArea', NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://www.w3.org/2000/01/rdf-schema#label', 0, N'Profile', N'[Display.Module].[Profile]', NULL, 1, NULL, NULL, NULL, NULL, NULL, 1, N'P', NULL, NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, NULL, NULL, N'Concept.SimilarConcept', N'[Display.Module].[Concept.SimilarConcept]', N'data', 1, NULL, NULL, NULL, NULL, NULL, 0, N'P', N'http://www.w3.org/2004/02/skos/core#Concept', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://www.w3.org/2000/01/rdf-schema#label', 0, N'Concept.GeneralInfo', N'[Display.Module].[Concept.GeneralInfo]', N'data', 1, NULL, NULL, NULL, NULL, NULL, 1, N'P', N'http://www.w3.org/2004/02/skos/core#Concept', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://www.w3.org/2000/01/rdf-schema#label', 0, N'Profile', N'[Display.Module].[Profile]', NULL, 1, NULL, NULL, NULL, NULL, NULL, 1, N'P', N'http://profiles.catalyst.harvard.edu/ontology/catalyst#MentoringCurrentStudentOpportunity', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://www.w3.org/2000/01/rdf-schema#label', 0, N'Profile', N'[Display.Module].[Profile]', NULL, 1, NULL, NULL, NULL, NULL, NULL, 1, N'P', N'http://profiles.catalyst.harvard.edu/ontology/catalyst#MentoringCompletedStudentProject', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://www.w3.org/2000/01/rdf-schema#label', 0, N'Profile', N'[Display.Module].[Profile]', NULL, 1, NULL, NULL, NULL, NULL, NULL, 1, N'P', N'http://vivoweb.org/ontology/core#AwardReceipt', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://www.w3.org/2000/01/rdf-schema#label', 0, N'Group.Label', N'[Display.Module].[Group.Label]', NULL, 1, NULL, NULL, NULL, NULL, NULL, 1, N'P', N'http://xmlns.com/foaf/0.1/Group', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://www.w3.org/2000/01/rdf-schema#label', 0, N'Person.Label', N'[Display.Module].[Person.Label]', N'pNetworks', 1, NULL, NULL, NULL, NULL, 0, 1, N'P', N'http://xmlns.com/foaf/0.1/Person', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://www.w3.org/2000/01/rdf-schema#label', 0, N'Publication.GeneralInfo', N'[Display.Module].[Publication.GeneralInfo]', N'data', 1, NULL, NULL, NULL, NULL, NULL, 1, N'P', N'http://vivoweb.org/ontology/core#InformationResource', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://vivoweb.org/ontology/core#hasSubjectArea', 0, N'Publication.Concepts', N'[Display.Module].[Publication.Concepts]', N'data', 0, NULL, NULL, NULL, NULL, NULL, 0, N'P', N'http://vivoweb.org/ontology/core#InformationResource', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://vivoweb.org/ontology/core#informationResourceInAuthorship', 0, N'Publication.Authors', N'[Display.Module].[Publication.Authors]', N'data', 0, NULL, NULL, NULL, NULL, NULL, 0, N'P', N'http://vivoweb.org/ontology/core#InformationResource', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, NULL, null, N'Concept.Publications', N'[Display.Module].[Concept.Publications]', N'data', 1, NULL, NULL, NULL, NULL, NULL, 0, N'P', N'http://www.w3.org/2004/02/skos/core#Concept', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, NULL, NULL, N'Concept.TopPeople', N'[Display.Module].[Concept.TopPeople]', N'data', 1, NULL, NULL, NULL, NULL, NULL, 0, N'P', N'http://www.w3.org/2004/02/skos/core#Concept', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, NULL, NULL, N'Concept.TopJournals', N'[Display.Module].[Concept.TopJournals]', N'data', 1, NULL, NULL, NULL, NULL, NULL, 0, N'P', N'http://www.w3.org/2004/02/skos/core#Concept', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, NULL, NULL, N'Concept.TopPeople', N'[Display.Module].[Concept.TopPeople]', N'data', 1, NULL, NULL, NULL, NULL, NULL, 0, N'P', N'http://www.w3.org/2004/02/skos/core#Concept', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, NULL, NULL, N'Concept.TopJournals', N'[Display.Module].[Concept.TopJournals]', N'data', 1, NULL, NULL, NULL, NULL, NULL, 0, N'P', N'http://www.w3.org/2004/02/skos/core#Concept', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://www.w3.org/2000/01/rdf-schema#label', 0, N'Group.Label', N'[Display.Module].[Group.Label]', N'data', 1, NULL, NULL, NULL, NULL, NULL, 1, N'P', N'http://xmlns.com/foaf/0.1/Group', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://vivoweb.org/ontology/core#contactInformation', 0, N'Group.ContactInformation', N'[Display.Module].[Group.ContactInformation]', N'data', 1, NULL, NULL, NULL, NULL, NULL, 0, N'P', N'http://xmlns.com/foaf/0.1/Group', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://vivoweb.org/ontology/core#webpage', 0, N'Group.Webpage', N'[Display.Module].[Group.Webpage]', N'data', 1, NULL, NULL, NULL, NULL, NULL, 0, N'P', N'http://xmlns.com/foaf/0.1/Group', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://vivoweb.org/ontology/core#contributingRole', 0, N'Group.ContributingRole', N'[Display.Module].[Group.ContributingRole]', N'data', 1, NULL, NULL, NULL, NULL, NULL, 0, N'P', N'http://xmlns.com/foaf/0.1/Group', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://profiles.catalyst.harvard.edu/ontology/prns#associatedInformationResource', 0, N'Group.AssociatedInformationResource', N'[Display.Module].[Group.AssociatedInformationResource]', N'data', 1, NULL, NULL, NULL, NULL, NULL, 0, N'P', N'http://xmlns.com/foaf/0.1/Group', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://profiles.catalyst.harvard.edu/ontology/prns#mainImage', 0, N'Group.MainImage', N'[Display.Module].[Group.MainImage]', N'data', 1, NULL, NULL, NULL, NULL, NULL, 0, N'P', N'http://xmlns.com/foaf/0.1/Group', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://profiles.catalyst.harvard.edu/ontology/prns#welcome', 0, N'Group.Welcome', N'[Display.Module].[Group.Welcome]', N'data', 1, NULL, NULL, NULL, NULL, NULL, 0, N'P', N'http://xmlns.com/foaf/0.1/Group', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://profiles.catalyst.harvard.edu/ontology/plugins#FeaturedVideos', 0, N'Group.FeaturedVideos', N'[Display.Module].[GenericRDF.FeaturedVideos]', N'data', 1, NULL, NULL, NULL, NULL, NULL, 0, N'P', N'http://xmlns.com/foaf/0.1/Group', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://profiles.catalyst.harvard.edu/ontology/plugins#Twitter', 0, N'Group.Twitter', N'[Display.Module].[GenericRDF.Twitter]', N'data', 1, NULL, NULL, NULL, NULL, NULL, 0, N'P', N'http://xmlns.com/foaf/0.1/Group', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://profiles.catalyst.harvard.edu/ontology/plugins#FeaturedPresentations', 0, N'Group.FeaturedPresentations', N'[Display.Module].[GenericRDF.FeaturedPresentations]', N'data', 1, NULL, NULL, NULL, NULL, NULL, 0, N'P', N'http://xmlns.com/foaf/0.1/Group', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://profiles.catalyst.harvard.edu/ontology/prns#mediaLinks', 0, N'Group.MediaLinks', N'[Display.Module].[Group.MediaLinks]', N'data', 1, NULL, NULL, NULL, NULL, NULL, 0, N'P', N'http://xmlns.com/foaf/0.1/Group', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://profiles.catalyst.harvard.edu/ontology/prns#aboutUs', 0, N'Group.AboutUs', N'[Display.Module].[Group.AboutUs]', N'data', 1, NULL, NULL, NULL, NULL, NULL, 0, N'P', N'http://xmlns.com/foaf/0.1/Group', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://vivoweb.org/ontology/core#overview', 0, N'Group.Overview', N'[Display.Module].[Group.Overview]', N'data', 1, NULL, NULL, NULL, NULL, NULL, 0, N'P', N'http://xmlns.com/foaf/0.1/Group', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://vivoweb.org/ontology/core#authorInAuthorship', 0, N'Person.AuthorInAuthorship', N'[Display.Module].[Person.AuthorInAuthorship.Oldest]', N'PubsOldest', 0, NULL, NULL, NULL, NULL, NULL, 0, N'P', N'http://xmlns.com/foaf/0.1/Person', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://vivoweb.org/ontology/core#authorInAuthorship', 0, N'Person.AuthorInAuthorship', N'[Display.Module].[Person.AuthorInAuthorship.Cited]', N'pubsCited', 0, NULL, NULL, NULL, NULL, NULL, 0, N'P', N'http://xmlns.com/foaf/0.1/Person', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://vivoweb.org/ontology/core#authorInAuthorship', 0, N'Person.AuthorInAuthorship', N'[Display.Module].[Person.AuthorInAuthorship.Discussed]', N'pubsDiscussed', 0, NULL, NULL, NULL, NULL, NULL, 0, N'P', N'http://xmlns.com/foaf/0.1/Person', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://vivoweb.org/ontology/core#authorInAuthorship', 0, N'Person.AuthorInAuthorship', N'[Display.Module].[Person.AuthorInAuthorship.All]', N'pubsAll', 0, NULL, NULL, NULL, NULL, NULL, 0, N'P', N'http://xmlns.com/foaf/0.1/Person', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://profiles.catalyst.harvard.edu/ontology/prns#associatedInformationResource', 936, N'Group.AssociatedInformationResource', N'[Display.Module].[Group.AssociatedInformationResource.Oldest]', N'PubsOldest', 0, NULL, NULL, NULL, NULL, NULL, 0, N'P', N'http://xmlns.com/foaf/0.1/Group', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://profiles.catalyst.harvard.edu/ontology/prns#associatedInformationResource', 0, N'Group.AssociatedInformationResource', N'[Display.Module].[Group.AssociatedInformationResource.Cited]', N'pubsCited', 0, NULL, NULL, NULL, NULL, NULL, 0, N'P', N'http://xmlns.com/foaf/0.1/Group', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://profiles.catalyst.harvard.edu/ontology/prns#associatedInformationResource', 0, N'Group.AssociatedInformationResource', N'[Display.Module].[Group.AssociatedInformationResource.Discussed]', N'pubsDiscussed', 0, NULL, NULL, NULL, NULL, NULL, 0, N'P', N'http://xmlns.com/foaf/0.1/Group', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://profiles.catalyst.harvard.edu/ontology/prns#associatedInformationResource', 0, N'Group.AssociatedInformationResource', N'[Display.Module].[Group.AssociatedInformationResource.All]', N'pubsAll', 0, NULL, NULL, NULL, NULL, NULL, 0, N'P', N'http://xmlns.com/foaf/0.1/Group', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://profiles.catalyst.harvard.edu/ontology/prns#hasConnection', 0, N'Group.Cluster', N'[Display.Module].[Group.Cluster]', N'coauthors', 0, NULL, NULL, NULL, NULL, NULL, 0, N'N', N'http://xmlns.com/foaf/0.1/Group', N'http://vivoweb.org/ontology/core#contributingRole', NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://profiles.catalyst.harvard.edu/ontology/prns#hasConnection', 0, N'Group.Map', N'[Display.Module].[CoauthorSimilar.Map]', N'map', 0, NULL, NULL, NULL, NULL, NULL, 0, N'N', N'http://xmlns.com/foaf/0.1/Group', N'http://vivoweb.org/ontology/core#contributingRole', NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://www.w3.org/2000/01/rdf-schema#label', 0, N'Group.Label', N'[Display.Module].[Group.Label]', N'coauthors', 1, NULL, NULL, NULL, NULL, NULL, 1, N'N', N'http://xmlns.com/foaf/0.1/Group', N'http://vivoweb.org/ontology/core#contributingRole', NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://www.w3.org/2000/01/rdf-schema#label', 0, N'Group.Label', N'[Display.Module].[Group.Label]', N'map', 1, NULL, NULL, NULL, NULL, NULL, 1, N'N', N'http://xmlns.com/foaf/0.1/Group', N'http://vivoweb.org/ontology/core#contributingRole', NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://profiles.catalyst.harvard.edu/ontology/prns#physicalNeighborOf', 0, N'Person.PhysicalNeighbour.Top5', N'[Display.Module].[Person.PhysicalNeighbour.Top5]', N'pNetworks', 1, NULL, N'Physical Neighbors', N'People whose addresses are nearby this person', N'RHS', 5, 0, N'P', N'http://xmlns.com/foaf/0.1/Person', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://profiles.catalyst.harvard.edu/ontology/prns#personInPrimaryPosition', 0, N'Person.SameDepartment.Top5', N'[Display.Module].[Person.SameDepartment.Top5]', N'pNetworks', 1, NULL, N'Same Department', N'People in same department with this person', N'RHS', 4, 0, N'P', N'http://xmlns.com/foaf/0.1/Person', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, NULL, NULL, N'AwardReceipt.GeneralInfo', N'[Display.Module].[AwardReceipt.GeneralInfo]', N'data', 0, NULL, NULL, NULL, NULL, NULL, 0, N'P', N'http://vivoweb.org/ontology/core#AwardReceipt', NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, NULL, NULL, N'GenericPropertyList', N'[Display.Module].[GenericPropertyList]', N'data', 0, NULL, NULL, NULL, NULL, NULL, 0, N'P', NULL, NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, NULL, NULL, N'GenericPropertyList', N'[Display.Module].[GenericPropertyList]', N'data', 0, NULL, NULL, NULL, NULL, NULL, 0, N'N', NULL, NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, NULL, NULL, N'GenericPropertyList', N'[Display.Module].[GenericPropertyList]', N'data', 0, NULL, NULL, NULL, NULL, NULL, 0, N'C', NULL, NULL, NULL)
GO
INSERT [Display.].[ModuleMapping] ([PresentationID], [ClassProperty], [_ClassPropertyID], [DisplayModule], [DataStoredProc], [Tab], [LayoutModule], [GroupLabel], [PropertyLabel], [ToolTip], [Panel], [SortOrder], [LayoutDataModule], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (0, N'http://www.w3.org/1999/02/22-rdf-syntax-ns#type', 0, N'Preload.Label', N'[Display.Module].[Concept.PreloadLabel]', N'data', 1, NULL, NULL, NULL, NULL, NULL, 1, N'P', N'http://www.w3.org/2004/02/skos/core#Concept', NULL, NULL)
GO



INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-1, N'', 1, 1, 0, 0, N'data', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 0, N'P', NULL, NULL, NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-2, N'', 1, 1, 1, 0, N'data', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 0, N'N', NULL, NULL, NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-3, N'', 1, 1, 1, 1, N'data', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 0, N'C', NULL, NULL, NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-4, N'', 1, 1, 0, 0, N'data', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 1, N'P', N'http://www.w3.org/2004/02/skos/core#Concept', NULL, NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-5, N'', 1, 1, 0, 0, N'pNetworks', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 1, N'P', N'http://xmlns.com/foaf/0.1/Person', NULL, NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-6, N'', 2, 1, 0, 0, N'data', N'Session', N'EDITABLE_PAGE_CACHE_EXPIRE', 1, N'P', N'http://xmlns.com/foaf/0.1/Person', NULL, NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-7, N'pubsAll', 1, 1, 0, 0, N'pubsAll', N'Session', N'EDITABLE_PAGE_CACHE_EXPIRE', 1, N'P', N'http://xmlns.com/foaf/0.1/Person', NULL, NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-8, N'pubsCited', 1, 1, 0, 0, N'pubsCited', N'Session', N'EDITABLE_PAGE_CACHE_EXPIRE', 1, N'P', N'http://xmlns.com/foaf/0.1/Person', NULL, NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-9, N'pubsDiscussed', 1, 1, 0, 0, N'pubsDiscussed', N'Session', N'EDITABLE_PAGE_CACHE_EXPIRE', 1, N'P', N'http://xmlns.com/foaf/0.1/Person', NULL, NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-10, N'pubsOldest', 1, 1, 0, 0, N'pubsOldest', N'Session', N'EDITABLE_PAGE_CACHE_EXPIRE', 1, N'P', N'http://xmlns.com/foaf/0.1/Person', NULL, NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-11, N'', 1, 1, 0, 0, N'pNetworks', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 1, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://profiles.catalyst.harvard.edu/ontology/prns#coAuthorOf', NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-12, N'', 2, 1, 1, 0, N'data', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 1, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://profiles.catalyst.harvard.edu/ontology/prns#coAuthorOf', NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-13, N'Cluster', 1, 1, 0, 0, N'pNetworks', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 1, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://profiles.catalyst.harvard.edu/ontology/prns#coAuthorOf', NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-14, N'Cluster', 2, 1, 1, 0, N'Cluster', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 1, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://profiles.catalyst.harvard.edu/ontology/prns#coAuthorOf', NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-15, N'Details', 1, 1, 0, 0, N'pNetworks', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 1, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://profiles.catalyst.harvard.edu/ontology/prns#coAuthorOf', NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-16, N'Details', 2, 1, 1, 0, N'data', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 1, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://profiles.catalyst.harvard.edu/ontology/prns#coAuthorOf', NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-17, N'map', 1, 1, 0, 0, N'pNetworks', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 1, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://profiles.catalyst.harvard.edu/ontology/prns#coAuthorOf', NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-18, N'map', 2, 1, 1, 0, N'map', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 1, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://profiles.catalyst.harvard.edu/ontology/prns#coAuthorOf', NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-19, N'Radial', 1, 1, 0, 0, N'pNetworks', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 1, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://profiles.catalyst.harvard.edu/ontology/prns#coAuthorOf', NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-20, N'Radial', 2, 1, 1, 0, N'Cluster', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 1, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://profiles.catalyst.harvard.edu/ontology/prns#coAuthorOf', NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-21, N'timeline', 1, 1, 0, 0, N'pNetworks', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 1, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://profiles.catalyst.harvard.edu/ontology/prns#coAuthorOf', NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-22, N'timeline', 2, 1, 1, 0, N'timeline', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 1, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://profiles.catalyst.harvard.edu/ontology/prns#coAuthorOf', NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-23, N'', 1, 1, 0, 0, N'pNetworks', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 1, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://profiles.catalyst.harvard.edu/ontology/prns#similarTo', NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-24, N'', 2, 1, 1, 0, N'list', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 1, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://profiles.catalyst.harvard.edu/ontology/prns#similarTo', NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-25, N'Details', 1, 1, 0, 0, N'pNetworks', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 1, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://profiles.catalyst.harvard.edu/ontology/prns#similarTo', NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-26, N'Details', 2, 1, 1, 0, N'list', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 1, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://profiles.catalyst.harvard.edu/ontology/prns#similarTo', NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-27, N'Map', 1, 1, 0, 0, N'pNetworks', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 1, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://profiles.catalyst.harvard.edu/ontology/prns#similarTo', NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-28, N'Map', 2, 1, 1, 0, N'map', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 1, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://profiles.catalyst.harvard.edu/ontology/prns#similarTo', NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-29, N'', 1, 1, 0, 0, N'pNetworks', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 1, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://vivoweb.org/ontology/core#hasResearchArea', NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-30, N'', 2, 1, 1, 0, N'cloud', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 1, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://vivoweb.org/ontology/core#hasResearchArea', NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-31, N'categories', 1, 1, 0, 0, N'pNetworks', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 1, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://vivoweb.org/ontology/core#hasResearchArea', NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-32, N'categories', 2, 1, 1, 0, N'cloud', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 1, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://vivoweb.org/ontology/core#hasResearchArea', NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-33, N'Cloud', 1, 1, 0, 0, N'pNetworks', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 1, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://vivoweb.org/ontology/core#hasResearchArea', NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-34, N'Cloud', 2, 1, 1, 0, N'cloud', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 1, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://vivoweb.org/ontology/core#hasResearchArea', NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-35, N'details', 1, 1, 0, 0, N'pNetworks', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 1, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://vivoweb.org/ontology/core#hasResearchArea', NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-36, N'details', 2, 1, 1, 0, N'cloud', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 1, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://vivoweb.org/ontology/core#hasResearchArea', NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-37, N'timeline', 1, 1, 0, 0, N'pNetworks', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 1, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://vivoweb.org/ontology/core#hasResearchArea', NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-38, N'timeline', 2, 1, 1, 0, N'timeline', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 1, N'N', N'http://xmlns.com/foaf/0.1/Person', N'http://vivoweb.org/ontology/core#hasResearchArea', NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-39, N'', 1, 1, 1, 1, N'data', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 0, N'C', N'http://xmlns.com/foaf/0.1/Person', N'http://profiles.catalyst.harvard.edu/ontology/prns#coAuthorOf', N'http://xmlns.com/foaf/0.1/Person')
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-40, N'', 1, 1, 1, 1, N'data', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 0, N'C', N'http://xmlns.com/foaf/0.1/Person', N'http://profiles.catalyst.harvard.edu/ontology/prns#similarTo', N'http://xmlns.com/foaf/0.1/Person')
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-41, N'', 1, 1, 1, 1, N'data', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 0, N'C', N'http://xmlns.com/foaf/0.1/Person', N'http://vivoweb.org/ontology/core#hasResearchArea', N'http://www.w3.org/2004/02/skos/core#Concept')
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-42, N'', 1, 1, 0, 0, N'data', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 0, N'P', N'http://vivoweb.org/ontology/core#InformationResource', NULL, NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-43, N'', 1, 1, 0, 0, N'data', N'Global', N'GENERATED_PAGE_CACHE_EXPIRE', 0, N'P', N'http://vivoweb.org/ontology/core#AwardReceipt', NULL, NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-44, N'', 1, 1, 0, 0, N'data', N'Session', N'EDITABLE_PAGE_CACHE_EXPIRE', 1, N'P', N'http://xmlns.com/foaf/0.1/Group', NULL, NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-45, N'pubsAll', 1, 1, 0, 0, N'pubsAll', N'Session', N'EDITABLE_PAGE_CACHE_EXPIRE', 1, N'P', N'http://xmlns.com/foaf/0.1/Group', NULL, NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-46, N'pubsCited', 1, 1, 0, 0, N'pubsCited', N'Session', N'EDITABLE_PAGE_CACHE_EXPIRE', 1, N'P', N'http://xmlns.com/foaf/0.1/Group', NULL, NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-47, N'pubsDiscussed', 1, 1, 0, 0, N'pubsDiscussed', N'Session', N'EDITABLE_PAGE_CACHE_EXPIRE', 1, N'P', N'http://xmlns.com/foaf/0.1/Group', NULL, NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-48, N'pubsOldest', 1, 1, 0, 0, N'pubsOldest', N'Session', N'EDITABLE_PAGE_CACHE_EXPIRE', 1, N'P', N'http://xmlns.com/foaf/0.1/Group', NULL, NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-49, N'', 1, 1, 0, 0, N'data', N'Session', N'GENERATED_PAGE_CACHE_EXPIRE', 1, N'N', N'http://xmlns.com/foaf/0.1/Group', N'http://vivoweb.org/ontology/core#contributingRole', NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-50, N'byname', 1, 1, 0, 0, N'data', N'Session', N'GENERATED_PAGE_CACHE_EXPIRE', 1, N'N', N'http://xmlns.com/foaf/0.1/Group', N'http://vivoweb.org/ontology/core#contributingRole', NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-51, N'byrole', 1, 1, 0, 0, N'data', N'Session', N'GENERATED_PAGE_CACHE_EXPIRE', 1, N'N', N'http://xmlns.com/foaf/0.1/Group', N'http://vivoweb.org/ontology/core#contributingRole', NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-52, N'coauthors', 1, 1, 1, 0, N'coauthors', N'Session', N'GENERATED_PAGE_CACHE_EXPIRE', 1, N'N', N'http://xmlns.com/foaf/0.1/Group', N'http://vivoweb.org/ontology/core#contributingRole', NULL)
GO
INSERT [Display.].[DataPath] ([PresentationID], [Tab], [Sort], [subject], [predicate], [object], [dataTab], [pageSecurityType], [cacheLength], [BotIndex], [PresentationType], [PresentationSubject], [PresentationPredicate], [PresentationObject]) 
VALUES (-53, N'map', 1, 1, 1, 0, N'map', N'Session', N'GENERATED_PAGE_CACHE_EXPIRE', 1, N'N', N'http://xmlns.com/foaf/0.1/Group', N'http://vivoweb.org/ontology/core#contributingRole', NULL)
GO


update a set a.PresentationID = b.PresentationID from [Display.].[DataPath] a join [Ontology.Presentation].[XML] b on a.PresentationType = b.Type and isnull(a.PresentationSubject, 'null') = isnull(b.Subject, 'null') and isnull(a.PresentationPredicate, 'null') = isnull(b.Predicate, 'null') and isnull(a.PresentationObject, 'null') = isnull(b.Object, 'null')
GO
update a set a.PresentationID = b.PresentationID from [Display.].[ModuleMapping] a join [Ontology.Presentation].[XML] b on a.PresentationType = b.Type and isnull(a.PresentationSubject, 'null') = isnull(b.Subject, 'null') and isnull(a.PresentationPredicate, 'null') = isnull(b.Predicate, 'null') and isnull(a.PresentationObject, 'null') = isnull(b.Object, 'null')
GO
update a set a._ClassPropertyID = b.NodeID from [Display.].[ModuleMapping] a join [RDF.].Node b on [RDF.].fnValueHash(null, null, ClassProperty) = ValueHash and a.ClassProperty is not null
GO


/**
*
* Update Preferred Paths for both People and Concepts
*
**/
exec [Profile.Cache].[Concept.UpdatePreferredPath]
GO

exec [Profile.Cache].[Person.UpdatePreferredPath]
GO


