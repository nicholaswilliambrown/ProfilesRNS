/*
Run this script on:

        Profiles 3.2.0   -  This database will be modified

to synchronize it with:

        Profiles 4.0.0

You are recommended to back up your database before running this script

Details of which objects have changed can be found in the release notes.
If you have made changes to existing tables or stored procedures in profiles, you may need to merge changes individually. 

*/

CREATE SCHEMA [Display.]
GO
CREATE SCHEMA [Display.Module]
GO
CREATE SCHEMA [Display.Lists]
GO

PRINT N'Update complete.';


GO

