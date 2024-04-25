using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Profiles.Activity
{
    public partial class ActivitySVC : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            //Profiles.Profile.Modules.CustomViewAuthorInAuthorship.DataIO data = new Profiles.Profile.Modules.CustomViewAuthorInAuthorship.DataIO();

            //Profiles.Framework.Utilities.RDFTriple request = new RDFTriple(Convert.ToInt32(Request.QueryString["p"]));

            string count = Request.QueryString["count"].ToString();
            string lastActivityLogID = Request.QueryString["lastActivityLogID"].ToString();

             Framework.Utilities.RDFTriple request = new Profiles.Framework.Utilities.RDFTriple(1);
            string sessionID = request.Session.SessionID;

            string str = string.Empty;
            try
            {
                string connstr = ConfigurationManager.ConnectionStrings["ProfilesDB"].ConnectionString;
                SqlConnection dbconnection = new SqlConnection(connstr);// "Data Source=.;Initial Catalog=ProfilesRNS_HMS_NewUI;Connection Timeout=5;User ID=app_HCProfiles;Password=Password1234");
                SqlCommand dbcommand = new SqlCommand("[Display.].[GetActivity]");
                dbcommand.CommandTimeout = 500;//Convert.ToInt32(ConfigurationSettings.AppSettings["COMMANDTIMEOUT"]);

                SqlDataReader dbreader;
                dbconnection.Open();
                dbcommand.CommandType = CommandType.StoredProcedure;
                //dbcommand.CommandTimeout = base.GetCommandTimeout();
                if (!"".Equals(count)) dbcommand.Parameters.Add(new SqlParameter("@count", count));
                if (!"".Equals(lastActivityLogID)) dbcommand.Parameters.Add(new SqlParameter("@lastActivityLogID", lastActivityLogID));


                dbcommand.Connection = dbconnection;
                dbreader = dbcommand.ExecuteReader(CommandBehavior.CloseConnection);

                while (dbreader.Read())
                    str += dbreader[0].ToString();


                if (!dbreader.IsClosed)
                    dbreader.Close();

            }
            catch (Exception ex)
            {
                str = "[{\"ErrorMessage\":\"There was an error: " + ex.Message + "\"}]";
                /*               return new HttpResponseMessage(System.Net.HttpStatusCode.InternalServerError)
                               {
                                   ReasonPhrase = "An Error Occurred",
                                   Content = new StringContent(ex.Message, System.Text.Encoding.UTF8, "text/plain")
                               };
               */
            }

            // js = new JsonString();
            //js.Value = str;

            //return js;


            Response.ContentType = "application/json; charset=utf-8";
            Response.AppendHeader("Access-Control-Allow-Origin", "*");
            Response.Write(str);
        }
    }
}