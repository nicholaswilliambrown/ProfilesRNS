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
using System.Web.Caching;

namespace Profiles.Profile
{
    public partial class ProfileJsonSVC : System.Web.UI.Page, System.Web.SessionState.IRequiresSessionState
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            //Profiles.Profile.Modules.CustomViewAuthorInAuthorship.DataIO data = new Profiles.Profile.Modules.CustomViewAuthorInAuthorship.DataIO();

            //Profiles.Framework.Utilities.RDFTriple request = new RDFTriple(Convert.ToInt32(Request.QueryString["p"]));
            string str = null;
            SessionManagement sessionManagement = new SessionManagement();
            Framework.Utilities.Session session = sessionManagement.Session();
            string s = string.Empty;
            string p = string.Empty;
            string o = string.Empty;
            string t = string.Empty;

            int cacheLengthInt = 0;

            string pageSecurityType = string.Empty;
            string cacheLength = string.Empty;
            long pageCacheSecurityGroup = 0;

            try
            {


                s = Request.QueryString["s"].ToString();
                p = "";
                if (Request.QueryString["p"] != null) p = Request.QueryString["p"].ToString();
                o = "";
                if (Request.QueryString["o"] != null) o = Request.QueryString["o"].ToString();
                t = "";
                if (Request.QueryString["t"] != null) t = Request.QueryString["t"].ToString();
                bool usecache = true;
                if (Request.QueryString["nocachekey"] != null)
                {
                    string noCacheKeyFromConfig = ConfigurationManager.AppSettings["noCacheKey"];
                    string noCacheKey = Request.QueryString["nocachekey"].ToString();
                    if (noCacheKeyFromConfig.Equals(noCacheKey)) usecache = false;
                }

                //Framework.Utilities.RDFTriple request = new Profiles.Framework.Utilities.RDFTriple(1);
                if (usecache)
                {
                    if (session.IsBot)
                    {
                        string botCacheKey = (string)Framework.Utilities.Cache.FetchObject("ProfileJsonSVC" + s + "|" + p + "|" + o + "|" + t + "|bot");
                        if (botCacheKey != null)
                        {
                            str = (string)Framework.Utilities.Cache.FetchObject(botCacheKey);
                            cacheLengthInt = (int)Framework.Utilities.Cache.FetchObject(botCacheKey + "CacheLength");
                        }
                    }
                    else if (session.UserID > 0)
                    {
                        if (!hasOwnerVisibilty(Int64.Parse(s), session))
                        {
                            string userCacheKey = (string)Framework.Utilities.Cache.FetchObject("ProfileJsonSVC" + s + "|" + p + "|" + o + "|" + t + "|user");
                            if (userCacheKey != null)
                            {
                                str = (string)Framework.Utilities.Cache.FetchObject(userCacheKey);
                                cacheLengthInt = (int)Framework.Utilities.Cache.FetchObject(userCacheKey + "CacheLength");
                            }
                        }
                    }
                    else
                    {
                        string publicCacheKey = (string)Framework.Utilities.Cache.FetchObject("ProfileJsonSVC" + s + "|" + p + "|" + o + "|" + t + "|public");
                        if (publicCacheKey != null)
                        {
                            str = (string)Framework.Utilities.Cache.FetchObject(publicCacheKey);
                            cacheLengthInt = (int)Framework.Utilities.Cache.FetchObject(publicCacheKey + "CacheLength");
                        }
                    }
                }
            }
            catch (Exception ex) { Framework.Utilities.DebugLogging.Log($"Profile/ProfileJsonSVC.aspx.cs : {ex.Message}"); }

