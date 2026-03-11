gEditProp.mentorJobOpportunities = [];

gEditProp.colSpecsJobOuterTwoCols = [
        newColumnSpec(`${gCommon.cols10or12} md_ebordE`),
        newColumnSpec(`${gCommon.cols2or12} d-flex justify-content-center align-items-center`)
];
gEditProp.colSpecsJobInnerTwoCols = [
        newColumnSpec(`${gCommon.cols5or12} wrap2`),
        newColumnSpec(`${gCommon.cols5or12} wrap2`)
];

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
                    <span class="bold"><b>Job Category</b></span>
                    <div class="jobCategoryOptions">
                        <div><input type="checkbox" id="students" /><span>Students</span></div>
                        <div><input type="checkbox" id="faculty" /><span>Faculty</span></div>
                        <div><input type="checkbox" id="residentsAndFellows" /><span>Residents and Fellows</span></div>
 
                        <div><input type="checkbox" id="fellowsAndPostDocs" /><span>Fellows and PostDocs</span></div>
                        <div><input type="checkbox" id="researchStaff" /><span>Research Staff</span></div>
                    </div>
                </div>
                <div><button class="link-ish mt-2 ps-0" id="saveJobOpp">Save</button>
                    <span class="pipe">|</span>
                    <button class="link-ish" id="cancelJobOppEdit">Cancel</button>
                </div>

            </div> <!-- jobOpportunityDetailsDiv -->
            <div id="moduleBody" class="container mt-2 ms-5">
                <div id="tableJobOpportunities"></div>
            </div> <!-- moduleBody -->
        </div> <!-- jobOpportunitiesOuterDiv -->
    `);
    target.append(div);
}
function emitJobOpportunities(jobOpportunities) {
    let numJobs = 0;

    if (Array.isArray(jobOpportunities)) {
        let jobOppsTable = $('#tableJobOpportunities');
        if (jobOpportunities.length != 0) {
            gEditProp.mentorJobOpportunities = jobOpportunities;
            numJobs = jobOpportunities.length;

            let rowId = 'jobOppHeader';
            let row = makeRowWithColumns(jobOppsTable, rowId, gEditProp.colSpecsJobOuterTwoCols, 'ebordS ebordE ebordT ebordB topRow');
            row.find(`#${rowId}Col0`).append($(`<div>Job Opportunities</div>`));
            row.find(`#${rowId}Col1`).append($(`<div>Action</div>`));
        }
        else {
            jobOppsTable.append("No job opportunities have been added.");
        }


        let tableJobOpportunities = $('#tableJobOpportunities');

        let numJobOpps = gEditProp.mentorJobOpportunities.length;
        for (let i=0; i<numJobOpps; i++) {
            let jobOpp = gEditProp.mentorJobOpportunities[i];

            let truthyJobCategories = prettyTruthyJobs(jobOpp);

            let oddEven = i%2 ? 'oddRow' : 'evenRow';

            let overallRowId = 'joRow2' + i;
            let overallRow = makeRowWithColumns(tableJobOpportunities, overallRowId, gEditProp.colSpecsJobOuterTwoCols, oddEven + ' ebordS ebordE ebordB');
            let actionCol = createJobOppsActionColumn(i, jobOpp, numJobOpps);
            overallRow.find(`#${overallRowId}Col1`).append(actionCol);

            let subRow1 = $(`<div class="row "><div class="bold col-12">${i + 1}. ${jobOpp.title}</div></div>`);
            tableJobOpportunities.append(subRow1);

            let subRow2 = $(`<div class="row ps-3"><div class="col-12">${jobOpp.jobDescription}</div></div>`);
            tableJobOpportunities.append(subRow1);

            let itemSubRowId = 'jobOpp' + i;
            let jobCategoryDiv = $(`
                    <div class="ps-4">
                        <span class="jobCategoryDisplayLabel">Job Category:</span><span> ${truthyJobCategories}</span>
                    </div>`);
            let subRow3;
            if ( ! jobOpp.jobURL) {
                subRow3 = $(`<div class="row ps-3"></div>`);
                let sr3Col = $('<div class="col-12"></div>');
                subRow3.find(`#${itemSubRowId}Col0`).append(sr3Col);
                sr3Col.append(jobCategoryDiv);
            }
            else {
                subRow3 = makeRowWithColumns(tableJobOpportunities, itemSubRowId, gEditProp.colSpecsJobInnerTwoCols, oddEven);

                let rightCol = $(`
                    <div class="ps-4">
                        <span class="jobCategoryDisplayLabel">Job URL:</span> 
                        <a target="_blank" rel="noopener noreferrer" href="${jobOpp.jobURL}">${jobOpp.jobURL}</a>
                    </div>`);
                subRow3.find(`#${itemSubRowId}Col0`).append(jobCategoryDiv);
                subRow3.find(`#${itemSubRowId}Col1`).append(rightCol);
            }

            overallRow.find(`#${overallRowId}Col0`).append(subRow1);
            overallRow.find(`#${overallRowId}Col0`).append(subRow2);
            overallRow.find(`#${overallRowId}Col0`).append(subRow3);

        }
    }
    return numJobs;
}
function createJobOppsActionColumn(index, jobOpp, numJobOpps) {
    let editIcon = $(`<img alt="edit" src='${g.profilesRootURL}/edit/images/Icon_Edit.gif'/>`);
    let deleteIcon = $(`<img alt="delete" src='${g.profilesRootURL}/edit/images/Icon_delete.gif'/>`);

    let upIcon = $(`<img alt="up" src='${g.profilesRootURL}/edit/images/Icon_rounded_ArrowGrayUp.png'/>`);
    let downIcon = $(`<img alt="down" src='${g.profilesRootURL}/edit/images/Icon_rounded_ArrowGrayDown.png'/>`);

    let centeredActionDiv = $(`<div>`);

    if (index > 0) {
        centeredActionDiv.append(upIcon);
    }
    if (index+1 < numJobOpps) {
        centeredActionDiv.append(downIcon);
    }

    centeredActionDiv.append(editIcon)  ;
    centeredActionDiv.append(deleteIcon);

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

    return centeredActionDiv;
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
        saveItemFn:             () => {saveJobOpportunity('')},
        createItemFn:           clearJobOpportunityForm,
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
            options.saveItemFn,
            options.createItemFn,
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
            options.createItemFn();
            saveItem.off('click').on('click', options.saveItemFn);
            toggleSrcIcon(togglingArrowImg, gEditProp.rightArrow, gEditProp.downArrow);
            visibilityFollowsArrow(itemDetailsDiv, togglingArrowImg, gEditProp.rightArrow)
        });
    }
}
function clearAndCloseJobOpportunityForm() {
    clearJobOpportunityForm();
    closeJobOpportunityForm();
}
function clearJobOpportunityForm() {
    // clear
    $("#jobTitle").val('');
    $("#jobDescription").val('');
    $("#jobURL").val('');
    $("#students").prop("checked", false);
    $("#faculty").prop("checked", false);
    $("#residentsAndFellows").prop("checked", false);
}
function closeJobOpportunityForm() {
    // close
    $("#jobOpportunityDetailsDiv").hide();
    $("#createJobOppArrow").attr('src', gEditProp.rightArrow);
}
function validateJobOpportunity() {
    let candidateUrl = $("#jobURL").val();
    return isValidURLRegex(candidateUrl);
}
function saveJobOpportunity(opportunityId) {
    if ( ! validateJobOpportunity()) {
        alert('Please enter a URL starting with http:// or https://');
        return;
    }

    if (gEditProp.mentorJobOpportunities.length != 0 && gEditProp.mentorJobOpportunities.find(x => x.opportunityId == opportunityId) != undefined) {
        //edit existing 

        const indexToEdit = gEditProp.mentorJobOpportunities.findIndex(x => x.opportunityId == opportunityId);
        gEditProp.mentorJobOpportunities[indexToEdit].title = $("#jobTitle").val();
        gEditProp.mentorJobOpportunities[indexToEdit].jobDescription = $("#jobDescription").val();
        gEditProp.mentorJobOpportunities[indexToEdit].jobURL = $("#jobURL").val();
        gEditProp.mentorJobOpportunities[indexToEdit].categoryStudents = $("#students").prop("checked");
        gEditProp.mentorJobOpportunities[indexToEdit].categoryFaculty = $("#faculty").prop("checked");
        gEditProp.mentorJobOpportunities[indexToEdit].categoryFellowsAndPostDocs = $("#fellowsAndPostDocs").prop("checked");
        gEditProp.mentorJobOpportunities[indexToEdit].categoryResearchStaff = $("#researchStaff").prop("checked");

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
        jobOpportunity.categoryFellowsAndPostDocs = $("#fellowsAndPostDocs").prop("checked");
        jobOpportunity.categoryResearchStaff = $("#researchStaff").prop("checked");

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
    $("#fellowsAndPostDocs").prop("checked", jobOpportunity.categoryFellowsAndPostDocs);
    $("#researchStaff").prop("checked", jobOpportunity.categoryResearchStaff);
    return true;

}
function prettyTruthyJobs(jobOpp) {
    function prettyJobCategory(category) {
        // handles single-word categories
        let result = category.replace('category', '');

        // break up multi-word categories
        if (result == 'FellowsAndPostDocs') {
            result = "Fellows and PostDocs";
        }
        if (result == 'ResearchStaff') {
            result = "Research Staff";
        }
        return result;
    }

    let truthyJobCategories = Object.keys(jobOpp)
        .filter(k => k.match(/^category/) && jobOpp[k])
        .map(k => prettyJobCategory(k));

    return truthyJobCategories.join(', ');
}
function maybePushPrettyJobCategory(array, jobOpp) {
    if (jobOpp.categoryStudents          ) {
        array.push("Students");
    }
    if (jobOpp.categoryFaculty           ) {
        array.push("Faculty");
    }
    if (jobOpp.categoryFellowsAndPostDocs) {
        array.push("Fellows and PostDocs");
    }
    if (jobOpp.categoryResearchStaff     ) {
        array.push("Research Staff");
    }

}
function editJobOpportunity(opportunityId) {
    closeJobOpportunityForm(); // eg, if in midst of creation
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