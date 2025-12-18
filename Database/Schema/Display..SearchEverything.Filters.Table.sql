SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [Display.].[SearchEverything.Filters](
	[Class] [varchar](255) NULL,
	[_NodeID] [bigint] NULL,
	[Label] [varchar](255) NULL,
	[pluralLabel] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

