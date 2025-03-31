
using System;

using System.Web.UI;
using System.Xml;
using System.Web.UI.HtmlControls;

using Profiles.Framework.Utilities;

namespace Profiles.About
{
    public partial class Default : System.Web.UI.Page
    {
        Profiles.Framework.Template masterpage;

        public void Page_Load(object sender, EventArgs e)
        {
            try
            {
                SessionManagement sessionManagement = new SessionManagement();
                Framework.Utilities.Session session = sessionManagement.Session();
                string sessionInfo = ConfigurationHelper.GetSessionInfoJavascriptObject(session);

                string pageText = "";

                string type;
                if (Request.QueryString["type"] != null) type = Request.QueryString["type"].ToString().ToLower();
                else type = "about";


                if ("opensourcesoftware".Equals(type))
                {
                    pageText = System.IO.File.ReadAllText(AppDomain.CurrentDomain.BaseDirectory + "/StaticFiles/html-templates/aboutOpenSource.html")
                        .Replace("{profilesPath}", ConfigurationHelper.ProfilesRootRelativePath)
                        .Replace("{globalVariables}", ConfigurationHelper.GlobalJavascriptVariables)
                        .Replace("{SessionInfo}", sessionInfo)
                        .Replace("{ProfilesSiteName}", ConfigurationHelper.ProfilesSiteName)
                        .Replace("{ProfilesInstitution}", ConfigurationHelper.ProfilesInstitution);
                }
                else if ("useourdata".Equals(type))
                {
                    pageText = System.IO.File.ReadAllText(AppDomain.CurrentDomain.BaseDirectory + "/StaticFiles/html-templates/useOurData.html")
                        .Replace("{profilesPath}", ConfigurationHelper.ProfilesRootRelativePath)
                        .Replace("{globalVariables}", ConfigurationHelper.GlobalJavascriptVariables)
                        .Replace("{SessionInfo}", sessionInfo)
                        .Replace("{ProfilesSiteName}", ConfigurationHelper.ProfilesSiteName)
                        .Replace("{ProfilesInstitution}", ConfigurationHelper.ProfilesInstitution);
                }
                else if ("help".Equals(type))
                {
                    pageText = System.IO.File.ReadAllText(AppDomain.CurrentDomain.BaseDirectory + "/StaticFiles/html-templates/help.html")
                        .Replace("{profilesPath}", ConfigurationHelper.ProfilesRootRelativePath)
                        .Replace("{globalVariables}", ConfigurationHelper.GlobalJavascriptVariables)
                        .Replace("{SessionInfo}", sessionInfo)
                        .Replace("{ProfilesSiteName}", ConfigurationHelper.ProfilesSiteName)
                        .Replace("{ProfilesInstitution}", ConfigurationHelper.ProfilesInstitution);
                }
                else  //if ("about".Equals(type)) Default to About page.
                {
                    pageText = System.IO.File.ReadAllText(AppDomain.CurrentDomain.BaseDirectory + "/StaticFiles/html-templates/aboutProfiles.html")
                        .Replace("{profilesPath}", ConfigurationHelper.ProfilesRootRelativePath)
                        .Replace("{globalVariables}", ConfigurationHelper.GlobalJavascriptVariables)
                        .Replace("{SessionInfo}", sessionInfo)
                        .Replace("{ProfilesSiteName}", ConfigurationHelper.ProfilesSiteName)
                        .Replace("{ProfilesInstitution}", ConfigurationHelper.ProfilesInstitution);
                }
                litText.Text = pageText;
            }
            catch (Exception ex) { Framework.Utilities.DebugLogging.Log($"About/Default.aspx.cs : {ex.Message}"); }
        }
    }
}
