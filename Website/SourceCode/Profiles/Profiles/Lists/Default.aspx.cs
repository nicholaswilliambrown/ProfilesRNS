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
            SqlDataReader reader1 = Profiles.Lists.Utilities.DataIO.GetGMapList(listId, "1", sessionId);
            SqlDataReader reader0 = Profiles.Lists.Utilities.DataIO.GetGMapList(listId, "0", sessionId);

            var jsonBuilder = new StringBuilder();

            jsonBuilder.Append("{");
            jsonBuilder.Append("\"connections\": [");

            if (reader1.HasRows) {
                while (reader1.Read())
                {
                    // a and b are person ids. u1 and u2 are display urls built from node ids
                    jsonBuilder.Append(   "{" +
                                            $"\"x1\":\"{reader1["x1"].ToString()}\", \"y1\":\"{reader1["y1"].ToString()}\" ," +
                                            $"\"x2\":\"{reader1["x2"].ToString()}\", \"y2\":\"{reader1["y2"].ToString()}\" ," +
                                            $"\"u1\":\"{reader1["u1"].ToString()}\", \"u2\":\"{reader1["u2"].ToString()}\" ," +
                                            $" \"a\":\"{reader1["a"]. ToString()}\",  \"b\":\"{reader1["b"].ToString()}\"  " +
                                          "}," );
                }
                // non for-loop way to manage nuking the final comma
                string jsonPart1 = jsonBuilder.ToString();
                jsonPart1 = jsonPart1.Remove(jsonPart1.Length - 1);
                jsonBuilder.Clear().Append(jsonPart1);
            }

            jsonBuilder.Append("],");


            jsonBuilder.Append("\"people\": [");

            if (reader0.HasRows) {
                while (reader0.Read())
                {
                    jsonBuilder.Append(   "{" +
                                            $"\"address1\":       \"{reader0["address1"]    .ToString().Replace("'", "\\'")}\"  ," +
                                            $"\"address2\":       \"{reader0["address2"]    .ToString().Replace("'", "\\'")}\"  ," +
                                            $"\"display_name\":   \"{reader0["display_name"].ToString().Replace("'", "\\'")}\"  ," +
                                            $"\"latitude\":       \"{reader0["latitude"]    .ToString()}\"  ," +
                                            $"\"longitude\":      \"{reader0["longitude"]   .ToString()}\"  ," +
                                            $" \"URI\":           \"{reader0["URI"]         .ToString()}\"   " +
                                          "},");
                }
                string jsonPart2 = jsonBuilder.ToString();
                jsonPart2 = jsonPart2.Remove(jsonPart2.Length - 1);
                jsonBuilder.Clear().Append(jsonPart2);
            }

            jsonBuilder.Append("]");
            jsonBuilder.Append("}");

            string result = jsonBuilder.ToString();
            return result;
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