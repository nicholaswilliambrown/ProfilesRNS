SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Profile.Data].[Publication.Group.Include](
	[PubID] [uniqueidentifier] NOT NULL,
	[GroupID] [int] NULL,
	[PMID] [int] NULL,
	[MPID] [nvarchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[PubID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
