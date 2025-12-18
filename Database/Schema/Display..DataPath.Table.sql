SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
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

