<%@ Control Language="C#" AutoEventWireup="true"
    CodeBehind="ManageLists.ascx.cs"
    Inherits="Profiles.Lists.Modules.Lists.ManageLists" %>

<script>    

    $(".panelPassive").show();
    $(".modalupdate").show();
</script>
<div>
    <div class="content-main" style="border-bottom: 1px solid #ccc; height: 32px;">
        <ul class="tabmenu">
            <li class="tab" id="tab-view" style="cursor: pointer;" onclick="window.location='<%=string.Format("{0}/lists/default.aspx?type=view",Profiles.Framework.Utilities.Root.Domain)%>';">
                <a href="<%=string.Format("{0}/lists/default.aspx?type=view",Profiles.Framework.Utilities.Root.Domain)%>">Manage List</a>
            </li>
            <li class="tab" id="tab-map" style="cursor: pointer;" onclick="window.location='<%=string.Format("{0}/lists/default.aspx?type=map",Profiles.Framework.Utilities.Root.Domain)%>';">
                <a href="<%=string.Format("{0}/lists/default.aspx?type=map",Profiles.Framework.Utilities.Root.Domain)%>">Map View</a> </li>
            <li class="tab" id="tab-coviz" style="cursor: pointer;" onclick="window.location='<%=string.Format("{0}/lists/default.aspx?type=coviz",Profiles.Framework.Utilities.Root.Domain)%>';">
                <a href="<%=string.Format("{0}/lists/default.aspx?type=coviz",Profiles.Framework.Utilities.Root.Domain)%>">Cluster View</a> </li>
            <li class="tab" id="tab-summary" style="cursor: pointer;" onclick="window.location='<%=string.Format("{0}/lists/default.aspx?type=summary",Profiles.Framework.Utilities.Root.Domain)%>';">
                <a href="<%=string.Format("{0}/lists/default.aspx?type=summary",Profiles.Framework.Utilities.Root.Domain)%>">Reports</a> </li>
            <li class="tab" id="tab-export" style="cursor: pointer;" onclick="window.location='<%=string.Format("{0}/lists/default.aspx?type=export",Profiles.Framework.Utilities.Root.Domain)%>';">
                <a href="<%=string.Format("{0}/lists/default.aspx?type=export",Profiles.Framework.Utilities.Root.Domain)%>">Export Data</a> </li>
            <li class="tab" id="tab-saved" style="cursor: pointer;" onclick="window.location='<%=string.Format("{0}/lists/default.aspx?type=saved",Profiles.Framework.Utilities.Root.Domain)%>';">
                <a href="<%=string.Format("{0}/lists/default.aspx?type=saved",Profiles.Framework.Utilities.Root.Domain)%>">Saved Lists</a> </li>
        </ul>
    </div>
</div>

<div class="modalupdate">
 <!--   <div class="modalcenter">
        <img alt="Updating..." src="<%=Profiles.Framework.Utilities.Root.Domain%>/edit/images/loader.gif" /><br />
        <div>This may take a few seconds to process.</div>
        <i>Updating...</i>
    </div>-->
