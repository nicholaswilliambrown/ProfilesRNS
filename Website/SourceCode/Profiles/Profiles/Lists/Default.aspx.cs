using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Xml;
using Profiles.Framework.Utilities;

namespace Profiles.Lists
{
    public partial class Default : System.Web.UI.Page
    {
        Profiles.Framework.Template masterpage;
        SessionManagement sessionManagement;

        private string dbActivity() {
        return "{}"; // for now

//
//            string presentationType = "";
//            string tab2 = "";
//            bool redirect = false;
//            string redirectURL = null;
//            string dataURLs = null;
//            bool validURL = true;
//            bool canEdit = false;
//            string str = string.Empty;
//            bool botindex = true;
//
//            try
//            {
//             string connstr = ConfigurationHelper.GetConnectionString(session);
//             SqlConnection dbconnection = new SqlConnection(connstr);
//             SqlCommand dbcommand = new SqlCommand("[Display.].[GetDataURLs]");
//             dbcommand.CommandTimeout = Convert.ToInt32(ConfigurationManager.AppSettings["COMMANDTIMEOUT"]);
//
//             SqlDataReader dbreader;
//             dbconnection.Open();
//             dbcommand.CommandType = CommandType.StoredProcedure;
//             //dbcommand.CommandTimeout = base.GetCommandTimeout();
//             dbcommand.Parameters.Add(new SqlParameter("@subject", this.Subject));
//             dbcommand.Parameters.Add(new SqlParameter("@predicate", null));
//             dbcommand.Parameters.Add(new SqlParameter("@object", null));
//             dbcommand.Parameters.Add(new SqlParameter("@tab", null));
//             //if (session.UserID > 0) dbcommand.Parameters.Add(new SqlParameter("@SessionID", session.SessionID));
//             dbcommand.Parameters.Add(new SqlParameter("@SessionID", session.SessionID));
//
//             dbcommand.Connection = dbconnection;
//             dbreader = dbcommand.ExecuteReader(CommandBehavior.CloseConnection);
//
//             while (dbreader.Read())
//             {
//                 validURL = (dbreader["ValidURL"] as int? == 1) ? true : false;
//                 presentationType = dbreader["PresentationType"].ToString();
//                 tab2 = dbreader["tab"].ToString();
//                 redirect = (dbreader["Redirect"] as int? == 1) ? true : false;
//                 redirectURL = dbreader["RedirectURL"].ToString();
//                 dataURLs = dbreader["dataURLs"].ToString();
//                 canEdit = (dbreader["canEdit"] as int? == 1) ? true : false;
//                 botindex = (dbreader["botIndex"] as int? == 1) ? true : false;
//                 layoutData = dbreader["layoutData"].ToString();
//             }
//
//             if (!dbreader.IsClosed)
//                 dbreader.Close();
//
//             SqlCommand dbcommand2 = new SqlCommand("[Edit.Module].[GetEditPropertyParams]");
//             dbcommand2.CommandTimeout = Convert.ToInt32(ConfigurationManager.AppSettings["COMMANDTIMEOUT"]);
//
//             SqlDataReader dbreader2;
//             dbconnection.Open();
//             dbcommand2.CommandType = CommandType.StoredProcedure;
//             //dbcommand.CommandTimeout = base.GetCommandTimeout();
//             dbcommand2.Parameters.Add(new SqlParameter("@subject", this.Subject));
//             dbcommand2.Parameters.Add(new SqlParameter("@PropertyURI", Request.QueryString["predicateuri"].Replace('!', '#')));
//             //if (session.UserID > 0) dbcommand.Parameters.Add(new SqlParameter("@SessionID", session.SessionID));
//             dbcommand2.Parameters.Add(new SqlParameter("@SessionID", session.SessionID));
//
//             dbcommand2.Connection = dbconnection;
//             dbreader2 = dbcommand2.ExecuteReader(CommandBehavior.CloseConnection);
//
//             while (dbreader2.Read())
//             {
//                 editPropertyParams = dbreader2["editPropertyParams"].ToString();
//             }
//
//             if (!dbreader2.IsClosed)
//                 dbreader2.Close();
//
//            }
//            catch (Exception ex) { Framework.Utilities.DebugLogging.Log($"Edit/UI/Display.aspx.cs : {ex.Message}");
//            }
        }

        override protected void OnInit(EventArgs e)
         {
            string layoutData = "{}";
            string editPropertyParams = "{}";

            sessionManagement = new SessionManagement();
            Framework.Utilities.Session session = sessionManagement.Session();

            string sessionInfo = ConfigurationHelper.GetSessionInfoJavascriptObject(session);
            string g = ConfigurationHelper.GlobalJavascriptVariablesProfilePage
                .Replace("{tab}", "")
                .Replace("{preLoad}", layoutData.Replace("'", "\\'"));

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
//            sessionManagement = new Framework.Utilities.SessionManagement();
//
//            if (sessionManagement.Session().UserID < 0 || sessionManagement.Session().UserID == 0)
//                Response.Redirect(Framework.Utilities.Root.Domain);
//
//            masterpage = (Framework.Template)base.Master;
//
//            LoadPresentationXML();
        }


//        public void LoadPresentationXML()
//        {
//
//            this.PresentationXML = new XmlDocument();
//
//            this.PresentationXML.LoadXml(System.IO.File.ReadAllText(AppDomain.CurrentDomain.BaseDirectory + "/Lists/PresentationXML/MyLists.xml"));
//            masterpage.PresentationXML = this.PresentationXML;
//        }


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
        public static void RemoveCoauthors()
        {
            Lists.Utilities.DataIO.AddRemoveCoAuthors("Replace");
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