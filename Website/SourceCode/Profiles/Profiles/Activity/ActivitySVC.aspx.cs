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
            string count = Request.QueryString["count"].ToString();
            string lastActivityLogID = Request.QueryString["lastActivityLogID"].ToString();

            string logIdList = "";
            string str = null ;


            string cachePlaceholder = (string)Framework.Utilities.Cache.FetchObject("GetLatestActivity" + count + "|" + lastActivityLogID);
            if (cachePlaceholder != null) str = (string)Framework.Utilities.Cache.FetchObject("GetLatestActivityJSON" + count + "|" + lastActivityLogID);

            if (str == null)
            {
                try
                {
                    string connstr = ConfigurationManager.ConnectionStrings["ProfilesDB"].ConnectionString;
                    SqlConnection dbconnection = new SqlConnection(connstr);// "Data Source=.;Initial Catalog=ProfilesRNS_HMS_NewUI;Connection Timeout=5;User ID=app_HCProfiles;Password=Password1234");
                    SqlCommand dbcommand = new SqlCommand("[Display.].[GetLatestActivityIDs]");
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
                        logIdList = logIdList + "," + dbreader[0].ToString();


                    if (!dbreader.IsClosed)
                        dbreader.Close();


                    //string cachePlaceholder = (string)Framework.Utilities.Cache.FetchObject("GetLatestActivity03");
                    string cacheIDs = (string)Framework.Utilities.Cache.FetchObject("GetLatestActivityIDs" + count + "|" + lastActivityLogID);
                    int cachetimeout = Convert.ToInt32(ConfigurationSettings.AppSettings["ACTIVITY_LOG_CACHE_EXPIRE"]);
                    int cachetimeout2 = Convert.ToInt32(ConfigurationSettings.AppSettings["EDITABLE_PAGE_CACHE_EXPIRE"]); // We cache the values longer so that we can compare to the current state and save rerequesting the json from the database

                    if (cacheIDs != null)
                    {
                        if(cacheIDs.Equals(logIdList)) 
                        {
                            str = (string)Framework.Utilities.Cache.FetchObject("GetLatestActivityJSON" + count + "|" + lastActivityLogID);
                                
                            Framework.Utilities.Cache.SetWithTimeout("GetLatestActivity" + count + "|" + lastActivityLogID, logIdList, cachetimeout);
                        }

                    }
                    else
                    {
                        Framework.Utilities.Cache.SetWithTimeout("GetLatestActivity" + count + "|" + lastActivityLogID, logIdList, cachetimeout);
                        Framework.Utilities.Cache.SetWithTimeout("GetLatestActivityIDs" + count + "|" + lastActivityLogID, logIdList, cachetimeout2);
                    }

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

            if (str == null)
            {
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
                    dbcommand.Parameters.Add(new SqlParameter("@activityLogIDs", logIdList));


                    dbcommand.Connection = dbconnection;
                    dbreader = dbcommand.ExecuteReader(CommandBehavior.CloseConnection);

                    while (dbreader.Read())
                        str += dbreader[0].ToString();


                    if (!dbreader.IsClosed)
                        dbreader.Close();

                    int cachetimeout = Convert.ToInt32(ConfigurationSettings.AppSettings["ACTIVITY_LOG_CACHE_EXPIRE"]);
                    int cachetimeout2 = Convert.ToInt32(ConfigurationSettings.AppSettings["EDITABLE_PAGE_CACHE_EXPIRE"]);
                    Framework.Utilities.Cache.SetWithTimeout("GetLatestActivity" + count + "|" + lastActivityLogID, logIdList, cachetimeout);
                    Framework.Utilities.Cache.SetWithTimeout("GetLatestActivityIDs" + count + "|" + lastActivityLogID, logIdList, cachetimeout2);
                    Framework.Utilities.Cache.SetWithTimeout("GetLatestActivityJSON" + count + "|" + lastActivityLogID, str, cachetimeout2);
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
            if (str == null) str = "[{\"ErrorMessage\":\"There was an error: Empty str\"}]";

            Response.ContentType = "application/json; charset=utf-8";
            Response.AppendHeader("Access-Control-Allow-Origin", "*");
            Response.Write(str);
        }


        protected void Page_Load2(object sender, EventArgs e)
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