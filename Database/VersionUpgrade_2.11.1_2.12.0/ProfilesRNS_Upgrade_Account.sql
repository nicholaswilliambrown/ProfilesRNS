/*
Run this script on:

        Profiles 2.11.1   -  This database will be modified

to synchronize it with:

        Profiles 2.12.0

You are recommended to back up your database before running this script

This script updates permissions for the App_Profiles10 database user. 
If you use a different user to connect your Profiles application to your 
Profiles Database, you should modify the user name in this script.

*/


GRANT EXEC ON [Profile.Module].[CustomViewAuthorInAuthorship.GetJournalHeadings] TO App_Profiles10

