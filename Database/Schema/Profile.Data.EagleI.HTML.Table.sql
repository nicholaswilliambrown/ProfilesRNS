SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [Profile.Data].[EagleI.HTML](
	[EagleIID] [int] IDENTITY(1,1) NOT NULL,
	[NodeID] [bigint] NOT NULL,
	[PersonID] [bigint] NOT NULL,
	[EagleIURI] [varchar](500) NULL,
	[HTML] [nvarchar](max) NULL,
PRIMARY KEY CLUSTERED 
(
	[EagleIID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO
