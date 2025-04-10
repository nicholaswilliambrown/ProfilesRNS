SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
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
	[LayoutDataModule] [bit] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [Display.].[ModuleMapping] ADD  DEFAULT ((0)) FOR [LayoutModule]
GO

ALTER TABLE [Display.].[ModuleMapping] ADD  DEFAULT ((0)) FOR [LayoutDataModule]
GO

