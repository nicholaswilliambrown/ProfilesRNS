
-- sqlcmd -S 10.0.0.182 -U sa -P DB_Password -d master -Q "SELECT name FROM master.dbo.sysdatabases"
-- sqlcmd -S 10.0.0.182 -U sa -P DB_Password -d master -Q "RESTORE DATABASE HCProfileOpenSource_Localhost FROM DISK = N'Z:\work\4dev-profiles\docker\HCProfileOpenSource_Localhost.bak' WITH MOVE N'Log' TO N'Z:\Downloads', MOVE N'Data' TO N'Z:\Downloads'"

--------------------------------------------------------
-- search: mssql restore database using vs code
RESTORE DATABASE HCProfileOpenSource_Localhost FROM DISK = N'Z:/tmp/HCPRofilesLocalhost.bak' WITH FILE = 1, MOVE N'HCProfilesOpenSource_Localhost' TO N'/tmp/HCProfileOpenSource_Localhost.mdf', MOVE N'HCProfilesOpenSource_Localhost_log' TO N'/tmp/HCProfileOpenSource_Localhost_log.ldf', NOUNLOAD, STATS = 10;

--------------------------------------------------------
-- nick's script helps to associate login user w existing DB user App_ProfilesLocalhost


IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'App_ProfilesLocalhost')
    BEGIN
        DROP LOGIN [App_ProfilesLocalhost];
    END;
GO

CREATE LOGIN [App_ProfilesLocalhost] WITH PASSWORD=N'Password1234', DEFAULT_DATABASE=[HCProfileOpenSource_Localhost], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO


USE [HCProfileOpenSource_Localhost]
GO

DROP USER IF EXISTS [App_ProfilesLocalhost];
GO

CREATE USER [App_ProfilesLocalhost] FOR LOGIN [App_ProfilesLocalhost] WITH DEFAULT_SCHEMA=[dbo]
GO

EXEC sp_addrolemember N'db_datareader', N'App_ProfilesLocalhost'
GO
SET NOCOUNT ON
DECLARE @user SYSNAME

-- 2 - Set @user variable
SELECT @user='App_ProfilesLocalhost'

-- 4 - Populate temporary table
SELECT  'GRANT EXEC ON ' + '[' + ROUTINE_SCHEMA + ']' + '.' + '[' +ROUTINE_NAME + ']' + ' TO ' + @user
            call
INTO #storedprocedures
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_NAME NOT LIKE 'dt_%'
  AND ROUTINE_TYPE = 'PROCEDURE'

-- 6 - WHILE loop
WHILE exists (SELECT TOP 1 * FROM #storedprocedures  )
    BEGIN

        DECLARE @sql varchar(max)
        SELECT TOP 1 @sql=call
        FROM #storedprocedures
        DELETE
        FROM #storedprocedures
        WHERE call=@sql
        EXEC (@SQL)
    END
DROP TABLE #storedprocedures

GRANT EXECUTE ON [Utility.Application].[fnDecryptBase64RC4] TO App_ProfilesLocalhost
GO
GRANT EXECUTE ON [Utility.Application].[fnEncryptBase64RC4] TO App_ProfilesLocalhost
GO
GRANT EXECUTE ON [RDF.].[fnValueHash] TO App_ProfilesLocalhost
GO
GRANT EXECUTE ON [RDF.].[fnNodeID2TypeID] TO App_ProfilesLocalhost
GO