            if (str == null)
            {

                string sessionID = session.SessionID;

                try
                {
                    string connstr;
                    if (!"".Equals(o)) connstr = ConfigurationHelper.GetConnectionPageConnectionString(session);
                    else connstr = ConfigurationHelper.GetConnectionString(session);
                    SqlConnection dbconnection = new SqlConnection(connstr);
                    SqlCommand dbcommand = new SqlCommand("[Display.].[GetJson]");
                    dbcommand.CommandTimeout = Convert.ToInt16(ConfigurationManager.AppSettings["COMMANDTIMEOUT"]);

                    SqlDataReader dbreader;
                    dbconnection.Open();
                    dbcommand.CommandType = CommandType.StoredProcedure;
                    //dbcommand.CommandTimeout = base.GetCommandTimeout();
                    if (!"".Equals(s)) dbcommand.Parameters.Add(new SqlParameter("@subject", Int64.Parse(s)));
                    if (!"".Equals(p)) dbcommand.Parameters.Add(new SqlParameter("@predicate", Int64.Parse(p)));
                    if (!"".Equals(o)) dbcommand.Parameters.Add(new SqlParameter("@object", Int64.Parse(o)));
                    if (!"".Equals(t)) dbcommand.Parameters.Add(new SqlParameter("@tab", t));
                    if (!"".Equals(sessionID)) dbcommand.Parameters.Add(new SqlParameter("@SessionID", sessionID));

                    dbcommand.Connection = dbconnection;
                    dbreader = dbcommand.ExecuteReader(CommandBehavior.CloseConnection);

                    while (dbreader.Read())
                    {
                        str += dbreader[0].ToString(); //jsonData
                        pageSecurityType = dbreader[1].ToString();
                        cacheLength = dbreader[2].ToString();
                        pageCacheSecurityGroup = long.Parse(dbreader[3].ToString());
                    }


                    if (System.Configuration.ConfigurationManager.AppSettings[cacheLength] != null) { cacheLengthInt = Convert.ToInt32(ConfigurationManager.AppSettings[cacheLength]); }


                    if (pageSecurityType == "Global")
                    {
                        Framework.Utilities.Cache.SetWithTimeout("ProfileJsonSVC" + s + "|" + p + "|" + o + "|" + t + "|data", str, cacheLengthInt);
                        Framework.Utilities.Cache.SetWithTimeout("ProfileJsonSVC" + s + "|" + p + "|" + o + "|" + t + "|dataCacheLength", cacheLengthInt, cacheLengthInt);
                        Framework.Utilities.Cache.SetWithTimeout("ProfileJsonSVC" + s + "|" + p + "|" + o + "|" + t + "|public", "ProfileJsonSVC" + s + "|" + p + "|" + o + "|" + t + "|data", cacheLengthInt);
                        Framework.Utilities.Cache.SetWithTimeout("ProfileJsonSVC" + s + "|" + p + "|" + o + "|" + t + "|user", "ProfileJsonSVC" + s + "|" + p + "|" + o + "|" + t + "|data", cacheLengthInt);
                        Framework.Utilities.Cache.SetWithTimeout("ProfileJsonSVC" + s + "|" + p + "|" + o + "|" + t + "|bot", "ProfileJsonSVC" + s + "|" + p + "|" + o + "|" + t + "|data", cacheLengthInt);

                    }
                    else if (pageSecurityType == "Session")
                    {
                        String[] dependencyKey = new String[1];
                        dependencyKey[0] = s;

                        if (pageCacheSecurityGroup == -1)
                        {
                            Framework.Utilities.Cache.Set("ProfileJsonSVC" + s + "|" + p + "|" + o + "|" + t + "|botdata", str, cacheLengthInt, new CacheDependency(null, dependencyKey));
                            Framework.Utilities.Cache.Set("ProfileJsonSVC" + s + "|" + p + "|" + o + "|" + t + "|botdataCacheLength", cacheLengthInt, cacheLengthInt, new CacheDependency(null, dependencyKey));
                            Framework.Utilities.Cache.Set("ProfileJsonSVC" + s + "|" + p + "|" + o + "|" + t + "|bot", "ProfileJsonSVC" + s + "|" + p + "|" + o + "|" + t + "|botdata", cacheLengthInt, new CacheDependency(null, dependencyKey));
                        }
                        else if (pageCacheSecurityGroup == -10)
                        {
                            Framework.Utilities.Cache.Set("ProfileJsonSVC" + s + "|" + p + "|" + o + "|" + t + "|publicdata", str, cacheLengthInt, new CacheDependency(null, dependencyKey));
                            Framework.Utilities.Cache.Set("ProfileJsonSVC" + s + "|" + p + "|" + o + "|" + t + "|publicdataCacheLength", cacheLengthInt, cacheLengthInt, new CacheDependency(null, dependencyKey));
                            Framework.Utilities.Cache.Set("ProfileJsonSVC" + s + "|" + p + "|" + o + "|" + t + "|public", "ProfileJsonSVC" + s + "|" + p + "|" + o + "|" + t + "|publicdata", cacheLengthInt, new CacheDependency(null, dependencyKey));
                        }
                        else if (pageCacheSecurityGroup == -20)
                        {
                            Framework.Utilities.Cache.Set("ProfileJsonSVC" + s + "|" + p + "|" + o + "|" + t + "|userdata", str, Convert.ToInt32(ConfigurationManager.AppSettings["cacheLength"]), new CacheDependency(null, dependencyKey));
                            Framework.Utilities.Cache.Set("ProfileJsonSVC" + s + "|" + p + "|" + o + "|" + t + "|userdataCacheLength", cacheLengthInt, cacheLengthInt, new CacheDependency(null, dependencyKey));
                            Framework.Utilities.Cache.Set("ProfileJsonSVC" + s + "|" + p + "|" + o + "|" + t + "|user", "ProfileJsonSVC" + s + "|" + p + "|" + o + "|" + t + "|userdata", cacheLengthInt, new CacheDependency(null, dependencyKey));
                        }
                    }


                    if (!dbreader.IsClosed)
                        dbreader.Close();

                }
                catch (Exception ex)
                {
                    Framework.Utilities.DebugLogging.Log($"Profile/ProfileJsonSVC.aspx.cs : {ex.Message}");

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
            Response.AppendHeader("Access-Control-Allow-Origin", "*");
            Response.AppendHeader("cache-control", "public, max-age=" + cacheLengthInt);
            Response.Write(str);
        }



        public bool hasOwnerVisibilty(Int64 NodeID, Framework.Utilities.Session session)
        {

            string canEdit = "";
            //String sessionKey = "SecurityGroup:" + session.ViewSecurityGroup.ToString();
            //string key = "s" + NodeID + sessionKey;
            //canEdit = (string)Framework.Utilities.Cache.FetchObject(key + "|canEdit");

            try
            {
                string connstr = ConfigurationHelper.GetConnectionString(session);
                using (var dbconnection = new SqlConnection(connstr))
                {
                    SqlCommand dbcommand = new SqlCommand("[RDF.Security].[CanEditNode]");

                    SqlDataReader dbreader;
                    dbconnection.Open();
                    dbcommand.CommandType = CommandType.StoredProcedure;
                    dbcommand.CommandTimeout = Convert.ToInt16(ConfigurationManager.AppSettings["COMMANDTIMEOUT"]);
                    dbcommand.Parameters.Add(new SqlParameter("@NodeID", NodeID));
                    dbcommand.Parameters.Add(new SqlParameter("@SessionID", session.SessionID));

                    dbcommand.Connection = dbconnection;

                    dbreader = dbcommand.ExecuteReader(CommandBehavior.CloseConnection);
                    while (dbreader.Read())
                        canEdit = dbreader[0].ToString();

                    if (!dbreader.IsClosed)
                        dbreader.Close();

                    //Framework.Utilities.Cache.Set(key + "|canEdit", canEdit, request.Subject, request.Session.SessionID);
                }
            }
            catch (Exception ex) { Framework.Utilities.DebugLogging.Log($"Profile/ProfileJsonSVC.aspx.cs : {ex.Message}"); }
            return canEdit == "True";
        }


    }
}