using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.IO;

namespace Profiles.Search
{
    public partial class SearchSVC : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            string searchType = "params";
            if (Request.QueryString["SearchType"] != null) searchType = Request.QueryString["SearchType"].ToString();
            string storedProc = null;
            string body = null;
            if ("params".Equals(searchType))
            {
                storedProc = "[Display.].[Search.Params]";

            }
            else
            {
                if (!string.Equals(Request.HttpMethod, "POST"))
                {
                    Response.StatusCode = 405;
                    Response.End();
                }
                body = new StreamReader(Request.InputStream).ReadToEnd(); // "{\"Keyword\": \"asthma\",\"KeywordExact\": false,\"Offset\": 0,\"Count\": 15}";
                if ("person".Equals(searchType)) storedProc = "[Display.].[SearchPeople]";
                else if ("everything".Equals(searchType)) storedProc = "[Display.].[SearchEverything]";
                else if ("why".Equals(searchType)) storedProc = "[Display.].[SearchWhy]";
                else
                {
                    Response.StatusCode = 500;
                    Response.End();
                }
            }
            
 /*           using (StreamReader stream = new StreamReader(Request.))
            {
                body = stream.ReadToEndAsync().Result;
                // body = "param=somevalue&param2=someothervalue"
            }
 */
            string str = string.Empty;
            try
            {
                string connstr = ConfigurationManager.ConnectionStrings["ProfilesDB"].ConnectionString;
                SqlConnection dbconnection = new SqlConnection(connstr);
                SqlCommand dbcommand = new SqlCommand(storedProc);
                dbcommand.CommandTimeout = 500;//Convert.ToInt32(ConfigurationSettings.AppSettings["COMMANDTIMEOUT"]);

                SqlDataReader dbreader;
                dbconnection.Open();
                dbcommand.CommandType = CommandType.StoredProcedure;
                //dbcommand.CommandTimeout = base.GetCommandTimeout();
                if (body != null)  dbcommand.Parameters.Add(new SqlParameter("@json", body));

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