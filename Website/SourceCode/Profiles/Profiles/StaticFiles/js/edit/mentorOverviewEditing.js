gEditProp.mentorJobOpportunities = [];

function loadMentorOverviewDiv(target) {
    let div = $(`
    <div id="mentoringOverviewOuterDiv">
        <div id="mentoringDisplayEmpty" class="mentoringAlternateDivs">
            <a class="editMentorOverview mt-2"><span class="link-ish">
                <img src="${gEditProp.rightArrow}"/> Create Mentoring Overview</span>
            </a>
        </div>
        <div id="mentoringDisplayNonempty" class="mentoringAlternateDivs">
            <a class="editMentorOverview link-ish mt-2"><span class="link-ish">
                <img src="${gEditProp.rightArrow}"/> Update Mentoring Overview</span>
            </a>
            <div class="mt-2 ms-2 displayInner"></div>
        </div>
        <div id="mentoringEdit" class="mentoringAlternateDivs">
                <div class="cancelEdit link-ish mt-2"><span class="link-ish"><img src="${gEditProp.downArrow}"/></span>
                        Create Mentoring Overview (Cancel)</a>
                </div>
                <div class="editPanel container mt-2 mb-2 pt-0">
                    <div class="mentoringAlternateButtons" id="mentorEditEmpty">
                        <button class="saveMentorOverview link-ish save">Save</a></button>
                        <button class="deleteMentorOverview link-ish save">Delete</a></button>
                        <button class="cancelEdit link-ish">Cancel</a></button>
                    </div>
                    <div class="mentoringAlternateButtons" id="mentorEditNonempty">
                        <div class="row">
                            <div class="${gCommon.cols6or12} ps-1">Enter or update an overview:</div>
                            <div class="${gCommon.cols6or12} d-flex justify-content-start">
                                <button class="cancelEdit link-ish">Cancel</a></button>
                                <button class="saveMentorOverview link-ish save">Save</a></button>
                                <button class="deleteMentorOverview link-ish save">Delete</a></button>
                           </div>
                         </div>                
                    </div>
                    <div class="row">
                        <div class="col-12 ps-1"><textarea rows="8" id="mentoringOverviewText"></textarea></div>
                    </div>
                    <div class="row">
                        <div class="${gCommon.cols4or12} ps-0" ><div class="moduleInstruction">I'm available to mentor:</div></div>
                        <div class="${gCommon.cols8or12}"><input type="checkbox" id="studentsOnResearchProjects" /> Students on Research Projects</div>
                    </div>
                    <div class="row">
                        <div class="${gCommon.cols4or12}" > </div>
                        <div class="${gCommon.cols8or12}"><div><input type="checkbox" id="studentsOnCareerDevelopment" /> Students on Career Development</div></div>
                    </div>
                    <div class="row">
                        <div class="${gCommon.cols4or12}" > </div>
                        <div class="${gCommon.cols8or12}" ><div><input type="checkbox" id="studentsOnWorkLifeBalance" /> Students on Work/Life Balance</div></div></div>
                    <div class="row">
                        <div class="${gCommon.cols4or12}" > </div>
                        <div class="${gCommon.cols8or12}" ><div><input type="checkbox" id="facultyOnResearch" /> Faculty on Research</div></div></div>
                    <div class="row">
                        <div class="${gCommon.cols4or12}" > </div>
                        <div class="${gCommon.cols8or12}" ><div><input type="checkbox" id="facultyOnResearchProjects" /> Faculty on Research Projects</div></div></div>
                    <div class="row">
                        <div class="${gCommon.cols4or12}" > </div>
                        <div class="${gCommon.cols8or12}" ><div><input type="checkbox" id="facultyOnCareerDevelopment" /> Faculty on Career Development</div></div></div>
                    <div class="row">
                        <div class="${gCommon.cols4or12}" > </div>
                        <div class="${gCommon.cols8or12}" ><div><input type="checkbox" id="facultyOnWorkLifeBalance" /> Faculty on Work/Life Balance</div></div></div>
                    <div class="row">
                        <div class="${gCommon.cols4or12}" > </div>
                        <div class="${gCommon.cols8or12}" ><div><input type="checkbox" id="residentsAndFellowsOnResearch" /> Residents and Fellows on Research</div></div></div>
                    <div class="row">
                        <div class="${gCommon.cols4or12}" > </div>
                        <div class="${gCommon.cols8or12}" ><div><input type="checkbox" id="residentsAndFellowsOnResearchProjects" /> Residents and Fellows on Research Projects</div></div></div>
                    <div class="row">
                        <div class="${gCommon.cols4or12}" > </div>
                        <div class="${gCommon.cols8or12}" ><div><input type="checkbox" id="residentsAndFellowsOnCareerDevelopment" /> Residents and Fellows on Career Development</div></div></div>
                    <div class="row">
                        <div class="${gCommon.cols4or12}" > </div>
                        <div class="${gCommon.cols8or12}" ><div><input type="checkbox" id="residentsAndFellowsOnWorkLifeBalance" /> Residents and Fellows on Work/Life Balance</div></div></div>
                </div>
            </div>
    </div>
    `);

    target.append(div);
    // todo Do we need find(), or maybe just access directly? or in *.css, vs JS
    div.find('#mentoringOverviewText').css('width', '100%');

    return div;
}
async function setupMentorOverview(target) {
    loadMentorOverviewDiv(target);

    let subject = getSearchParam('subject');
    let url = gEditProp.getDataFunctionPrefix + subject + "&p=" + gEditProp.getMentorOverviewPrnsUrl;

    let mentoringJson = await getDataViaPost(url, emitMentor);

    $('.deleteMentorOverview').on('click', deleteMentorOverview);
    $('.saveMentorOverview').on('click', saveMentorOverview);
    $('.cancelEdit').on('click', function() {
        setupMentorOverview(target)});
    $('.editMentorOverview').on('click', function() {
        emitMentorOverviewEdit(mentoringJson)});
}
function emitMentor(mentoringJson) {
    emitMentorOverviewDisplay(mentoringJson);
    return mentoringJson;
}
function getMentoringTextAndAreas(mentoringJson, truthy) {
    let areas = Object.keys(mentoringJson)
        .filter(a => a != 'text');
    if (truthy) {
        areas = areas.filter(a => mentoringJson[a] == true);
    }

    let text = mentoringJson.text;

    return [text, areas]
}
function mentoringIsEmpty(mentoringJson) {
    let [blurb, areas] = getMentoringTextAndAreas(mentoringJson, true);
    return ( ! blurb && ! areas.length);
}
function emitMentorOverviewDisplay(mentoringJson, target) {
    let innerTarget = target;

    if (! target) { // specific to edit module
        $('.mentoringAlternateDivs').hide();

        let displayFlavor = mentoringIsEmpty(mentoringJson) ? 'Empty' : 'Nonempty'
        target = $(`#mentoringDisplay${displayFlavor}`);
        target.show();

        innerTarget = target.find('.displayInner');
        innerTarget.empty();

        if (displayFlavor == 'Empty') {
            return; // our work here is done for now
        }
    }

    let [blurb, areas] = getMentoringTextAndAreas(mentoringJson, true);

    let blurbDiv = $(`<div class="mb-2">${blurb}</div>`);
    innerTarget.append(blurbDiv);

    if (areas.length) {
        innerTarget.append($('<div>Available to mentor:</div>'));
        let list = $('<ul></ul>');
        innerTarget.append(list);
        for (let area of areas) {
            // https://stackoverflow.com/questions/18379254/regex-to-split-camel-case
            area = area.replace(/([a-z])([A-Z])/g, '$1 $2')
                .replace(/ On /, " on ");
            area = initialCap(area);
            list.append($(`<li>${area}</li>`));
        }
    }
}
function emitMentorOverviewEdit(mentoringOverview) {
    let newVsUpdate = mentoringIsEmpty(mentoringOverview);

    $('.mentoringAlternateDivs').hide();
    $('.mentoringAlternateButtons').hide();
    $('#mentoringEdit').show();
    if (newVsUpdate) {
        $('#mentorEditEmpty').show();
    }
    else {
        $('#mentorEditNonempty').show();
    }

    $("#mentoringOverviewText").val(mentoringOverview.text);
    $("#studentsOnResearchProjects").prop("checked", mentoringOverview.studentsOnResearchProjects);
    $("#studentsOnCareerDevelopment").prop("checked", mentoringOverview.studentsOnCareerDevelopment);
    $("#studentsOnWorkLifeBalance").prop("checked", mentoringOverview.studentsOnWorkLifeBalance);
    $("#facultyOnResearch").prop("checked", mentoringOverview.facultyOnResearch);
    $("#facultyOnResearchProjects").prop("checked", mentoringOverview.facultyOnResearchProjects);
    $("#facultyOnCareerDevelopment").prop("checked", mentoringOverview.facultyOnCareerDevelopment);
    $("#facultyOnWorkLifeBalance").prop("checked", mentoringOverview.facultyOnWorkLifeBalance);
    $("#residentsAndFellowsOnResearch").prop("checked", mentoringOverview.residentsAndFellowsOnResearch);
    $("#residentsAndFellowsOnResearchProjects").prop("checked", mentoringOverview.residentsAndFellowsOnResearchProjects);
    $("#residentsAndFellowsOnCareerDevelopment").prop("checked", mentoringOverview.residentsAndFellowsOnCareerDevelopment);
    $("#residentsAndFellowsOnWorkLifeBalance").prop("checked", mentoringOverview.residentsAndFellowsOnWorkLifeBalance);
}
function deleteMentorOverview() {
    $("#mentoringOverviewText").val("");
    $("#studentsOnResearchProjects").prop("checked", false);
    $("#studentsOnCareerDevelopment").prop("checked", false);
    $("#studentsOnWorkLifeBalance").prop("checked", false);
    $("#facultyOnResearch").prop("checked", false);
    $("#facultyOnResearchProjects").prop("checked", false);
    $("#facultyOnCareerDevelopment").prop("checked", false);
    $("#facultyOnWorkLifeBalance").prop("checked", false);
    $("#residentsAndFellowsOnResearch").prop("checked", false);
    $("#residentsAndFellowsOnResearchProjects").prop("checked", false);
    $("#residentsAndFellowsOnCareerDevelopment").prop("checked", false);
    $("#residentsAndFellowsOnWorkLifeBalance").prop("checked", false);

    saveMentorOverview();
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
    mentoringOverview.facultyOnCareerDevelopment = $("#facultyOnCareerDevelopment").prop("checked");
    mentoringOverview.facultyOnWorkLifeBalance = $("#facultyOnWorkLifeBalance").prop("checked");
    mentoringOverview.residentsAndFellowsOnResearch = $("#residentsAndFellowsOnResearch").prop("checked");
    mentoringOverview.residentsAndFellowsOnResearchProjects = $("#residentsAndFellowsOnResearchProjects").prop("checked");
    mentoringOverview.residentsAndFellowsOnCareerDevelopment = $("#residentsAndFellowsOnCareerDevelopment").prop("checked");
    mentoringOverview.residentsAndFellowsOnWorkLifeBalance = $("#residentsAndFellowsOnWorkLifeBalance").prop("checked");
    let url = gEditProp.addUpdateDataFunctionPrefix + subject + "&p=" + gEditProp.getMentorOverviewPrnsUrl;

    editSaveViaPost(url, mentoringOverview);
}
