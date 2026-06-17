using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Xml;
using Profiles.Framework.Utilities;
using System.Web.Script.Serialization;

namespace Profiles.Lists
{
    public partial class Default : System.Web.UI.Page
    {
        SessionManagement sessionManagement;

        private void myLog(string message) {
            message = $"------------myLog--------------->> {message} <<----------";
            System.Diagnostics.Debug.WriteLine(message);
        }
        private string dbActivity() {
            myLog("dbActivity");
            Session session = sessionManagement.Session();

            if (session.ListID == null)
            {
                session.ListID = session.PersonID.ToString();
            }

            Utilities.DataIO.ProfilesList profilesList =
                Profiles.Lists.Utilities.DataIO.GetPeople("", "");

            var serializer = new JavaScriptSerializer();
            string result = serializer.Serialize(profilesList);
            return result;
        }

        override protected void OnInit(EventArgs e)
         {
            sessionManagement = new SessionManagement();
            Framework.Utilities.Session session = sessionManagement.Session();

            string peopleJson = dbActivity();

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