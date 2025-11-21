@echo off
echo.
echo Usage: %0 ^(for this usage message^) ^|
echo        %0 In the following order, any or all of:
echo             initial PubMedDisambiguation_GetPubs GetPubMedXML bibliometrics funding rdf jobGroups
echo         NB: sanity ^(for DB sanity check^) can occur anywhere ^(and multiple times^) in the above sequence
echo.

set INSTALL_DRIVE=y:
set INSTALL_DATA_PATH=\work\ProfilesRNS-OpenSource\Database\002-20nov\ProfilesRNS\Database
set INSTALL_BATCH_PATH=\work\ProfilesRNS-OpenSource\Database\000-BatchSetup
set DOT_NET_PERSON_DATA_BIN_PATH=\work\ProfilesRNS-OpenSource\Database\.NET_ProfilesRNS_CallPRNSWebservice\bin\Debug\Net8.0
set SERVER=10.211.55.2
set DB_NAME=ProfilesRNS
set SA_PW=DB_Password
set APP_BASE_PATH=http://localhost:55956
set SERVER_DATA_PATH=z:\tmp

for %%x in (%*) do (
  call :doTask %%x
)
goto :bye

:doTask
    echo.
    set task=%~1
    echo ============= Start task: %task% at =============  %date% %time%
    set jobTask=no
    FOR %%G IN ("PubMedDisambiguation_GetPubs", "GetPubMedXML", "bibliometrics", "funding") DO (IF /I "x%1" == "x%%~G" set jobTask=yes)
    IF "x%jobTask%" == "xyes" ( call :doJob %1 ) ELSE ( call :%1 )
    echo ============= Done task: %task% at =============  %date% %time%
goto :bye

:doJob
    cd %DOT_NET_PERSON_DATA_BIN_PATH%
    echo --------- Prerequisite: ProfilesRNS_CallPRNSWebservice.exe has been built
    echo --------- ProfilesRNS_CallPRNSWebservice.exe -server %SERVER% -database %DB_NAME% -username sa -password %SA_PW% -job %task%
    ProfilesRNS_CallPRNSWebservice.exe -server %SERVER% -database %DB_NAME% -username sa -password %SA_PW% -job %task%
    echo --------- Done with job: %task%
goto :bye

:initial
    %INSTALL_DRIVE%
    cd %INSTALL_DATA_PATH%
    echo.
    echo ----------------------------------Creating new %DB_NAME% database
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d master -i ProfilesRNS_CreateDatabase.sql
    echo.
    echo --------------------------------- Prerequisite: Data for job creation has been copied to the server (to folder %SERVER_DATA_PATH%)
    echo ----------------------------------Creating %DB_NAME% schema
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -i ProfilesRNS_CreateSchema.sql
    echo.
    echo ----------------------------------Creating user account
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d master -i ProfilesRNS_CreateAccount.sql
    echo.
    echo ----------------------------------Data load, part 1, folded into this script
    call :dataLoadPart1
    echo.
    echo ----------------------------------Load person import data (not done by this script), perhaps from favorite other DB
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -i profileImportPersonData.sql  > nul
    echo.
    echo ----------------------------------Validate that person import data
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "exec [Profile.Import].ValidateProfilesImportTables"
    echo.
    echo ----------------------------------Harvest person data from import
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "exec [Profile.Import].LoadProfilesData"
    echo.
    echo ----------------------------------Load sample affiliation strings
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -i harvardAffiliationStringSample.sql
    echo.
    echo ----------------------------------Load funding disambiguation strings
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -i fundingDisambiguationSample.sql
    echo.
goto :bye

:dataLoadPart1
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "EXEC [Framework.].[LoadXMLFile] @FilePath = N'%SERVER_DATA_PATH%\Data\InstallData.xml', @TableDestination = '[Framework.].[InstallData]', @DestinationColumn = 'DATA'"
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "EXEC [Framework.].[LoadXMLFile] @FilePath = N'%SERVER_DATA_PATH%\Data\VIVO_1.4.owl', @TableDestination = '[Ontology.Import].owl', @DestinationColumn = 'DATA', @NameValue = 'VIVO_1.4'"
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "EXEC [Framework.].[LoadXMLFile] @FilePath = N'%SERVER_DATA_PATH%\Data\PRNS_1.4.owl', @TableDestination = '[Ontology.Import].owl', @DestinationColumn = 'DATA', @NameValue = 'PRNS_1.4'"
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "EXEC [Framework.].[LoadXMLFile] @FilePath = N'%SERVER_DATA_PATH%\Data\SemGroups.xml', @TableDestination = '[Profile.Data].[Concept.Mesh.File]', @DestinationColumn = 'DATA', @NameValue = 'SemGroups.xml'"
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "EXEC [Framework.].[LoadXMLFile] @FilePath = N'%SERVER_DATA_PATH%\Data\SemTypes.xml', @TableDestination = '[Profile.Data].[Concept.Mesh.File]', @DestinationColumn = 'DATA', @NameValue = 'SemTypes.xml'"
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "EXEC [Framework.].[LoadXMLFile] @FilePath = N'%SERVER_DATA_PATH%\Data\MeSH.xml', @TableDestination = '[Profile.Data].[Concept.Mesh.File]', @DestinationColumn = 'DATA', @NameValue = 'MeSH.xml'"
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "EXEC [Framework.].[LoadInstallData]"
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "UPDATE [Framework.].[Parameter] SET Value = N'%APP_BASE_PATH%' WHERE ParameterID = 'basePath'"
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "EXEC [Framework.].[RunJobGroup] @JobGroup = 1"
goto :bye

