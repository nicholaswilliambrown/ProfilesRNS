/*  
 
    Copyright (c) 2008-2012 by the President and Fellows of Harvard College. All rights reserved.  
    Profiles Research Networking Software was developed under the supervision of Griffin M Weber, MD, PhD.,
    and Harvard Catalyst: The Harvard Clinical and Translational Science Center, with support from the 
    National Center for Research Resources and Harvard University.


    Code licensed under a BSD License. 
    For details, see: LICENSE.txt 
  
*/


using System;
using System.Web;
using System.Web.UI;
using System.Xml;
using System.Web.UI.WebControls;
using System.Web.UI.HtmlControls;

using Profiles.Framework.Utilities;
using System.Web.Configuration;

namespace Profiles.Search
{
    public partial class Default : System.Web.UI.Page
    {
        Profiles.Framework.Template masterpage;



        //public void Page_Load(object sender, EventArgs e)
        override protected void OnInit(EventArgs e)
        {
            string pageText = "";
            if (Request.QueryString.Count > 0)
            {
                if ("PersonResults".Equals(Request.QueryString[0]))
                {
                    pageText = System.IO.File.ReadAllText(AppDomain.CurrentDomain.BaseDirectory + "/StaticFiles/html-templates/searchPeopleResults.html")
                        .Replace("{profilesPath}", ConfigurationHelper.ProfilesRootRelativePath)
                        .Replace("{searchApiPath}", ConfigurationHelper.ProfilesRootURL + "/Search/SearchSvc.aspx")
                        .Replace("{activityApiPath}", ConfigurationHelper.ProfilesRootURL + "/Activity/ActivitySvc.aspx");
                }
                else if ("EverythingResults".Equals(Request.QueryString[0]))
                {
                    pageText = System.IO.File.ReadAllText(AppDomain.CurrentDomain.BaseDirectory + "/StaticFiles/html-templates/searchAllElseResults.html")
                        .Replace("{profilesPath}", ConfigurationHelper.ProfilesRootRelativePath)
                        .Replace("{searchApiPath}", ConfigurationHelper.ProfilesRootURL + "/Search/SearchSvc.aspx")
                        .Replace("{activityApiPath}", ConfigurationHelper.ProfilesRootURL + "/Activity/ActivitySvc.aspx");
                }
            }
            else
            {
                pageText = System.IO.File.ReadAllText(AppDomain.CurrentDomain.BaseDirectory + "/StaticFiles/html-templates/searchForm.html")
                    .Replace("{profilesPath}", ConfigurationHelper.ProfilesRootRelativePath)
                    .Replace("{searchApiPath}", ConfigurationHelper.ProfilesRootURL + "/Search/SearchSvc.aspx")
                    .Replace("{activityApiPath}", ConfigurationHelper.ProfilesRootURL + "/Activity/ActivitySvc.aspx");
            }
            //activityApiPath searchApiPath
            litText.Text = pageText;
        }
    }
}
