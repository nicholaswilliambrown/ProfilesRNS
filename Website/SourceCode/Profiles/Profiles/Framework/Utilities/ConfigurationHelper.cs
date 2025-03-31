using System.Configuration;
using System;
using System.Web.Configuration;
using System.Web;

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
        public static string ProfilesSiteName = "";
        public static string ProfilesInstitution = "";
        public static string GlobalJavascriptVariables = "";
        public static string GlobalJavascriptVariablesProfilePage = "";
        public static bool SendConnectionPagesToBotDatabase = false;

        //TODO this should come from the database and be overwritten app settings as needed.
        public static void initialize()
        {
            if (WebConfigurationManager.AppSettings["ProfilesRootRelativePath"] != null)
                if ("".Equals(WebConfigurationManager.AppSettings["ProfilesRootRelativePath"])) ProfilesRootRelativePath = "";
                else ProfilesRootRelativePath = "/" + WebConfigurationManager.AppSettings["ProfilesRootRelativePath"];

            if (WebConfigurationManager.AppSettings["ProfilesRootURL"] != null)
                ProfilesRootURL = WebConfigurationManager.AppSettings["ProfilesRootURL"];

            if (WebConfigurationManager.AppSettings["ProfilesSiteName"] != null)
                ProfilesSiteName = WebConfigurationManager.AppSettings["ProfilesSiteName"];

            if (WebConfigurationManager.AppSettings["ProfilesInstitution"] != null)
                ProfilesInstitution = WebConfigurationManager.AppSettings["ProfilesInstitution"];

            string bannerMessage = "";
            if (WebConfigurationManager.AppSettings["BannerMessage"] != null)
                bannerMessage = WebConfigurationManager.AppSettings["BannerMessage"];

            if (WebConfigurationManager.AppSettings["SendConnectionPagesToBotDatabase"] != null)
                SendConnectionPagesToBotDatabase = Convert.ToBoolean(WebConfigurationManager.AppSettings["SendConnectionPagesToBotDatabase"]);

            string g1 = "g.dataURLs = '{dataURLs}';" +
                        "g.tab = '{tab}';" +
                        "g.preLoad = '{preLoad}';";

            string g2 = "g.profilesPath = '" + ProfilesRootRelativePath + "';" +
                        "g.profilesRootURL = '" + ProfilesRootURL + "';" +
                        "g.staticRoot = '" + ProfilesRootRelativePath + "/StaticFiles/';" +
                        "g.apiBasePath = '" + ProfilesRootURL + "/Profile/ProfileJsonSvc.aspx';" +
                        "g.searchApiPath = '" + ProfilesRootURL + "/Search/SearchSvc.aspx';" +
                        "g.listsApiPath = '" + ProfilesRootURL + "/Lists/ListsSvc.aspx';" +
                        "g.activityApiPath = '" + ProfilesRootURL + "/Activity/ActivitySvc.aspx';" +
                        "g.bannerMessage = '" + bannerMessage + "';" +
                        "g.directLink = '" + ProfilesRootRelativePath + "/Direct/default.aspx';" +
                        "console.log(\"Global values after DisplayRepository replace\", g);";

            GlobalJavascriptVariables = "<script type=\"text/javascript\">" +
                                        "let g = {};" +
                                        g2 +
                                        "</script>";

            GlobalJavascriptVariablesProfilePage = "<script type=\"text/javascript\">" +
                            "let g = {};" +
                            g1 +
                            g2 +
                            "</script>";
        }
        public static string GetConnectionString(Framework.Utilities.Session session)
        {
            string connstr = string.Empty;
            try
            {
                if (session != null)
                {
                    if (session.IsBot)
                        connstr = ConfigurationManager.ConnectionStrings["ProfilesBOTDB"].ConnectionString;
                    else
                        connstr = ConfigurationManager.ConnectionStrings["ProfilesDB"].ConnectionString;
                }
                else
                    connstr = connstr = ConfigurationManager.ConnectionStrings["ProfilesDB"].ConnectionString;
            }
            catch (Exception ex)
            {//An error will kick in if this is an Application level request for the rest path data because a session does not exist. If no session exists
                Framework.Utilities.DebugLogging.Log(connstr + " CONNECTION USED" + "\r\n");
                connstr = connstr = ConfigurationManager.ConnectionStrings["ProfilesDB"].ConnectionString;
            }


            return connstr;
        }
        

        //This allows us to send connection pages to the bot database when we need to reduce load on the primary database.
        //Spiders or unidentified bots produce huge amounts of connection page usage, where humans usage hits these pages
        //at a very low rate
        public static string GetConnectionPageConnectionString(Framework.Utilities.Session session)
        {
            string connstr = string.Empty;
            try
            {
                if (SendConnectionPagesToBotDatabase)
                {
                    connstr = ConfigurationManager.ConnectionStrings["ProfilesBOTDB"].ConnectionString;
                }
                else if (session != null)
                {
                    if (session.IsBot)
                        connstr = ConfigurationManager.ConnectionStrings["ProfilesBOTDB"].ConnectionString;
                    else
                        connstr = ConfigurationManager.ConnectionStrings["ProfilesDB"].ConnectionString;
                }
                else
                    connstr = connstr = ConfigurationManager.ConnectionStrings["ProfilesDB"].ConnectionString;
            }
            catch (Exception ex)
            {//An error will kick in if this is an Application level request for the rest path data because a session does not exist. If no session exists
                Framework.Utilities.DebugLogging.Log(connstr + " CONNECTION USED" + "\r\n");
                connstr = connstr = ConfigurationManager.ConnectionStrings["ProfilesDB"].ConnectionString;
            }


            return connstr;
        }

        public static string GetSessionInfoJavascriptObject(Framework.Utilities.Session session)
        {
            return GetSessionInfoJavascriptObject(session, false);
        }
        public static string GetSessionInfoJavascriptObject(Framework.Utilities.Session session, bool canEdit)
        {
            string sessionInfo;
            if (session.UserID > 0)
            {

                int listSize;
                bool parseSuccess = false;
                parseSuccess = Int32.TryParse(session.ListSize, out listSize);
                if (!parseSuccess)
                {
                    listSize = 0;
                }
                sessionInfo =
                "<script type = \"text/javascript\">" +
                    "let sessionInfo = { };" +
                    "sessionInfo.sessionID = \"" + session.SessionID + "\";" +
                    "sessionInfo.userID = " + session.UserID + ";" +
                    "sessionInfo.personID = " + session.PersonID + ";" +
                    "sessionInfo.personNodeID = " + session.NodeID + ";" +
                    "sessionInfo.personURI = \"" + session.PersonURI + "\";" +
                    "sessionInfo.canEditPage = " + (canEdit ? "true" : "false") + ";" +
                    "sessionInfo.listID = \"" + session.ListID + "\";" +
                    "sessionInfo.listSize = " + listSize + ";" +
                    "</script>";
            }
            else
            {
                sessionInfo =
                    "<script type = \"text/javascript\">" +
                        "let sessionInfo = { };" +
                        "sessionInfo.sessionID = \"" + session.SessionID + "\";" +
                        "sessionInfo.userID = 0;" +
                        "sessionInfo.personID = 0;" +
                        "sessionInfo.personNodeID = 0;" +
                        "sessionInfo.personURI = \"\";" +
                        "sessionInfo.canEditPage = false;" +
                        "sessionInfo.listID = \"\";" +
                        "sessionInfo.listSize = 0;" +
                        "</script>";
            }
            return sessionInfo;
        }
    }
}