gEditProp.mentorJobOpportunities = [];

async function mentorEditingReady() {
    let mainDiv = await editCommonReady();

    if (gEditProp.properties.propertyURI.toLowerCase().match(gEditProp.ontologyHasJobOpps.toLowerCase())) {
        await setupJobOpps(mainDiv);
    } else if (gEditProp.properties.propertyURI.toLowerCase().match(gEditProp.ontologyMentoring.toLowerCase())) {
        await setupOverview(mainDiv);
    }

    setupScrolling();
}

function loadMentoringOverviewDiv(target) {
    let div = $(`
        <div id="mentoringOverviewOuterDiv">
            <table class="moduleTable mt-2 mb-2">
                <tr id="moduleTableHeadRow" class="topRow bold">
                    <td colspan="3">Mentoring Overview</td>
                </tr>
                <tr><td class="moduleOptions w-50">Enter or update an overview:</td>
                    <td class="w-50 d-flex justify-content-end">
                        <button id="clearMentorOverview" class="link-ish clearPage">Clear</a></button>
                        <button id="saveMentorOverview" class="link-ish save">Save</a></button></td>
                    <td></td>
                    </tr>
                <tr><td colspan="3"><textarea rows="8" cols="100" id="mentoringOverviewText"></textarea>"</td></tr>
                <tr><td><div class="moduleInstruction">I'm available to mentor:</div></td><td><div><input type="checkbox" id="studentsOnResearchProjects" /> Students on Research Projects</div></td></tr>
                <tr><td></td><td colspan="2"><div><input type="checkbox" id="studentsOnCareerDevelopment" /> Students on Career Development</div></td></tr>
                <tr><td></td><td><div><input type="checkbox" id="studentsOnWorkLifeBalance" /> Students on Work/Life Balance</div></td></tr>
                <tr><td></td><td><div><input type="checkbox" id="facultyOnResearch" /> Faculty on Research</div></td></tr>
                <tr><td></td><td><div><input type="checkbox" id="facultyOnResearchProjects" /> Faculty on Research Projects</div></td></tr>
                <tr><td></td><td><div><input type="checkbox" id="facultyOnCreerDevelopment" /> Faculty on Career Development</div></td></tr>
                <tr><td></td><td><div><input type="checkbox" id="facultyOnWorkLifeBalance" /> Faculty on Work/Life Balance</div></td></tr>
                <tr><td></td><td><div><input type="checkbox" id="residentsAndFellowsOnResearch" /> Residents and Fellows on Research</div></td></tr>
                <tr><td></td><td><div><input type="checkbox" id="residentsAndFellowsOnResearchProjects" /> Residents and Fellows on Research Projects</div></td></tr>
                <tr><td></td><td><div><input type="checkbox" id="residentsAndFellowsOnCareerDevelopment" /> Residents and Fellows on Career Development</div></td></tr>
                <tr><td></td><td><div><input type="checkbox" id="residentsAndFellowsOnWorkLifeBalance" /> Residents and Fellows on Work/Life Balance</div></td></tr>
            </table>
        </div>
        `);
    target.append(div);
    return div;
}
function loadJobOpportunitiesDiv(target) {
    let div = $(`
        <div id="jobOpportunitiesOuterDiv">
            <div class="link-ish mt-2" id="createJobOppDiv"><span class="link-ish"><img id="createJobOppArrow" src="${gEditProp.rightArrow}"/></span>
                        Create New Job Opportunity</a>
            </div>
            <div id="addEditJobOpportunity" class="editPanel mt-0">
                <div><a id="editJobOpportunity" href="#" onclick="saveMentoringJobOpportunities('')">Save</a>
                    <span class="pipe">|</span><span><a href="#" onclick='clearJobOpportunityForm(); return false;'>Cancel</a></span>
                </div>
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
            </div> <!-- addEditJobOpportunity -->
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

function setupOverview(target) {
    loadMentoringOverviewDiv(target);
    $('#clearMentorOverview').on('click', clearMentorOverviewSection);
    $('#saveMentorOverview').on('click', saveMentoringOverview);

    let subject = getSearchParam('subject');
    let url = gEditProp.getDataFunctionPrefix + subject + "&p=" + gEditProp.getMentorOverviewPrnsUrl;

    getDataViaPost(url, emitOverviewSection);
}
async function setupJobOpps(target) {
    loadJobOpportunitiesDiv(target);

    let subject = getSearchParam('subject');
    let url = gEditProp.getDataFunctionPrefix + subject + "&p=" + gEditProp.getJobOpportunitiesPrnsUrl;

    await getDataViaPost(url, emitJobOpportunities);

    let addEdit = $('#addEditJobOpportunity');
    addEdit.hide(); // initially
    $('#createJobOppDiv').on('click', function (e) {
        toggleEltVisibility(addEdit);
        toggleSrcIcon($('#createJobOppArrow'), gEditProp.downArrow, gEditProp.rightArrow);
    });
}

function clearMentorOverviewSection() {
    $("#mentoringOverviewText").val("");
    $("#studentsOnResearchProjects").prop("checked", false);
    $("#studentsOnCareerDevelopment").prop("checked", false);
    $("#studentsOnWorkLifeBalance").prop("checked", false);
    $("#facultyOnResearch").prop("checked", false);
    $("#facultyOnResearchProjects").prop("checked", false);
    $("#facultyOnCreerDevelopment").prop("checked", false);
    $("#facultyOnWorkLifeBalance").prop("checked", false);
    $("#residentsAndFellowsOnResearch").prop("checked", false);
    $("#residentsAndFellowsOnResearchProjects").prop("checked", false);
    $("#residentsAndFellowsOnCareerDevelopment").prop("checked", false);
    $("#residentsAndFellowsOnWorkLifeBalance").prop("checked", false);

    return true;
}

function clearJobOpportunityForm() {
    $("#jobTitle").val('');
    $("#jobDescription").val('');
    $("#jobURL").val('');
    $("#students").prop("checked", false);
    $("#faculty").prop("checked", false);
    $("#residentsAndFellows").prop("checked", false);
    //$("#addEditJobOpportunity").hide();
    $("#editJobOpportunity").attr("onclick", `javascript:saveMentoringJobOpportunities('')`)

}

function saveMentoringOverview() {
    let searchParams = window.location.search;
    let urlParams = new URLSearchParams(searchParams);
    let subject = urlParams.get('subject');
    let mentoringOverview = {};

    mentoringOverview.text = $("#mentoringOverviewText").val();
    mentoringOverview.studentsOnResearchProjects = $("#studentsOnResearchProjects").prop("checked");
    mentoringOverview.studentsOnCareerDevelopment = $("#studentsOnCareerDevelopment").prop("checked");
    mentoringOverview.studentsOnWorkLifeBalance = $("#studentsOnWorkLifeBalance").prop("checked");
    mentoringOverview.facultyOnResearch = $("#facultyOnResearch").prop("checked");
    mentoringOverview.facultyOnResearchProjects = $("#facultyOnResearchProjects").prop("checked");
    mentoringOverview.facultyOnCreerDevelopment = $("#facultyOnCreerDevelopment").prop("checked");
    mentoringOverview.facultyOnWorkLifeBalance = $("#facultyOnWorkLifeBalance").prop("checked");
    mentoringOverview.residentsAndFellowsOnResearch = $("#residentsAndFellowsOnResearch").prop("checked");
    mentoringOverview.residentsAndFellowsOnResearchProjects = $("#residentsAndFellowsOnResearchProjects").prop("checked");
    mentoringOverview.residentsAndFellowsOnCareerDevelopment = $("#residentsAndFellowsOnCareerDevelopment").prop("checked");
    mentoringOverview.residentsAndFellowsOnWorkLifeBalance = $("#residentsAndFellowsOnWorkLifeBalance").prop("checked");
    let url = gEditProp.addUpdateDataFunctionPrefix + subject + "&p=" + gEditProp.getMentorOverviewPrnsUrl;

    editSaveViaPost(url, mentoringOverview);
}

function saveMentoringJobOpportunities(opportunityId) {
    let searchParams = window.location.search;
    const urlParams = new URLSearchParams(searchParams);
    let subject = urlParams.get('subject');

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


    let url = gEditProp.addUpdateDataFunctionPrefix + subject +  "&p=" + gEditProp.getJobOpportunitiesPrnsUrl;

    editSaveViaPost(url, gEditProp.mentorJobOpportunities);
}

function emitOverviewSection(mentoringOverview) {

    $("#mentoringOverviewText").val(mentoringOverview.text);
    $("#studentsOnResearchProjects").prop("checked", mentoringOverview.studentsOnResearchProjects);
    $("#studentsOnCareerDevelopment").prop("checked", mentoringOverview.studentsOnCareerDevelopment);
    $("#studentsOnWorkLifeBalance").prop("checked", mentoringOverview.studentsOnWorkLifeBalance);
    $("#facultyOnResearch").prop("checked", mentoringOverview.facultyOnResearch);
    $("#facultyOnResearchProjects").prop("checked", mentoringOverview.facultyOnResearchProjects);
    $("#facultyOnCreerDevelopment").prop("checked", mentoringOverview.facultyOnCreerDevelopment);
    $("#facultyOnWorkLifeBalance").prop("checked", mentoringOverview.facultyOnWorkLifeBalance);
    $("#residentsAndFellowsOnResearch").prop("checked", mentoringOverview.residentsAndFellowsOnResearch);
    $("#residentsAndFellowsOnResearchProjects").prop("checked", mentoringOverview.residentsAndFellowsOnResearchProjects);
    $("#residentsAndFellowsOnCareerDevelopment").prop("checked", mentoringOverview.residentsAndFellowsOnCareerDevelopment);
    $("#residentsAndFellowsOnWorkLifeBalance").prop("checked", mentoringOverview.residentsAndFellowsOnWorkLifeBalance);
    return true;
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
    if (Array.isArray(jobOpportunities)) {
        if (jobOpportunities.length != 0) {
            gEditProp.mentorJobOpportunities = jobOpportunities;
        }

        let jobCategories = "";

        let editIcon = `${g.profilesRootURL}/edit/images/Icon_Edit.gif`;
        let deleteIcon = `${g.profilesRootURL}/edit/images/Icon_delete.gif`;
        let $tableBody = $('#tableJobOpportunities tbody');
        $tableBody.html('');
        let cnt = 1;
        gEditProp.mentorJobOpportunities.forEach(row => {
            //console.log(row);

            jobCategories = row.categoryStudents ? "Students " : "";
            jobCategories += row.categoryFaculty ? "Faculty " : "";
            jobCategories += row.categoryResidentsAndFellows ? "Residents and Fellows " : "";
            let $newRow = $('<tr class="oddRow">');

            $newRow.append($('<td class="jobOpportunitiesFirstCell">').append(`<div class="jobTitle">${cnt}. ${row.title}</div><div class="jobDescription">${row.jobDescription}</div><div><span class="jobCategoryDisplayLabel">Job Category:</span> ${jobCategories} <span class="jobURLDisplayLabel">Job URL:</span> <a target="_blank" rel="noopener noreferrer" href="${row.jobURL}">${row.jobURL}</a></div>`));
            $newRow.append($('<td class="alignCenterAction">').append(`<div><img src='${editIcon}' onclick='editJobOpportunity("${row.opportunityId}"); return false;'/><img src='${deleteIcon}' onclick='deleteJobOpportunity("${row.opportunityId}");return false;'/></div>`));
            $tableBody.append($newRow);
            cnt++;
        });
    }

    return true;

}

function editJobOpportunity(opportunityId) {
    $("#addEditJobOpportunity").show();
    let jobOpportunity = gEditProp.mentorJobOpportunities.find(x => x.opportunityId == opportunityId);
    $("#editJobOpportunity").attr("onclick", `javascript:saveMentoringJobOpportunities('${opportunityId}')`)
    loadJobOpportunity(jobOpportunity);
}

function deleteJobOpportunity(opportunityId) {

    let byeBye = gEditProp.mentorJobOpportunities.filter(x => x.opportunityId == opportunityId);
    if (byeBye != -1) {
        gEditProp.mentorJobOpportunities.splice(byeBye, 1);
    }
    let searchParams = window.location.search;
    const urlParams = new URLSearchParams(searchParams);
    let subject = urlParams.get('subject');

    let url = gEditProp.addUpdateDataFunctionPrefix + subject +  "&p=" + gEditProp.getJobOpportunitiesPrnsUrl;

    editSaveViaPost(url, gEditProp.mentorJobOpportunities);
}

