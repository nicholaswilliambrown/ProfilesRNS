let gEditProp = {};
gEditProp.downArrow = `${g.profilesRootURL}/Edit/Images/icon_squaredownArrow.gif`;
gEditProp.rightArrow = `${g.profilesRootURL}/Edit/Images/icon_squareArrow.gif`;

gEditProp.visPublic = '-1' ;
gEditProp.visNoBots = '-10';
gEditProp.visUsers  = '-20';

gEditProp.prettyVis = new Map();
gEditProp.prettyVis.set(gEditProp.visPublic, 'public'   );
gEditProp.prettyVis.set(gEditProp.visNoBots, 'no search');
gEditProp.prettyVis.set(gEditProp.visUsers , 'any user' );

gEditProp.updateVisibilityPrefix = g.editApiPath + "?function=UpdateVisibility&s=";
gEditProp.getDataFunctionPrefix = g.editApiPath + "?function=GetData&s=";
gEditProp.addUpdateDataFunctionPrefix = g.editApiPath + "?function=AddUpdateProperty&s=";

gEditProp.ontologyUrlPrnsPrefix = 'http://profiles.catalyst.harvard.edu/ontology/prns!';
gEditProp.ontologyMentoring = 'mentoringOverview';
gEditProp.ontologyHasJobOpps = 'hasMentoringJobOpportunity';

gEditProp.getMentorOverviewPrnsUrl = `${gEditProp.ontologyUrlPrnsPrefix}${gEditProp.ontologyMentoring}`;
gEditProp.getJobOpportunitiesPrnsUrl = `${gEditProp.ontologyUrlPrnsPrefix}${gEditProp.ontologyHasJobOpps}`;

async function editCommonReady() {
    gEditProp.subject = getSearchParam('subject');

    console.log('=============editProp', g.editPropertyParams);
    console.log('=============subject <', gEditProp.subject, '>');

    gEditProp.title = JSON.parse(g.preLoad).filter(p=>p.DisplayModule=='Person.Label')[0].ModuleData[0].DisplayName;
    gEditProp.properties = JSON.parse(g.editPropertyParams);

    await commonSetup(gEditProp.title);
    let mainDiv = $('#mainDiv')

    loadBreadcrumbs(gEditProp.title, mainDiv);
    
    setupVisibilityTable(mainDiv);
    
    return mainDiv;
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
    return div;
}
function setupVisibilityTable(target) {
    let div = loadVisibilityDiv(target);
    // let visibilityData = getDataViaPost(url, (data) => {
    //     let d = data;
    // });

    let table = $('#tblVisibility');
    table.hide(); // initially
    div.on('click', function() {
        toggleEltVisibility(table);
        toggleSrcIcon($("#visibilityMenuIcon"), gEditProp.rightArrow, gEditProp.downArrow);
    });
    $('input[name="visibility"]').on('click', function() {
        let visibility = $('input[name="visibility"]:checked').val();
        gEditProp.visibility = visibility;
        let prettyVis = gEditProp.prettyVis.get(visibility) ? gEditProp.prettyVis.get(visibility) : 'Only ' + gEditProp.title;
        $('#currentVisibility').text(prettyVis);
        console.log("======= visibility: --------", gEditProp.visibility);
        let predicateURI = getSearchParam('predicateuri');
        let subject = getSearchParam('subject');
        let url = `${gEditProp.updateVisibilityPrefix}${subject}`
            + `&p=${predicateURI}&v=${visibility}`;
        editSaveViaPost(url);
    });
}

function loadBreadcrumbs(title, target) {
    let breadcrumbs = $(`<div class="row ">
                        <div class='col-10 d-flex justify-content-start'>
                            <a class='editMenuLink' href='${g.profilesRootURL}/edit/default.aspx?subject=${sessionInfo.personNodeID}'>Edit Menu</a>
                            <span class='editMenuGT'>&nbsp;>&nbsp;</span><span><b>${title}</b></span>
                        </div>
                        <div class='col-2 d-flex justify-content-end'>
                            <a href='${sessionInfo.personURI}'><img src='${g.profilesRootURL}/Framework/Images/arrowLeft.png' /> View Profile</a> 
                        </div>
                    </div>`);
    target.append(breadcrumbs);
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
///////////////////////////////////////////////////

async function editSaveViaPost(url, content, redirectTo) {
    let _content = JSON.stringify(content);
    console.log(_content);
     try {
         await $.ajax({
             type: "POST",
             url: url,
             data: _content,
             success: () => {
                 if (redirectTo) {
                     window.location.href = redirectTo;
                 }
                 else {
                     window.location.reload();
                 }
             },
             dataType: 'text'
         });
     } catch (error) {
         console.log(error);
         window.location.reload();
     }
}
 async function getDataViaPost(url, callback) {
    $.post(url,function (results) {
        callback(results);
    });
}

