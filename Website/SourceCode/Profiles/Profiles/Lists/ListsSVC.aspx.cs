using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
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


    }
}