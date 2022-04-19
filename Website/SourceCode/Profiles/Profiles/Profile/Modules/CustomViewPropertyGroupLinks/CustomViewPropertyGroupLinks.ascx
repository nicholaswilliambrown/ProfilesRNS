<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="CustomViewPropertyGroupLinks.ascx.cs"
    Inherits="Profiles.Profile.Modules.CustomViewPropertyGroupLinks.CustomViewPropertyGroupLinks" %>
<script type="text/javascript">    


    $(document).ready(function () {

        var clipboard;
        var properties = document.querySelectorAll('.property-list-link');


        clipboard = new ClipboardJS(properties);

        clipboard.on('success', function (e) {
            $('[data-toggle="tooltip"]').attr("class", "property-list-link bi bi-clipboard");
            $("#" + e.trigger.attributes.id.nodeValue).toggleClass('bi-clipboard bi-clipboard-check', 'slow');           

            //console.log(e.text);

            e.clearSelection();
        });
        clipboard.on('error', function (e) {
            console.log(e);
            e.clearSelection();
        });


    });
</script>
<asp:Literal runat="server" ID="litPropertyGroupLinks"></asp:Literal>


<script type="text/javascript">

    $(document).ready(function () {

        $('[data-toggle="tooltip"]').tooltip();        

    });
</script>
