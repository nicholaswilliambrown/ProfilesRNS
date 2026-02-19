let gEditProp = {};
gEditProp.downArrow = `${g.profilesRootURL}/Edit/Images/icon_squaredownArrow.gif`;
gEditProp.rightArrow = `${g.profilesRootURL}/Edit/Images/icon_squareArrow.gif`;

gEditProp.visPublic = '-1';
gEditProp.visNoBots = '-10';
gEditProp.visUsers = '-20';

gEditProp.ontologyUrlPrefix = 'http://profiles.catalyst.harvard.edu/ontology/prns!';
gEditProp.ontologyMentoring = 'mentoringOverview';
gEditProp.ontologyJobOpps = 'hasMentoringJobOpportunity';
gEditProp.getMentorOverviewUrl = `${gEditProp.ontologyUrlPrefix}${gEditProp.ontologyMentoring}`;
gEditProp.getJobOpportunitiesUrl = `${gEditProp.ontologyUrlPrefix}${gEditProp.ontologyJobOpps}`;

async function editCommonReady() {
    gEditProp.subject = getSearchParam('subject');

    console.log('=============editProp', g.editPropertyParams);
    console.log('=============subject <', gEditProp.subject, '>');

    let title = JSON.parse(g.preLoad).filter(p=>p.DisplayModule=='Person.Label')[0].ModuleData[0].DisplayName;

    gEditProp.properties = JSON.parse(g.editPropertyParams);

    await commonSetup(title);
    let mainDiv = $('#mainDiv')

    loadBreadcrumbs(title, mainDiv);
    
    setupVisibilityTable(mainDiv);
    
    return mainDiv;
}
function setupVisibilityTable(target) {
    let div = loadVisibilityDiv(target)

    let table = $('#tblVisibility');
    table.hide(); // initially
    div.on('click', function() {
        toggleEltVisibility(table);
        toggleSrcIcon($("#visibilityMenuIcon"), gEditProp.rightArrow, gEditProp.downArrow);
    });
}
function getSearchParam(param) {
    let urlParams = new URLSearchParams(window.location.search);
    let result = urlParams.get(param);
    return result;
}
function toggleSrcIcon(target, srcRoot1, srcRoot2) {
    console.log(target.attr('src'));
    if (target.attr('src').match(srcRoot1)) {
        target.attr('src', srcRoot2);
    }
    else {
        target.attr('src', srcRoot1);
    }
}
function loadVisibilityDiv(target) {
    let div = $(`
        <div id="editVisibilityDiv"><a className="editMenuLink link-ish">
            <img id="visibilityMenuIcon" src="${gEditProp.rightArrow}"/> Edit Visibility (<span
            id="currentVisibility"></span>)</a>
        </div>
        <table id="tblVisibility">
            <thead>
                <tr class="topRow"> 
                    <th class="CenterSelect">Select
                    <th class="alignLeft">Privacy</th>
                    <th class="alignLeft">Description</th>
                </tr>
            </thead>
            <tbody>
                <tr class="evenRow">
                    <td class="CenterSelect">
                        <input type="radio" name="visibility" value="${gEditProp.subject}" /></td>
                    <td>Only Me</td>
                    <td>Only me and special authorized users who manage this website.</td></tr>
                <tr class="oddRow"><td class="CenterSelect">
                        <input type="radio" name="visibility" value="${gEditProp.visUsers}" /></td>
                    <td>Users</td>
                    <td>Limited to people who have logged into website.</td></tr>
                <tr class="evenRow"><td class="CenterSelect">
                        <input type="radio" name="visibility" value="${gEditProp.visNoBots}" /></td>
                    <td>No Search</td>
                    <td>Open to the general public, but blocked to certain (but not all) search engines such as Google.</td></tr>
                <tr class="oddRow"><td class="CenterSelect">
                        <input type="radio" name="visibility" value="${gEditProp.visPublic}" /></td>
                    <td>Public</td>
                    <td>Open to the general public and may be indexed by search engines.</td></tr>
            </tbody>
        </table>
    `)
    target.append(div);
    $('input[name="visibility"]').on('click', function() {
        gEditProp.visibility = $('input[name="visibility"]:checked').val();
        console.log("======= visibility: --------", gEditProp.visibility);
    });
    return div;
}
///////////////////////////////////////////////////

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
        callback(results);
    });
    return true;
}



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

    // $("#visibilityMenuIcon").attr('src', $("#visibilityMenuIcon").attr('src').replace('icon_squaredownArrow', 'icon_squareArrow'));
    // $('#editVisibility').hide();


}
function loadBreadcrumbs(title, target) {
    let breadcrumbs = $(`<div class="row ">
                        <div class='col-10 d-flex justify-content-start'>
                            <a class='editMenuLink' href='edit/${g.profilesRootURL}/default.aspx?subject=${sessionInfo.personNodeID}'>Edit Menu</a>
                            <span class='editMenuGT'>&nbsp;>&nbsp;</span><span><b>${title}</b></span>
                        </div>
                        <div class='col-2 d-flex justify-content-end'>
                            <a href='${sessionInfo.personURI}'><img src='${g.profilesRootURL}/Framework/Images/arrowLeft.png' /> View Profile</a> 
                        </div>
                    </div>`);
    target.append(breadcrumbs);
}
