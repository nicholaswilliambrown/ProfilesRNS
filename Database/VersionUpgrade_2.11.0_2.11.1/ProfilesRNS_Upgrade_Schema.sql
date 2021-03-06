/*
Run this script on:

        Profiles 2.11.0   -  This database will be modified

to synchronize it with:

        Profiles 2.11.1

You are recommended to back up your database before running this script

Details of which objects have changed can be found in the release notes.
If you have made changes to existing tables or stored procedures in profiles, you may need to merge changes individually. 

*/


GO
PRINT N'Dropping [Direct.Framework].[AddLogIncoming]...';


GO
DROP PROCEDURE [Direct.Framework].[AddLogIncoming];


GO
PRINT N'Dropping [Direct.Framework].[AddLogOutgoing]...';


GO
DROP PROCEDURE [Direct.Framework].[AddLogOutgoing];


GO
PRINT N'Dropping [Direct.Framework].[UpdateLogOutgoing]...';


GO
DROP PROCEDURE [Direct.Framework].[UpdateLogOutgoing];


GO
PRINT N'Dropping [Profile.Data].[Group.GetPhotos]...';


GO
DROP PROCEDURE [Profile.Data].[Group.GetPhotos];


GO
PRINT N'Creating [Ontology.].[ClassPropertyCustom]...';


GO
CREATE TABLE [Ontology.].[ClassPropertyCustom] (
    [ClassPropertyCustomTypeID] INT           NOT NULL,
    [Class]                     VARCHAR (400) NOT NULL,
    [NetworkProperty]           VARCHAR (400) NULL,
    [Property]                  VARCHAR (400) NOT NULL,
    [IncludeProperty]           BIT           NULL,
    [Limit]                     INT           NULL,
    [IncludeNetwork]            BIT           NULL,
    [IncludeDescription]        BIT           NULL,
    [IsDetail]                  BIT           NULL,
    [_ClassPropertyID]          INT           NOT NULL,
    CONSTRAINT [PK_ClassPropertyCustom] PRIMARY KEY CLUSTERED ([ClassPropertyCustomTypeID] ASC, [_ClassPropertyID] ASC)
);


GO
PRINT N'Creating [Profile.Data].[UC_Department_DepartmentName]...';


GO
ALTER TABLE [Profile.Data].[Organization.Department]
    ADD CONSTRAINT [UC_Department_DepartmentName] UNIQUE NONCLUSTERED ([DepartmentName] ASC);


GO
PRINT N'Creating [Profile.Data].[UC_Division_DivisionName]...';


GO
ALTER TABLE [Profile.Data].[Organization.Division]
    ADD CONSTRAINT [UC_Division_DivisionName] UNIQUE NONCLUSTERED ([DivisionName] ASC);


GO
PRINT N'Creating [Profile.Data].[UC_Institution_InstitutionAbbreviation]...';


GO
ALTER TABLE [Profile.Data].[Organization.Institution]
    ADD CONSTRAINT [UC_Institution_InstitutionAbbreviation] UNIQUE NONCLUSTERED ([InstitutionAbbreviation] ASC);


GO
PRINT N'Creating [Profile.Data].[UC_Institution_InstitutionName]...';


GO
ALTER TABLE [Profile.Data].[Organization.Institution]
    ADD CONSTRAINT [UC_Institution_InstitutionName] UNIQUE NONCLUSTERED ([InstitutionName] ASC);


GO
PRINT N'Creating [Profile.Data].[UC_Person_InternalUserName]...';


GO
ALTER TABLE [Profile.Data].[Person]
    ADD CONSTRAINT [UC_Person_InternalUserName] UNIQUE NONCLUSTERED ([InternalUsername] ASC);


GO
PRINT N'Creating [Profile.Data].[UC_PrimaryAffiliation]...';


GO
ALTER TABLE [Profile.Data].[Person.Affiliation]
    ADD CONSTRAINT [UC_PrimaryAffiliation] UNIQUE NONCLUSTERED ([PersonID] ASC, [IsPrimary] ASC, [SortOrder] ASC);


GO
PRINT N'Creating [Profile.Data].[UC_FacultyRank_FacultyRank]...';


GO
ALTER TABLE [Profile.Data].[Person.FacultyRank]
    ADD CONSTRAINT [UC_FacultyRank_FacultyRank] UNIQUE NONCLUSTERED ([FacultyRank] ASC);


GO
PRINT N'Creating [Profile.Data].[UC_FacultyRank_FacultyRankSort]...';


GO
ALTER TABLE [Profile.Data].[Person.FacultyRank]
    ADD CONSTRAINT [UC_FacultyRank_FacultyRankSort] UNIQUE NONCLUSTERED ([FacultyRankSort] ASC);


GO
PRINT N'Creating [User.Account].[UC_User_InternalUserName]...';


GO
ALTER TABLE [User.Account].[User]
    ADD CONSTRAINT [UC_User_InternalUserName] UNIQUE NONCLUSTERED ([InternalUserName] ASC);


GO
PRINT N'Altering [Framework.].[CreateInstallData]...';


