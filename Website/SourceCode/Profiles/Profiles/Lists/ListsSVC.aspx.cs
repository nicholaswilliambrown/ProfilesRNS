using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Data;
using System.Linq;
using System.Web.Script.Serialization;
using System.Configuration;
using Profiles.Framework.Utilities;
using System.IO;

namespace Profiles.Lists
{
    public partial class ListsSVC : System.Web.UI.Page, System.Web.SessionState.IRequiresSessionState
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            //Profiles.Profile.Modules.CustomViewAuthorInAuthorship.DataIO data = new Profiles.Profile.Modules.CustomViewAuthorInAuthorship.DataIO();
            //Profiles.Framework.Utilities.RDFTriple request = new RDFTriple(Convert.ToInt32(Request.QueryString["p"]));
            string str = null;
            SessionManagement sessionManagement = new SessionManagement();
            Framework.Utilities.Session session = sessionManagement.Session();

            if (session.UserID <= 0)
            {
                Response.StatusCode = 403;
                Response.End();
                return;
            }

            if (!string.Equals(Request.HttpMethod, "POST"))
            {
                Response.StatusCode = 405;
                Response.End();
                return;
            }

            string action = string.Empty;
            string body = string.Empty;

            try
            {

                action = Request.QueryString["action"].ToString();
                body = new StreamReader(Request.InputStream).ReadToEnd();

            }
            catch (Exception ex) { Framework.Utilities.DebugLogging.Log($"Lists/ListsJsonSVC.aspx.cs : {ex.Message}"); }

            if (str == null)
            {

                try
                {
                    string connstr = ConfigurationHelper.GetConnectionString(session);
                    SqlConnection dbconnection = new SqlConnection(connstr);
                    SqlCommand dbcommand = new SqlCommand("[Display.Lists].[UpdateLists]");
                    dbcommand.CommandTimeout = Convert.ToInt16(ConfigurationManager.AppSettings["COMMANDTIMEOUT"]);

                    SqlDataReader dbreader;
                    dbconnection.Open();
                    dbcommand.CommandType = CommandType.StoredProcedure;
                    //dbcommand.CommandTimeout = base.GetCommandTimeout();
                    dbcommand.Parameters.Add(new SqlParameter("@UserID", session.UserID));
                    dbcommand.Parameters.Add(new SqlParameter("@Action", action));
                    dbcommand.Parameters.Add(new SqlParameter("@SessionID", session.SessionID));
                    dbcommand.Parameters.Add(new SqlParameter("@Json", body));

                    dbcommand.Connection = dbconnection;
                    dbreader = dbcommand.ExecuteReader(CommandBehavior.CloseConnection);
                    string s = "";
                    while (dbreader.Read())
                    {
                        s = dbreader[0].ToString();
                    }

                    str = "{\"Size\":" + s + "}";
                    session.ListSize = s;

                    if (!dbreader.IsClosed)
                        dbreader.Close();

                }
                catch (Exception ex)
                {
                    Framework.Utilities.DebugLogging.Log($"Lists/ListsSVC.aspx.cs : {ex.Message}");

                    str = "[{\"ErrorMessage\":\"There was an error: " + ex.Message + "\"}]";

                }

            }

            Response.ContentType = "application/json; charset=utf-8";
            Response.AppendHeader("Access-Control-Allow-Origin", "*");
            Response.AppendHeader("cache-control", "no-cache");
            Response.Write(str);
        }

        /////////////////////// service API ///////////////////
        // used by MyLists (in logged-in menu)
        public static string AddPersonToList(string ownernodeid, string listid, string personid)
        {
            if (listid == "0")
                listid = Lists.Utilities.DataIO.CreateList(ownernodeid, "List");

            return Lists.Utilities.DataIO.AddRemovePerson(listid, personid);
        }

        // used by MyLists (in logged-in menu)
        public static string DeleteSingle(string listid, string personid)
        {
            Lists.Utilities.DataIO.AddRemovePerson(listid, personid, true);
            return Lists.Utilities.DataIO.GetListCount();
        }

        public static string DeleteSelected(string listid, string personids)
        {

            Lists.Utilities.DataIO.DeleteSelected(listid, personids);
            return Lists.Utilities.DataIO.GetListCount();
        }

        public static void AddCoauthors()
        {
            Lists.Utilities.DataIO.AddRemoveCoAuthors("Add");
        }

        public static void RemoveCoauthors() // better name would be RemoveAndReplaceWithCoauthors
        {
            Lists.Utilities.DataIO.AddRemoveCoAuthors("Replace");
        }

        public static string GetMapJson(string listId, string sessionId)
        {
            return Lists.Utilities.DataIO.GetMapJson(listId, sessionId);
        }

        public static string GetCluster(string listId)
        {
            return Lists.Utilities.DataIO.GetNetworkRadialCoAuthors(listId);
        }

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

        public static List<Profiles.Lists.Utilities.DataIO.ProfilesList> GetSavedLists()
        {
            return Profiles.Lists.Utilities.DataIO.GetLists();
        }

        public static string GetReports(string listId, string summaryType)
        {
            return Profiles.Lists.Utilities.DataIO.GetSummary(listId, summaryType);
        }

        public static void Save(string listId, string name)
        {
            Profiles.Lists.Utilities.DataIO.AddUpdateList("Save", listId, name);
        }

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

        public static void RenameList(string listid, string name)
        {
            Lists.Utilities.DataIO.AddUpdateList("Rename", listid, name);
        }

        public static void ModifyActiveList(string action,string listids)
        {
            Lists.Utilities.DataIO.ModifyActiveList(action, listids);
        }

        public static void ClearList(string ListID)
        {
            Profiles.Lists.Utilities.DataIO.DeleteFiltered(ListID, null, null);
        }

        public static string handleViz(string listIds)
        {
            var profilesListGraphs = Utilities.DataIO.GetSelectedSavedLists(listIds);

            List<string> graphColors = Utilities.DataIO.GetGraphColors(profilesListGraphs.Count);

            //init all the colors and defaults before loading the grid.
            for (int i = 0; i < graphColors.Count; i++)
            {
                profilesListGraphs[i].GraphColor = graphColors[i];
            }

            var serializer = new JavaScriptSerializer();
            string result = serializer.Serialize(profilesListGraphs);
            return result;
        }

        public static string handleVizCluster(string listIds)
        {
            string result = Profiles.Lists.Utilities.DataIO.GetCoAuthorsForSavedLists(listIds);
            return result;
        }
    }
}