</div>
<asp:Panel runat="server" ID="pnlPeople" Visible="false">

    <script type="text/javascript">

        var _page = 0;

        function GotoNextPage() {

            _page++;
            NavToPage();
        }
        function GotoPreviousPage() {

            _page--;
            NavToPage();
        }
        function GotoFirstPage() {

            _page = 1;
            NavToPage();
        }
        function GotoLastPage() {

            _page = _totalpages;
            NavToPage();
        }
        function NavToPage() {

            window.location = "<%=Profiles.Framework.Utilities.Root.Domain %>/lists/default.aspx?type=view&page=" + _page + GetFilters();
        }

        function NavToProfile(personid) {
            document.location.href = "<%= Profiles.Framework.Utilities.Root.Domain %>/display/Person/" + personid;
        }


        function removeselected() {
            
            var selected = "";
            $('input[type=checkbox]:checked').each(function () {
                selected += ($(this).parent().attr('name')) + ',';
            });
            
            RemoveSelected(selected.slice(0, -1));
        }
        function removecoauthors() {
            RemoveCoAuthors();
        }

        function RemoveCoAuthors() {

            jQuery.ajax({
                type: "POST",
                url: "<%=Profiles.Framework.Utilities.Root.Domain%>/Lists/Default.aspx/RemoveCoauthors",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: OnListSuccess,
                failure: function (response) {
                    //  
                    // alert(response.d + " " + check_text + " " + obj.checked);
                    document.location.href = "<%= Profiles.Framework.Utilities.Root.Domain%>/lists/default.aspx";
                }
            });
        }
        function addcoauthors() {
            AddCoAuthors();
        }

        function AddCoAuthors() {

            jQuery.ajax({
                type: "POST",
                url: "<%=Profiles.Framework.Utilities.Root.Domain%>/Lists/Default.aspx/AddCoauthors",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: OnListSuccess,
                failure: function (response) {
                    //  
                    // alert(response.d + " " + check_text + " " + obj.checked);
                    document.location.href = "<%= Profiles.Framework.Utilities.Root.Domain%>/lists/default.aspx";
                }
            });
        }
        function removefilter() {
            document.location.href = "<%= Profiles.Framework.Utilities.Root.Domain%>/lists/default.aspx?type=deletefilter" + GetFilters();
        }

        function RemoveSelected(personids) {
            var listid = <%=this.ListID%>;
            jQuery.ajax({
                type: "POST",
                url: "<%=Profiles.Framework.Utilities.Root.Domain%>/Lists/Default.aspx/DeleteSelected",
                data: "{listid: '" + listid + "', personids: '" + personids + "' }",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: OnRemoveSuccess,
                failure: function (response) {
                    //  
                    // alert(response.d + " " + check_text + " " + obj.checked);
                    document.location.href = "<%= Profiles.Framework.Utilities.Root.Domain%>/lists/default.aspx";
                }
            });
        }

        function OnRemoveSuccess(response) {  // alert(response.d); 

            document.location.href = "<%= Profiles.Framework.Utilities.Root.Domain%>/lists/default.aspx?type=view";
        }

        function OnListSuccess(response) {  // alert(response.d); 
            
            document.location.href = "<%= Profiles.Framework.Utilities.Root.Domain%>/lists/default.aspx?type=view" + GetFilters();
        }

        function ApplyFilter() {
            document.location.href = "<%= Profiles.Framework.Utilities.Root.Domain%>/lists/default.aspx?type=view" + GetFilters();
        }
        function GetFilters() {
            var institution = $("#ddlinstitution").find(":selected").val();
            var facultyrank = $("#ddlfacultyrank").find(":selected").val();
            return "&institution=" + institution + "&facultyrank=" + facultyrank;
        }
    </script>


    <div style="float: left; margin-top: 16px; width: 100%; font-size: 12px; line-height: 16px; border-bottom: 1px dotted #999; padding-bottom: 12px; margin-bottom: 10px;">
        <asp:Literal runat="server" ID="litListStats"></asp:Literal>

    </div>
    <div class="searchSection" style="display: table">
        <div style="display: table-cell; padding-right: 10px; text-align: left">
            <label class="form-label" style="float: left; margin-top: 5px; margin-right: 5px;" for="<%=ddlInstitution.ClientID %>">Institution</label>
            <asp:Literal runat="server" ID="ddlInstitution"></asp:Literal>
        </div>
        <div style="display: table-cell; text-align: left; padding-right: 14px;">
            <label class="form-label" style="float: left; margin-top: 5px; margin-right: 5px;" for="<%=ddlFacultyRank.ClientID %>">Faculty Rank</label>
            <asp:Literal runat="server" ID="ddlFacultyRank"></asp:Literal>
        </div>

    </div>
    <div style="margin-top: 4px;">
        <asp:GridView Width="100%" ID="gridSearchResults" runat="server" DataKeyNames="PersonID"
            AllowPaging="true" PageSize="100" EmptyDataText="No matching people could be found."
            AutoGenerateColumns="False" OnRowDataBound="gridSearchResults_RowDataBound">
            <RowStyle CssClass="oddRow" />
            <AlternatingRowStyle CssClass="evenRow" />
            <HeaderStyle CssClass="topRow" />
            <PagerTemplate>
                <div class="listTablePagination" style="display: inline-flex; padding-left: 200px; border-left: 0px !important; border-bottom: 0px !important; border-right: 0px !important;">
                    <div style="vertical-align: middle; margin-left: 12px; padding-left: 130px;">
                        <asp:Literal ID="litFirst" runat="server"></asp:Literal>
                    </div>
                    <div style="margin-left: 5px;">
                        <asp:Literal ID="litPage" runat="server"></asp:Literal>
                    </div>
                    <div style="vertical-align: middle; margin-left: 5px;">
                        <asp:Literal ID="litLast" runat="server"></asp:Literal>
                    </div>
                </div>
            </PagerTemplate>
            <Columns>
                <asp:BoundField ItemStyle-CssClass="editLeftPaddedCol" HeaderStyle-CssClass="editLeftPaddedCol" DataField="DisplayName" HeaderText="Name" NullDisplayText="--" SortExpression="" />
                <asp:BoundField ItemStyle-CssClass="editLeftPaddedCol" HeaderStyle-CssClass="editLeftPaddedCol" DataField="InstitutionName" HeaderText="Institution" NullDisplayText="--" SortExpression="" />
                <asp:BoundField ItemStyle-CssClass="editLeftPaddedCol" HeaderStyle-CssClass="editLeftPaddedCol" DataField="FacultyRank" HeaderText="Faculty Rank" NullDisplayText="--" SortExpression="" />
                <asp:TemplateField HeaderText="Remove">
                    <ItemTemplate>
                        <asp:CheckBox runat="server" ID="chkRemove" />
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
        </asp:GridView>
    </div>
    <button style="margin-top: 6px; float: right;" type="button" class="btn btn-default" onclick="$('.modalupdate').show(); removeselected();">Remove Selected People</button>
    <asp:Literal runat="server" ID="litPagination"></asp:Literal>