:rdf
    echo ----------------------------------Run miscellaneous jobs
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "exec  [Profile.Data].[Publication.Pubmed.ParseALLPubMedXML]"
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "exec  [Profile.Data].[Publication.Pubmed.LoadDisambiguationResults]"
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "exec [Profile.Data].[Funding.LoadDisambiguationResults]"

    echo ----------------------------------RDF conversion
    :: ProfilesRNS_DataLoad_Part3.sql took too long with no indication of progress
    echo EXEC [Framework.].[RunJobGroup] @JobGroup = 10
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "EXEC [Framework.].[RunJobGroup] @JobGroup = 10"
    echo EXEC [Framework.].[RunJobGroup] @JobGroup = 7
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "EXEC [Framework.].[RunJobGroup] @JobGroup = 7"
    echo EXEC [Framework.].[RunJobGroup] @JobGroup = 8
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "EXEC [Framework.].[RunJobGroup] @JobGroup = 8"
    echo EXEC [Framework.].[RunJobGroup] @JobGroup = 9
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "EXEC [Framework.].[RunJobGroup] @JobGroup = 9"
    echo EXEC [Framework.].[RunJobGroup] @JobGroup = 3
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "EXEC [Framework.].[RunJobGroup] @JobGroup = 3"
    echo EXEC [Profile.Cache].[Concept.UpdatePreferredPath]
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "EXEC [Profile.Cache].[Concept.UpdatePreferredPath]"
goto :bye

:jobGroups
    echo ----------------------------------Run JobGroups
    echo sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "EXEC [Framework.].[RunJobGroup] @JobGroup = 4"
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "EXEC [Framework.].[RunJobGroup] @JobGroup = 4"
    echo sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "EXEC [Framework.].[RunJobGroup] @JobGroup = 5"
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "EXEC [Framework.].[RunJobGroup] @JobGroup = 5"
    echo sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "EXEC [Framework.].[RunJobGroup] @JobGroup = 6"
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "EXEC [Framework.].[RunJobGroup] @JobGroup = 6"
    echo.
goto :bye

:bye
    cd %INSTALL_BATCH_PATH%
    exit /b 0 :: 0 may let it try subsequent task even if one fails


:sanity
    echo.
    echo ----------------------------------Sanity check
    echo --------------------select count(*)  from [RDF.Stage].[Log.DataMap]
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "select count(*) from [RDF.Stage].[Log.DataMap]"                                                        | findstr /R /C:"[0-9]
    echo --------------------SELECT * FROM [Framework.].[Job] o WHERE  o.Status = 'PROCESSING'"
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "SELECT * FROM [Framework.].[Job] o WHERE  o.Status = 'PROCESSING'"                                     | findstr /R /C:"[0-9]
    echo --------------------SELECT job from [Profile.Import].[PRNSWebservice.Options]
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "SELECT job from [Profile.Import].[PRNSWebservice.Options]"
    echo --------------------SELECT JobGroup,Name FROM [Framework.].JobGroup
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "SELECT JobGroup,Name FROM [Framework.].JobGroup"
    echo --------------------Select count(*) from [Profile.Import].[Person]
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "SET NOCOUNT ON; Select count(*) from [profile.import].[Person]"                                        | findstr /R /C:"[0-9]"
    echo --------------------Select count(*) from [Profile.Import].[PersonAffiliation]
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "SET NOCOUNT ON; Select count(*) from [profile.import].[PersonAffiliation]"                             | findstr /R /C:"[0-9]"
    echo --------------------Select count(*) from [Profile.Data].[Person]
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "SET NOCOUNT ON; Select count(*) from [Profile.Data].[Person]"                                          | findstr /R /C:"[0-9]"
    echo --------------------Select count(*) from [Profile.Data].[Publication.PubMed.DisambiguationAffiliation]
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "SET NOCOUNT ON; Select count(*) from [Profile.Data].[Publication.PubMed.DisambiguationAffiliation]"    | findstr /R /C:"[0-9]"
    echo --------------------Select count(*) from [Profile.Data].[Funding.DisambiguationOrganizationMapping]
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "SET NOCOUNT ON; Select count(*) from [Profile.Data].[Funding.DisambiguationOrganizationMapping]"       | findstr /R /C:"[0-9]"
    echo --------------------Select count(*) from [Profile.Data].[Funding.DisambiguationResults]
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "SET NOCOUNT ON; Select count(*) from [Profile.Data].[Funding.DisambiguationResults]"                   | findstr /R /C:"[0-9]"
    echo --------------------Select count(*) from [Profile.Data].[Publication.PubMed.AllXML]
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "SET NOCOUNT ON; Select count(*) from [Profile.Data].[Publication.PubMed.AllXML]"
    echo --------------------Select count(*) from [Profile.Data].[Publication.PubMed.General]
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "SET NOCOUNT ON; Select count(*) from [Profile.Data].[Publication.PubMed.General]"
    echo --------------------Select count(*) from [Profile.Data].[Publication.PubMed.Disambiguation]
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "SET NOCOUNT ON; Select count(*) from [Profile.Data].[Publication.PubMed.Disambiguation]"
    echo --------------------Select count(*) from [Profile.Data].[Publication.Person.Include]
    sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "SET NOCOUNT ON; Select count(*) from [Profile.Data].[Publication.Person.Include]"
    echo .
goto :bye
