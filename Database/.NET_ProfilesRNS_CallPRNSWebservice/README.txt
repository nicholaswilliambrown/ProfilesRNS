This is a .Net version of the code to call disambiguation/bibliometrics/funding/geocoding webservices to populating a profiles database. 

This is Pre-Production code. It has had some testing, however it is not currently fully tested. It is also does not have robust error handling code. Debugging issues in disambiguation using this code probably involves running the code in debug mode in visual studio.

Open cmd.exe and navigate to the bin\Debug\net5.0 folder. 

Run the following 4 commands (edit database, username and password first):

ProfilesRNS_CallPRNSWebservice.exe -server . -database ProfilesRNS -username App_profiles10 -password Password1234 -job PubMedDisambiguation_GetPubs

ProfilesRNS_CallPRNSWebservice.exe -server . -database ProfilesRNS -username App_profiles10 -password Password1234 -job GetPubMedXML

ProfilesRNS_CallPRNSWebservice.exe -server . -database ProfilesRNS -username App_profiles10 -password Password1234 -job bibliometrics

ProfilesRNS_CallPRNSWebservice.exe -server . -database ProfilesRNS -username App_profiles10 -password Password1234 -job funding


After these have run, run the following in SSMS:

EXEC [Framework.].[RunJobGroup] @JobGroup = 7
EXEC [Framework.].[RunJobGroup] @JobGroup = 8
EXEC [Framework.].[RunJobGroup] @JobGroup = 9
EXEC [Framework.].[RunJobGroup] @JobGroup = 3

These can be configured as part of a SQL Server Agent job. Scripts will be included in a future release.