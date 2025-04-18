/*
Run this script on:

        Profiles 3.2.0   -  This database will be modified

to synchronize it with:

        Profiles 4.0.0

You are recommended to back up your database before running this script

Details of which objects have changed can be found in the release notes.
If you have made changes to existing tables or stored procedures in profiles, you may need to merge changes individually. 


ALTERED TABLES:
[Profile.Cache].Person
[Profile.Data].[Publication.Group.MyPub.General]
[Profile.Data].[Publication.MyPub.General]
[Profile.Module].[GenericRDF.Plugins]
[RDF.].Alias
*/


ALTER TABLE [Profile.Cache].Person ADD NodeID BIGINT
ALTER TABLE [Profile.Cache].Person ADD PreferredPath VARCHAR(MAX)
ALTER TABLE [Profile.Cache].Person ADD defaultApplication VARCHAR(MAX)

ALTER TABLE [Profile.Data].[Publication.Group.MyPub.General] ADD DOI VARCHAR(100)

ALTER TABLE [Profile.Data].[Publication.MyPub.General] ADD DOI VARCHAR(100)

ALTER TABLE [Profile.Module].[GenericRDF.Plugins] ADD _PropertyNode BIGINT
ALTER TABLE [Profile.Module].[GenericRDF.Plugins] ADD dataType BIT


ALTER TABLE [RDF.].Alias ADD [DefaultApplication] VARCHAR (50) DEFAULT ('display') NOT NULL

ALTER TABLE [Profile.Data].[Publication.Pubmed.Bibliometrics] ADD [RelativeCitationRatio] FLOAT (53)

GO
PRINT N'Update complete.';


GO
