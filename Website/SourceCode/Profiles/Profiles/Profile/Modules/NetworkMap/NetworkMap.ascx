﻿<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="NetworkMap.ascx.cs" Inherits="Profiles.Profile.Modules.NetworkMap.NetworkMap" %>
<%--
    Copyright (c) 2008-2010 by the President and Fellows of Harvard College. All rights reserved.  
    Profiles Research Networking Software was developed under the supervision of Griffin M Weber, MD, PhD.,
    and Harvard Catalyst: The Harvard Clinical and Translational Science Center, with support from the 
    National Center for Research Resources and Harvard University.


    Code licensed under a BSD License. 
    For details, see: LICENSE.txt 
 --%>
<style type="text/css">
    div.slider div.handle
    {
        top: -7px !important;
    }

    #map_canvas {
        height: 500px;
        border: 1px solid #999;
        text-align: center;
    }
</style>

<script type="text/javascript">
    var longitude;
    var latitude;
    var mapZoom;
</script>


<script type="text/javascript" src="//maps.googleapis.com/maps/api/js<%= googleKey %>"></script>

<asp:Literal ID="litGoogleCode" runat="server"></asp:Literal>

<script type="text/javascript">

    function zoomMap(zoom, latitude, longitude) {
        ProfilesRNS.currentPage.gmap.setCenter(new google.maps.LatLng(latitude, longitude));
        ProfilesRNS.currentPage.gmap.setZoom(zoom);
    }

    
