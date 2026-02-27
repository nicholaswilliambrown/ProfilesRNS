gEditProp.mentorJobOpportunities = [];

function loadJobOpportunitiesDiv(target) {
    let div = $(`
        <div id="jobOpportunitiesOuterDiv">
            <div class="link-ish mt-2" id="createJobOppDiv"><span class="link-ish"><img id="createJobOppArrow" src="${gEditProp.rightArrow}"/></span>
                        Create New Job Opportunity</a>
            </div>
            <div id="jobOpportunityDetailsDiv" class="editPanel mt-0">
                <div class="moduleOptions">Enter the job opportunity information below:</div>
                <div class="inputLabel">Job Title</div>
                <div><input type="text" id="jobTitle" /></div>
                <div class="inputLabel">Job Description</div>
                <div><textarea rows="4" cols="40" id="jobDescription"></textarea></div>
                <div class="inputLabel">Job URL</div>
                <div><input type="text" id="jobURL" /></div>
                <div class="jobCategories">
                    <span class="jobCategoryTitle"><b>Job Category</b></span>
                    <div class="jobCategoryOptions">
                        <div><input type="checkbox" id="students" /><span>Students</span></div>
                        <div><input type="checkbox" id="faculty" /><span>Faculty</span></div>
                        <div><input type="checkbox" id="residentsAndFellows" /><span>Residents and Fellows</span></div>
                    </div>
                </div>
                <div><button class="link-ish mt-2 ps-0" id="saveJobOpp">Save</button>
                    <span class="pipe">|</span>
                    <button class="link-ish" id="cancelJobOppEdit">Cancel</button>
                </div>

            </div> <!-- jobOpportunityDetailsDiv -->
            <div id="moduleBody" class="container">
                <div class="row d-flex">
                    <div class="col-12">
                        <table id="tableJobOpportunities">
                            <thead>
                                <tr id="moduleHeadRow" class="topRow bold">
                                    <th class="alignLeft">Job Opportunities</th>
                                    <th class="alignCenterAction">Action</th>
                                </tr>
                            </thead>
                            <tbody id="moduleBody">
                            </tbody>
                        </table>
                    </div>
                </div>
            </div> <!-- moduleBody -->

        </div> <!-- jobOpportunitiesOuterDiv -->
    `);
    target.append(div);
    return div;
}

