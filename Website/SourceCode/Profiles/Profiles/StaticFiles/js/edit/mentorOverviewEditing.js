gEditProp.mentorJobOpportunities = [];

function loadMentorOverviewDiv(target) {
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
function setupMentorOverview(target) {
    loadMentorOverviewDiv(target);
    $('#clearMentorOverview').on('click', clearMentorOverviewSection);
    $('#saveMentorOverview').on('click', saveMentorOverview);

    let subject = getSearchParam('subject');
    let url = gEditProp.getDataFunctionPrefix + subject + "&p=" + gEditProp.getMentorOverviewPrnsUrl;

    getDataViaPost(url, emitMentorOverviewSection);
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
function saveMentorOverview() {
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
function emitMentorOverviewSection(mentoringOverview) {

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
}