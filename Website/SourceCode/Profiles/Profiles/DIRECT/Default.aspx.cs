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
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Xml;


namespace Profiles.DIRECT
{
    public partial class Default : System.Web.UI.Page
    {     

        protected void Page_Load(object sender, EventArgs e)
        {

            try
            {
                SessionManagement sessionManagement = new SessionManagement();
                Framework.Utilities.Session session = sessionManagement.Session();
                string sessionInfo = ConfigurationHelper.GetSessionInfoJavascriptObject(session);

                string pageText = "";
                string layoutData = "";

                try
                {
                    string connstr = ConfigurationHelper.GetConnectionString(session);
                    SqlConnection dbconnection = new SqlConnection(connstr);
                    SqlCommand dbcommand = new SqlCommand("[Display.].[DIRECT.GetSiteListJson]");
                    dbcommand.CommandTimeout = Convert.ToInt32(ConfigurationManager.AppSettings["COMMANDTIMEOUT"]);

                    SqlDataReader dbreader;
                    dbconnection.Open();
                    dbcommand.CommandType = CommandType.StoredProcedure;

                    dbcommand.Connection = dbconnection;
                    dbreader = dbcommand.ExecuteReader(CommandBehavior.CloseConnection);

                    while (dbreader.Read())
                    {
                        layoutData= dbreader["json"].ToString();
                    }

                    if (!dbreader.IsClosed)
                        dbreader.Close();

                }
                catch (Exception ex) { Framework.Utilities.DebugLogging.Log($"DIRECT/Display.aspx.cs : {ex.Message}"); }


                string g = ConfigurationHelper.GlobalJavascriptVariablesProfilePage.Replace("{dataURLs}", "{}").Replace("{tab}", "{}").Replace("{preLoad}", layoutData.Replace("'", "\\'"));
                pageText = System.IO.File.ReadAllText(AppDomain.CurrentDomain.BaseDirectory + "/StaticFiles/html-templates/DIRECT.html")
                    .Replace("{profilesPath}", ConfigurationHelper.ProfilesRootRelativePath)
                    .Replace("{globalVariables}", g)
                    .Replace("{SessionInfo}", sessionInfo)
                    .Replace("{ProfilesSiteName}", ConfigurationHelper.ProfilesSiteName)
                    .Replace("{TrackingCode}", ConfigurationHelper.GlobalGoogleTrackingCode);

                litText.Text = pageText;
            }
            catch (Exception ex) { Framework.Utilities.DebugLogging.Log($"About/Default.aspx.cs : {ex.Message}"); }

        }
    }
}
