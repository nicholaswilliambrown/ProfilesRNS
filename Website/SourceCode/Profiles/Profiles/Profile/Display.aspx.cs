/*  
 
    Copyright (c) 2008-2012 by the President and Fellows of Harvard College. All rights reserved.  
    Profiles Research Networking Software was developed under the supervision of Griffin M Weber, MD, PhD.,
    and Harvard Catalyst: The Harvard Clinical and Translational Science Center, with support from the 
    National Center for Research Resources and Harvard University.


    Code licensed under a BSD License. 
    For details, see: LICENSE.txt 
  
*/

using System;
using System.Web.UI;
using System.Xml;
using System.Web.UI.HtmlControls;

using Profiles.Profile.Utilities;
using Profiles.Framework.Utilities;
using Profiles.Framework.Modules.HelloWorld;
using System.Threading.Tasks;
using static System.Net.WebRequestMethods;
using System.Net.Http;
using System.Data.SqlClient;
using System.Data;
using System.Configuration;
using Profiles.Activity.Utilities;

namespace Profiles.Profile
{
    public partial class Display : ProfileData
    {
        private Profiles.Framework.Template masterpage;

        public void Page_Load(object sender, EventArgs e)
        {
            DisplayParams dp = GetParameters(base.RDFTriple.Subject, base.RDFTriple.Predicate, base.RDFTriple.Object, base.Tab);
            litText.Text = dp.HTML;

            string str = base.RDFTriple.Subject + "; " + base.RDFTriple.Predicate + "; " + base.RDFTriple.Object + "; " + base.Tab;
        }

