USE HCProfileOpenSource_Localhost;
GO

DROP TABLE IF EXISTS [Profile.Data].[List.SavedLists.General];
CREATE TABLE [Profile.Data].[List.SavedLists.General] (
    ListID int IDENTITY(1,1) NOT NULL,
    UserID int NULL,
    Name varchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CreateDate datetime NULL,
    UpdatedDate datetime NULL,
    [Size] int NULL,
    CONSTRAINT [PK__List.Sav__E3832865DBACA274] PRIMARY KEY (ListID)
    );
GO

DROP TABLE IF EXISTS [Profile.Data].[List.SavedLists.Member];
CREATE TABLE [Profile.Data].[List.SavedLists.Member] (
   ListID int NOT NULL,
   PersonID int NOT NULL,
   CONSTRAINT [PK__List.Sav__A921D7DDA14FDF6E] PRIMARY KEY (ListID,PersonID)
);
GO

DROP TABLE IF EXISTS [Debug.].DebugLog;
CREATE TABLE [Debug.].DebugLog (
                                                 LogID int IDENTITY(1,1) NOT NULL,
    [Date] datetime NULL,
    ProcedureName varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    LocationID int NULL,
    Message varchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONSTRAINT PK__DebugLog__5E5499A8B5204B1A PRIMARY KEY (LogID)
    );
GO