</asp:Panel>
<asp:Panel runat="server" ID="pnlExport" Visible="false">

    <div style="float: left; margin-top: 16px; width: 100%; font-size: 12px; line-height: 16px; border-bottom: 1px dotted #999; padding-bottom: 12px; margin-bottom: 6px;">
        Download data about the people in your list as comma separated text files (*.csv), which you can open in Microsoft Excel and other programs.           
    </div>
    <div style="display: table; width: 100%; padding-top: 5px;" class="listTable">
        <div style="display: table-row">
            <div class="throw tdborderleft thborderright">File</div>
            <div class="throw thborderright">Description</div>
        </div>
        <div style="display: table-row">
            <div class="tdrow tdborderleft thborderright"><a style="margin-left: 5px;" href="<%= Profiles.Framework.Utilities.Root.Domain%>/lists/default.aspx?exporttype=persons&type=export&ok=true&tab=export">People</a></div>
            <div class="tdrow thborderright" style="padding-left: 5px;">One row per person.  Columns include name, address, institution, department, faculty rank, and number of publications.</div>
        </div>
        <div style="display: table-row">
            <div class="tdrow tdborderleft thborderright"><a style="margin-left: 5px;" href="<%= Profiles.Framework.Utilities.Root.Domain%>/lists/default.aspx?exporttype=publications&type=export&ok=true&tab=export">Publications</a></div>
            <div class="tdrow thborderright" style="padding-left: 5px;">One row per person-publication pair.  Columns include the publication title, date, and PubMed ID if available.</div>
        </div>
        <div style="display: table-row">
            <div class="tdrow tdborderleft thborderright"><a style="margin-left: 5px;" href="<%= Profiles.Framework.Utilities.Root.Domain%>/lists/default.aspx?exporttype=coconnections&type=export&ok=true&tab=export">Connections</a></div>
            <div class="tdrow thborderright" style="padding-left: 5px;">This file lists pairs of people who are co-authors.  Columns include the number of co-authored publications.</div>
        </div>
    </div>

</asp:Panel>

<asp:Panel ID="pnlCluster" CssClass="cluster-viz" runat="server" Visible="false">
    <iframe id="iframe-cluster" scrolling="no" src="about:blank" width="100%" height="900" style="overflow: hidden; border: none"></iframe>
    <asp:Literal ID="litCluster" runat="server"></asp:Literal>
