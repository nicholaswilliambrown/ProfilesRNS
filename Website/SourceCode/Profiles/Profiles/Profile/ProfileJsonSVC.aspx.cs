using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Configuration;

namespace Profiles.Profile
{
    public partial class ProfileJsonSVC : System.Web.UI.Page, System.Web.SessionState.IRequiresSessionState
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            //Profiles.Profile.Modules.CustomViewAuthorInAuthorship.DataIO data = new Profiles.Profile.Modules.CustomViewAuthorInAuthorship.DataIO();

            //Profiles.Framework.Utilities.RDFTriple request = new RDFTriple(Convert.ToInt32(Request.QueryString["p"]));

            string s = Request.QueryString["s"].ToString();
            string p = "";
            if (Request.QueryString["p"] != null) p = Request.QueryString["p"].ToString();
            string o = "";
            if (Request.QueryString["o"] != null) o = Request.QueryString["o"].ToString();
            string t = "";
            if (Request.QueryString["t"] != null) t = Request.QueryString["t"].ToString();

            Framework.Utilities.RDFTriple request = new Profiles.Framework.Utilities.RDFTriple(1);
           string sessionID = request.Session.SessionID;

            string str = string.Empty;
            try
            {
                string connstr = ConfigurationManager.ConnectionStrings["ProfilesDB"].ConnectionString;
                SqlConnection dbconnection = new SqlConnection(connstr);// "Data Source=.;Initial Catalog=ProfilesRNS_HMS_NewUI;Connection Timeout=5;User ID=app_HCProfiles;Password=Password1234");
                SqlCommand dbcommand = new SqlCommand("[Display.].[GetJson]");
                dbcommand.CommandTimeout = 500;//Convert.ToInt32(ConfigurationSettings.AppSettings["COMMANDTIMEOUT"]);

                SqlDataReader dbreader;
                dbconnection.Open();
                dbcommand.CommandType = CommandType.StoredProcedure;
                //dbcommand.CommandTimeout = base.GetCommandTimeout();
                if (!"".Equals(s)) dbcommand.Parameters.Add(new SqlParameter("@subject", int.Parse(s)));
                if (!"".Equals(p)) dbcommand.Parameters.Add(new SqlParameter("@predicate", int.Parse(p)));
                if (!"".Equals(o)) dbcommand.Parameters.Add(new SqlParameter("@object", int.Parse(o)));
                if (!"".Equals(t)) dbcommand.Parameters.Add(new SqlParameter("@tab", t));
                if (!"".Equals(sessionID)) dbcommand.Parameters.Add(new SqlParameter("@SessionID", sessionID));

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