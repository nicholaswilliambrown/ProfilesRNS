/*
Run this script on:

        Profiles 3.2.0   -  This database will be modified

to synchronize it with:

        Profiles 4.0.0

You are recommended to back up your database before running this script

Details of which objects have changed can be found in the release notes.
If you have made changes to existing tables or stored procedures in profiles, you may need to merge changes individually. 

NEW TABLES:
[Display.].[Activity.Log.MethodDetails]
[Display.].DataPath
[Display.].GetJsonLog
[Display.].GetProfileDataLog
[Display.].ModuleMapping
[Display.].[SearchEverything.Filters]
[Profile.Cache].[Concept.Mesh.URL]

*/


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Display.].[Activity.Log.MethodDetails](
	[methodName] [nvarchar](255) NULL,
	[Property] [nvarchar](255) NULL,
	[label] [varchar](255) NULL
) ON [PRIMARY]
GO



SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Display.].[DataPath](
	[PresentationID] [int] NOT NULL,
	[Tab] [varchar](16) NOT NULL,
	[Sort] [int] NOT NULL,
	[subject] [bit] NULL,
	[predicate] [bit] NULL,
	[object] [bit] NULL,
	[dataTab] [varchar](16) NULL,
	[pageSecurityType] [varchar](32) NULL,
	[cacheLength] [varchar](32) NULL,
	[BotIndex] [bit] NULL,
	[PresentationType] [char](1) NULL,
	[PresentationSubject] [nvarchar](400) NULL,
	[PresentationPredicate] [nvarchar](400) NULL,
	[PresentationObject] [nvarchar](400) NULL,
 CONSTRAINT [PK_Display__DataPath] PRIMARY KEY CLUSTERED 
(
	[PresentationID] ASC,
	[Tab] ASC,
	[Sort] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO





SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Display.].[GetJsonLog](
	[getJsonLogID] [int] IDENTITY(1,1) NOT NULL,
	[timestamp] [datetime] NULL,
	[subject] [bigint] NULL,
	[predicate] [bigint] NULL,
	[object] [bigint] NULL,
	[tab] [varchar](16) NULL,
	[SessionID] [uniqueidentifier] NULL
) ON [PRIMARY]
GO




SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Display.].[GetProfileDataLog](
	[GetProfileDataLogID] [int] IDENTITY(1,1) NOT NULL,
	[timestamp] [datetime] NULL,
	[param1] [varchar](max) NULL,
	[param2] [varchar](max) NULL,
	[param3] [varchar](max) NULL,
	[param4] [varchar](max) NULL,
	[param5] [varchar](max) NULL,
	[param6] [varchar](max) NULL,
	[param7] [varchar](max) NULL,
	[param8] [varchar](max) NULL,
	[param9] [varchar](max) NULL,
	[SessionID] [uniqueidentifier] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO





SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Display.].[ModuleMapping](
	[PresentationID] [int] NOT NULL,
	[ClassProperty] [varchar](400) NULL,
	[_ClassPropertyID] [bigint] NULL,
	[DisplayModule] [varchar](max) NULL,
	[DataStoredProc] [varchar](max) NULL,
	[Tab] [varchar](16) NULL,
	[LayoutModule] [bit] NOT NULL,
	[GroupLabel] [varchar](100) NULL,
	[PropertyLabel] [varchar](100) NULL,
	[ToolTip] [varchar](max) NULL,
	[Panel] [varchar](10) NULL,
	[SortOrder] [int] NULL,
	[LayoutDataModule] [bit] NOT NULL,
	[PresentationType] [char](1) NULL,
	[PresentationSubject] [nvarchar](400) NULL,
	[PresentationPredicate] [nvarchar](400) NULL,
	[PresentationObject] [nvarchar](400) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [Display.].[ModuleMapping] ADD  DEFAULT ((0)) FOR [LayoutModule]
GO
ALTER TABLE [Display.].[ModuleMapping] ADD  DEFAULT ((0)) FOR [LayoutDataModule]
GO




SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Display.].[SearchEverything.Filters](
	[Class] [varchar](255) NULL,
	[_NodeID] [bigint] NULL,
	[Label] [varchar](255) NULL,
	[pluralLabel] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO





SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Profile.Cache].[Concept.Mesh.URL](
	[DescriptorName] [varchar](255) NOT NULL,
	[NodeID] [bigint] NULL,
	[DescriptorUI] [varchar](10) NOT NULL,
	[URL] [varchar](553) NULL,
	[DefaultApplication] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[DescriptorName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO





PRINT N'Update complete.';


GO