</asp:Panel>
<asp:Panel ID="pnlSummary" runat="server" Visible="false">
    <style>
        .h3 {
            color: #933;
            font-size: 15px;
            font-weight: bold;
            margin-top: 17px !important;
            margin-bottom: 17px !important;
        }
    </style>

    <div style="display: inline-block; margin-top: 16px; width: 100%; font-size: 12px; line-height: 16px; border-bottom: 1px dotted #999; padding-bottom: 12px; margin-bottom: 6px;">
        The reports below provide aggregate summaries of the institutions, departments, and faculty ranks of the people in your list.
          
    </div>
    <div>
        <a id="a-institution" href="<%=string.Format("{0}/lists/default.aspx?type=summary&summarytype=institution",Profiles.Framework.Utilities.Root.Domain) %>">Institution Summary</a>&nbsp;&nbsp;|&nbsp;&nbsp;<a id="a-department" href="<%=string.Format("{0}/lists/default.aspx?type=summary&summarytype=department",Profiles.Framework.Utilities.Root.Domain) %>">Department Summary</a>&nbsp;&nbsp;|&nbsp;&nbsp;<a id="a-facultyrank" href="<%=string.Format("{0}/lists/default.aspx?type=summary&summarytype=facultyrank",Profiles.Framework.Utilities.Root.Domain) %>">Faculty Rank Summary</a>
    </div>
    <div id="piechart" style="width: 580px; height: 340px; margin-top: 16px;"></div>

    <script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
    <script type="text/javascript" src="//ajax.googleapis.com/ajax/libs/jquery/1.10.2/jquery.min.js"></script>
    <script type="text/javascript">

        // Load the Visualization API and the piechart package.
        google.charts.load('current', { 'packages': ['corechart'] });

        function drawChart(jsonData, linkname) {
            // Create our data table out of JSON data loaded from server.
            var data = new google.visualization.DataTable(jsonData);
            $('#a-' + linkname).css('cursor', 'default');
            $('#a-' + linkname).css('text-decoration', 'none');
            $('#a-' + linkname).css('font-weight', 'bold');
            $('#a-' + linkname).css('color', '#000000');
            colorArray = ['#4E79A7', '#F28E2B', '#E15759', '#76B7B2', '#59A14F', '#EDC948', '#B07AA1', '#FF9DA7', '#9C755F', '#BAB0AC'];
            // Instantiate and draw our chart, passing in some options.
            var chart = new google.visualization.PieChart(document.getElementById("piechart"));
            chart.draw(data, { width: 680, height: 300, fontSize: 12, colors: colorArray, legend: { alignment: 'center' }, chartArea: { left: 20, top: 20, width: '90%', height: '90%' }, tooltip: { text: 'percentage' } });

        }

    </script>

    <div style="display: table; width: 100%;" class="listTable">
        <asp:Literal runat="server" ID="litSumHeader"></asp:Literal>
        <asp:Literal runat="server" ID="litSumItem"></asp:Literal>
    </div>

    <asp:Literal ID="litSummaryJS" runat="server"></asp:Literal>
</asp:Panel>

<asp:Panel ID="pnlMap" runat="server" Visible="false">
    <iframe id="iframe-map" scrolling="no" src="about:blank" width="100%" height="900" style="overflow: hidden; border: none"></iframe>
    <asp:Literal ID="litMap" runat="server"></asp:Literal>
