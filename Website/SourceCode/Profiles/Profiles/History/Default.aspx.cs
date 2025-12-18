/*  
 
    Copyright (c) 2008-2012 by the President and Fellows of Harvard College. All rights reserved.  
    Profiles Research Networking Software was developed under the supervision of Griffin M Weber, MD, PhD.,
    and Harvard Catalyst: The Harvard Clinical and Translational Science Center, with support from the 
    National Center for Research Resources and Harvard University.


    Code licensed under a BSD License. 
    For details, see: LICENSE.txt 
  
*/
using Profiles.Framework.Utilities;
using System;
using System.Web.Configuration;
using System.Xml;

namespace Profiles.History
{
    public partial class Default : System.Web.UI.Page
    {
        private Profiles.Framework.Template masterpage;

        protected void Page_Load(object sender, EventArgs e)
        {
            try
            {
                SessionManagement sessionManagement = new SessionManagement();
                Framework.Utilities.Session session = sessionManagement.Session();
                string sessionInfo = ConfigurationHelper.GetSessionInfoJavascriptObject(session);

                string pageText = "";

                pageText = System.IO.File.ReadAllText(AppDomain.CurrentDomain.BaseDirectory + "/StaticFiles/html-templates/history.html")
                    .Replace("{profilesPath}", ConfigurationHelper.ProfilesRootRelativePath)
                    .Replace("{globalVariables}", ConfigurationHelper.GlobalJavascriptVariables)
                    .Replace("{SessionInfo}", sessionInfo)
                    .Replace("{TrackingCode}", ConfigurationHelper.GlobalGoogleTrackingCode);

                litText.Text = pageText;
            }
            catch (Exception ex) { Framework.Utilities.DebugLogging.Log($"History/Default.aspx.cs : {ex.Message}"); }
        }
    }

}
