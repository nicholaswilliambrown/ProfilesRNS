using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Xml;
using Profiles.Framework.Utilities;
using System.Web.Script.Serialization;
using System.Data.SqlClient;
using System.Text;
using System.Text.RegularExpressions;

namespace Profiles.Lists
{
    public partial class Default : System.Web.UI.Page
    {
        SessionManagement sessionManagement;

        private static void myLog(string message) {
            message = $"------------myLog--------------->> {message} <<----------";
            System.Diagnostics.Debug.WriteLine(message);
        }
        private string getListPeople()
        {
            myLog("getListPeople");
            Session session = sessionManagement.Session();

            if (session.ListID == null)
            {
                session.ListID = session.PersonID.ToString();
            }

            string institution = (string.IsNullOrEmpty(Request.QueryString["institution"]) ? "" : Request.QueryString["institution"].ToString());
            institution = Uri.UnescapeDataString(institution);
            //institution = Regex.Replace(institution, @"'", "''");

            string facultyRank = (string.IsNullOrEmpty(Request.QueryString["facultyrank"]) ? "" : Request.QueryString["facultyrank"].ToString());
            facultyRank = Uri.UnescapeDataString(facultyRank);
            //facultyRank = Regex.Replace(facultyRank, @"'", "''");

            Utilities.DataIO.ProfilesList profilesList =
                Profiles.Lists.Utilities.DataIO.GetPeople(institution, facultyRank);

           if (null == profilesList.ListID) {
                profilesList.ListID = session.ListID;
           }
           if (null == profilesList.SessionID) {
                profilesList.SessionID = session.SessionID.ToString();
           }

            var serializer = new JavaScriptSerializer();
            string result = serializer.Serialize(profilesList);
            return result;
        }

        override protected void OnInit(EventArgs e)
         {
            sessionManagement = new SessionManagement();
            Framework.Utilities.Session session = sessionManagement.Session();

            string editPropertyParams = "{}";

            string sessionInfo = ConfigurationHelper.GetSessionInfoJavascriptObject(session);
            string g = ConfigurationHelper.GlobalJavascriptVariablesProfilePage
                .Replace("{tab}", "")
                .Replace("{preLoad}", "");

            string HTML = System.IO.File.ReadAllText(AppDomain.CurrentDomain.BaseDirectory + "/StaticFiles/html-templates/lists.html");
            HTML = HTML.Replace("{profilesPath}", ConfigurationHelper.ProfilesRootRelativePath)
             .Replace("{globalVariables}", g)
             .Replace("{SessionInfo}", sessionInfo)
             .Replace("{TrackingCode}", ConfigurationHelper.GlobalGoogleTrackingCode)
             .Replace("{metaDescription}", " ");

            litText.Text = HTML;
         }
       protected void Page_Load(object sender, EventArgs e)
       {
            Response.Headers.Add("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0");
            Response.Headers.Add("Pragma", "no-cache");
            Response.Headers.Add("Expires", "0");

            Framework.Utilities.Session session = sessionManagement.Session();
            if (session.PersonID <= 0) {
                string redirectUrl = Root.Domain + "/login/default.aspx?method=logout&redirectto=" + Root.Domain;
                myLog("************************** zero-Person, time to login again");
                Response.Redirect(redirectUrl);
            }

            string[] restSegments = Request.Url.AbsolutePath.Split('/');
            int len = restSegments.Length;
            var serializer = new JavaScriptSerializer();

            string restTask = null;
            if (len > 3) {
                // b/c of split() behavior, non-trivial content is 1 based
                restTask = restSegments[3];
                string listId = session.ListID;
                string result = "{result: '" + restTask + "' does not compute}";

                if (restTask == "ClearList") {
                    ClearList(listId);

                    string expect = $"Expect 0 list-size for {listId}: {session.ListSize}";
                    result = serializer.Serialize("{result: '" + expect + "' }");
                }
                else if (restTask == "ModifyActiveList") {
                    string action = Request.Form["action"].ToString();
                    string listIds = Request.Form["listIds"].ToString();

                    ModifyActiveList(action, listIds);
               }
                else if (restTask == "AddUpdateList") {
                    string action = Request.Form["action"].ToString();
                    string listIds = Request.Form["listIds"].ToString();
                    string name = Request.Form["name"].ToString();

                    AddUpdateList(action, listIds, name);
               }
                else if (restTask == "DeleteSelected") {
                    string personIds = Request.Form["personIds"].ToString();

                    string newSize = DeleteSelected(listId, personIds);
                    result = serializer.Serialize("{newListSize: '" + newSize + "' }");
               }
                else if (restTask == "Save") {
                    string name = Request.QueryString["name"].ToString();
                    if ( ! string.IsNullOrEmpty(name)) {
                        Save(listId, name);
                    }
               }
                else if (restTask == "AddCoauthors") {
                    AddCoauthors();
               }
                else if (restTask == "ReplaceWithCoauthors") {
                    RemoveCoauthors(); // amounts to RemoveAndReplaceWith
               }
                else if (restTask == "Map") {
                    result = GetMapJson(listId, session.SessionID.ToString());
                }
                else if (restTask == "Cluster") {
                    result = GetCluster(listId);
                }
                else if (restTask == "SavedLists") {
                    if (len > 4) {
                        string flavor = restSegments[4];
                        //SavedListsTask(listId, flavor);
                    }
                    else {
                        List<Profiles.Lists.Utilities.DataIO.ProfilesList> lists = GetSavedLists();
                        result = serializer.Serialize(lists);
                    }
                }
                else if (restTask == "Export" && len > 4) {
                    string flavor = restSegments[4];
                    Export(listId, flavor);
                }
                else if (restTask == "Reports") {
                    string summaryType = "institution";
                    if (!string.IsNullOrEmpty(Request.QueryString["summaryType"]))
                        summaryType = Request.QueryString["summaryType"];

                    result = GetReports(listId, summaryType);
                }
                else if (restTask == "GetList"){
                    result = getListPeople();
                }
                else if (restTask == "VisualizeLists"){
                    result = handleViz();
                }
                else if (restTask == "VisualizeListsCluster"){
                    result = handleVizCluster();
                }
                Response.Write(result);
                Response.End(); // nuke the page lifecycle additions
            }
       }

