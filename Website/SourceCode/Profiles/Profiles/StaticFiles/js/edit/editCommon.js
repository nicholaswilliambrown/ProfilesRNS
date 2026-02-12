 async function editPost(url, body,redirectTo) {
    console.log('--------edit for post----------');
    console.log(url);
    var _body = JSON.stringify(body);
    console.log(_body); 
     try {
         const results = await $.post(url, _body);

        
             let stringResults = JSON.stringify(results);
             console.log('--------Done with edit for post----------');
             console.log(stringResults);
             if (redirectTo != '')
                window.location.href = redirectTo;
         

     } catch (error) {
         console.log(error);
         if (redirectTo != '')
            window.location.href = redirectTo;
     }
       
    
}
 async function getData(url,callback) {
    console.log('--------get edit data----------');
    console.log(url);

    $.post(url,function (results) {
       
            let stringResults = JSON.stringify(results);
            console.log(results);
            callback(results);
        
    });

     return true;


}
function loadEditTopNav(title) {
    var menuStr = `<div class="row ">
                        <div class='col-10 d-flex justify-content-start'>
                            <a class='editMenuLink' href='${g.profilesRootURL}/edit/default.aspx?subject=${sessionInfo.personNodeID}'>Edit Menu</a><span class='editMenuGT'>&nbsp;>&nbsp;</span><span><b>${title}</b></span>
                        </div>
                        <div class='col-2 d-flex justify-content-end'>
                            <a href='${sessionInfo.personURI}'><img src='${g.profilesRootURL}/Framework/Images/arrowLeft.png' /> View Profile</a> 
                        </div>
                    </div>`;
    $("#editTopNav").html(menuStr);
    
} 


$(document).ready(function () {

    $('.editMenuLink').on('click', function (event) {
        event.preventDefault();
        var $clickedLink = $(this); // The link that was clicked
        var $image = $clickedLink.find('img'); // Find the image within that div
        let displayTable = $(this).attr("table-id");
        
        if ($image.attr('src').includes('down')) {
            $image.attr('src', $image.attr('src').replace('icon_squaredownArrow', 'icon_squareArrow'));
            $(`#${displayTable}`).hide();
        } else {
            $image.attr('src', $image.attr('src').replace('icon_squareArrow', 'icon_squaredownArrow'));
            $(`#${displayTable}`).show();
        }
        
    });
    

    $("#editVisibility").load(`${g.profilesRootURL}/StaticFiles/html-templates/SecuritySettings.html`, function (response, status, xhr) {
        if (status === "error") {
            console.error("Error loading SecuritySettings.html: " + xhr.status + " " + xhr.statusText);
        }
        $('input:radio[value="' + propertyList.Categories[0].Properties.find(obj => obj.Label == g.pageContext).ViewSecurityGroup + '"]').prop('checked', true);
                
    });



});
function SecuritySettingChange(secVal) {

    // Get the selected radio button's value
    const selectedValue = secVal;

    // Find the matching SecurityGroup object in propertyList.SecurityGroupList
    const securityGroup = propertyList.SecurityGroupList.find(
        group => group.SecurityGroup.toString() === selectedValue
    );

    // Update the #currentVisibility span with the corresponding ViewSecurityGroupLabel
    if (securityGroup) {
        $('#currentVisibility').text(securityGroup.Label);
    } else {
        $('#currentVisibility').text('Unknown'); // Fallback if no matching label is found
    }

    // Hide the #editVisibility div

    $("#visibilityMenuIcon").attr('src', $("#visibilityMenuIcon").attr('src').replace('icon_squaredownArrow', 'icon_squareArrow'));
    $('#editVisibility').hide();


}