let gMentoriesOpportunities = [];

async function mentorReady() {
    await commonSetup('Mentoring');
    $('#modules-left-div').append(getPageBody());
    setupScrolling();

    setupOverview();
    setupJobOpps();
}
function setupOverview() {
    var label = "Mentoring Overview";
    loadEditTopNav(label);
    setCurrentVisibility(label);
    //$(".pageTitle").html(`<h2>${propertyList.Label}</h2>`);
    var searchParams = window.location.search;
    const urlParams = new URLSearchParams(searchParams);
    var subject = urlParams.get('subject');
    var url = g.editApiPath + "?function=GetData&s=" + subject + "&p=http://profiles.catalyst.harvard.edu/ontology/prns!mentoringOverview"

    let mentoringOverview = getData(url, loadOverviewPage);

}
function setupJobOpps() {
    var label = "Mentoring Job Opportunities";
    loadEditTopNav(label);
    clearJobOpportunityPage();
    setCurrentVisibility(label);
    //$(".pageTitle").html(`<h2>${propertyList.Label}</h2>`);
    var searchParams = window.location.search;
    const urlParams = new URLSearchParams(searchParams);
    var subject = urlParams.get('subject');
    var url = g.editApiPath + "?function=GetData&s=" + subject + "&p=http://profiles.catalyst.harvard.edu/ontology/prns!hasMentoringJobOpportunity"

    let jobOpportunities = getData(url, loadJobOpportunities);

}

