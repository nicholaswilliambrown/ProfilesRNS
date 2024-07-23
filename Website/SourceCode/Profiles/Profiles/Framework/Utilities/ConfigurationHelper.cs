using System.Configuration;
using System;
using System.Web.Configuration;

namespace Profiles.Framework.Utilities
{
    /// <summary>
    /// This class is used for all database IO of the web data layer of profiles.
    /// Plus contains generic data base IO methods for building Command Objects, Data Readers ect...
    ///
    /// </summary>
    public static class ConfigurationHelper
    {
        public static string ProfilesRootRelativePath = "";
        public static string ProfilesRootURL = "";

        //TODO this should come from the database and be overwritten app settings as needed.
        public static void initialize()
        {
            if (WebConfigurationManager.AppSettings["ProfilesRootRelativePath"] != null)
                if ("".Equals(WebConfigurationManager.AppSettings["ProfilesRootRelativePath"])) ProfilesRootRelativePath = "";
                else ProfilesRootRelativePath = "/" + WebConfigurationManager.AppSettings["ProfilesRootRelativePath"];

            if (WebConfigurationManager.AppSettings["ProfilesRootURL"] != null)
                ProfilesRootURL = WebConfigurationManager.AppSettings["ProfilesRootURL"];
        }
        public static string GetConnectionString(Framework.Utilities.Session session)
        {
            string connstr = string.Empty;
            /*
            try
            {
                if (session != null)
                {
                    if (session.IsBot)
                        connstr = ConfigurationManager.ConnectionStrings["ProfilesBOTDB"].ConnectionString;
                    else
                        connstr = ConfigurationManager.ConnectionStrings["ProfilesDB1"].ConnectionString;
                }
                else
                    connstr = connstr = ConfigurationManager.ConnectionStrings["ProfilesDB1"].ConnectionString;
            }
            catch (Exception ex)
            {//An error will kick in if this is an Application level request for the rest path data because a session does not exist. If no session exists
                Framework.Utilities.DebugLogging.Log(connstr + " CONNECTION USED" + "\r\n");
                connstr = connstr = ConfigurationManager.ConnectionStrings["ProfilesDB1"].ConnectionString;
            }
            */
            connstr = connstr = ConfigurationManager.ConnectionStrings["ProfilesDB"].ConnectionString;
            return connstr;
        }
    }
}