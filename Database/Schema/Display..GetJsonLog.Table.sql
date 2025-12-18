SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
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
