SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

CREATE TABLE [Profile.Data].[Publication.Pubmed.DisambiguationSettings](
	[PersonID] [int] NOT NULL,
	[Enabled] [bit] NULL,
	[PubMedSearchTerm]        VARCHAR (MAX) NULL,
    [PubMedSearchTermEnabled] BIT           NULL,
    [ORCID]                   VARCHAR (MAX) NULL,
    [SyncFromORCID]           BIT           NULL,
PRIMARY KEY CLUSTERED 
(
	[PersonID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