function clearPage() {
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
function clearJobOpportunityPage() {
     $("#jobTitle").val('');
    $("#jobDescription").val('');
    $("#jobURL").val('');
    $("#students").prop("checked",false);
    $("#faculty").prop("checked",false);
    $("#residentsAndFellows").prop("checked", false);
    $("#addEditJobOpportunity").hide();
    $("#editJobOpportunity").attr("onclick", `javascript:saveMentoringJobOpportunities(''); return true;`)

}
function createNewJobOpportunity() {
    $("#addEditJobOpportunity").show();
}
function saveMentoringOverview() {
    var searchParams = window.location.search;
    const urlParams = new URLSearchParams(searchParams);
    var subject = urlParams.get('subject');
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
    var url = g.editApiPath + "?function=AddUpdateProperty&s=" + subject + "&p=http://profiles.catalyst.harvard.edu/ontology/prns!mentoringOverview"

    var redirectTo = g.profilesRootURL + "/edit/default.aspx?subject=" + subject;
    editPost(url, mentoringOverview, redirectTo);
  
    return false;

}

function saveMentoringJobOpportunities(opportunityId) {
    var searchParams = window.location.search;
    const urlParams = new URLSearchParams(searchParams);
    var subject = urlParams.get('subject');
  
    if (gMentoriesOpportunities.length != 0 && gMentoriesOpportunities.find(x => x.opportunityId == opportunityId) != undefined) {
        //edit existing 

        const indexToEdit = gMentoriesOpportunities.findIndex(x => x.opportunityId == opportunityId);
        gMentoriesOpportunities[indexToEdit].title = $("#jobTitle").val();
        gMentoriesOpportunities[indexToEdit].jobDescription = $("#jobDescription").val();
        gMentoriesOpportunities[indexToEdit].jobURL = $("#jobURL").val();
        gMentoriesOpportunities[indexToEdit].categoryStudents = $("#students").prop("checked");
        gMentoriesOpportunities[indexToEdit].categoryFaculty = $("#faculty").prop("checked");
        gMentoriesOpportunities[indexToEdit].categoryResidentsAndFellows = $("#residentsAndFellows").prop("checked");

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
        
        gMentoriesOpportunities.push(jobOpportunity);
    }

   

    var url = g.editApiPath + "?function=AddUpdateProperty&s=" + subject + "&p=http://profiles.catalyst.harvard.edu/ontology/prns!hasMentoringJobOpportunity"


    editPost(url, gMentoriesOpportunities, "");
    setupJobOpps();
    return false;

}
function loadOverviewPage(mentoringOverview) {

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
function loadJobOpportunities(jobOpportunities) {


    if (Array.isArray(jobOpportunities)) {
        if (jobOpportunities.length != 0) {
            gMentoriesOpportunities = jobOpportunities;
        }
        
        var jobCategories = "";

        var editIcon = `${g.profilesRootURL}/edit/images/Icon_Edit.gif`;
        var deleteIcon = `${g.profilesRootURL}/edit/images/Icon_delete.gif`;
        var $tableBody = $('#tableJobOpportunities tbody');
        $tableBody.html('');
        var cnt = 1;
        gMentoriesOpportunities.forEach(row => {
            console.log(row);
          
            jobCategories = row.categoryStudents ? "Students " : "";
            jobCategories += row.categoryFaculty ? "Faculty " : "";
            jobCategories += row.categoryResidentsAndFellows ? "Residents and Fellows " : "";
            var $newRow = $('<tr class="oddRow">');

            $newRow.append($('<td class="jobOpportunitiesFirstCell">').append(`<div class="jobTitle">${cnt}. ${row.title}</div><div class="jobDescription">${row.jobDescription}</div><div><span class="jobCategoryDisplayLabel">Job Category:</span> ${jobCategories} <span class="jobURLDisplayLabel">Job URL:</span> <a target="_blank" rel="noopener noreferrer" href="${row.jobURL}">${row.jobURL}</a></div>`));
            $newRow.append($('<td class="alignCenterAction">').append(`<div><img src='${editIcon}' onclick='javascript:editJobOpportunity("${row.opportunityId}"); return false;'/><img src='${deleteIcon}' onclick='javascript:deleteJobOpportunity("${row.opportunityId}");return false;'/></div>`));
            $tableBody.append($newRow);
            cnt++;
        });
    }

    return true;

}
function editJobOpportunity(opportunityId) {
    $("#addEditJobOpportunity").show();
    let jobOpportunity = gMentoriesOpportunities.find(x => x.opportunityId == opportunityId);
    $("#editJobOpportunity").attr("onclick", `javascript:saveMentoringJobOpportunities('${opportunityId}'); return true;`)
    loadJobOpportunity(jobOpportunity);
}
function deleteJobOpportunity(opportunityId) {

    let byeBye = gMentoriesOpportunities.filter(x => x.opportunityId == opportunityId);
    if (byeBye != -1) {
        gMentoriesOpportunities.splice(byeBye, 1);
    }
    var searchParams = window.location.search;
    const urlParams = new URLSearchParams(searchParams);
    var subject = urlParams.get('subject');

    var url = g.editApiPath + "?function=AddUpdateProperty&s=" + subject + "&p=http://profiles.catalyst.harvard.edu/ontology/prns!MentoringJobOpportunities"

    editPost(url, gMentoriesOpportunities, "");
    setupJobOpps();
    return false;
}

$('input[type="radio"][name="visibility"]').change(function () {
    var selectedValue = $('input[name="visibility"]:checked').val();
}); 

function setCurrentVisibility(catagory) {
    
    //$("#currentVisibility").text(propertyList.Categories[0].Properties.find(obj => obj.Label == catagory).ViewSecurityGroupLabel)
}
function getPageBody() {
    return $(`
    <div id="pageBody" class="container">
        <div class="row d-flex justify-content-center">
            <div class="col-12">
                <div id="editTopNav" class="container">
                </div>
                <div id="editMenu">
                    <div><a id="editVisibilityLink" class="editMenuLink" table-id="editVisibility" href="#"><img id="visibilityMenuIcon" src="{profilesPath}/edit/images/icon_squareArrow.gif" /> Edit Visibility (<span id="currentVisibility"></span>)</a></div>
                    <div id="editVisibility">
                    </div>
                </div>
                <div id="addEditJobOpportunity" class="editPanel">
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
                    <div><a id="editJobOpportunity" href="#" onclick="javascript:saveMentoringJobOpportunities(''); return true;">Save</a><span class="pipe">|</span><span><a href="#" onclick='javascript:clearJobOpportunityPage(); return false;'>Cancel</a></span></div>
                </div>
                <div id="moduleBody" class="container">
                    <div class="row d-felx">
                        <div class="col-6">
                            <a href="#" onclick="javascript:createNewJobOpportunity()">Create New Job Opportunity</a>
                        </div>
                    </div>
                    <div class="row d-felx">
                        <div class="col-12">
                            <table id="tableJobOpportunities">
                                <thead>
                                    <tr id="moduleHeadRow" class="topRow">
                                        <th class="alignLeft">Job Opportunities</th>
                                        <th class="alignCenterAction">Action</th>
                                    </tr>
                                </thead>
                                <tbody id="moduleBody">
                                </tbody>
                            </table>
                        </div>
                    </div>
                    <table class="moduleTable">
                        <tr id="moduleHeadRow" class="topRow">
                            <td colspan="3">Mentoring Overview</td>
                        </tr>
                        <tr><td colspan="2" class="moduleOptions">Enter an overview:</td><td><span class="clearPage"><a href="#" onclick="javascript: clearPage();">Clear</a></span><span class="save"><a href="#" onclick="javascript: saveMentoringOverview();">Save</a></span></td></tr>
                        <tr><td colspan="3"><textarea rows="25" cols="100" id="mentoringOverviewText"></textarea>"</td></tr>
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
            </div>
        </div>
    </div>
    `);
}

