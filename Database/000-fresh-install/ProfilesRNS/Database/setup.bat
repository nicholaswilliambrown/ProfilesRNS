@echo off
echo.
echo Usage: %0 ^(for this usage message^) ^|
echo        %0 ^(In this order, any or all of:^)
echo             initial pubMedDisambiguation pubMedXML bibliometrics funding rdf jobGroups
echo         NB: sanity ^(for DB sanity check^) can occur anywhere ^(and multiple times^) in the above sequence
echo.

set INSTALL_DRIVE=z:
set INSTALL_PATH=\work\ProfilesRNS-OpenSource\Database\000-fresh-install\ProfilesRNS\Database
set DOT_NET_PERSON_DATA_BIN_PATH=\work\ProfilesRNS-OpenSource\Database\.NET_ProfilesRNS_CallPRNSWebservice\bin\Debug\Net8.0
set SERVER=10.211.55.2
set DB_NAME=ProfilesRNS
set SA_PW=DB_Password

for %%x in (%*) do (
  call :doStep %%x
)
exit /b 0
echo should not get here

:doStep
echo.
set step=%~1
echo --------- arg is %step%
if /I %step% == pubMedDisambiguation (
   set step=PubMedDisambiguation_GetPubs
   call :doJob %step%
   goto :bye
)
if /I %step% == pubMedXML (
   set step=GetPubMedXML
   call :doJob %step%
   goto :bye
)
if /I %step% == funding (
   call :doJob %step%
   goto :bye
)
if /I %step% == rdf (
   call :doJob %step%
   goto :bye
)

call :%step%
    goto :bye

:bye
cd %INSTALL_PATH%
exit /b

:doJob
cd %DOT_NET_PERSON_DATA_BIN_PATH%
echo --------- Prerequisite: ProfilesRNS_CallPRNSWebservice.exe has been built
echo --------- ProfilesRNS_CallPRNSWebservice.exe -server %SERVER% -database %DB_NAME% -username sa -password %SA_PW% -job %step%
ProfilesRNS_CallPRNSWebservice.exe -server %SERVER% -database %DB_NAME% -username sa -password %SA_PW% -job %step%
   goto :bye

:sanity
echo.
echo ----------------------------------Sanity check
echo --------------------SELECT job from [Profile.Import].[PRNSWebservice.Options]
sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "SELECT job from [Profile.Import].[PRNSWebservice.Options]"                                             | findstr /V /R /C:"[0-9]"
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
echo --------------------Select count(*) from [Profile.Data].[Publication.Pubmed.Allxml]
sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "SET NOCOUNT ON; Select count(*) from [profile.data].[publication.pubmed.allxml]"                       | findstr /R /C:"[0-9]"
echo.
   goto :bye

:initial
%INSTALL_DRIVE%
cd %INSTALL_PATH%
echo.
echo ----------------------------------Creating new %DB_NAME% database
sqlcmd -S %SERVER% -U sa -P %SA_PW% -d master -i ProfilesRNS_CreateDatabase.sql
echo.
echo --------------------------------- Prerequisite: Data for job creation has been copied to the server
echo ----------------------------------Creating %DB_NAME% schema
sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -i ProfilesRNS_CreateSchema.sql
echo.
echo ----------------------------------Creating user account
sqlcmd -S %SERVER% -U sa -P %SA_PW% -d master -i ProfilesRNS_CreateAccount.sql
echo.
echo ----------------------------------Data load, part 1, after copying data to server (to folder /tmp), and adjusting the sql file per docs
sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -i ProfilesRNS_DataLoad_Part1.sql
echo.
echo ----------------------------------Load person import data, perhaps (but not in this script) from favorite other DB
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

:rdf
echo ----------------------------------RDF conversion
sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -i ProfilesRNS_DataLoad_Part3.sql
   goto :bye

:jobGroups
echo ----------------------------------Run JobGroups
sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "EXEC [Framework.].[RunJobGroup] @JobGroup = 4"
sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "EXEC [Framework.].[RunJobGroup] @JobGroup = 5"
sqlcmd -S %SERVER% -U sa -P %SA_PW% -d %DB_NAME% -Q "EXEC [Framework.].[RunJobGroup] @JobGroup = 6"
echo EXEC [Framework.].[RunJobGroup] @JobGroup = 3
echo.
   goto :bye