        public XmlDocument PresentationXML { get; set; }

        /////////////////////// service API ///////////////////

        [System.Web.Services.WebMethod]
        public static string AddPersonToList(string ownernodeid, string listid, string personid)
        {
            return ListsSVC.AddPersonToList( ownernodeid,  listid,  personid);
        }

        [System.Web.Services.WebMethod]
        public static string DeleteSingle(string listid, string personid)
        {
            return ListsSVC.DeleteSingle( listid,  personid);
        }

        [System.Web.Services.WebMethod]
        public static string DeleteSelected(string listid, string personids)
        {
            return ListsSVC.DeleteSelected( listid,  personids);
        }

        [System.Web.Services.WebMethod]
        public static void AddCoauthors()
        {
            ListsSVC.AddCoauthors();
        }

        [System.Web.Services.WebMethod]
        public static void RemoveCoauthors() // better name would be RemoveAndReplaceWithCoauthors
        {
            ListsSVC.RemoveCoauthors();
        }

        [System.Web.Services.WebMethod]
        public static string GetMapJson(string listId, string sessionId)
        {
            return ListsSVC.GetMapJson( listId,  sessionId);
        }

        [System.Web.Services.WebMethod]
        public static string GetCluster(string listId)
        {
            return ListsSVC.GetCluster( listId);
        }

        [System.Web.Services.WebMethod]
        public static void Export(string listId, string flavor)
        {
            ListsSVC.Export( listId,  flavor);
        }

        [System.Web.Services.WebMethod]
        public static List<Profiles.Lists.Utilities.DataIO.ProfilesList> GetSavedLists()
        {
            return ListsSVC.GetSavedLists();
        }

        [System.Web.Services.WebMethod]
        public static string GetReports(string listId, string summaryType)
        {
            return ListsSVC.GetReports( listId,  summaryType);
        }

        [System.Web.Services.WebMethod]
        public static void Save(string listId, string name)
        {
            ListsSVC.Save( listId,  name);
        }

        [System.Web.Services.WebMethod]
        public static void AddUpdateList(string action, string listid, string name)
        {
            ListsSVC.AddUpdateList( action,  listid,  name);
        }
        [System.Web.Services.WebMethod]
        public static void RenameList(string listid, string name)
        {
            ListsSVC.RenameList( listid,  name);
        }

        [System.Web.Services.WebMethod]
        public static void ModifyActiveList(string action,string listids)
        {
            ListsSVC.ModifyActiveList( action, listids);
        }

        [System.Web.Services.WebMethod]
        public static void ClearList(string ListID)
        {
            ListsSVC.ClearList( ListID);
        }

        private string handleViz()
        {
            string listIds = Request.Form["listIds"].ToString();
            return ListsSVC.handleViz(listIds);
        }
        private string handleVizCluster()
        {
            string listIds = Request.Form["listIds"].ToString();
            return ListsSVC.handleVizCluster(listIds);
        }
    }
}