GO
ALTER procedure [Framework.].[CreateInstallData]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	declare @x xml

	select @x = (
		select
			(
				select
					--------------------------------------------------------
					-- [Framework.]
					--------------------------------------------------------
					(
						select	'[Framework.].[Parameter]' 'Table/@Name',
								(
									select	ParameterID 'ParameterID', 
											Value 'Value'
									from [Framework.].[Parameter]
									for xml path('Row'), type
								) 'Table'
						for xml path(''), type
					),
					(
						select	'[Framework.].[RestPath]' 'Table/@Name',
								(
									select	ApplicationName 'ApplicationName',
											Resolver 'Resolver'
									from [Framework.].[RestPath]
									for xml path('Row'), type
								) 'Table'
						for xml path(''), type
					),
					(
						select	'[Framework.].[Job]' 'Table/@Name',
								(
									select	JobGroup 'JobGroup',
											Step 'Step',
											IsActive 'IsActive',
											Script 'Script'
									from [Framework.].[Job]
									for xml path('Row'), type
								) 'Table'
						for xml path(''), type
					),
					(
						select	'[Framework.].[JobGroup]' 'Table/@Name',
								(
									SELECT  JobGroup 'JobGroup',
											Name 'Name',
											Type 'Type',
											Description 'Description'	
									from [Framework.].JobGroup
									for xml path('Row'), type
								) 'Table'
						for xml path(''), type
					),
					--------------------------------------------------------
					-- [Ontology.]
					--------------------------------------------------------
					(
						select	'[Ontology.].[ClassGroup]' 'Table/@Name',
								(
									select	ClassGroupURI 'ClassGroupURI',
											SortOrder 'SortOrder',
											IsVisible 'IsVisible'
									from [Ontology.].[ClassGroup]
									for xml path('Row'), type
								) 'Table'
						for xml path(''), type
					),
					(
						select	'[Ontology.].[ClassGroupClass]' 'Table/@Name',
								(
									select	ClassGroupURI 'ClassGroupURI',
											ClassURI 'ClassURI',
											SortOrder 'SortOrder'
									from [Ontology.].[ClassGroupClass]
									for xml path('Row'), type
								) 'Table'
						for xml path(''), type
					),
					(
						select	'[Ontology.].[ClassProperty]' 'Table/@Name',
								(
									select	Class 'Class',
											NetworkProperty 'NetworkProperty',
											Property 'Property',
											IsDetail 'IsDetail',
											Limit 'Limit',
											IncludeDescription 'IncludeDescription',
											IncludeNetwork 'IncludeNetwork',
											SearchWeight 'SearchWeight',
											CustomDisplay 'CustomDisplay',
											CustomEdit 'CustomEdit',
											ViewSecurityGroup 'ViewSecurityGroup',
											EditSecurityGroup 'EditSecurityGroup',
											EditPermissionsSecurityGroup 'EditPermissionsSecurityGroup',
											EditExistingSecurityGroup 'EditExistingSecurityGroup',
											EditAddNewSecurityGroup 'EditAddNewSecurityGroup',
											EditAddExistingSecurityGroup 'EditAddExistingSecurityGroup',
											EditDeleteSecurityGroup 'EditDeleteSecurityGroup',
											MinCardinality 'MinCardinality',
											MaxCardinality 'MaxCardinality',
											CustomDisplayModule 'CustomDisplayModule',
											CustomEditModule 'CustomEditModule'
									from [Ontology.].ClassProperty
									for xml path('Row'), type
								) 'Table'
						for xml path(''), type
					),
					(
						select	'[Ontology.].[ClassPropertyCustom]' 'Table/@Name',
								(
									select	
											ClassPropertyCustomTypeID 'ClassPropertyCustomTypeID',
											Class 'Class',
											NetworkProperty 'NetworkProperty',
											Property 'Property',
											IncludeProperty 'IncludeProperty',
											Limit 'Limit',
											IncludeNetwork 'IncludeNetwork',
											IncludeDescription 'IncludeDescription',
											IsDetail 'IsDetail'
									from [Ontology.].ClassPropertyCustom
									for xml path('Row'), type
								) 'Table'
						for xml path(''), type
					),
					(
						select	'[Ontology.].[DataMap]' 'Table/@Name',
						
								(
									select  DataMapGroup 'DataMapGroup',
											IsAutoFeed 'IsAutoFeed',
											Graph 'Graph',
											Class 'Class',
											NetworkProperty 'NetworkProperty',
											Property 'Property',
											MapTable 'MapTable',
											sInternalType 'sInternalType',
											sInternalID 'sInternalID',
											cClass 'cClass',
											cInternalType 'cInternalType',
											cInternalID 'cInternalID',
											oClass 'oClass',
											oInternalType 'oInternalType',
											oInternalID 'oInternalID',
											oValue 'oValue',
											oDataType 'oDataType',
											oLanguage 'oLanguage',
											oStartDate 'oStartDate',
											oStartDatePrecision 'oStartDatePrecision',
											oEndDate 'oEndDate',
											oEndDatePrecision 'oEndDatePrecision',
											oObjectType 'oObjectType',
											Weight 'Weight',
											OrderBy 'OrderBy',
											ViewSecurityGroup 'ViewSecurityGroup',
											EditSecurityGroup 'EditSecurityGroup'
									from [Ontology.].[DataMap]
									for xml path('Row'), type
								) 'Table'
						for xml path(''), type
					),
					(
						select	'[Ontology.].[Namespace]' 'Table/@Name',
								(
									select	URI 'URI',
											Prefix 'Prefix'
									from [Ontology.].[Namespace]
									for xml path('Row'), type
								) 'Table'
						for xml path(''), type
					),
					(
						select	'[Ontology.].[PropertyGroup]' 'Table/@Name',
								(
									select	PropertyGroupURI 'PropertyGroupURI',
											SortOrder 'SortOrder',
											_PropertyGroupLabel '_PropertyGroupLabel'
									from [Ontology.].[PropertyGroup]
									for xml path('Row'), type
								) 'Table'
						for xml path(''), type
					),
					(
						select	'[Ontology.].[PropertyGroupProperty]' 'Table/@Name',
								(
									select	PropertyGroupURI 'PropertyGroupURI',
											PropertyURI 'PropertyURI',
											SortOrder 'SortOrder',
											CustomDisplayModule 'CustomDisplayModule',
											CustomEditModule 'CustomEditModule',
											_TagName '_TagName',
											_PropertyLabel '_PropertyLabel'
									from [Ontology.].[PropertyGroupProperty]
									for xml path('Row'), type
								) 'Table'
						for xml path(''), type
					),
					--------------------------------------------------------
					-- [Ontology.Presentation]
					--------------------------------------------------------
					(
						select	'[Ontology.Presentation].[XML]' 'Table/@Name',
								(
									select	type 'type',
											subject 'subject',
											predicate 'predicate',
											object 'object',
											presentationXML 'presentationXML'
									from [Ontology.Presentation].[XML]
									for xml path('Row'), type
								) 'Table'
						for xml path(''), type
					),
					--------------------------------------------------------
					-- [RDF.Security]
					--------------------------------------------------------
					(
						select	'[RDF.Security].[Group]' 'Table/@Name',
								(
									select	SecurityGroupID 'SecurityGroupID',
											Label 'Label',
											HasSpecialViewAccess 'HasSpecialViewAccess',
											HasSpecialEditAccess 'HasSpecialEditAccess',
											Description 'Description'
									from [RDF.Security].[Group]
									for xml path('Row'), type
								) 'Table'
						for xml path(''), type
					),
					--------------------------------------------------------
					-- [Utility.NLP]
					--------------------------------------------------------
					(
						select	'[Utility.NLP].[ParsePorterStemming]' 'Table/@Name',
								(
									select	step 'Step',
											Ordering 'Ordering',
											phrase1 'phrase1',
											phrase2 'phrase2'
									from [Utility.NLP].ParsePorterStemming
									for xml path('Row'), type
								) 'Table'
						for xml path(''), type
					),
					(
						select	'[Utility.NLP].[StopWord]' 'Table/@Name',
								(
									select	word 'word',
											stem 'stem',
											scope 'scope'
									from [Utility.NLP].[StopWord]
									for xml path('Row'), type
								) 'Table'
						for xml path(''), type
					),
					(
						select	'[Utility.NLP].[Thesaurus.Source]' 'Table/@Name',
								(
									select	Source 'Source',
											SourceName 'SourceName'
									from [Utility.NLP].[Thesaurus.Source]
									for xml path('Row'), type
								) 'Table'
						for xml path(''), type
					),
					--------------------------------------------------------
					-- [User.Session]
					--------------------------------------------------------
					(
						select	'[User.Session].Bot' 'Table/@Name',
							(
								SELECT UserAgent 'UserAgent' 
								  FROM [User.Session].Bot
				  					for xml path('Row'), type
			   				) 'Table'  
						for xml path(''), type
					),
					--------------------------------------------------------
					-- [Direct.]
					--------------------------------------------------------
					(
						select	'[Direct.].[Sites]' 'Table/@Name',
							(
								SELECT SiteID 'SiteID',
										BootstrapURL 'BootstrapURL',
										SiteName 'SiteName',
										QueryURL 'QueryURL',
										SortOrder 'SortOrder',
										IsActive 'IsActive'  
								  FROM [Direct.].[Sites] 
			 					for xml path('Row'), type
					 		) 'Table'   
						for xml path(''), TYPE
					),
					--------------------------------------------------------
					-- [Profile.Data]
					--------------------------------------------------------
					(
						select	'[Profile.Data].[Publication.Type]' 'Table/@Name',
							(
								SELECT	pubidtype_id 'pubidtype_id',
										name 'name',
										sort_order 'sort_order'
								  FROM [Profile.Data].[Publication.Type]
				  					for xml path('Row'), type
			   				) 'Table'  
						for xml path(''), type
					),
					(
						select	'[Profile.Data].[Publication.MyPub.Category]' 'Table/@Name',
							(
								SELECT	HmsPubCategory 'HmsPubCategory',
										CategoryName 'CategoryName'
								  FROM [Profile.Data].[Publication.MyPub.Category]
				  					for xml path('Row'), type
							) 'Table'  
						for xml path(''), type
					),
					--------------------------------------------------------
					-- [ORCID.]
					--------------------------------------------------------
					(
						select '[ORCID.].[REF_Permission]' 'Table/@Name',
						(
							SELECT	PermissionScope 'PermissionScope', 
									PermissionDescription 'PermissionDescription', 
									MethodAndRequest 'MethodAndRequest',
									SuccessMessage 'SuccessMessage',
									FailedMessage 'FailedMessage'
								from [ORCID.].[REF_Permission]
									for xml path('Row'), type
						) 'Table'  
						for xml path(''), type
					),
					(
						select '[ORCID.].[REF_PersonStatusType]' 'Table/@Name',
						(
							SELECT	StatusDescription 'StatusDescription'
								from [ORCID.].[REF_PersonStatusType]
									for xml path('Row'), type
						) 'Table'  
						for xml path(''), type
					),
					(
						select '[ORCID.].[REF_WorkExternalType]' 'Table/@Name',
						(
							SELECT	WorkExternalType 'WorkExternalType',
									WorkExternalDescription 'WorkExternalDescription'
								from [ORCID.].[REF_WorkExternalType]
									for xml path('Row'), type
						) 'Table'  
						for xml path(''), type
					),
					(
						select '[ORCID.].[REF_RecordStatus]' 'Table/@Name',
						(
							SELECT	RecordStatusID 'RecordStatusID',
									StatusDescription, 'StatusDescription'
								from [ORCID.].[REF_RecordStatus]
									for xml path('Row'), type
						) 'Table'  
						for xml path(''), type
					),
					(
						select '[ORCID.].[REF_Decision]' 'Table/@Name',
						(
							SELECT	DecisionDescription 'DecisionDescription',
									DecisionDescriptionLong 'DecisionDescriptionLong'
								from [ORCID.].[REF_Decision]
									for xml path('Row'), type
						) 'Table'  
						for xml path(''), type
					),
					(
						select '[ORCID.].[RecordLevelAuditType]' 'Table/@Name',
						(
							SELECT	AuditType 'AuditType'
								from [ORCID.].[RecordLevelAuditType]
									for xml path('Row'), type
						) 'Table'  
						for xml path(''), type
					),
					(
						select '[ORCID.].[DefaultORCIDDecisionIDMapping]' 'Table/@Name',
						(
							SELECT	SecurityGroupID 'SecurityGroupID',
									DefaultORCIDDecisionID 'DefaultORCIDDecisionID'
								from [ORCID.].[DefaultORCIDDecisionIDMapping]
									for xml path('Row'), type
						) 'Table'  
						for xml path(''), type
					),
					--------------------------------------------------------
					-- [ORNG.]
					--------------------------------------------------------					
					(
						select '[ORNG.].[Apps]' 'Table/@Name',
						(
							SELECT	AppID 'AppID',
									Name 'Name',
									Url 'URL',
									PersonFilterID 'PersonFilterID',
									OAuthSecret 'OAuthSecret',
									[Enabled] 'Enabled'
								from [ORNG.].[Apps]
									for xml path('Row'), type
						) 'Table'  
						for xml path(''), type
					),
					(
						select '[ORNG.].[AppViews]' 'Table/@Name',
						(
							SELECT	[AppID] 'AppID',
									[Page] 'Page',
									[View] 'View',
									[ChromeID] 'ChromeID',
									[Visibility] 'Visibility',
									[DisplayOrder] 'DisplayOrder',
									[OptParams] 'OptParams'
								from [ORNG.].[AppViews]
									for xml path('Row'), type
						) 'Table'  
						for xml path(''), type
					)					
				for xml path(''), type
			) 'Import'
		for xml path(''), type
	)

	insert into [Framework.].[InstallData] (Data)
		select @x


   --Use to generate select lists for new tables
   --SELECT    c.name +  ' ''' + name + ''','
   --FROM sys.columns c  
   --WHERE object_id IN (SELECT object_id FROM sys.tables WHERE name = 'Publication.MyPub.Category')  

END
GO
PRINT N'Altering [Framework.].[LoadInstallData]...';


GO
ALTER procedure [Framework.].[LoadInstallData]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

 DECLARE @x XML
 SELECT @x = ( SELECT TOP 1
                        Data
               FROM     [Framework.].[InstallData]
               ORDER BY InstallDataID DESC
             ) 

---------------------------------------------------------------
-- [Utility.Math]
---------------------------------------------------------------


-- [Utility.Math].N
; WITH   E00 ( N )
          AS ( SELECT   1
               UNION ALL
               SELECT   1
             ),
        E02 ( N )
          AS ( SELECT   1
               FROM     E00 a ,
                        E00 b
             ),
        E04 ( N )
          AS ( SELECT   1
               FROM     E02 a ,
                        E02 b
             ),
        E08 ( N )
          AS ( SELECT   1
               FROM     E04 a ,
                        E04 b
             ),
        E16 ( N )
          AS ( SELECT   1
               FROM     E08 a ,
                        E08 b
             ),
        E32 ( N )
          AS ( SELECT   1
               FROM     E16 a ,
                        E16 b
             ),
        cteTally ( N )
          AS ( SELECT   ROW_NUMBER() OVER ( ORDER BY N )
               FROM     E32
             )
    
    INSERT INTO [Utility.Math].N
    SELECT  N -1
    FROM    cteTally
    WHERE   N <= 100000 ; 
			 
---------------------------------------------------------------
-- [Framework.]
---------------------------------------------------------------
 
             
-- [Framework.].[Parameter]
TRUNCATE TABLE [Framework.].[Parameter]
INSERT INTO [Framework.].Parameter
	( ParameterID, Value )        
SELECT	R.x.value('ParameterID[1]', 'varchar(max)') ,
		R.x.value('Value[1]', 'varchar(max)')
FROM    ( SELECT
			@x.query
			('Import[1]/Table[@Name=''[Framework.].[Parameter]'']')
			x
		) t
CROSS APPLY x.nodes('//Row') AS R ( x )

  
       
-- [Framework.].[RestPath] 
INSERT INTO [Framework.].RestPath
        ( ApplicationName, Resolver )   
SELECT  R.x.value('ApplicationName[1]', 'varchar(max)') ,
        R.x.value('Resolver[1]', 'varchar(max)') 
FROM    ( SELECT
                    @x.query
                    ('Import[1]/Table[@Name=''[Framework.].[RestPath]'']')
                    x
        ) t
CROSS APPLY x.nodes('//Row') AS R ( x )

   
--[Framework.].[Job]
INSERT INTO [Framework.].Job
        ( JobID,
		  JobGroup,
          Step,
          IsActive,
          Script
        ) 
SELECT	Row_Number() OVER (ORDER BY (SELECT 1)),
		R.x.value('JobGroup[1]','varchar(max)'),
		R.x.value('Step[1]','varchar(max)'),
		R.x.value('IsActive[1]','varchar(max)'),
		R.x.value('Script[1]','varchar(max)')
FROM    ( SELECT
                  @x.query
                  ('Import[1]/Table[@Name=''[Framework.].[Job]'']')
                  x
      ) t
CROSS APPLY x.nodes('//Row') AS R ( x )

	
--[Framework.].[JobGroup]
INSERT INTO [Framework.].JobGroup
        ( JobGroup, Name, Type, Description ) 
SELECT	R.x.value('JobGroup[1]','varchar(max)'),
		R.x.value('Name[1]','varchar(max)'),
		R.x.value('Type[1]','varchar(max)'),
		R.x.value('Description[1]','varchar(max)')
FROM    ( SELECT
                  @x.query
                  ('Import[1]/Table[@Name=''[Framework.].[JobGroup]'']')
                  x
      ) t
CROSS APPLY x.nodes('//Row') AS R ( x )
       
  

---------------------------------------------------------------
-- [Ontology.]
---------------------------------------------------------------
 
 --[Ontology.].[ClassGroup]
 TRUNCATE TABLE [Ontology.].[ClassGroup]
 INSERT INTO [Ontology.].ClassGroup
         ( ClassGroupURI,
           SortOrder,
           IsVisible
         )
  SELECT  R.x.value('ClassGroupURI[1]', 'varchar(max)') ,
          R.x.value('SortOrder[1]', 'varchar(max)'),
          R.x.value('IsVisible[1]', 'varchar(max)')
  FROM    ( SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[Ontology.].[ClassGroup]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x ) 
  
 --[Ontology.].[ClassGroupClass]
 TRUNCATE TABLE [Ontology.].[ClassGroupClass]
 INSERT INTO [Ontology.].ClassGroupClass
         ( ClassGroupURI,
           ClassURI,
           SortOrder
         )
  SELECT  R.x.value('ClassGroupURI[1]', 'varchar(max)') ,
          R.x.value('ClassURI[1]', 'varchar(max)'),
          R.x.value('SortOrder[1]', 'varchar(max)')
  FROM    ( SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[Ontology.].[ClassGroupClass]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )

  
--[Ontology.].[ClassProperty]
INSERT INTO [Ontology.].ClassProperty
        ( ClassPropertyID,
          Class,
          NetworkProperty,
          Property,
          IsDetail,
          Limit,
          IncludeDescription,
          IncludeNetwork,
          SearchWeight,
          CustomDisplay,
          CustomEdit,
          ViewSecurityGroup,
          EditSecurityGroup,
          EditPermissionsSecurityGroup,
          EditExistingSecurityGroup,
          EditAddNewSecurityGroup,
          EditAddExistingSecurityGroup,
          EditDeleteSecurityGroup,
          MinCardinality,
          MaxCardinality,
          CustomDisplayModule,
          CustomEditModule
        )
SELECT  Row_Number() OVER (ORDER BY (SELECT 1)),
		R.x.value('Class[1]','varchar(max)'),
		R.x.value('NetworkProperty[1]','varchar(max)'),
		R.x.value('Property[1]','varchar(max)'),
		R.x.value('IsDetail[1]','varchar(max)'),
		R.x.value('Limit[1]','varchar(max)'),
		R.x.value('IncludeDescription[1]','varchar(max)'),
		R.x.value('IncludeNetwork[1]','varchar(max)'),
		R.x.value('SearchWeight[1]','varchar(max)'),
		R.x.value('CustomDisplay[1]','varchar(max)'),
		R.x.value('CustomEdit[1]','varchar(max)'),
		R.x.value('ViewSecurityGroup[1]','varchar(max)'),
		R.x.value('EditSecurityGroup[1]','varchar(max)'),
		R.x.value('EditPermissionsSecurityGroup[1]','varchar(max)'),
		R.x.value('EditExistingSecurityGroup[1]','varchar(max)'),
		R.x.value('EditAddNewSecurityGroup[1]','varchar(max)'),
		R.x.value('EditAddExistingSecurityGroup[1]','varchar(max)'),
		R.x.value('EditDeleteSecurityGroup[1]','varchar(max)'),
		R.x.value('MinCardinality[1]','varchar(max)'),
		R.x.value('MaxCardinality[1]','varchar(max)'),
		(case when CAST(R.x.query('CustomDisplayModule[1]/*') AS NVARCHAR(MAX))<>'' then R.x.query('CustomDisplayModule[1]/*') else NULL end),
		(case when CAST(R.x.query('CustomEditModule[1]/*') AS NVARCHAR(MAX))<>'' then R.x.query('CustomEditModule[1]/*') else NULL end)
  FROM    ( SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[Ontology.].[ClassProperty]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )

  
    --[Ontology.].[ClassPropertyCustom]
  INSERT INTO [Ontology.].ClassPropertyCustom
        ( _ClassPropertyID,
		  ClassPropertyCustomTypeID,
          Class,
          NetworkProperty,
          Property,
		  IncludeProperty,
          IsDetail,
          Limit,
          IncludeDescription,
          IncludeNetwork
        )
  SELECT  Row_Number() OVER (ORDER BY (SELECT 1) + 1000),
		R.x.value('ClassPropertyCustomTypeID[1]','varchar(max)'),
		R.x.value('Class[1]','varchar(max)'),
		R.x.value('NetworkProperty[1]','varchar(max)'),
		R.x.value('Property[1]','varchar(max)'),
		R.x.value('IncludeProperty[1]','varchar(max)'),
		R.x.value('IsDetail[1]','varchar(max)'),
		R.x.value('Limit[1]','varchar(max)'),
		R.x.value('IncludeDescription[1]','varchar(max)'),
		R.x.value('IncludeNetwork[1]','varchar(max)')
  FROM    ( SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[Ontology.].[ClassPropertyCustom]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )
  
  
  --[Ontology.].[DataMap]
  TRUNCATE TABLE [Ontology.].DataMap
  INSERT INTO [Ontology.].DataMap
          ( DataMapID,
			DataMapGroup ,
            IsAutoFeed ,
            Graph ,
            Class ,
            NetworkProperty ,
            Property ,
            MapTable ,
            sInternalType ,
            sInternalID ,
            cClass ,
            cInternalType ,
            cInternalID ,
            oClass ,
            oInternalType ,
            oInternalID ,
            oValue ,
            oDataType ,
            oLanguage ,
            oStartDate ,
            oStartDatePrecision ,
            oEndDate ,
            oEndDatePrecision ,
            oObjectType ,
            Weight ,
            OrderBy ,
            ViewSecurityGroup ,
            EditSecurityGroup
          )
  SELECT    Row_Number() OVER (ORDER BY (SELECT 1)),
			R.x.value('DataMapGroup[1]','varchar(max)'),
			R.x.value('IsAutoFeed[1]','varchar(max)'),
			R.x.value('Graph[1]','varchar(max)'),
			R.x.value('Class[1]','varchar(max)'),
			R.x.value('NetworkProperty[1]','varchar(max)'),
			R.x.value('Property[1]','varchar(max)'),
			R.x.value('MapTable[1]','varchar(max)'),
			R.x.value('sInternalType[1]','varchar(max)'),
			R.x.value('sInternalID[1]','varchar(max)'),
			R.x.value('cClass[1]','varchar(max)'),
			R.x.value('cInternalType[1]','varchar(max)'),
			R.x.value('cInternalID[1]','varchar(max)'),
			R.x.value('oClass[1]','varchar(max)'),
			R.x.value('oInternalType[1]','varchar(max)'),
			R.x.value('oInternalID[1]','varchar(max)'),
			R.x.value('oValue[1]','varchar(max)'),
			R.x.value('oDataType[1]','varchar(max)'),
			R.x.value('oLanguage[1]','varchar(max)'),
			R.x.value('oStartDate[1]','varchar(max)'),
			R.x.value('oStartDatePrecision[1]','varchar(max)'),
			R.x.value('oEndDate[1]','varchar(max)'),
			R.x.value('oEndDatePrecision[1]','varchar(max)'),
			R.x.value('oObjectType[1]','varchar(max)'),
			R.x.value('Weight[1]','varchar(max)'),
			R.x.value('OrderBy[1]','varchar(max)'),
			R.x.value('ViewSecurityGroup[1]','varchar(max)'),
			R.x.value('EditSecurityGroup[1]','varchar(max)')
  FROM    ( SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[Ontology.].[DataMap]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )
  
  
 -- [Ontology.].[Namespace]
 TRUNCATE TABLE [Ontology.].[Namespace]
 INSERT INTO [Ontology.].[Namespace]
        ( URI ,
          Prefix
        )
  SELECT  R.x.value('URI[1]', 'varchar(max)') ,
          R.x.value('Prefix[1]', 'varchar(max)')
  FROM    ( SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[Ontology.].[Namespace]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )
  

   --[Ontology.].[PropertyGroup]
   INSERT INTO [Ontology.].PropertyGroup
           ( PropertyGroupURI ,
             SortOrder ,
             [_PropertyGroupLabel]
           ) 
	SELECT	R.x.value('PropertyGroupURI[1]','varchar(max)'),
			R.x.value('SortOrder[1]','varchar(max)'),
			R.x.value('_PropertyGroupLabel[1]','varchar(max)')
	 FROM    ( SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[Ontology.].[PropertyGroup]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )
  
  
	--[Ontology.].[PropertyGroupProperty]
	INSERT INTO [Ontology.].PropertyGroupProperty
	        ( PropertyGroupURI ,
	          PropertyURI ,
	          SortOrder ,
	          CustomDisplayModule ,
	          CustomEditModule ,
	          [_TagName] ,
	          [_PropertyLabel]
	        ) 
	SELECT	R.x.value('PropertyGroupURI[1]','varchar(max)'),
			R.x.value('PropertyURI[1]','varchar(max)'),
			R.x.value('SortOrder[1]','varchar(max)'),
			(case when CAST(R.x.query('CustomDisplayModule[1]/*') AS NVARCHAR(MAX))<>'' then R.x.query('CustomDisplayModule[1]/*') else NULL end),
			(case when CAST(R.x.query('CustomEditModule[1]/*') AS NVARCHAR(MAX))<>'' then R.x.query('CustomEditModule[1]/*') else NULL end),
			R.x.value('_TagName[1]','varchar(max)'),
			R.x.value('_PropertyLabel[1]','varchar(max)')
	 FROM    ( SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[Ontology.].[PropertyGroupProperty]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )
  

---------------------------------------------------------------
-- [Ontology.Presentation]
---------------------------------------------------------------


 --[Ontology.Presentation].[XML]
 INSERT INTO [Ontology.Presentation].[XML]
         ( PresentationID,
			type ,
           subject ,
           predicate ,
           object ,
           presentationXML ,
           _SubjectNode ,
           _PredicateNode ,
           _ObjectNode
         )       
  SELECT  Row_Number() OVER (ORDER BY (SELECT 1)),
		  R.x.value('type[1]', 'varchar(max)') ,
          R.x.value('subject[1]', 'varchar(max)'),
          R.x.value('predicate[1]', 'varchar(max)'),
          R.x.value('object[1]', 'varchar(max)'),
          (case when CAST(R.x.query('presentationXML[1]/*') AS NVARCHAR(MAX))<>'' then R.x.query('presentationXML[1]/*') else NULL end) , 
          R.x.value('_SubjectNode[1]', 'varchar(max)'),
          R.x.value('_PredicateNode[1]', 'varchar(max)'),
          R.x.value('_ObjectNode[1]', 'varchar(max)')
  FROM    ( SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[Ontology.Presentation].[XML]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )

  
---------------------------------------------------------------
-- [RDF.Security]
---------------------------------------------------------------
             
 -- [RDF.Security].[Group]
 TRUNCATE TABLE [RDF.Security].[Group]
 INSERT INTO [RDF.Security].[Group]
 
         ( SecurityGroupID ,
           Label ,
           HasSpecialViewAccess ,
           HasSpecialEditAccess ,
           Description
         )
 SELECT   R.x.value('SecurityGroupID[1]', 'varchar(max)') ,
          R.x.value('Label[1]', 'varchar(max)'),
          R.x.value('HasSpecialViewAccess[1]', 'varchar(max)'),
          R.x.value('HasSpecialEditAccess[1]', 'varchar(max)'),
          R.x.value('Description[1]', 'varchar(max)')
  FROM    ( SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[RDF.Security].[Group]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x ) 



---------------------------------------------------------------
-- [Utility.NLP]
---------------------------------------------------------------
   
	--[Utility.NLP].[ParsePorterStemming]
	INSERT INTO [Utility.NLP].ParsePorterStemming
	        ( Step, Ordering, phrase1, phrase2 ) 
	SELECT	R.x.value('Step[1]','varchar(max)'),
			R.x.value('Ordering[1]','varchar(max)'), 
			R.x.value('phrase1[1]','varchar(max)'), 
			R.x.value('phrase2[1]','varchar(max)')
	 FROM    ( SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[Utility.NLP].[ParsePorterStemming]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )
	
	--[Utility.NLP].[StopWord]
	INSERT INTO [Utility.NLP].StopWord
	        ( word, stem, scope ) 
	SELECT	R.x.value('word[1]','varchar(max)'),
			R.x.value('stem[1]','varchar(max)'),
			R.x.value('scope[1]','varchar(max)')
	 FROM    ( SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[Utility.NLP].[StopWord]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )
  
	--[Utility.NLP].[Thesaurus.Source]
	INSERT INTO [Utility.NLP].[Thesaurus.Source]
	        ( Source, SourceName ) 
	SELECT	R.x.value('Source[1]','varchar(max)'),
			R.x.value('SourceName[1]','varchar(max)')
	 FROM    ( SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[Utility.NLP].[Thesaurus.Source]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )


---------------------------------------------------------------
-- [User.Session]
---------------------------------------------------------------

  --[User.Session].Bot		
  INSERT INTO [User.Session].Bot  ( UserAgent )
   SELECT	R.x.value('UserAgent[1]','varchar(max)') 
	 FROM    ( SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[User.Session].Bot'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )
  
  
  
---------------------------------------------------------------
-- [Direct.]
---------------------------------------------------------------
   
  --[Direct.].[Sites]
  INSERT INTO [Direct.].[Sites]
          ( SiteID ,
            BootstrapURL ,
            SiteName ,
            QueryURL ,
            SortOrder ,
            IsActive
          )
  SELECT	R.x.value('SiteID[1]','varchar(max)'),
			R.x.value('BootstrapURL[1]','varchar(max)'),
			R.x.value('SiteName[1]','varchar(max)'),
			R.x.value('QueryURL[1]','varchar(max)'),
			R.x.value('SortOrder[1]','varchar(max)'),
			R.x.value('IsActive[1]','varchar(max)')
	 FROM    ( SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[Direct.].[Sites]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )
	
	
---------------------------------------------------------------
-- [Profile.Data]
---------------------------------------------------------------
 
    --[Profile.Data].[Publication.Type]		
  INSERT INTO [Profile.Data].[Publication.Type]
          ( pubidtype_id, name, sort_order )
           
   SELECT	R.x.value('pubidtype_id[1]','varchar(max)'),
			R.x.value('name[1]','varchar(max)'),
			R.x.value('sort_order[1]','varchar(max)')
	 FROM    (SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[Profile.Data].[Publication.Type]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )
   
  --[Profile.Data].[Publication.MyPub.Category]
  TRUNCATE TABLE [Profile.Data].[Publication.MyPub.Category]
  INSERT INTO [Profile.Data].[Publication.MyPub.Category]
          ( [HmsPubCategory] ,
            [CategoryName]
          ) 
   SELECT	R.x.value('HmsPubCategory[1]','varchar(max)'),
			R.x.value('CategoryName[1]','varchar(max)')
	 FROM    (SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[Profile.Data].[Publication.MyPub.Category]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )
  
 ---------------------------------------------------------------
-- [ORCID.]
---------------------------------------------------------------
  
	INSERT INTO [ORCID.].[REF_Permission]
		(
			[PermissionScope],
			[PermissionDescription],
			[MethodAndRequest],
			[SuccessMessage],
			[FailedMessage]
		)
   SELECT	R.x.value('PermissionScope[1]','varchar(max)'),
			R.x.value('PermissionDescription[1]','varchar(max)'),
			R.x.value('MethodAndRequest[1]','varchar(max)'),
			R.x.value('SuccessMessage[1]','varchar(max)'),
			R.x.value('FailedMessage[1]','varchar(max)')
	 FROM    (SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[ORCID.].[REF_Permission]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )


	INSERT INTO [ORCID.].[REF_PersonStatusType]
		(
			[StatusDescription]
		)
   SELECT	R.x.value('StatusDescription[1]','varchar(max)')
	 FROM    (SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[ORCID.].[REF_PersonStatusType]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )


	INSERT INTO [ORCID.].[REF_RecordStatus]
		(
			[RecordStatusID],
			[StatusDescription]
		)
   SELECT	R.x.value('RecordStatusID[1]','varchar(max)'),
			R.x.value('StatusDescription[1]','varchar(max)')
	 FROM    (SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[ORCID.].[REF_RecordStatus]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )


	INSERT INTO [ORCID.].[REF_Decision]
		(
			[DecisionDescription],
			[DecisionDescriptionLong]
		)
   SELECT	R.x.value('DecisionDescription[1]','varchar(max)'),
			R.x.value('DecisionDescriptionLong[1]','varchar(max)')
	 FROM    (SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[ORCID.].[REF_Decision]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )

	INSERT INTO [ORCID.].[REF_WorkExternalType]
		(
			[WorkExternalType],
			[WorkExternalDescription]
		)
   SELECT	R.x.value('WorkExternalType[1]','varchar(max)'),
			R.x.value('WorkExternalDescription[1]','varchar(max)')
	 FROM    (SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[ORCID.].[REF_WorkExternalType]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )


	INSERT INTO [ORCID.].[RecordLevelAuditType]
		(
			[AuditType]
		)
   SELECT	R.x.value('AuditType[1]','varchar(max)')
	 FROM    (SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[ORCID.].[RecordLevelAuditType]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )



	INSERT INTO [ORCID.].[DefaultORCIDDecisionIDMapping]
		(
			[SecurityGroupID],
			[DefaultORCIDDecisionID]
		)
   SELECT	R.x.value('SecurityGroupID[1]','varchar(max)'),
			R.x.value('DefaultORCIDDecisionID[1]','varchar(max)')
	 FROM    (SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[ORCID.].[DefaultORCIDDecisionIDMapping]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )

   ---------------------------------------------------------------
-- [ORNG.]
---------------------------------------------------------------
	INSERT INTO [ORNG.].[Apps]
		(
			[AppID],
			[Name],
			[Url],
			[PersonFilterID],
			[OAuthSecret],
			[Enabled]
		)
   SELECT	R.x.value('AppID[1]','varchar(max)'),
			R.x.value('Name[1]','varchar(max)'),
			R.x.value('URL[1]','varchar(max)'),
			R.x.value('PersonFilterID[1]','varchar(max)'),
			R.x.value('OAuthSecret[1]','varchar(max)'),
			R.x.value('Enabled[1]','varchar(max)')
	 FROM    (SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[ORNG.].[Apps]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )

  	INSERT INTO [ORNG.].[AppViews]
		(
			[AppID],
			[Page],
			[View],
			[ChromeID],
			[Visibility],
			[DisplayOrder],
			[OptParams]
		)
   SELECT	R.x.value('AppID[1]','varchar(max)'),
			R.x.value('Page[1]','varchar(max)'),
			R.x.value('View[1]','varchar(max)'),
			R.x.value('ChromeID[1]','varchar(max)'),
			R.x.value('Visibility[1]','varchar(max)'),
			R.x.value('DisplayOrder[1]','varchar(max)'),
			R.x.value('OptParams[1]','varchar(max)')
	 FROM    (SELECT
                      @x.query
                      ('Import[1]/Table[@Name=''[ORNG.].[AppViews]'']')
                      x
          ) t
  CROSS APPLY x.nodes('//Row') AS R ( x )
  
  -- Use to generate select lists for new tables
  -- SELECT   'R.x.value(''' + c.name +  '[1]'',' + '''varchar(max)'')'+ ',' ,* 
  -- FROM sys.columns c 
  -- JOIN  sys.types t ON t.system_type_id = c.system_type_id 
  -- WHERE object_id IN (SELECT object_id FROM sys.tables WHERE name = 'Publication.MyPub.Category') 
  -- AND T.NAME<>'sysname'ORDER BY c.column_id
	 
END
GO
PRINT N'Altering [Ontology.].[CleanUp]...';


GO
ALTER PROCEDURE [Ontology.].[CleanUp]
	@Action varchar(100) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- This stored procedure contains code to help developers manage
	-- content in several ontology tables.
	
	-------------------------------------------------------------
	-- View the contents of the tables
	-------------------------------------------------------------

	if @Action = 'ShowTables'
	begin
		select * from [Ontology.].ClassGroup
		select * from [Ontology.].ClassGroupClass
		select * from [Ontology.].ClassProperty
		select * from [Ontology.].DataMap
		select * from [Ontology.].Namespace
		select * from [Ontology.].PropertyGroup
		select * from [Ontology.].PropertyGroupProperty
		select * from [Ontology.Import].[Triple]
		select * from [Ontology.Import].OWL
		select * from [Ontology.Presentation].General
	end
	
	-------------------------------------------------------------
	-- Insert missing records, use default values
	-------------------------------------------------------------

	if @Action = 'AddMissingRecords'
	begin

		insert into [Ontology.].ClassProperty (ClassPropertyID, Class, NetworkProperty, Property, IsDetail, Limit, IncludeDescription, IncludeNetwork, SearchWeight, CustomDisplay, CustomEdit, ViewSecurityGroup, EditSecurityGroup, EditPermissionsSecurityGroup, EditExistingSecurityGroup, EditAddNewSecurityGroup, EditAddExistingSecurityGroup, EditDeleteSecurityGroup, MinCardinality, MaxCardinality, CustomEditModule)
			select ClassPropertyID, Class, NetworkProperty, Property, IsDetail, Limit, IncludeDescription, IncludeNetwork, SearchWeight, CustomDisplay, CustomEdit, ViewSecurityGroup, EditSecurityGroup, EditPermissionsSecurityGroup, EditExistingSecurityGroup, EditAddNewSecurityGroup, EditAddExistingSecurityGroup, EditDeleteSecurityGroup, MinCardinality, MaxCardinality, CustomEditModule
				from [Ontology.].vwMissingClassProperty

		insert into [Ontology.].PropertyGroupProperty (PropertyGroupURI, PropertyURI, SortOrder)
			select PropertyGroupURI, PropertyURI, SortOrder
				from [Ontology.].vwMissingPropertyGroupProperty

	end

	-------------------------------------------------------------
	-- Update IDs using the default sort order
	-------------------------------------------------------------

	if @Action = 'UpdateIDs'
	begin
		
		update x
			set x.ClassPropertyID = y.k
			from [Ontology.].ClassProperty x, (
				select *, row_number() over (order by (case when NetworkProperty is null then 0 else 1 end), Class, NetworkProperty, IsDetail, IncludeNetwork, Property) k
					from [Ontology.].ClassProperty
			) y
			where x.Class = y.Class and x.Property = y.Property
				and ((x.NetworkProperty is null and y.NetworkProperty is null) or (x.NetworkProperty = y.NetworkProperty))

		update x
			set x.DataMapID = y.k
			from [Ontology.].DataMap x, (
				select *, row_number() over (order by	(case when Property is null then 0 when NetworkProperty is null then 1 else 2 end), 
														(case when Class = 'http://profiles.catalyst.harvard.edu/ontology/prns#User' then 0 else 1 end), 
														Class,
														(case when NetworkProperty = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type' then 0 when NetworkProperty = 'http://www.w3.org/2000/01/rdf-schema#label' then 1 else 2 end),
														NetworkProperty, 
														(case when Property = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type' then 0 when Property = 'http://www.w3.org/2000/01/rdf-schema#label' then 1 else 2 end),
														MapTable,
														Property
														) k
					from [Ontology.].DataMap
			) y
			where x.Class = y.Class and x.sInternalType = y.sInternalType
				and ((x.Property is null and y.Property is null) or (x.Property = y.Property))
				and ((x.NetworkProperty is null and y.NetworkProperty is null) or (x.NetworkProperty = y.NetworkProperty))

		update x
			set x.PresentationID = y.k
			from [Ontology.Presentation].General x, (
				select *, row_number() over (order by	(case when Type = 'E' then 1 else 0 end), 
														Subject,
														(case Type when 'P' then 1 when 'N' then 2 else 3 end),
														Predicate, Object
														) k
					from [Ontology.Presentation].General
			) y
			where x.Type = y.Type
				and ((x.Subject is null and y.Subject is null) or (x.Subject = y.Subject))
				and ((x.Predicate is null and y.Predicate is null) or (x.Predicate = y.Predicate))
				and ((x.Object is null and y.Object is null) or (x.Object = y.Object))	

		update x 
			set x.JobID = y.k 
			from [Framework.].Job x, (
				select *, ROW_NUMBER() over (order by JobGroup, Step) k 
					from [Framework.].Job
			) y
			where x.JobGroup = y.JobGroup and x.Step = y.Step
			
		update x 
			set x._ClassPropertyID = b.ClassPropertyID 
			from [Ontology.].ClassPropertyCustom x join [Ontology.].ClassProperty b
				on x.Class=b.Class and x.Property=b.Property
				and ((x.NetworkProperty is null and b.NetworkProperty is null) or (x.NetworkProperty = b.NetworkProperty))
	end

	-------------------------------------------------------------
	-- Update derived and calculated fields
	-------------------------------------------------------------

	if @Action = 'UpdateFields'
	begin
		exec [Ontology.].UpdateDerivedFields
		exec [Ontology.].UpdateCounts
	end
    
END
GO
PRINT N'Altering [Profile.Data].[Person.GetFacultyRanks]...';


GO
ALTER procedure [Profile.Data].[Person.GetFacultyRanks]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT x.FacultyRankID, x.FacultyRank,  n.NodeID, n.Value URI
		FROM (
				SELECT CAST(MAX(FacultyRankID) AS VARCHAR(50)) FacultyRankID,
						LTRIM(RTRIM(FacultyRank)) FacultyRank, 	FacultyRankSort							
				FROM [Profile.Data].[Person.FacultyRank] WITH (NOLOCK) where facultyrank <> ''				
				group by FacultyRank ,FacultyRankSort
			) x 
			LEFT OUTER JOIN [RDF.Stage].InternalNodeMap m WITH (NOLOCK)
				ON m.class = 'http://profiles.catalyst.harvard.edu/ontology/prns#FacultyRank'
					AND m.InternalType = 'FacultyRank'
					AND m.InternalID = CAST(x.FacultyRankID AS VARCHAR(50))
			LEFT OUTER JOIN [RDF.].Node n WITH (NOLOCK)
				ON m.NodeID = n.NodeID
					AND n.ViewSecurityGroup = -1
		ORDER BY FacultyRankSort
 

END
GO
PRINT N'Altering [Profile.Data].[Person.GetPhotos]...';


GO
ALTER procedure [Profile.Data].[Person.GetPhotos](@NodeID bigINT)
AS
BEGIN

DECLARE @InternalID INT, @InternalType NVARCHAR(300)

    SELECT @InternalID = CAST(m.InternalID AS INT),
		@InternalType = InternalType
 		FROM [RDF.Stage].[InternalNodeMap] m, [RDF.].Node n
		WHERE m.Status = 3 AND m.ValueHash = n.ValueHash AND n.NodeID = @NodeID

	IF @InternalType = 'Person'
	BEGIN
		SELECT  photo,
				p.PhotoID		
			FROM [Profile.Data].[Person.Photo] p WITH(NOLOCK)
		 WHERE PersonID=@InternalID  
	 END

	ELSE IF @InternalType = 'Group' 
	BEGIN
		SELECT  photo,
				p.PhotoID		
			FROM [Profile.Data].[Group.Photo] p WITH(NOLOCK)
		 WHERE GroupID=@InternalID  
	 END
END
GO
PRINT N'Altering [RDF.].[GetDataRDF]...';


GO
ALTER PROCEDURE [RDF.].[GetDataRDF]
	@subject BIGINT=NULL,
	@predicate BIGINT=NULL,
	@object BIGINT=NULL,
	@offset BIGINT=NULL,
	@limit BIGINT=NULL,
	@showDetails BIT=1,
	@expand BIT=1,
	@SessionID UNIQUEIDENTIFIER=NULL,
	@NodeListXML XML=NULL,
	@ExpandRDFListXML XML=NULL,
	@returnXML BIT=1,
	@returnXMLasStr BIT=0,
	@dataStr NVARCHAR (MAX)=NULL OUTPUT,
	@dataStrDataType NVARCHAR (255)=NULL OUTPUT,
	@dataStrLanguage NVARCHAR (255)=NULL OUTPUT,
	@RDF XML=NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	/*

	This stored procedure returns the data for a node in RDF format.

	Input parameters:
		@subject		The NodeID whose RDF should be returned.
		@predicate		The predicate NodeID for a network.
		@object			The object NodeID for a connection.
		@offset			Pagination - The first object node to return.
		@limit			Pagination - The number of object nodes to return.
		@showDetails	If 1, then additional properties will be returned.
		@expand			If 1, then object properties will be expanded.
		@SessionID		The SessionID of the user requesting the data.

	There are two ways to call this procedure. By default, @returnXML = 1,
	and the RDF is returned as XML. When @returnXML = 0, the data is instead
	returned as the strings @dataStr, @dataStrDataType, and @dataStrLanguage.
	This second method of calling this procedure is used by other procedures
	and is generally not called directly by the website.

	The RDF returned by this procedure is not equivalent to what is
	returned by SPARQL. This procedure applies security rules, expands
	nodes as defined by [Ontology.].[RDFExpand], and calculates network
	information on-the-fly.

	*/

	--declare @debugLogID int
	--insert into [RDF.].[GetDataRDF.DebugLog] (subject,predicate,object,offset,limit,showDetails,expand,SessionID,StartDate)
	--	select @subject,@predicate,@object,@offset,@limit,@showDetails,@expand,@SessionID,GetDate()
	--select @debugLogID = @@IDENTITY
	--insert into [RDF.].[GetDataRDF.DebugLog.ExpandRDFListXML] (LogID, ExpandRDFListXML)
	--	select @debugLogID, @ExpandRDFListXML

	
	declare @d datetime

	declare @baseURI nvarchar(400)
	select @baseURI = value from [Framework.].Parameter where ParameterID = 'baseURI'

	select @subject = null where @subject = 0
	select @predicate = null where @predicate = 0
	select @object = null where @object = 0
		
	declare @firstURI nvarchar(400)
	select @firstURI = @baseURI+cast(@subject as varchar(50))

	declare @firstValue nvarchar(400)
	select @firstValue = null
	
	declare @typeID bigint
	select @typeID = [RDF.].fnURI2NodeID('http://www.w3.org/1999/02/22-rdf-syntax-ns#type')

	declare @labelID bigint
	select @labelID = [RDF.].fnURI2NodeID('http://www.w3.org/2000/01/rdf-schema#label')	

	declare @validURI bit
	select @validURI = 1
	
	declare @includePredicates bit
	select @includePredicates = 1

	--*******************************************************************************************
	--*******************************************************************************************
	-- Define temp tables
	--*******************************************************************************************
	--*******************************************************************************************

	/*
		drop table #subjects
		drop table #types
		drop table #expand
		drop table #properties
		drop table #connections
	*/

	create table #subjects (
		subject bigint primary key,
		showDetail bit,
		expanded bit,
		uri nvarchar(400)
	)
	
	create table #types (
		subject bigint not null,
		object bigint not null,
		predicate bigint,
		showDetail bit,
		uri nvarchar(400)
	)
	create unique clustered index idx_sop on #types (subject,object,predicate)

	create table #expand (
		subject bigint not null,
		predicate bigint not null,
		uri nvarchar(400),
		property nvarchar(400),
		tagName nvarchar(1000),
		propertyLabel nvarchar(400),
		IsDetail bit,
		limit bigint,
		showStats bit,
		showSummary bit
	)
	alter table #expand add primary key (subject,predicate)

	create table #properties (
		uri nvarchar(400),
		subject bigint,
		predicate bigint,
		object bigint,
		showSummary bit,
		property nvarchar(400),
		tagName nvarchar(1000),
		propertyLabel nvarchar(400),
		Language nvarchar(255),
		DataType nvarchar(255),
		Value nvarchar(max),
		ObjectType bit,
		SortOrder int
	)

	create table #connections (
		subject bigint,
		subjectURI nvarchar(400),
		predicate bigint,
		predicateURI nvarchar(400),
		object bigint,
		Language nvarchar(255),
		DataType nvarchar(255),
		Value nvarchar(max),
		ObjectType bit,
		SortOrder int,
		Weight float,
		Reitification bigint,
		ReitificationURI nvarchar(400),
		connectionURI nvarchar(400)
	)
	
	create table #ClassPropertyCustom (
		ClassPropertyID int primary key,
		IncludeProperty bit,
		Limit int,
		IncludeNetwork bit,
		IncludeDescription bit,
		IsDetail bit
	)

	--*******************************************************************************************
	--*******************************************************************************************
	-- Setup variables used for security
	--*******************************************************************************************
	--*******************************************************************************************

	DECLARE @SecurityGroupID BIGINT, @HasSpecialViewAccess BIT, @HasSecurityGroupNodes BIT
	EXEC [RDF.Security].GetSessionSecurityGroup @SessionID, @SecurityGroupID OUTPUT, @HasSpecialViewAccess OUTPUT
	CREATE TABLE #SecurityGroupNodes (SecurityGroupNode BIGINT PRIMARY KEY)
	INSERT INTO #SecurityGroupNodes (SecurityGroupNode) EXEC [RDF.Security].GetSessionSecurityGroupNodes @SessionID, @Subject
	SELECT @HasSecurityGroupNodes = (CASE WHEN EXISTS (SELECT * FROM #SecurityGroupNodes) THEN 1 ELSE 0 END)


	--*******************************************************************************************
	--*******************************************************************************************
	-- Check if user has access to the URI
	--*******************************************************************************************
	--*******************************************************************************************

	if @subject is not null
		select @validURI = 0
			where not exists (
				select *
				from [RDF.].Node
				where NodeID = @subject
					and ( (ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)) )
			)

	if @predicate is not null
		select @validURI = 0
			where not exists (
				select *
				from [RDF.].Node
				where NodeID = @predicate and ObjectType = 0
					and ( (ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)) )
			)

	if @object is not null
		select @validURI = 0
			where not exists (
				select *
				from [RDF.].Node
				where NodeID = @object and ObjectType = 0
					and ( (ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)) )
			)


	--*******************************************************************************************
	--*******************************************************************************************
	-- Get subject information when it is a literal
	--*******************************************************************************************
	--*******************************************************************************************

	select @dataStr = Value, @dataStrDataType = DataType, @dataStrLanguage = Language
		from [RDF.].Node
		where NodeID = @subject and ObjectType = 1
			and ( (ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)) )


	--*******************************************************************************************
	--*******************************************************************************************
	-- Seed temp tables
	--*******************************************************************************************
	--*******************************************************************************************

	---------------------------------------------------------------------------------------------
	-- Profile [seed with the subject(s)]
	---------------------------------------------------------------------------------------------
	if (@subject is not null) and (@predicate is null) and (@object is null)
	begin
		insert into #subjects(subject,showDetail,expanded,URI)
			select NodeID, @showDetails, 0, Value
				from [RDF.].Node
				where NodeID = @subject
					and ((ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)))
		select @firstValue = URI
			from #subjects s, [RDF.].Node n
			where s.subject = @subject
				and s.subject = n.NodeID and n.ObjectType = 0
	end
	if (@NodeListXML is not null)
	begin
		insert into #subjects(subject,showDetail,expanded,URI)
			select n.NodeID, t.ShowDetails, 0, n.Value
			from [RDF.].Node n, (
				select NodeID, MAX(ShowDetails) ShowDetails
				from (
					select x.value('@ID','bigint') NodeID, IsNull(x.value('@ShowDetails','tinyint'),0) ShowDetails
					from @NodeListXML.nodes('//Node') as N(x)
				) t
				group by NodeID
				having NodeID not in (select subject from #subjects)
			) t
			where n.NodeID = t.NodeID and n.ObjectType = 0
	end
	
	---------------------------------------------------------------------------------------------
	-- Get all connections
	---------------------------------------------------------------------------------------------
	insert into #connections (subject, subjectURI, predicate, predicateURI, object, Language, DataType, Value, ObjectType, SortOrder, Weight, Reitification, ReitificationURI, connectionURI)
		select	s.NodeID subject, s.value subjectURI, 
				p.NodeID predicate, p.value predicateURI,
				t.object, o.Language, o.DataType, o.Value, o.ObjectType,
				t.SortOrder, t.Weight, 
				r.NodeID Reitification, r.Value ReitificationURI,
				@baseURI+cast(@subject as varchar(50))+'/'+cast(@predicate as varchar(50))+'/'+cast(object as varchar(50)) connectionURI
			from [RDF.].Triple t
				inner join [RDF.].Node s
					on t.subject = s.NodeID
				inner join [RDF.].Node p
					on t.predicate = p.NodeID
				inner join [RDF.].Node o
					on t.object = o.NodeID
				left join [RDF.].Node r
					on t.reitification = r.NodeID
						and t.reitification is not null
						and ((r.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (r.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (r.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)))
			where @subject is not null and @predicate is not null
				and s.NodeID = @subject 
				and p.NodeID = @predicate 
				and o.NodeID = IsNull(@object,o.NodeID)
				and ((t.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (t.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (t.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)))
				and ((s.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (s.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (s.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)))
				and ((p.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (p.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (p.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)))
				and ((o.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (o.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (o.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)))

	-- Make sure there are connections
	if (@subject is not null) and (@predicate is not null)
		select @validURI = 0
		where not exists (select * from #connections)

	---------------------------------------------------------------------------------------------
	-- Network [seed with network statistics and connections]
	---------------------------------------------------------------------------------------------
	if (@subject is not null) and (@predicate is not null) and (@object is null)
	begin
		select @firstURI = @baseURI+cast(@subject as varchar(50))+'/'+cast(@predicate as varchar(50))
		-- Basic network properties
		;with networkProperties as (
			select 1 n, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type' property, 'rdf:type' tagName, 'type' propertyLabel, 0 ObjectType
			union all select 2, 'http://profiles.catalyst.harvard.edu/ontology/prns#numberOfConnections', 'prns:numberOfConnections', 'number of connections', 1
			union all select 3, 'http://profiles.catalyst.harvard.edu/ontology/prns#maxWeight', 'prns:maxWeight', 'maximum connection weight', 1
			union all select 4, 'http://profiles.catalyst.harvard.edu/ontology/prns#minWeight', 'prns:minWeight', 'minimum connection weight', 1
			union all select 5, 'http://profiles.catalyst.harvard.edu/ontology/prns#predicateNode', 'prns:predicateNode', 'predicate node', 0
			union all select 6, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#predicate', 'rdf:predicate', 'predicate', 0
			union all select 7, 'http://www.w3.org/2000/01/rdf-schema#label', 'rdfs:label', 'label', 1
			union all select 8, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#subject', 'rdf:subject', 'subject', 0
		), networkStats as (
			select	cast(isnull(count(*),0) as varchar(50)) numberOfConnections,
					cast(isnull(max(Weight),1) as varchar(50)) maxWeight,
					cast(isnull(min(Weight),1) as varchar(50)) minWeight,
					max(predicateURI) predicateURI
				from #connections
		), subjectLabel as (
			select IsNull(Max(o.Value),'') Label
			from [RDF.].Triple t, [RDF.].Node o
			where t.subject = @subject
				and t.predicate = @labelID
				and t.object = o.NodeID
				and ((t.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (t.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (t.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)))
				and ((o.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (o.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (o.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)))
		)
		insert into #properties (uri,predicate,property,tagName,propertyLabel,Value,ObjectType,SortOrder)
			select	@firstURI,
					[RDF.].fnURI2NodeID(p.property), p.property, p.tagName, p.propertyLabel,
					(case p.n when 1 then 'http://profiles.catalyst.harvard.edu/ontology/prns#Network'
								when 2 then n.numberOfConnections
								when 3 then n.maxWeight
								when 4 then n.minWeight
								when 5 then @baseURI+cast(@predicate as varchar(50))
								when 6 then n.predicateURI
								when 7 then l.Label
								when 8 then @baseURI+cast(@subject as varchar(50))
								end),
					p.ObjectType,
					1
				from networkStats n, networkProperties p, subjectLabel l
		-- Limit the number of connections if the subject is not a person or a group
		select @limit = 10
			where (@limit is null) 
				and not exists (
					select *
					from [rdf.].[triple]
					where subject = @subject
						and predicate = [RDF.].fnURI2NodeID('http://www.w3.org/1999/02/22-rdf-syntax-ns#type')
						and object in ( [RDF.].fnURI2NodeID('http://xmlns.com/foaf/0.1/Person') , [RDF.].fnURI2NodeID('http://xmlns.com/foaf/0.1/Group') )
				)
		-- Remove connections not within offset-limit window
		delete from #connections
			where (SortOrder < 1+IsNull(@offset,0)) or (SortOrder > IsNull(@limit,SortOrder) + (case when IsNull(@offset,0)<1 then 0 else @offset end))
		-- Add hasConnection properties
		insert into #properties (uri,predicate,property,tagName,propertyLabel,Value,ObjectType,SortOrder)
			select	@baseURI+cast(@subject as varchar(50))+'/'+cast(@predicate as varchar(50)),
					[RDF.].fnURI2NodeID('http://profiles.catalyst.harvard.edu/ontology/prns#hasConnection'), 
					'http://profiles.catalyst.harvard.edu/ontology/prns#hasConnection', 'prns:hasConnection', 'has connection',
					connectionURI,
					0,
					SortOrder
				from #connections
	end

	---------------------------------------------------------------------------------------------
	-- Connection [seed with connection]
	---------------------------------------------------------------------------------------------
	if (@subject is not null) and (@predicate is not null) and (@object is not null)
	begin
		select @firstURI = @baseURI+cast(@subject as varchar(50))+'/'+cast(@predicate as varchar(50))+'/'+cast(@object as varchar(50))
	end

	---------------------------------------------------------------------------------------------
	-- Expanded Connections [seed with statistics, subject, object, and connectionDetails]
	---------------------------------------------------------------------------------------------
	if (@expand = 1 or @object is not null) and exists (select * from #connections)
	begin
		-- Connection statistics
		;with connectionProperties as (
			select 1 n, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type' property, 'rdf:type' tagName, 'type' propertyLabel, 0 ObjectType
			union all select 2, 'http://profiles.catalyst.harvard.edu/ontology/prns#connectionWeight', 'prns:connectionWeight', 'connection weight', 1
			union all select 3, 'http://profiles.catalyst.harvard.edu/ontology/prns#sortOrder', 'prns:sortOrder', 'sort order', 1
			union all select 4, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#object', 'rdf:object', 'object', 0
			union all select 5, 'http://profiles.catalyst.harvard.edu/ontology/prns#hasConnectionDetails', 'prns:hasConnectionDetails', 'connection details', 0
			union all select 6, 'http://profiles.catalyst.harvard.edu/ontology/prns#predicateNode', 'prns:predicateNode', 'predicate node', 0
			union all select 7, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#predicate', 'rdf:predicate', 'predicate', 0
			union all select 8, 'http://www.w3.org/2000/01/rdf-schema#label', 'rdfs:label', 'label', 1
			union all select 9, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#subject', 'rdf:subject', 'subject', 0
			union all select 10, 'http://profiles.catalyst.harvard.edu/ontology/prns#connectionInNetwork', 'prns:connectionInNetwork', 'connection in network', 0
		)
		insert into #properties (uri,predicate,property,tagName,propertyLabel,Value,ObjectType,SortOrder)
			select	connectionURI,
					[RDF.].fnURI2NodeID(p.property), p.property, p.tagName, p.propertyLabel,
					(case p.n	when 1 then 'http://profiles.catalyst.harvard.edu/ontology/prns#Connection'
								when 2 then cast(c.Weight as varchar(50))
								when 3 then cast(c.SortOrder as varchar(50))
								when 4 then c.value
								when 5 then c.ReitificationURI
								when 6 then @baseURI+cast(@predicate as varchar(50))
								when 7 then c.predicateURI
								when 8 then l.value
								when 9 then c.subjectURI
								when 10 then c.subjectURI+'/'+cast(@predicate as varchar(50))
								end),
					(case p.n when 4 then c.ObjectType else p.ObjectType end),
					1
				from #connections c, connectionProperties p
					left outer join (
						select o.value
							from [RDF.].Triple t, [RDF.].Node o
							where t.subject = @subject 
								and t.predicate = @labelID
								and t.object = o.NodeID
								and ((t.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (t.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (t.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)))
								and ((o.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (o.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (o.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes)))
					) l on p.n = 8
				where (p.n < 5) 
					or (p.n = 5 and c.ReitificationURI is not null)
					or (p.n > 5 and @object is not null)
		if (@expand = 1)
		begin
			-- Connection subject
			insert into #subjects (subject, showDetail, expanded, URI)
				select NodeID, 0, 0, Value
					from [RDF.].Node
					where NodeID = @subject
			-- Connection objects
			insert into #subjects (subject, showDetail, expanded, URI)
				select object, 0, 0, value
					from #connections
					where ObjectType = 0 and object not in (select subject from #subjects)
			-- Connection details (reitifications)
			insert into #subjects (subject, showDetail, expanded, URI)
				select Reitification, 0, 0, ReitificationURI
					from #connections
					where Reitification is not null and Reitification not in (select subject from #subjects)
		end
	end

	--*******************************************************************************************
	--*******************************************************************************************
	-- Get property values
	--*******************************************************************************************
	--*******************************************************************************************

	-- Get custom settings to override the [Ontology.].[ClassProperty] default values
	insert into #ClassPropertyCustom (ClassPropertyID, IncludeProperty, Limit, IncludeNetwork, IncludeDescription, IsDetail)
		select p.ClassPropertyID, t.IncludeProperty, t.Limit, t.IncludeNetwork, t.IncludeDescription, t.IsDetail
			from [Ontology.].[ClassProperty] p
				inner join (
					select	x.value('@Class','varchar(400)') Class,
							x.value('@NetworkProperty','varchar(400)') NetworkProperty,
							x.value('@Property','varchar(400)') Property,
							(case x.value('@IncludeProperty','varchar(5)') when 'true' then 1 when 'false' then 0 else null end) IncludeProperty,
							x.value('@Limit','int') Limit,
							(case x.value('@IncludeNetwork','varchar(5)') when 'true' then 1 when 'false' then 0 else null end) IncludeNetwork,
							(case x.value('@IncludeDescription','varchar(5)') when 'true' then 1 when 'false' then 0 else null end) IncludeDescription,
							(case x.value('@IsDetail','varchar(5)') when 'true' then 1 when 'false' then 0 else null end) IsDetail
					from @ExpandRDFListXML.nodes('//ExpandRDF') as R(x)
				) t
				on p.Class=t.Class and p.Property=t.Property
					and ((p.NetworkProperty is null and t.NetworkProperty is null) or (p.NetworkProperty = t.NetworkProperty))

	declare @ClassPropertyCustomTypeID int
	select @ClassPropertyCustomTypeID = ClassPropertyCustomTypeID from (select x.value('@ClassPropertyCustomTypeID', 'int') ClassPropertyCustomTypeID from @ExpandRDFListXML.nodes('//ExpandRDFOptions') as R(x)) t
	insert into #ClassPropertyCustom (ClassPropertyID, IncludeProperty, Limit, IncludeNetwork, IncludeDescription, IsDetail)
		select _ClassPropertyID, IncludeProperty, Limit, IncludeNetwork, IncludeDescription, IsDetail from [Ontology.].[ClassPropertyCustom]
		where ClassPropertyCustomTypeID=@ClassPropertyCustomTypeID and _ClassPropertyID not in (select ClassPropertyID from #ClassPropertyCustom)

	if exists (select 1 from (select (case x.value('@ExpandPredicates', 'varchar(5)') when 'false' then 0 else 1 end) ExpandPredicates from @ExpandRDFListXML.nodes('//ExpandRDFOptions') as R(x)) t
		where t.ExpandPredicates = 0) begin set @includePredicates = 0 end

	-- Get properties and loop if objects need to be expanded
	declare @numLoops int
	declare @maxLoops int
	declare @actualLoops int
	declare @NewSubjects int
	select @numLoops = 0, @maxLoops = 10, @actualLoops = 0
	while (@numLoops < @maxLoops)
	begin
		-- Get the types of each subject that hasn't been expanded
		truncate table #types
		insert into #types(subject,object,predicate,showDetail,uri)
			select s.subject, t.object, null, s.showDetail, s.uri
				from #subjects s 
					inner join [RDF.].Triple t on s.subject = t.subject 
						and t.predicate = @typeID 
					inner join [RDF.].Node n on t.object = n.NodeID
						and ((n.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (n.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (1 = CASE WHEN @HasSecurityGroupNodes = 0 THEN 0 WHEN n.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes) THEN 1 ELSE 0 END))
						and ((t.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (t.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (1 = CASE WHEN @HasSecurityGroupNodes = 0 THEN 0 WHEN t.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes) THEN 1 ELSE 0 END))
				where s.expanded = 0				   
		-- Get the subject types of each reitification that hasn't been expanded
		insert into #types(subject,object,predicate,showDetail,uri)
		select distinct s.subject, t.object, r.predicate, s.showDetail, s.uri
			from #subjects s 
				inner join [RDF.].Triple r on s.subject = r.reitification
				inner join [RDF.].Triple t on r.subject = t.subject 
					and t.predicate = @typeID 
				inner join [RDF.].Node n on t.object = n.NodeID
					and ((n.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (n.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (1 = CASE WHEN @HasSecurityGroupNodes = 0 THEN 0 WHEN n.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes) THEN 1 ELSE 0 END))
					and ((t.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (t.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (1 = CASE WHEN @HasSecurityGroupNodes = 0 THEN 0 WHEN t.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes) THEN 1 ELSE 0 END))
					and ((r.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (r.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (1 = CASE WHEN @HasSecurityGroupNodes = 0 THEN 0 WHEN r.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes) THEN 1 ELSE 0 END))
			where s.expanded = 0
		-- Get the items that should be expanded
		truncate table #expand
		insert into #expand(subject, predicate, uri, property, tagName, propertyLabel, IsDetail, limit, showStats, showSummary)
			select p.subject, o._PropertyNode, max(p.uri) uri, o.property, o._TagName, o._PropertyLabel, min(o.IsDetail*1) IsDetail, 
					(case when min(IsNull(c.IsDetail, o.IsDetail)*1) = 0 then max(case when IsNull(c.IsDetail, o.IsDetail)=0 then IsNull(c.limit,o.limit) else null end) else max(IsNull(c.limit,o.limit)) end) limit,
					(case when min(IsNull(c.IsDetail, o.IsDetail)*1) = 0 then max(case when IsNull(c.IsDetail, o.IsDetail)=0 then IsNull(c.IncludeNetwork,o.IncludeNetwork)*1 else 0 end) else max(IsNull(c.IncludeNetwork,o.IncludeNetwork)*1) end) showStats,
					(case when min(IsNull(c.IsDetail, o.IsDetail)*1) = 0 then max(case when IsNull(c.IsDetail, o.IsDetail)=0 then IsNull(c.IncludeDescription,o.IncludeDescription)*1 else 0 end) else max(IsNull(c.IncludeDescription,o.IncludeDescription)*1) end) showSummary
				from #types p
					inner join [Ontology.].ClassProperty o
						on p.object = o._ClassNode 
						and ((p.predicate is null and o._NetworkPropertyNode is null) or (p.predicate = o._NetworkPropertyNode))
					left outer join #ClassPropertyCustom c
						on o.ClassPropertyID = c.ClassPropertyID
				where IsNull(c.IncludeProperty,1) = 1
				and IsNull(c.IsDetail, o.IsDetail) <= showDetail
				group by p.subject, o.property, o._PropertyNode, o._TagName, o._PropertyLabel
		-- Get the values for each property that should be expanded
		insert into #properties (uri,subject,predicate,object,showSummary,property,tagName,propertyLabel,Language,DataType,Value,ObjectType,SortOrder)
			select e.uri, e.subject, t.predicate, t.object, e.showSummary,
					e.property, e.tagName, e.propertyLabel, 
					o.Language, o.DataType, o.Value, o.ObjectType, t.SortOrder
			from #expand e
				inner join [RDF.].Triple t
					on t.subject = e.subject and t.predicate = e.predicate
						and (e.limit is null or t.sortorder <= e.limit)
						and ((t.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (t.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (1 = CASE WHEN @HasSecurityGroupNodes = 0 THEN 0 WHEN t.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes) THEN 1 ELSE 0 END))
				inner join [RDF.].Node p
					on t.predicate = p.NodeID
						and ((p.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (p.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (1 = CASE WHEN @HasSecurityGroupNodes = 0 THEN 0 WHEN p.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes) THEN 1 ELSE 0 END))
				inner join [RDF.].Node o
					on t.object = o.NodeID
						and ((o.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (o.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (1 = CASE WHEN @HasSecurityGroupNodes = 0 THEN 0 WHEN o.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes) THEN 1 ELSE 0 END))
		-- Get network properties
		if (@numLoops = 0)
		begin
			-- Calculate network statistics
			select e.uri, e.subject, t.predicate, e.property, e.tagName, e.PropertyLabel, 
					cast(isnull(count(*),0) as varchar(50)) numberOfConnections,
					cast(isnull(max(t.Weight),1) as varchar(50)) maxWeight,
					cast(isnull(min(t.Weight),1) as varchar(50)) minWeight,
					@baseURI+cast(e.subject as varchar(50))+'/'+cast(t.predicate as varchar(50)) networkURI
				into #networks
				from #expand e
					inner join [RDF.].Triple t
						on t.subject = e.subject and t.predicate = e.predicate
							and (e.showStats = 1)
							and ((t.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (t.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (1 = CASE WHEN @HasSecurityGroupNodes = 0 THEN 0 WHEN t.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes) THEN 1 ELSE 0 END))
					inner join [RDF.].Node p
						on t.predicate = p.NodeID
							and ((p.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (p.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (1 = CASE WHEN @HasSecurityGroupNodes = 0 THEN 0 WHEN p.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes) THEN 1 ELSE 0 END))
					inner join [RDF.].Node o
						on t.object = o.NodeID
							and ((o.ViewSecurityGroup BETWEEN @SecurityGroupID AND -1) OR (o.ViewSecurityGroup > 0 AND @HasSpecialViewAccess = 1) OR (1 = CASE WHEN @HasSecurityGroupNodes = 0 THEN 0 WHEN o.ViewSecurityGroup IN (SELECT * FROM #SecurityGroupNodes) THEN 1 ELSE 0 END))
				group by e.uri, e.subject, t.predicate, e.property, e.tagName, e.PropertyLabel
			-- Create properties from network statistics
			;with networkProperties as (
				select 1 n, 'http://profiles.catalyst.harvard.edu/ontology/prns#hasNetwork' property, 'prns:hasNetwork' tagName, 'has network' propertyLabel, 0 ObjectType
				union all select 2, 'http://profiles.catalyst.harvard.edu/ontology/prns#numberOfConnections', 'prns:numberOfConnections', 'number of connections', 1
				union all select 3, 'http://profiles.catalyst.harvard.edu/ontology/prns#maxWeight', 'prns:maxWeight', 'maximum connection weight', 1
				union all select 4, 'http://profiles.catalyst.harvard.edu/ontology/prns#minWeight', 'prns:minWeight', 'minimum connection weight', 1
				union all select 5, 'http://profiles.catalyst.harvard.edu/ontology/prns#predicateNode', 'prns:predicateNode', 'predicate node', 0
				union all select 6, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#predicate', 'rdf:predicate', 'predicate', 0
				union all select 7, 'http://www.w3.org/2000/01/rdf-schema#label', 'rdfs:label', 'label', 1
				union all select 8, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type', 'rdf:type', 'type', 0
			)
			insert into #properties (uri,subject,predicate,property,tagName,propertyLabel,Value,ObjectType,SortOrder)
				select	(case p.n when 1 then n.uri else n.networkURI end),
						(case p.n when 1 then subject else null end),
						[RDF.].fnURI2NodeID(p.property), p.property, p.tagName, p.propertyLabel,
						(case p.n when 1 then n.networkURI 
									when 2 then n.numberOfConnections
									when 3 then n.maxWeight
									when 4 then n.minWeight
									when 5 then @baseURI+cast(n.predicate as varchar(50))
									when 6 then n.property
									when 7 then n.PropertyLabel
									when 8 then 'http://profiles.catalyst.harvard.edu/ontology/prns#Network'
									end),
						p.ObjectType,
						1
					from #networks n, networkProperties p
					where p.n = 1 or @expand = 1
		end
		-- Mark that all previous subjects have been expanded
		update #subjects set expanded = 1 where expanded = 0
		-- See if there are any new subjects that need to be expanded
		insert into #subjects(subject,showDetail,expanded,uri)
			select distinct object, 0, 0, value
				from #properties
				where showSummary = 1
					and ObjectType = 0
					and object not in (select subject from #subjects)
		select @NewSubjects = @@ROWCOUNT
		if(@includePredicates = 1)
		begin		
			insert into #subjects(subject,showDetail,expanded,uri)
				select distinct predicate, 0, 0, property
					from #properties
					where predicate is not null
						and predicate not in (select subject from #subjects)
			select @NewSubjects = @NewSubjects + @@ROWCOUNT
		end
		-- If no subjects need to be expanded, then we are done
		if @NewSubjects = 0
			select @numLoops = @maxLoops
		select @numLoops = @numLoops + 1 + @maxLoops * (1 - @expand)
		select @actualLoops = @actualLoops + 1
	end
	-- Add tagName as a property of DatatypeProperty and ObjectProperty classes
	insert into #properties (uri, subject, showSummary, property, tagName, propertyLabel, Value, ObjectType, SortOrder)
		select p.uri, p.subject, 0, 'http://profiles.catalyst.harvard.edu/ontology/prns#tagName', 'prns:tagName', 'tag name', 
				n.prefix+':'+substring(p.uri,len(n.uri)+1,len(p.uri)), 1, 1
			from #properties p, [Ontology.].Namespace n
			where p.property = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'
				and p.value in ('http://www.w3.org/2002/07/owl#DatatypeProperty','http://www.w3.org/2002/07/owl#ObjectProperty')
				and p.uri like n.uri+'%'
	--select @actualLoops
	--select * from #properties order by (case when uri = @firstURI then 0 else 1 end), uri, tagName, value


	--*******************************************************************************************
	--*******************************************************************************************
	-- Handle the special case where a local node is storing a copy of an external URI
	--*******************************************************************************************
	--*******************************************************************************************

	if (@firstValue IS NOT NULL) AND (@firstValue <> @firstURI)
		insert into #properties (uri, subject, predicate, object, 
				showSummary, property, 
				tagName, propertyLabel, 
				Language, DataType, Value, ObjectType, SortOrder
			)
			select @firstURI uri, @subject subject, predicate, object, 
					showSummary, property, 
					tagName, propertyLabel, 
					Language, DataType, Value, ObjectType, 1 SortOrder
				from #properties
				where uri = @firstValue
					and not exists (select * from #properties where uri = @firstURI)
			union all
			select @firstURI uri, @subject subject, null predicate, null object, 
					0 showSummary, 'http://www.w3.org/2002/07/owl#sameAs' property,
					'owl:sameAs' tagName, 'same as' propertyLabel, 
					null Language, null DataType, @firstValue Value, 0 ObjectType, 1 SortOrder

	--*******************************************************************************************
	--*******************************************************************************************
	-- Generate an XML string from the node properties table
	--*******************************************************************************************
	--*******************************************************************************************

	declare @description nvarchar(max)
	select @description = ''
	-- sort the tags
	select *, 
			row_number() over (partition by uri order by i) j, 
			row_number() over (partition by uri order by i desc) k 
		into #propertiesSorted
		from (
			select *, row_number() over (order by (case when uri = @firstURI then 0 else 1 end), uri, tagName, SortOrder, value) i
				from #properties
		) t
	create unique clustered index idx_i on #propertiesSorted(i)
	-- handle special xml characters in the uri and value strings
	update #propertiesSorted
		set uri = replace(replace(replace(uri,'&','&amp;'),'<','&lt;'),'>','&gt;')
		where uri like '%[&<>]%'
	update #propertiesSorted
		set value = replace(replace(replace(value,'&','&amp;'),'<','&lt;'),'>','&gt;')
		where value like '%[&<>]%'
	-- concatenate the tags
	select @description = (
			select (case when j=1 then '<rdf:Description rdf:about="' + uri + '">' else '' end)
					+'<'+tagName
					+(case when ObjectType = 0 then ' rdf:resource="'+value+'"/>' else '>'+value+'</'+tagName+'>' end)
					+(case when k=1 then '</rdf:Description>' else '' end)
			from #propertiesSorted
			order by i
			for xml path(''), type
		).value('(./text())[1]','nvarchar(max)')
	-- default description if none exists
	if (@description IS NULL) OR (@validURI = 0)
		select @description = '<rdf:Description rdf:about="' + @firstURI + '"'
			+IsNull(' xml:lang="'+@dataStrLanguage+'"','')
			+IsNull(' rdf:datatype="'+@dataStrDataType+'"','')
			+IsNull(' >'+replace(replace(replace(@dataStr,'&','&amp;'),'<','&lt;'),'>','&gt;')+'</rdf:Description>',' />')


	--*******************************************************************************************
	--*******************************************************************************************
	-- Return as a string or as XML
	--*******************************************************************************************
	--*******************************************************************************************

	select @dataStr = IsNull(@dataStr,@description)

	declare @x as varchar(max)
	select @x = '<rdf:RDF'
	select @x = @x + ' xmlns:'+Prefix+'="'+URI+'"' 
		from [Ontology.].Namespace
	select @x = @x + ' >' + @description + '</rdf:RDF>'

	if @returnXML = 1 and @returnXMLasStr = 0
		select cast(replace(@x,char(13),'&#13;') as xml) RDF

	if @returnXML = 1 and @returnXMLasStr = 1
		select @x RDF

	--update [RDF.].[GetDataRDF.DebugLog]
	--	set DurationMS = DATEDIFF(ms,StartDate,GetDate())
	--	where LogiD = @debugLogID

	/*	
		declare @d datetime
		select @d = getdate()
		select datediff(ms,@d,getdate())
	*/
		
END
GO
PRINT N'Creating [Direct.].[AddLogIncoming]...';


GO
CREATE PROCEDURE [Direct.].[AddLogIncoming]
	@Details bit,
	@RequestIP varchar(16),
	@QueryString varchar(1000)
AS
BEGIN
	INSERT INTO [Direct.].LogIncoming(Details,ReceivedDate,RequestIP,QueryString)
	values (@Details, GETDATE(), @RequestIP, @QueryString)
END
GO
PRINT N'Creating [Direct.].[AddLogOutgoing]...';


GO
CREATE PROCEDURE [Direct.].[AddLogOutgoing]
	@FSID uniqueidentifier,
	@SiteID int,
	@Details bit
AS
BEGIN
	INSERT INTO [Direct.].LogOutgoing(FSID, SiteID, Details, SentDate)
	values (@FSID, @SiteID, @Details, GETDATE())
END
GO
PRINT N'Creating [Direct.].[UpdateLogOutgoing]...';


GO
CREATE PROCEDURE [Direct.].[UpdateLogOutgoing]
	@FSID uniqueidentifier,
	@ResponseState int,
	@ResponseStatus int = NULL,
	@ResultText varchar(4000) = NULL,
	@ResultCount varchar(10) = NULL,
	@ResultDetailsURL varchar(1000) = NULL
AS
BEGIN
	UPDATE [Direct.].LogOutgoing SET ResponseTime = datediff(ms,SentDate,GetDate()),
	ResponseState = @ResponseState,
	ResponseStatus = ISNULL(@ResponseStatus, ResponseStatus),
	ResultText = ISNULL(@ResultText, ResultText),
	ResultCount = ISNULL(@ResultCount, ResultCount),
	ResultDetailsURL = ISNULL(@ResultDetailsURL, ResultDetailsURL)
	WHERE FSID = @FSID
END
GO

GO
PRINT N'Altering [Profile.Data].[Concept.Mesh.ParseMeshXML]...';

GO
ALTER PROCEDURE [Profile.Data].[Concept.Mesh.ParseMeshXML]
AS
BEGIN
	SET NOCOUNT ON;

	-- Clear any existing data
	TRUNCATE TABLE [Profile.Data].[Concept.Mesh.XML]
	TRUNCATE TABLE [Profile.Data].[Concept.Mesh.Descriptor]
	TRUNCATE TABLE [Profile.Data].[Concept.Mesh.Qualifier]
	TRUNCATE TABLE [Profile.Data].[Concept.Mesh.Term]
	TRUNCATE TABLE [Profile.Data].[Concept.Mesh.SemanticType]
	TRUNCATE TABLE [Profile.Data].[Concept.Mesh.SemanticType.XML]
	TRUNCATE TABLE [Profile.Data].[Concept.Mesh.SemanticGroupType]
	TRUNCATE TABLE [Profile.Data].[Concept.Mesh.SemanticGroup]
	TRUNCATE TABLE [Profile.Data].[Concept.Mesh.Tree]
	TRUNCATE TABLE [Profile.Data].[Concept.Mesh.TreeTop]

	-- Extract items from SemGroups.xml
	INSERT INTO [Profile.Data].[Concept.Mesh.SemanticGroupType] (SemanticGroupUI,SemanticGroupName,SemanticTypeUI,SemanticTypeName)
		SELECT 
			S.x.value('SemanticGroupUI[1]','varchar(10)'),
			S.x.value('SemanticGroupName[1]','varchar(50)'),
			S.x.value('SemanticTypeUI[1]','varchar(10)'),
			S.x.value('SemanticTypeName[1]','varchar(50)')
		FROM [Profile.Data].[Concept.Mesh.File] CROSS APPLY Data.nodes('//SemanticType') AS S(x)
		WHERE Name = 'SemGroups.xml'

	-- Extract items from SemTypes.xml
	INSERT INTO [Profile.Data].[Concept.Mesh.SemanticType.XML] (DescriptorUI, x)
		SELECT
				D.x.value('DescriptorUI[1]','varchar(100)'),
				D.x.query('SemanticTypeList[1]') SemanticTypeName
			FROM [Profile.Data].[Concept.Mesh.File] m 
				CROSS APPLY Data.nodes('//DescriptorRecord') AS D(x)
				WHERE Name = 'SemTypes.xml'

	INSERT INTO [Profile.Data].[Concept.Mesh.SemanticType] (DescriptorUI, SemanticTypeUI, SemanticTypeName)
		SELECT
				DescriptorUI,
				D.x.value('SemanticTypeUI[1]','varchar(10)') SemanticTypeUI,
				D.x.value('SemanticTypeName[1]','varchar(50)') SemanticTypeName
			FROM [Profile.Data].[Concept.Mesh.SemanticType.XML] m 
				CROSS APPLY X.nodes('//SemanticType') AS D(x)
		
	INSERT INTO [Profile.Data].[Concept.Mesh.SemanticGroup] (DescriptorUI, SemanticGroupUI, SemanticGroupName)
		SELECT DISTINCT t.DescriptorUI, g.SemanticGroupUI, g.SemanticGroupName
			FROM [Profile.Data].[Concept.Mesh.SemanticGroupType] g, [Profile.Data].[Concept.Mesh.SemanticType] t
			WHERE g.SemanticTypeUI = t.SemanticTypeUI

		-- Extract items from MeSH2011.xml
	INSERT INTO [Profile.Data].[Concept.Mesh.XML] (DescriptorUI, MeSH)
		SELECT D.x.value('DescriptorUI[1]','varchar(10)'), D.x.query('.')
			FROM [Profile.Data].[Concept.Mesh.File] CROSS APPLY Data.nodes('//DescriptorRecord') AS D(x)
			WHERE Name = 'MeSH.xml'


	---------------------------------------
	-- Parse MeSH XML and populate tables
	---------------------------------------


	INSERT INTO [Profile.Data].[Concept.Mesh.Descriptor] (DescriptorUI, DescriptorName)
		SELECT DescriptorUI, MeSH.value('DescriptorRecord[1]/DescriptorName[1]/String[1]','varchar(255)')
			FROM [Profile.Data].[Concept.Mesh.XML]

	INSERT INTO [Profile.Data].[Concept.Mesh.Qualifier] (DescriptorUI, QualifierUI, DescriptorName, QualifierName, Abbreviation)
		SELECT	m.DescriptorUI,
				Q.x.value('QualifierReferredTo[1]/QualifierUI[1]','varchar(10)'),
				m.MeSH.value('DescriptorRecord[1]/DescriptorName[1]/String[1]','varchar(255)'),
				Q.x.value('QualifierReferredTo[1]/QualifierName[1]/String[1]','varchar(255)'),
				Q.x.value('Abbreviation[1]','varchar(2)')
			FROM [Profile.Data].[Concept.Mesh.XML] m CROSS APPLY MeSH.nodes('//AllowableQualifier') AS Q(x)

	SELECT	m.DescriptorUI,
			C.x.value('ConceptUI[1]','varchar(10)') ConceptUI,
			m.MeSH.value('DescriptorRecord[1]/DescriptorName[1]/String[1]','varchar(255)') DescriptorName,
			C.x.value('@PreferredConceptYN[1]','varchar(1)') PreferredConceptYN,
			C.x.value('ConceptRelationList[1]/ConceptRelation[1]/@RelationName[1]','varchar(3)') RelationName,
			C.x.value('ConceptName[1]/String[1]','varchar(255)') ConceptName,
			C.x.query('.') ConceptXML
		INTO #c
		FROM [Profile.Data].[Concept.Mesh.XML] m 
			CROSS APPLY MeSH.nodes('//Concept') AS C(x)

	INSERT INTO [Profile.Data].[Concept.Mesh.Term] (DescriptorUI, ConceptUI, TermUI, TermName, DescriptorName, PreferredConceptYN, RelationName, ConceptName, ConceptPreferredTermYN, IsPermutedTermYN, LexicalTag)
		SELECT	DescriptorUI,
				ConceptUI,
				T.x.value('TermUI[1]','varchar(10)'),
				T.x.value('String[1]','varchar(255)'),
				DescriptorName,
				PreferredConceptYN,
				RelationName,
				ConceptName,
				T.x.value('@ConceptPreferredTermYN[1]','varchar(1)'),
				T.x.value('@IsPermutedTermYN[1]','varchar(1)'),
				T.x.value('@LexicalTag[1]','varchar(3)')
			FROM #c C CROSS APPLY ConceptXML.nodes('//Term') AS T(x)

	INSERT INTO [Profile.Data].[Concept.Mesh.Tree] (DescriptorUI, TreeNumber)
		SELECT	m.DescriptorUI,
				T.x.value('.','varchar(255)')
			FROM [Profile.Data].[Concept.Mesh.XML] m 
				CROSS APPLY MeSH.nodes('//TreeNumber') AS T(x)

	INSERT INTO [Profile.Data].[Concept.Mesh.TreeTop] (TreeNumber, DescriptorName)
		SELECT	T.x.value('.','varchar(255)'),
				m.MeSH.value('DescriptorRecord[1]/DescriptorName[1]/String[1]','varchar(255)')
			FROM [Profile.Data].[Concept.Mesh.XML] m 
				CROSS APPLY MeSH.nodes('//TreeNumber') AS T(x)
	UPDATE [Profile.Data].[Concept.Mesh.TreeTop]
		SET TreeNumber = left(TreeNumber,1)+'.'+TreeNumber
	INSERT INTO [Profile.Data].[Concept.Mesh.TreeTop] VALUES ('A','Anatomy')
	INSERT INTO [Profile.Data].[Concept.Mesh.TreeTop] VALUES ('B','Organisms')
	INSERT INTO [Profile.Data].[Concept.Mesh.TreeTop] VALUES ('C','Diseases')
	INSERT INTO [Profile.Data].[Concept.Mesh.TreeTop] VALUES ('D','Chemicals and Drugs')
	INSERT INTO [Profile.Data].[Concept.Mesh.TreeTop] VALUES ('E','Analytical, Diagnostic and Therapeutic Techniques and Equipment')
	INSERT INTO [Profile.Data].[Concept.Mesh.TreeTop] VALUES ('F','Psychiatry and Psychology')
	INSERT INTO [Profile.Data].[Concept.Mesh.TreeTop] VALUES ('G','Biological Sciences')
	INSERT INTO [Profile.Data].[Concept.Mesh.TreeTop] VALUES ('H','Natural Sciences')
	INSERT INTO [Profile.Data].[Concept.Mesh.TreeTop] VALUES ('I','Anthropology, Education, Sociology and Social Phenomena')
	INSERT INTO [Profile.Data].[Concept.Mesh.TreeTop] VALUES ('J','Technology, Industry, Agriculture')
	INSERT INTO [Profile.Data].[Concept.Mesh.TreeTop] VALUES ('K','Humanities')
	INSERT INTO [Profile.Data].[Concept.Mesh.TreeTop] VALUES ('L','Information Science')
	INSERT INTO [Profile.Data].[Concept.Mesh.TreeTop] VALUES ('M','Named Groups')
	INSERT INTO [Profile.Data].[Concept.Mesh.TreeTop] VALUES ('N','Health Care')
	INSERT INTO [Profile.Data].[Concept.Mesh.TreeTop] VALUES ('V','Publication Characteristics')
	INSERT INTO [Profile.Data].[Concept.Mesh.TreeTop] VALUES ('Z','Geographicals')

END
GO


PRINT N'Refreshing [Search.Cache].[Public.GetConnection]...';


GO
EXECUTE sp_refreshsqlmodule N'[Search.Cache].[Public.GetConnection]';


GO
PRINT N'Refreshing [Search.Cache].[Private.GetConnection]...';


GO
EXECUTE sp_refreshsqlmodule N'[Search.Cache].[Private.GetConnection]';


GO
PRINT N'Refreshing [Search.].[GetConnection]...';


GO
EXECUTE sp_refreshsqlmodule N'[Search.].[GetConnection]';


GO
PRINT N'Update complete.';


GO
