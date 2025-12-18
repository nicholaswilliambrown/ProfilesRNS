using System;
using Profiles.Framework.Utilities;

namespace Profiles.Lists.Modules.NetworkClusterList
{
    public partial class NetworkClusterGroupSvc : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Request.QueryString["p"] != null)
            {
                string listid = Request.QueryString["p"].ToString();
                Response.ContentType = "application/json; charset=utf-8";
                Response.AppendHeader("Access-Control-Allow-Origin", "*");
                Response.Write(Profiles.Lists.Utilities.DataIO.GetNetworkRadialCoAuthors(listid));
            }
            else
            {
                string listids = Request.QueryString["s"].ToString();
                Response.ContentType = "application/json; charset=utf-8";
                Response.AppendHeader("Access-Control-Allow-Origin", "*");
                Response.Write(Profiles.Lists.Utilities.DataIO.GetCoAuthorsForSavedLists(listids));
            }
        }
    }
}
