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
using Profiles.Framework.Utilities;

namespace Profiles.Search
{
    public partial class SearchSVC : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {

            double cachetimeout = 0;
            string searchType = "params";
            if (Request.QueryString["SearchType"] != null) searchType = Request.QueryString["SearchType"].ToString();
            string storedProc = null;
            string body = null;
            SessionManagement sessionManagement = new SessionManagement();
            Session session = sessionManagement.Session();
            if ("params".Equals(searchType))
            {
                storedProc = "[Display.].[Search.Params]";
                cachetimeout = Convert.ToInt32(ConfigurationManager.AppSettings["STATIC_PAGE_CACHE_EXPIRE"]);
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
                cachetimeout = Convert.ToInt32(ConfigurationManager.AppSettings["SEARCH_CACHE_EXPIRE"]);
            }
            
 /*           using (StreamReader stream = new StreamReader(Request.))
            {
                body = stream.ReadToEndAsync().Result;
                // body = "param=somevalue&param2=someothervalue"
            }
 */
            string str = string.Empty;
            string cacheKey = storedProc + (body != null ? body : string.Empty);
            // Return from cache 
            str = (string) Framework.Utilities.Cache.FetchObject(cacheKey);
            if (str == null)
            {
                try
                {
                    string connstr = ConfigurationHelper.GetConnectionString(session);
                    SqlConnection dbconnection = new SqlConnection(connstr);
                    SqlCommand dbcommand = new SqlCommand(storedProc);
                    dbcommand.CommandTimeout = Convert.ToInt16(ConfigurationManager.AppSettings["COMMANDTIMEOUT"]);

                    SqlDataReader dbreader;
                    dbconnection.Open();
                    dbcommand.CommandType = CommandType.StoredProcedure;
                    //dbcommand.CommandTimeout = base.GetCommandTimeout();
                    if (body != null) dbcommand.Parameters.Add(new SqlParameter("@json", body));

                    dbcommand.Connection = dbconnection;
                    dbreader = dbcommand.ExecuteReader(CommandBehavior.CloseConnection);

                    while (dbreader.Read())
                        str += dbreader[0].ToString();


                    if (!dbreader.IsClosed)
                        dbreader.Close();

                    Framework.Utilities.Cache.SetWithTimeout(cacheKey, str, cachetimeout);

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
            }

            // js = new JsonString();
            //js.Value = str;

            //return js;


            Response.ContentType = "application/json; charset=utf-8";
            //Response.AppendHeader("Access-Control-Allow-Origin", "*");
            Response.AppendHeader("cache-control", "public, max-age=" + cachetimeout);
            Response.Write(str);
        }
    }
}