async function setupJobOpps(target) {
    loadJobOpportunitiesDiv(target);

    let subject = getSearchParam('subject');
    let url = gEditProp.getDataFunctionPrefix + subject + "&p=" + gEditProp.getJobOpportunitiesPrnsUrl;

    $('#jobOpportunityDetailsDiv').hide(); // at least initially
    $('#cancelJobOppEdit').on('click', clearAndCloseJobOpportunityForm);

    let numCurrentJobs = await getDataViaPost(url, emitJobOpportunities);
    await cardinalityPattern({
        createItemOverallDivId: 'createJobOppDiv',
        itemDetailsDivId:       'jobOpportunityDetailsDiv',
        currentItemsDivId:      'tableJobOpportunities',
        togglingArrowImgId:     'createJobOppArrow',
        saveItemId:             'saveJobOpp',
        numItems:               numCurrentJobs }
    );
}
function cardinalityPattern(options) {
    // allow 'de-structuring' to tolerate options provided in any order
    let [createItemOverallDivId, itemDetailsDivId, currentItemsDivId,
            togglingArrowImgId, saveItemId, numItems] =
        [   options.createItemOverallDivId,
            options.itemDetailsDivId,
            options.currentItemsDivId,
            options.togglingArrowImgId,
            options.saveItemId,
            options.numItems ];
    
    let maxCardinality = gEditProp.properties.maxCardinality;

    let currentItemsDiv = $(`#${currentItemsDivId}`);
    let createItemDiv = $(`#${createItemOverallDivId}`);
    let itemDetailsDiv = $(`#${itemDetailsDivId}`);
    let togglingArrowImg = $(`#${togglingArrowImgId}`);
    let saveItem = $(`#${saveItemId}`);

    if ( maxCardinality > 0 && numItems >= maxCardinality) {
        createItemDiv.remove();
        currentItemsDiv.addClass("mt-2"); // mind the gap
    }
    else {
        createItemDiv.on('click', function (e) {
            console.log('++++++++++++++++++++++++++++++ save will CREATE opp')
            saveItem.off('click').on('click', () => {saveJobOpportunity('')});
            toggleEltVisibility(itemDetailsDiv);
            toggleSrcIcon(togglingArrowImg, gEditProp.downArrow, gEditProp.rightArrow);
        });
    }
}
function clearAndCloseJobOpportunityForm() {
    // clear
    $("#jobTitle").val('');
    $("#jobDescription").val('');
    $("#jobURL").val('');
    $("#students").prop("checked", false);
    $("#faculty").prop("checked", false);
    $("#residentsAndFellows").prop("checked", false);

    // close
    $("#jobOpportunityDetailsDiv").hide();
    $("#createJobOppArrow").attr('src', gEditProp.rightArrow);
}
function saveJobOpportunity(opportunityId) {
    if (gEditProp.mentorJobOpportunities.length != 0 && gEditProp.mentorJobOpportunities.find(x => x.opportunityId == opportunityId) != undefined) {
        //edit existing 

        const indexToEdit = gEditProp.mentorJobOpportunities.findIndex(x => x.opportunityId == opportunityId);
        gEditProp.mentorJobOpportunities[indexToEdit].title = $("#jobTitle").val();
        gEditProp.mentorJobOpportunities[indexToEdit].jobDescription = $("#jobDescription").val();
        gEditProp.mentorJobOpportunities[indexToEdit].jobURL = $("#jobURL").val();
        gEditProp.mentorJobOpportunities[indexToEdit].categoryStudents = $("#students").prop("checked");
        gEditProp.mentorJobOpportunities[indexToEdit].categoryFaculty = $("#faculty").prop("checked");
        gEditProp.mentorJobOpportunities[indexToEdit].categoryResidentsAndFellows = $("#residentsAndFellows").prop("checked");

    } else {
        //add new
        opportunityId = crypto.randomUUID();
        let jobOpportunity = {};
        jobOpportunity.opportunityId = opportunityId;
        jobOpportunity.title = $("#jobTitle").val();
        jobOpportunity.jobDescription = $("#jobDescription").val();
        jobOpportunity.jobURL = $("#jobURL").val();
        jobOpportunity.categoryStudents = $("#students").prop("checked");
        jobOpportunity.categoryFaculty = $("#faculty").prop("checked");
        jobOpportunity.categoryResidentsAndFellows = $("#residentsAndFellows").prop("checked");

        gEditProp.mentorJobOpportunities.push(jobOpportunity);
    }
    saveAllJobOpportunities();
}
function saveAllJobOpportunities() {
    let searchParams = window.location.search;
    const urlParams = new URLSearchParams(searchParams);

    let subject = urlParams.get('subject');
    let url = gEditProp.addUpdateDataFunctionPrefix + subject +  "&p=" + gEditProp.getJobOpportunitiesPrnsUrl;
    editSaveViaPost(url, gEditProp.mentorJobOpportunities);
}
function loadJobOpportunity(jobOpportunity) {
    $("#jobTitle").val(jobOpportunity.title);
    $("#jobDescription").val(jobOpportunity.jobDescription);
    $("#jobURL").val(jobOpportunity.jobURL);
    $("#students").prop("checked", jobOpportunity.categoryStudents);
    $("#faculty").prop("checked", jobOpportunity.categoryFaculty);
    $("#residentsAndFellows").prop("checked", jobOpportunity.categoryResidentsAndFellows);
    return true;

}
function emitJobOpportunities(jobOpportunities) {
    let numJobs = 0;

    if (Array.isArray(jobOpportunities)) {
        if (jobOpportunities.length != 0) {
            gEditProp.mentorJobOpportunities = jobOpportunities;
            numJobs = jobOpportunities.length;
        }

        let jobCategories = "";

        let tableBody = $('#tableJobOpportunities tbody');
        tableBody.empty();

        let numJobOpps = gEditProp.mentorJobOpportunities.length;
        for (let i=0; i<numJobOpps; i++) {
            let jobOpp = gEditProp.mentorJobOpportunities[i];

            jobCategories = jobOpp.categoryStudents ? "Students " : "";
            jobCategories += jobOpp.categoryFaculty ? "Faculty " : "";
            jobCategories += jobOpp.categoryResidentsAndFellows ? "Residents and Fellows " : "";
            let row = $(`<tr class="oddRow" jId="${jobOpp.opportunityId}">`);
            tableBody.append(row);

            row.append($('<td class="jobOpportunitiesFirstCell">').append(`
        <div
    } class="jobTitle">${i+1}. ${jobOpp.title}</div>
                <div class="jobDescription">${jobOpp.jobDescription}</div>
                <div>   <span class="jobCategoryDisplayLabel">Job Category:</span> 
                        ${jobCategories} <span class="jobURLDisplayLabel">Job URL:</span> 
                        <a target="_blank" rel="noopener noreferrer" href="${jobOpp.jobURL}">${jobOpp.jobURL}</a>
                </div>`));

            emitJobOppsActionTd(row, i, jobOpp, numJobOpps);
        }
    }
    return numJobs;
}
function emitJobOppsActionTd(row, index, jobOpp, numJobOpps) {
    let editIcon = $(`<img alt="edit" src='${g.profilesRootURL}/edit/images/Icon_Edit.gif'/>`);
    let deleteIcon = $(`<img alt="delete" src='${g.profilesRootURL}/edit/images/Icon_delete.gif'/>`);

    let upIcon = $(`<img alt="up" src='${g.profilesRootURL}/edit/images/Icon_rounded_ArrowGrayUp.png'/>`);
    let downIcon = $(`<img alt="down" src='${g.profilesRootURL}/edit/images/Icon_rounded_ArrowGrayDown.png'/>`);

    let td = $('<td class="alignCenterAction">');
    row.append(td);
    let actionDiv = $(`<div id="actions_row_${index}"></div>`);
    td.append(actionDiv) ;

    if (index > 0) {
        td.append(upIcon);
    }
    if (index+1 < numJobOpps) {
        td.append(downIcon);
    }

    td.append(editIcon)  ;
    td.append(deleteIcon);

    console.log('--------- oppId ---------', jobOpp.opportunityId);
    editIcon.on('click', function() {
        editJobOpportunity(jobOpp.opportunityId);
    });
    deleteIcon.on('click', function() {
        deleteJobOpportunity(jobOpp.opportunityId);
    });
    upIcon.on('click', function() {
        moveArrayItemUp(gEditProp.mentorJobOpportunities, index);
        saveAllJobOpportunities();
    });
    downIcon.on('click', function() {
        moveArrayItemDown(gEditProp.mentorJobOpportunities, index)
        saveAllJobOpportunities();
    });
}
function editJobOpportunity(opportunityId) {
    $("#jobOpportunityDetailsDiv").show();
    let jobOpportunity = gEditProp.mentorJobOpportunities.find(x => x.opportunityId == opportunityId);
    console.log('++++++++++++++++++++++++++++++ save will UPDATE opp')
    $("#saveJobOpp").off('click').on('click', function() {
        saveJobOpportunity(opportunityId);
    });
    loadJobOpportunity(jobOpportunity);
}
function deleteJobOpportunity(opportunityId) {

    gEditProp.mentorJobOpportunities = gEditProp.mentorJobOpportunities.filter(x => x.opportunityId != opportunityId);

    let searchParams = window.location.search;
    const urlParams = new URLSearchParams(searchParams);
    let subject = urlParams.get('subject');

    let url = gEditProp.addUpdateDataFunctionPrefix + subject +  "&p=" + gEditProp.getJobOpportunitiesPrnsUrl;

    editSaveViaPost(url, gEditProp.mentorJobOpportunities);
}