</script>
<div>
    <div id="divData">

        <div>
            <span style="color: #C00; font-weight: bold;">Red markers</span> indicate <asp:Literal runat="server" ID="litCoauthorGroup" Text="the co-authors"></asp:Literal>.
            <asp:Label ID="lblPerson" runat="server"></asp:Label><br />
            <span style="color: #00C; font-weight: bold;">Blue lines</span> connect people who
            have published papers together.</div>
        <div style="background-color: #999; height: 1px; overflow: hidden;
            margin: 5px 0px;">
        </div>
        <div style="margin-bottom: 5px;">
            <b>Zoom</b>:&nbsp;&nbsp;
            <asp:DataList ID="dlGoogleMapLinks" runat="server" RepeatDirection="Horizontal" RepeatLayout="Flow">
                <ItemTemplate>
                    <a style="cursor: pointer" id="lnkMapLink" runat="server" onkeypress='<%# "if (event.keyCode == 13) JavaScript:zoomMap(" + Eval("ZoomLevel") + "," + Eval("Latitude") + "," + Eval("Longitude") + "); "%>' onclick='<%# "JavaScript:zoomMap(" + Eval("ZoomLevel") + "," + Eval("Latitude") + "," + Eval("Longitude") + "); "%>' tabindex="0">
                        <asp:Label ID="lblMapLink" runat="server" Text='<%#Eval("Label")%>'></asp:Label></a>
                </ItemTemplate>
                <SeparatorTemplate>
                    &nbsp;|&nbsp;</SeparatorTemplate>
            </asp:DataList>
        </div>
        <div id="map_canvas">
        </div>
            <br />
        To see the data from this visualization as text, <a id="divShowTimelineTable" tabindex="0" class="jQueryLink">click here.</a>
     </div>   
    <div id="divDataText" style="display:none;margin-top:12px;margin-bottom:8px;">
        To return to the map,  <a id="dirReturnToTimelineTop" tabindex="0" class="jQueryLink">click here.</a> <br /><br />
        <asp:Literal runat="server" ID="litNetworkText"></asp:Literal> 
        <br />
        To return to the map,  <a id="dirReturnToTimeline" tabindex="0" class="jQueryLink">click here.</a>                      
    </div>
    <script type="text/javascript">

    
        
        // DATASET
        ProfilesRNS.currentPage.data.mapCenter = new google.maps.LatLng(latitude, longitude);
        ProfilesRNS.currentPage.data.mapZoom = mapZoom;




        ProfilesRNS.currentPage.clickLocation = function() {
            // This function is called when the user clicks on a marker
            ProfilesRNS.currentPage.ginfowindow.setContent(this.dataRecord.txt);
            ProfilesRNS.currentPage.ginfowindow.open(ProfilesRNS.currentPage.gmap, this);
        };


        ProfilesRNS.currentPage.loadData = function() {
            // create markers for people
            // var l = ProfilesRNS.currentPage.data.people.length; <== bug: thanks Microsoft
            for (var i = 0; typeof ProfilesRNS.currentPage.data.people[i] !== "undefined"; i++) {
                if (typeof ProfilesRNS.currentPage.data.people[i].pin === "undefined") {
                    var pin = new google.maps.Marker({
                        position: new google.maps.LatLng(ProfilesRNS.currentPage.data.people[i].lt, ProfilesRNS.currentPage.data.people[i].ln),
                        title: ProfilesRNS.currentPage.data.people[i].name,
                        dataRecord: ProfilesRNS.currentPage.data.people[i]
                    });

                    // click event handler
                    google.maps.event.addListener(pin, 'click', ProfilesRNS.currentPage.clickLocation);

                    // drop animation
                    setTimeout("ProfilesRNS.currentPage.data.people[" + i + "].pin.setMap(ProfilesRNS.currentPage.gmap);", 100 * i);

                    // save reference to data array
                    ProfilesRNS.currentPage.data.people[i].pin = pin;
                    pin = null;
                }
            }
            // create network lines
            //var l = ProfilesRNS.currentPage.data.network.length; <== bug: thanks Microsoft IE8
            for (var i = 0; typeof ProfilesRNS.currentPage.data.network[i] !== "undefined"; i++) {
                if (typeof ProfilesRNS.currentPage.data.network[i].overlay === "undefined") {
                    var conData = ProfilesRNS.currentPage.data.network[i];
                    var conOptions = {
                        map: ProfilesRNS.currentPage.gmap,
                        strokeOpacity: 0.5,
                        path: [new google.maps.LatLng(conData.p1[0], conData.p1[1]),
                            new google.maps.LatLng(conData.p2[0], conData.p2[1])]
                    };
                    if (conData.zm == 1) {
                        conOptions.strokeColor = '#9900CC';
                        conOptions.strokeWeight = 6;
                    } else {
                        conOptions.strokeColor = '#0000FF';
                        conOptions.strokeWeight = 2;
                    };
                    // save back to data array
                    ProfilesRNS.currentPage.data.network[i].overlay = new google.maps.Polyline(conOptions);
                }
            }
        };


        ProfilesRNS.currentPage.InitPage = function() {
            // Google map options
            var goptions = {
                zoom: ProfilesRNS.currentPage.data.mapZoom,
                center: ProfilesRNS.currentPage.data.mapCenter,
                mapTypeId: google.maps.MapTypeId.ROADMAP
            };

            // create google map object
            ProfilesRNS.currentPage.gmap = new google.maps.Map(document.getElementById("map_canvas"), goptions);

            // create our info window object
            ProfilesRNS.currentPage.ginfowindow = new google.maps.InfoWindow;

            // load the points in a second (allow map render)
            setTimeout(ProfilesRNS.currentPage.loadData, 500);
        }


        // INITIALIZE ON PAGE LOAD
        $(document).ready(function() {
        ProfilesRNS.currentPage.InitPage();
        ProfilesRNS.currentPage.InitPage();
        });



        jQuery(function () {
            jQuery("#divShowTimelineTable").bind("click", function () {

                jQuery("#divDataText").show();
                jQuery("#divData").hide();
            });

            jQuery("#divShowTimelineTable").bind("keypress", function () {

                jQuery("#divDataText").show();
                jQuery("#divData").hide();
            });
        });

        jQuery(function () {
            jQuery("#dirReturnToTimeline").bind("click", function () {
                jQuery("#divDataText").hide();
                jQuery("#divData").show();
            });
        });

        jQuery(function () {
            jQuery("#dirReturnToTimelineTop").bind("click", function () {
                jQuery("#divDataText").hide();
                jQuery("#divData").show();
            });
        });
               
    </script>

</div>
