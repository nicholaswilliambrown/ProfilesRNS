using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Xml;

namespace Profiles.Lists
{
    public partial class Default : System.Web.UI.Page
    {
        Profiles.Framework.Template masterpage;
        Framework.Utilities.SessionManagement sm;

        protected void Page_Load(object sender, EventArgs e)
        {
            sm = new Framework.Utilities.SessionManagement();

            if (sm.Session().UserID < 0 || sm.Session().UserID == 0)
                Response.Redirect(Framework.Utilities.Root.Domain);

            masterpage = (Framework.Template)base.Master;

            LoadPresentationXML();
        }


        public void LoadPresentationXML()
        {

            this.PresentationXML = new XmlDocument();

            this.PresentationXML.LoadXml(System.IO.File.ReadAllText(AppDomain.CurrentDomain.BaseDirectory + "/Lists/PresentationXML/MyLists.xml"));
            masterpage.PresentationXML = this.PresentationXML;
        }


        [System.Web.Services.WebMethod]
        public static string AddPersonToList(string ownernodeid, string listid, string personid)
        {

            if (listid == "0")
                listid = Lists.Utilities.DataIO.CreateList(ownernodeid, "List");

            return Lists.Utilities.DataIO.AddRemovePerson(listid, personid);


        }

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