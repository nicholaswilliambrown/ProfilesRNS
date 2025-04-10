SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
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
