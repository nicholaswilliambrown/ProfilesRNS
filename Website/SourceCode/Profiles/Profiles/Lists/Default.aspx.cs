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
        private string getListPeople() {
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
       protected void Page_Load(object sender, EventArgs e) {
            Response.Headers.Add("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0");
            Response.Headers.Add("Pragma", "no-cache");
            Response.Headers.Add("Expires", "0");

            Framework.Utilities.Session session = sessionManagement.Session();
            if (session.PersonID <= 0) {
                string redirectUrl = Root.Domain + "/login/default.aspx?method=logout&redirectto=" + Root.Domain;
                myLog("************************** zero-Person, time to login again");
                Response.Write("logout. Use: " + redirectUrl);
                Response.End();
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
                Response.Write(result);
                Response.End(); // nuke the page lifecycle additions
            }
       }

        /////////////////////// service API ///////////////////

        // used by MyLists (in logged-in menu)
        [System.Web.Services.WebMethod]
        public static string AddPersonToList(string ownernodeid, string listid, string personid)
        {
            if (listid == "0")
                listid = Lists.Utilities.DataIO.CreateList(ownernodeid, "List");

            return Lists.Utilities.DataIO.AddRemovePerson(listid, personid);
        }
        // used by MyLists (in logged-in menu)
        [System.Web.Services.WebMethod]
        public static string DeleteSingle(string listid, string personid)
        {
            Lists.Utilities.DataIO.AddRemovePerson(listid, personid, true);
            return Lists.Utilities.DataIO.GetListCount();
        }


        [System.Web.Services.WebMethod]
        public static string DeleteSelected(string listid, string personids)
        {

            Lists.Utilities.DataIO.DeleteSelected(listid, personids);
            return Lists.Utilities.DataIO.GetListCount();
        }

        [System.Web.Services.WebMethod]
        public static void AddCoauthors()
        {
            Lists.Utilities.DataIO.AddRemoveCoAuthors("Add");
        }

        [System.Web.Services.WebMethod]
        public static void RemoveCoauthors() // better name would be RemoveAndReplaceWithCoauthors
        {
            Lists.Utilities.DataIO.AddRemoveCoAuthors("Replace");
        }

        [System.Web.Services.WebMethod]
        public static string GetMapJson(string listId, string sessionId)
        {
            return Lists.Utilities.DataIO.GetMapJson(listId, sessionId);
        }

        [System.Web.Services.WebMethod]
        public static string GetCluster(string listId)
        {
            return Lists.Utilities.DataIO.GetNetworkRadialCoAuthors(listId);
        }

        [System.Web.Services.WebMethod]
        public static void Export(string listId, string flavor)
        {
            switch (flavor)
            {
                case "People":
                    Profiles.Lists.Utilities.DataIO.GetPersonsCsv(listId);
                    break;
                case "Publications":
                    Profiles.Lists.Utilities.DataIO.GetPublicationsCsv(listId);
                    break;
                case "Connections":
                    Profiles.Lists.Utilities.DataIO.GetCoauthorConnectionsCsv(listId);
                    break;
            }
        }

        [System.Web.Services.WebMethod]
        public static List<Profiles.Lists.Utilities.DataIO.ProfilesList> GetSavedLists()
        {
            return Profiles.Lists.Utilities.DataIO.GetLists();
        }

        [System.Web.Services.WebMethod]
        public static string GetReports(string listId, string summaryType)
        {
            return Profiles.Lists.Utilities.DataIO.GetSummary(listId, summaryType);
        }

        //AddUpdateList Proc
        [System.Web.Services.WebMethod]
        public static void Save(string listId, string name)
        {
            Profiles.Lists.Utilities.DataIO.AddUpdateList("Save", listId, name);
        }

        [System.Web.Services.WebMethod]
        public static void AddUpdateList(string action, string listid, string name)
        {
            List<string> listids = listid.Split(',').ToList();
            if (action == "Delete")
                foreach (string lid in listids)
                {
                    // name irrelevant for deletes
                    Lists.Utilities.DataIO.AddUpdateList(action, lid, "");
                }
            else
                Lists.Utilities.DataIO.AddUpdateList(action, listid , name);
        }
        [System.Web.Services.WebMethod]
        public static void RenameList(string listid, string name)
        {
            Lists.Utilities.DataIO.AddUpdateList("Rename", listid, name);
        }


        //ModifyActiveList       
        [System.Web.Services.WebMethod]
        public static void ModifyActiveList(string action,string listids)
        {
            Lists.Utilities.DataIO.ModifyActiveList(action, listids);
        }

        [System.Web.Services.WebMethod]
        public static void ClearList(string ListID)
        {
            Profiles.Lists.Utilities.DataIO.DeleteFiltered(ListID, null, null);
        }

        public XmlDocument PresentationXML { get; set; }

    }
}