</asp:Panel>
<asp:Panel runat="server" ID="pnlSaved" Visible="false">

    <script type="text/javascript">

        function Save(listid) {
            var userid = "";
            var name = $("#<%=txtListName.ClientID%>").val();
            ///alert("hello world!!!" + listid);
            jQuery.ajax({
                type: "POST",
                url: "<%=Profiles.Framework.Utilities.Root.Domain%>/Lists/Default.aspx/Save",
                  data: "{listid: '" + listid + "',name: '" + name + "'}",
                  contentType: "application/json; charset=utf-8",
                  dataType: "json",
                  success: OnSaveSuccess,
                  failure: function (response) {
                      $("input:checkbox").prop('checked', false);
                      // alert(response.d + " " + check_text + " " + obj.checked);
                      document.location.href = "<%= Profiles.Framework.Utilities.Root.Domain%>/lists/default.aspx?type=saved";
                  }
            });



        }

        function addupdatelist(action) {
            $('.modalupdate').show();
            var selected = "";
            

            if ($('input[type=checkbox]:checked').length == 0) {
                alert("Please select a list from the table.");
                $('.modalupdate').hide();
                return false;
            }

            if ($('input[type=checkbox]:checked').length > 1 && action != "Delete") {

                alert("Please select only one item from table for this action.")
                $('.modalupdate').hide();
                return false;
            }


            $('input[type=checkbox]:checked').each(function () {
                //Some actions can only grab one item, test for it here.

                selected += ($(this).parent().attr('name')) + ',';
            });

            AddUpdateList(action, selected.slice(0, -1));
        }
        function AddUpdateList(action, listids) {

            jQuery.ajax({
                type: "POST",
                url: "<%=Profiles.Framework.Utilities.Root.Domain%>/Lists/Default.aspx/AddUpdateList",
                data: "{action: '" + action + "',listid: '" + listids + "'}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: OnSaveSuccess,
                failure: function (response) {
                    $("input:checkbox").prop('checked', false); 
                    // alert(response.d + " " + check_text + " " + obj.checked);
                    document.location.href = "<%= Profiles.Framework.Utilities.Root.Domain%>/lists/default.aspx?type=saved";
                }
            });
        }

        function renamelist() {
            $("input:text").val('');            
            $("#myModal").show();
        }

        function executerenamelist() {
            $('.modalupdate').show();
            var selected = "";
            $('input[type=checkbox]:checked').each(function () {
                selected += ($(this).parent().attr('name')) + ',';
            });
            if (selected.length == 0) {
                alert("Please select a list from the table.");
                $('.modalupdate').hide();
                $("#myModal").hide();
                return false;
            }
            if ($('input[type=checkbox]:checked').length > 1) {

                alert("Please select only one item from table for rename action.")
                $('.modalupdate').hide();
                $("#myModal").hide();
                return false;
            }

            var newname = $("#<%=txtRenameList.ClientID%>").val();
            if (newname.length == 0) {
                alert("Please enter a new name for your list.");
                $("#<%=txtRenameList.ClientID%>").focus();
                $('.modalupdate').hide();
                $("#myModal").hide();
                return false;
            }

            RenameList(selected.slice(0, -1), newname);

        }
        function RenameList(listid,newname) {
            

            jQuery.ajax({
                type: "POST",
                url: "<%=Profiles.Framework.Utilities.Root.Domain%>/Lists/Default.aspx/RenameList",
                data: "{listid: '" + listid + "', name: '" + newname + "'}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: OnSaveSuccess,
                failure: function (response) {
                    $("input:checkbox").prop('checked', false);
                    // alert(response.d + " " + check_text + " " + obj.checked);
                    document.location.href = "<%= Profiles.Framework.Utilities.Root.Domain%>/lists/default.aspx?type=saved";
                }
            });
        }

        function modifyactivelist(action) {
            $('.modalupdate').show();

            var selected = "";
            $('input[type=checkbox]:checked').each(function () {
                selected += ($(this).parent().attr('name')) + ',';
            });
            if (selected.length == 0) {
                alert("Please select a list from the table.");
                $('.modalupdate').hide();
                return false;
            }
            ModifyActiveList(action, selected.slice(0, -1), userid);
        }
        function ModifyActiveList(action, listids, userid) {

            jQuery.ajax({
                type: "POST",
                url: "<%=Profiles.Framework.Utilities.Root.Domain%>/Lists/Default.aspx/ModifyActiveList",
                data: "{action: '" + action + "',listids: '" + listids + "'}",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                success: OnSaveSuccess,
                failure: function (response) {
                    $("input:checkbox").prop('checked', false);
                    // alert(response.d + " " + check_text + " " + obj.checked);
                    document.location.href = "<%= Profiles.Framework.Utilities.Root.Domain%>/lists/default.aspx?type=saved";
                }
            });
        }
        function OnSaveSuccess(response) {  // alert(response.d); 
            $("input:text").val('');
            $("input:checkbox").prop('checked', false);
            document.location.href = "<%= Profiles.Framework.Utilities.Root.Domain%>/lists/default.aspx?type=saved";            
        }     
        $(document).ready(function () {
              $("#<%=txtRenameList.ClientID%>").css("padding-left", "5px");
            $("#btnClose").click(function () {
                executerenamelist();
            });
        });
        // When the user clicks anywhere outside of the modal, close it
        $(window).click(function (e) {              
            if (e.target.className== "modal"){
                $("#myModal").hide();
            }   
        });

    </script>



    <div style="float: left; margin-top: 16px; width: 100%; font-size: 12px; line-height: 16px; border-bottom: 1px dotted #999; padding-bottom: 12px; margin-bottom: 10px;">
        On this page you can save your person list, view previously saved person lists, and combine person lists in different ways.
    </div>
    <div class="searchSection" id="div-save-list-as" style="display: table;border-bottom: 1px dotted #999;line-height: 16px;  padding-bottom: 12px; margin-bottom: 10px;width:100%;float:left;">
        <div style="display: table-cell; padding-right: 10px; text-align: left;width:200px;">
            <span class="act-heading">Save my current person list as </span>
        </div>
        <div style="display: table-cell; text-align: left; padding-right: 14px;width:200px;">
            <asp:TextBox runat="server" ID="txtListName" ClientIDMode="Static"></asp:TextBox>
        </div>
        <div style="display: table-cell; text-align: left;">
            <asp:Button runat="server" ID="cmdSaveListName" Text="Save List" />
        </div>
        

    </div>
    <asp:Panel runat="server" ID="pnlSavedLists">
    
    <div style="float: left; width: 100%; font-size: 12px; line-height: 16px; border-bottom: 1px dotted #999; padding-bottom: 12px; margin-bottom: 10px;">

        <div class="searchSection" style="display: table">
            <div style="display: table-row">
                <div class="act-heading" style="width:600px;display: table-cell; padding-right: 10px; text-align: left">
                    Modify your current person list
                </div>
                <div class="act-heading" style="display: table-cell; padding-right: 10px; text-align: left; padding-left: 25px;">
                    Modify one or more saved lists
                </div>
            </div>
            <div id="div-row-1" style="display: table-row">
                <div onclick="modifyactivelist('Replace');" style="display: table-cell; padding-right: 10px; text-align: left; padding-bottom: 5px;">
                    <img src="<%=Profiles.Framework.Utilities.Root.Domain%>/Framework/Images/icon_squareArrow.gif" />
                    <a href="#">Replace my person list with the people in the selected list(s)</a>
                </div>

                <div onclick="addupdatelist('Replace')" style="display: table-cell; padding-right: 10px; padding-left: 25px; text-align: left">
                    <img src="<%=Profiles.Framework.Utilities.Root.Domain%>/Framework/Images/icon_squareArrow.gif" />
                    <a href="#">Replace the selected list with the people in my person list</a>
                </div>
            </div>
            <div id="div-row-2" style="display: table-row">
                <div id="div-row-2-col-1" onclick="modifyactivelist('Add');" style="display: table-cell; padding-right: 10px; text-align: left; padding-bottom: 5px;">
                    <img src="<%=Profiles.Framework.Utilities.Root.Domain%>/Framework/Images/icon_squareArrow.gif" />
                    <a href="#">Add the people in the selected list(s) to my person list</a>
                </div>

                <div id="div-row-2-col-2" onclick="renamelist()" style="display: table-cell; padding-right: 10px; padding-left: 25px; text-align: left">
                    <img src="<%=Profiles.Framework.Utilities.Root.Domain%>/Framework/Images/icon_squareArrow.gif" />
                    <a href="#">Rename the selected list</a>
                </div>
            </div>
            <div id="div-row-3" style="display: table-row">
                <div id="div-row-3-col-1" onclick="modifyactivelist('Remove');" style="display: table-cell; padding-right: 10px; text-align: left; padding-bottom: 5px;">
                    <img src="<%=Profiles.Framework.Utilities.Root.Domain%>/Framework/Images/icon_squareArrow.gif" />
                    <a href="#">Remove the people in the selected list(s) from my person list</a>
                </div>

                <div id="div-row-3-col-2" onclick="addupdatelist('Delete');" style="display: table-cell; padding-right: 10px; padding-left: 25px; text-align: left; cursor: pointer;">
                    <img src="<%=Profiles.Framework.Utilities.Root.Domain%>/Framework/Images/icon_squareArrow.gif" />
                    <a href="#">Delete the selected list(s)</a>
                </div>
            </div>
            <div id="div-row-4" style="display: table-row">
                <div onclick="modifyactivelist('RemoveNotInAll');" style="display: table-cell; padding-right: 10px; text-align: left; padding-bottom: 5px;">
                    <img src="<%=Profiles.Framework.Utilities.Root.Domain%>/Framework/Images/icon_squareArrow.gif" />
                    <a href="#">Remove the people who are not in all of the selected list(s) from my person list</a>
                </div>

                <div style="display: table-cell; padding-right: 10px; text-align: left; padding-left: 25px;">
                </div>
            </div>
            <div id="div-row-5" style="display: table-row">
                <div onclick="modifyactivelist('RemoveNotInAny');" style="display: table-cell; padding-right: 10px; text-align: left; padding-bottom: 5px;">
                    <img src="<%=Profiles.Framework.Utilities.Root.Domain%>/Framework/Images/icon_squareArrow.gif" />
                    <a href="#">Remove the people who are not in at least one of the selected list(s) from my person list</a>
                </div>

                <div style="display: table-cell; padding-right: 10px; text-align: left; padding-left: 25px;">
                </div>
            </div>

        </div>

    </div>

    <div style="margin-top: 4px;">
        <asp:GridView Width="100%" ID="gridSaved" runat="server" DataKeyNames="ListID"
            EmptyDataText="You have no saved lists."
            AutoGenerateColumns="False" OnRowDataBound="gridSaved_RowDataBound">
            <RowStyle CssClass="oddRow" />
            <AlternatingRowStyle CssClass="evenRow" />
            <HeaderStyle CssClass="topRow" />
            <Columns>
                <asp:BoundField ItemStyle-CssClass="editLeftPaddedCol" HeaderStyle-CssClass="editLeftPaddedCol" DataField="ListName" HeaderText="Person List" NullDisplayText="--" />
                <asp:BoundField ItemStyle-CssClass="editLeftPaddedCol" HeaderStyle-CssClass="editLeftPaddedCol" DataField="Size" HeaderText="People" NullDisplayText="--" />
                <asp:BoundField ItemStyle-CssClass="editLeftPaddedCol" HeaderStyle-CssClass="editLeftPaddedCol" DataField="CreateDate" HeaderText="Created Date" NullDisplayText="--" />
                <asp:BoundField ItemStyle-CssClass="editLeftPaddedCol" HeaderStyle-CssClass="editLeftPaddedCol" DataField="UpdatedDate" HeaderText="Updated Date" NullDisplayText="--" />
                <asp:TemplateField HeaderText="Select">
                    <ItemTemplate>
                        <asp:CheckBox runat="server" ID="chkRemove" />
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
        </asp:GridView>
    </div>

    <div id="myModal" class="modal">
        <!-- Modal content -->
        <div class="modal-content">
            <div class="searchSection" style="display: table">
                <div style="display: table-cell; padding-right: 10px; text-align: left">
                    <span class="act-heading">Rename selected person list as </span>
                </div>
                <div style="display: table-cell; text-align: left; padding-right: 14px;">
                    <asp:TextBox runat="server" ID="txtRenameList"></asp:TextBox>
                </div>
                <div style="display: table-cell; text-align: left;">                    
                    <button ID="btnClose">Save List</button>
                </div>

            </div>
        </div>

    </div>
    </asp:Panel>

</asp:Panel>

<asp:Literal runat="server" ID="NoLists" Visible="false"></asp:Literal>

<asp:Literal ID="litJS" runat="server"></asp:Literal>
<script>
    $(document).ready(function () { $(".modalupdate").hide(); });
</script>
