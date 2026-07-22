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
            string facultyRank = (string.IsNullOrEmpty(Request.QueryString["facultyrank"]) ? "" : Request.QueryString["facultyrank"].ToString());

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

            string peopleJson = getListPeople();

            string editPropertyParams = "{}";

            string sessionInfo = ConfigurationHelper.GetSessionInfoJavascriptObject(session);
            string g = ConfigurationHelper.GlobalJavascriptVariablesProfilePage
                .Replace("{tab}", "")
                .Replace("{preLoad}", peopleJson);

            string HTML = System.IO.File.ReadAllText(AppDomain.CurrentDomain.BaseDirectory + "/StaticFiles/html-templates/lists.html");
            HTML = HTML.Replace("{profilesPath}", ConfigurationHelper.ProfilesRootRelativePath)
             .Replace("{globalVariables}", g)
             .Replace("{SessionInfo}", sessionInfo)
             .Replace("{TrackingCode}", ConfigurationHelper.GlobalGoogleTrackingCode)
             .Replace("{metaDescription}", " ");

            litText.Text = HTML;
         }
       protected void Page_Load(object sender, EventArgs e) {
            Framework.Utilities.Session session = sessionManagement.Session();

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
                else if (restTask == "DeleteSelected") {
                    string personIds = Request.Form["personIds"].ToString();

                    string newSize = DeleteSelected(listId, personIds);
                    result = serializer.Serialize("{newListSize: '" + newSize + "' }");
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

        //AddUpdateList Proc
        [System.Web.Services.WebMethod]
        public static void Save(string listid, string name)
        {
            Profiles.Lists.Utilities.DataIO.AddUpdateList("Save", listid, name);
        }

        [System.Web.Services.WebMethod]
        public static void AddUpdateList(string action,string listid)
        {
            List<string> listids = listid.Split(',').ToList();
            if (action == "Delete")
                foreach (string lid in listids)
                {
                    Lists.Utilities.DataIO.AddUpdateList(action, lid, "");
                }
            else
                Lists.Utilities.DataIO.AddUpdateList(action,listid , "");
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