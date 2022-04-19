using System;
using System.Collections.Generic;
using System.Text;
using System.Xml;
using Profiles.Framework.Utilities;


namespace Profiles.Profile.Modules.CustomViewPropertyGroupLinks
{
    public partial class CustomViewPropertyGroupLinks : BaseModule
    {
        protected void Page_Load(object sender, EventArgs e)
        { PropertyGroupLinks(); }
        public CustomViewPropertyGroupLinks() : base() { }
        public CustomViewPropertyGroupLinks(XmlDocument pagedata, List<ModuleParams> moduleparams, XmlNamespaceManager pagenamespaces)
            : base(pagedata, moduleparams, pagenamespaces)
        {
            if (Request.QueryString["subject"] != null)
                this.SubjectID = Convert.ToInt64(Request.QueryString["subject"]);
            else if (base.GetRawQueryStringItem("subject") != null)
                this.SubjectID = Convert.ToInt64(base.GetRawQueryStringItem("subject"));

        }
        private void PropertyGroupLinks()
        {
            List<string> propgroups = new List<string>();
            Profiles.Profile.Utilities.DataIO data = new Profiles.Profile.Utilities.DataIO();
            List<string> exclusion = new List<string> { "name suffix", "research areas", "ecommons login", "person id", "has faculty rank", "label", "type", "similar to", "physical neighbor", "coauthor of", "person in primary position", "positions", "full name", "first name", "middle name or initial", "last name", "mailing address", "phone", "fax", "email address", "email", "photo", "latitude", "longitude", "preferred title" };

            XmlDocument PropertyListXML = data.GetPropertyList(base.BaseData, base.PresentationXML, "", false, false, true);
            StringBuilder grouplinks = new StringBuilder();
            string label = string.Empty;
            int loop = 1;
            grouplinks.Append("<div style='display:flex;flex-wrap:wrap;border: 1px solid #CCC;padding-top:15px;padding-left:15px;padding-right:15px;padding-bottom:5px;margin-top:20px;'>");


            foreach (XmlNode property in PropertyListXML.SelectNodes("PropertyList/PropertyGroup/Property"))
            {
                label = property.SelectSingleNode("@Label").Value.ToLower();

                if (!exclusion.Exists(x => x == label))
                {
                    grouplinks.Append($"<div style='padding-bottom:8px;'><a href='#{label.Replace(" ", "")}'>");
                    grouplinks.Append(label);
                    grouplinks.Append("</a>");
                    grouplinks.Append($"<span id='{loop}' style='padding-left:15px;padding-right:15px'>|</span></div>");
                    propgroups.Add($"{label.Replace(" ", "")}x");
                    loop++;
                }
            }

            grouplinks.Append("</div><script type=\"text/javascript\" src=\"//ajax.aspnetcdn.com/ajax/jQuery/jquery-1.4.2.min.js\"></script><script type='text/javascript'>");
/*
            foreach (string s in propgroups)
            {
                grouplinks.Append($" $('#{s}').click(function() {{ scrollToAnchor('{s}');  }}); ");
            }
*/

            grouplinks.Append(" var $jQuery_1_4_2 = $.noConflict(true);     $jQuery_1_4_2('.PropertyGroup').live(\"click\",function(e) {  e.stopPropagation(); ");
            grouplinks.Append(" var _this = $jQuery_1_4_2(this).find('img');");
            grouplinks.Append(" var current = _this.attr('src');");
            grouplinks.Append(" var swap = _this.attr('data-swap');");
            grouplinks.Append(" _this.attr('src', swap).attr('data-swap', current);");
            grouplinks.Append($"}}); $(\"span[id^='{(loop - 1)}']\").remove();");

            grouplinks.Append("</script>");

            litPropertyGroupLinks.Text = grouplinks.ToString();
        }
        private Int64 SubjectID { get; set; }

    }


}