        private DisplayParams GetParameters(long subject, long predicate, long obj, string tab)
        {
            DisplayParams dp = new DisplayParams();
            SessionManagement sessionManagement = new SessionManagement();
            Framework.Utilities.Session session = sessionManagement.Session();

            string presentationType = "";
            string tab2 = "";
            bool redirect = false;
            string redirectURL = null;
            string dataURLs = null;
            bool validURL = true;
            bool canEdit = false;
            string str = string.Empty;
            bool botindex = true;
            string layoutData = "{}";

            try
            {
                string connstr = ConfigurationHelper.GetConnectionString(session);
                SqlConnection dbconnection = new SqlConnection(connstr);
                SqlCommand dbcommand = new SqlCommand("[Display.].[GetDataURLs]");
                dbcommand.CommandTimeout = Convert.ToInt32(ConfigurationManager.AppSettings["COMMANDTIMEOUT"]);

                SqlDataReader dbreader;
                dbconnection.Open();
                dbcommand.CommandType = CommandType.StoredProcedure;
                //dbcommand.CommandTimeout = base.GetCommandTimeout();
                dbcommand.Parameters.Add(new SqlParameter("@subject", subject));
                dbcommand.Parameters.Add(new SqlParameter("@predicate", predicate));
                dbcommand.Parameters.Add(new SqlParameter("@object", obj));
                dbcommand.Parameters.Add(new SqlParameter("@tab", tab));
                dbcommand.Parameters.Add(new SqlParameter("@SessionID", session.SessionID));

                dbcommand.Connection = dbconnection;
                dbreader = dbcommand.ExecuteReader(CommandBehavior.CloseConnection);

                while (dbreader.Read())
                {
                    validURL = (dbreader["ValidURL"] as int? == 1) ? true : false;
                    presentationType = dbreader["PresentationType"].ToString();
                    tab2 = dbreader["tab"].ToString();
                    redirect = (dbreader["Redirect"] as int? == 1) ? true : false;
                    redirectURL = dbreader["RedirectURL"].ToString();
                    dataURLs = dbreader["dataURLs"].ToString();
                    canEdit = (dbreader["canEdit"] as int? == 1) ? true : false;
                    botindex = (dbreader["botIndex"] as int? == 1) ? true : false;
                    layoutData = dbreader["layoutData"].ToString();
                }

                if (!dbreader.IsClosed)
                    dbreader.Close();

            }
            catch (Exception ex) { Framework.Utilities.DebugLogging.Log($"Profile/Display.aspx.cs : {ex.Message}"); }

            if (session.IsBot && !botindex)
            {
                string sessionInfo = ConfigurationHelper.GetSessionInfoJavascriptObject(session, canEdit);

                dp.HTML = System.IO.File.ReadAllText(AppDomain.CurrentDomain.BaseDirectory + "/StaticFiles/html-templates/noindex.html");
                dp.HTML = dp.HTML.Replace("{profilesPath}", ConfigurationHelper.ProfilesRootRelativePath)
                    .Replace("{globalVariables}", ConfigurationHelper.GlobalJavascriptVariablesProfilePage)
                    .Replace("{SessionInfo}", sessionInfo)
                    .Replace("{TrackingCode}", ConfigurationHelper.GlobalGoogleTrackingCode);
                Response.AddHeader("X-Robots-Tag", "noindex");
                return dp;
            }



            try
            {
                // string url = _hostingSiteRepository.GetConfiguration().DisplayApiURL + "/getPageParams?p1=" + p1 + "&p2=" + p2 + "&p3=" + p3 + "&p4=" + p4 + "&p5=" + p5 + "&p6=" + p6 + "&p7=" + p7 + "&p8=" + p8 + "&p9=" + p9 + "&p10=" + p10;
                //string url = "https://localhost:7208/api" + "/getPageParams?p1=" + p1 + "&p2=" + p2 + "&p3=" + p3 + "&p4=" + p4 + "&p5=" + p5 + "&p6=" + p6 + "&p7=" + p7 + "&p8=" + p8 + "&p9=" + p9 + "&p10=" + p10;

                //Task<string> task = Task.Run<string>(async () => await httpGetParams(url));
                //string j = task.Result;
                //var jsonObject = JsonNode.Parse(j);
                dp.DataURLs = dataURLs;// jsonObject[0]["DataURLS"].ToString();
                dp.DataURLs = dp.DataURLs.Replace("\r", "").Replace("\n", "");
                //string jsonValidURL = jsonObject[0]["validURL"].ToString();
                dp.ValidURL = validURL; //jsonValidURL.Equals("True");
                dp.PresentationType = int.Parse(presentationType); //jsonObject[0]["PresentationType"];
                dp.Tab = tab; // jsonObject[0]["Tab"].ToString();

                //string jsonRedirect = jsonObject[0]["Redirect"].ToString();
                dp.Redirect = redirect; // jsonRedirect.Equals("True");
                dp.RedirectURL = redirectURL;//jsonObject[0]["RedirectURL"].ToString();

                ConfigurationHelper.PageTypes pageType;
                pageType = ConfigurationHelper.getPageType(dp.PresentationType);
                string htmlfilename;

/*                public enum PageTypes
        {
            profile, concept, person, personCoAuthors, personSimilarPeople, personConcepts, personCoAuthorConnection,
            personSimilarConnection, personConceptConnection, publication, MentoringCurrentStudentOpportunity, MentoringCompletedStudentProject,
            AwardReceipt, group, groupRole
        };
*/
                switch (pageType)
                {
                    case ConfigurationHelper.PageTypes.profile:
                        htmlfilename = "profile.html";
                        break;
                    case ConfigurationHelper.PageTypes.concept:
                        htmlfilename = "concept.html";
                        break;
                    case ConfigurationHelper.PageTypes.person:
                        htmlfilename = "person.html";
                        break;
                    case ConfigurationHelper.PageTypes.personCoAuthors:
                        if (dp.Tab.ToLower().Equals("data")) { htmlfilename = "personCoAuthors.html"; }
                        else if (dp.Tab.ToLower().Equals("map")) { htmlfilename = "personCoAuthorsMap.html"; }
                        else if (dp.Tab.ToLower().Equals("radial")) { htmlfilename = "personCoAuthorsRadial.html"; }
                        else if (dp.Tab.ToLower().Equals("cluster")) { htmlfilename = "personCoAuthorsCluster.html"; }
                        else if (dp.Tab.ToLower().Equals("timeline")) { htmlfilename = "personCoAuthorsTimeline.html"; }
                        else if (dp.Tab.ToLower().Equals("details")) { htmlfilename = "personCoAuthorsDetails.html"; }
                        else { htmlfilename = "personCoAuthors.html"; }
                        break;
                    case ConfigurationHelper.PageTypes.personSimilarPeople:
                        htmlfilename = "personSimilarPeople.html";
                        break;
                    case ConfigurationHelper.PageTypes.personConcepts:
                        htmlfilename = "personConcepts.html";
                        break;
                    case ConfigurationHelper.PageTypes.personCoAuthorConnection:
                        htmlfilename = "personCoAuthorConnection.html";
                        break;
                    case ConfigurationHelper.PageTypes.personSimilarConnection:
                        htmlfilename = "personSimilarConnection.html";
                        break;
                    case ConfigurationHelper.PageTypes.personConceptConnection:
                        htmlfilename = "personConceptConnection.html";
                        break;
                    case ConfigurationHelper.PageTypes.publication:
                        htmlfilename = "publication.html";
                        break;
                    case ConfigurationHelper.PageTypes.MentoringCurrentStudentOpportunity:
                        htmlfilename = "MentoringCurrentStudentOpportunity.html";
                        break;
                    case ConfigurationHelper.PageTypes.MentoringCompletedStudentProject:
                        htmlfilename = "MentoringCompletedStudentProject.html";
                        break;
                    case ConfigurationHelper.PageTypes.AwardReceipt:
                        htmlfilename = "AwardReceipt.html";
                        break;
                    case ConfigurationHelper.PageTypes.group:
                        htmlfilename = "group.html";
                        break;
                    case ConfigurationHelper.PageTypes.groupRole:
                        if (dp.Tab.ToLower().Equals("data")) { htmlfilename = "groupRole.html"; }
                        else if (dp.Tab.ToLower().Equals("byname")) { htmlfilename = "groupRole.html"; }
                        else if (dp.Tab.ToLower().Equals("byrole")) { htmlfilename = "groupRoleByRole.html"; }
                        else if (dp.Tab.ToLower().Equals("map")) { htmlfilename = "groupRoleMap.html"; }
                        else if (dp.Tab.ToLower().Equals("coauthors")) { htmlfilename = "groupRoleCoAuthors.html"; }
                        else { htmlfilename = "groupRole.html"; }
                        break;
                    default:
                        htmlfilename = "default.html";
                        break;
                }

                string sessionInfo = ConfigurationHelper.GetSessionInfoJavascriptObject(session, canEdit);
                string g = ConfigurationHelper.GlobalJavascriptVariablesProfilePage.Replace("{dataURLs}", dp.DataURLs).Replace("{tab}", dp.Tab).Replace("{preLoad}", layoutData.Replace("'", "\\'"));

                dp.HTML = System.IO.File.ReadAllText(AppDomain.CurrentDomain.BaseDirectory + "/StaticFiles/html-templates/" + htmlfilename);
                dp.HTML = dp.HTML.Replace("{profilesPath}", ConfigurationHelper.ProfilesRootRelativePath)
                    .Replace("{globalVariables}", g)
                    .Replace("{SessionInfo}", sessionInfo)
                    .Replace("{TrackingCode}", ConfigurationHelper.GlobalGoogleTrackingCode);
            }
            catch (Exception ex) { Framework.Utilities.DebugLogging.Log($"Profile/Display.aspx.cs : {ex.Message}"); }

            return dp;
        }

        private async Task<string> httpGetParams(string url)
        {
            String str = "";
            using (var client = new HttpClient())
            {
                //client.BaseAddress = new Uri("http://localhost:55587/");

                //GET Method
                try
                {
                    HttpResponseMessage response = await client.GetAsync(url);
                    if (response.IsSuccessStatusCode)
                    {
                        str = await response.Content.ReadAsStringAsync();
                    }
                    else
                    {
                        Console.WriteLine("Internal server Error");
                    }
                }
                catch (Exception ex) { Framework.Utilities.DebugLogging.Log($"Profile/Display.aspx.cs : {ex.Message}"); }
            }
            return str;

        }

        private class DisplayParams
        {
            public int PresentationType { get; set; } = -1;
            public string Tab { get; set; } = string.Empty;
            public bool Redirect { get; set; } = false;
            public string RedirectURL { get; set; } = string.Empty;
            public string DataURLs { get; set; } = string.Empty;
            public bool ValidURL { get; set; } = true;
            public string HTML { get; set; } = string.Empty;



        }
    }
}
