gEditProp.mentorSlideshare = [];

gEditProp.colSpecsJobOuterTwoCols = [
        newColumnSpec(`${gCommon.cols10or12} md_ebordE`),
        newColumnSpec(`${gCommon.cols2or12} d-flex justify-content-center align-items-center`)
];
gEditProp.colSpecsJobInnerTwoCols = [
        newColumnSpec(`${gCommon.cols5or12} wrap2`),
        newColumnSpec(`${gCommon.cols5or12} wrap2`)
];

async function setupSlideshare(target) {
    await loadSlideshareDiv(target);
    await setupHelpSlideshare($('#mainDiv'));

    let subject = getSearchParam('subject');
    let url = gEditProp.getDataFunctionPrefix + subject + "&p=" + gEditProp.getSlidesharePrnsUrl;

    $('#slideshareDetailsDiv').hide(); // at least initially
    $('#cancelSlideshareEdit').on('click', clearAndCloseSlideshareForm);

    let numCurrentSlideshares = await getDataViaPost(url, emitSlideshare);
    await cardinalityPattern({
        createItemOverallDivId: 'createSlideshareDiv',
        itemDetailsDivId:       'slideshareDetailsDiv',
        currentItemsDivId:      'slideshareDiv',
        togglingArrowImgId:     'createSlideshareArrow',
        saveItemId:             'saveSlideshare',
        saveItemFn:             () => {saveSlideshare('')},
        createItemFn:           clearSlideshareForm,
        numItems:               numCurrentSlideshares }
    );
}
async function setupHelpSlideshare(target) {
    let div = $('#helpSlideshareDiv');
    let innerHelp = $('#helpSlideshareInnerDiv');
    innerHelp.hide();

    div.on('click', function() {
        toggleEltVisibility(innerHelp);
        toggleSrcIcon($("#helpSlideshareMenuIcon"), gEditProp.rightArrow, gEditProp.downArrow);
    });
}

function loadSlideshareDiv(target) {
    let div = $(`
        <div id="helpSlideshareDiv" class="link-ish mt-2">
            <img id="helpSlideshareMenuIcon" src="${gEditProp.rightArrow}"/> How to Embed a Slideshare
        </div>
        <div id="helpSlideshareInnerDiv" class="editPanel">
            <h2>How to Embed a Slideshare</h2>
            <div>Navigate to your slideshare presentation. E.g., For one that Griffin Weber has <br/>
                <a href="https://www.slideshare.net/slideshow/profiles-rns/44789326"></a>
                <img class="mt-2 helpSlideshare" src="${g.profilesRootURL}/Edit/Images/slideshare-griffin.jpg"/>
            </div>
            <hr/>
            <div>Notice the 'Embed' option. <br/>
                <img class="mt-2 helpSlideshare" src="${g.profilesRootURL}/Edit/Images/slideshare-embed.jpg"/>
            </div>
            <hr/>
            <div>
                <ol>
                    <li>Click the Embed option</li> 
                    <li>Then click the smallest (427x356) size</li> 
                    <li>Finally, select and copy the 'iframe' code</li>
                </ol>
                <img class="helpSlideshare mt-2" src="${g.profilesRootURL}/Edit/Images/slideshare-code.jpg"/>
            </div>
        </div>
        
        <div id="slideshareOuterDiv">
            <div class="link-ish mt-2" id="createSlideshareDiv"><span class="link-ish"><img id="createSlideshareArrow" src="${gEditProp.rightArrow}"/></span>
                        Embed a Slideshare</a>
            </div>
            <div id="slideshareDetailsDiv" class="editPanel mt-2">
                <div class="moduleOptions">Enter the slideshare information below:</div>
                <div class="inputLabel">Job Title</div>
                <div><input type="text" id="jobTitle" /></div>
                <div class="inputLabel">Job Description</div>
                <div><textarea rows="4" cols="40" id="jobDescription"></textarea></div>
                <div class="inputLabel">Job URL</div>
                <div><input type="text" id="jobURL" /></div>
                <div class="jobCategories mt-2">
                    <span class="inputLabel">Job Category</span>
                    <div class="mt-2">
                        <div class="ms-2"><input type="checkbox" id="students" /><span class="ms-1">Students</span></div>
                        <div class="ms-2"><input type="checkbox" id="faculty" /><span class="ms-1">Faculty</span></div>
 
                        <div class="ms-2"><input type="checkbox" id="fellowsAndPostDocs" /><span class="ms-1">Fellows and PostDocs</span></div>
                        <div class="ms-2"><input type="checkbox" id="researchStaff" /><span class="ms-1">Research Staff</span></div>
                    </div>
                </div>
                <div><button class="link-ish mt-2 ps-0" id="saveSlideshare">Save</button>
                    <span class="pipe">|</span>
                    <button class="link-ish" id="cancelSlideshareEdit">Cancel</button>
                </div>

            </div> <!-- slideshareDetailsDiv -->
            <div id="moduleBody" class="container mt-2 ms-5">
                <div id="slideshareDiv"></div>
            </div> <!-- moduleBody -->
        </div> <!-- slideshareOuterDiv -->
    `);
    target.append(div);
}
function emitSlideshare(slideshare) {
    let numSlideshares = 0;

    if (Array.isArray(slideshare)) {
        let slideshareDiv = $('#slideshareDiv');

        if (slideshare.length != 0) {
            gEditProp.mentorSlideshare = slideshare;
            numSlideshares = slideshare.length;

            let rowId = 'slideshareHeader';
            let row = makeRowWithColumns(slideshareDiv, rowId, gEditProp.colSpecsJobOuterTwoCols, 'ebordS ebordE ebordT ebordB topRow');
            row.find(`#${rowId}Col0`).append($(`<div>Job Opportunities</div>`));
            row.find(`#${rowId}Col1`).append($(`<div>Action</div>`));
        }
        else {
            slideshareDiv.append("No job opportunities have been added.");
        }

        let numSlideshares = gEditProp.mentorSlideshare.length;
        for (let i=0; i<numSlideshares; i++) {
            let slideshare = gEditProp.mentorSlideshare[i];

            let truthyJobCategories = prettyTruthySlideshares(slideshare);

            let oddEven = i%2 ? 'oddRow' : 'evenRow';

            let overallRowId = 'joRow2' + i;
            let overallRow = makeRowWithColumns(slideshareDiv, overallRowId, gEditProp.colSpecsJobOuterTwoCols, oddEven + ' ebordS ebordE ebordB');
            let actionCol = createSlidesharesActionColumn(i, slideshare, numSlideshares);
            overallRow.find(`#${overallRowId}Col1`).append(actionCol);

            let jobTitleDiv = $(`<div class="bold">${i + 1}. ${slideshare.title}</div>`);
            let jobDescDiv = $(`<div class="">${slideshare.jobDescription}</div>`);
            let jobCategoryDiv = $(`<div class=""><span class="jobCategoryDisplayLabel">Job Category:</span>
                                        <span> ${truthyJobCategories}</span></div>`);

            let col0 = overallRow.find(`#${overallRowId}Col0`);
            col0.append(jobTitleDiv);
            col0.append(jobDescDiv);
            col0.append(jobCategoryDiv);

            let url = slideshare.jobURL;
            if (url) {
                col0.append($(`<div class=""><span class="jobCategoryDisplayLabel">Job URL:</span> 
                                    <a target="_blank" rel="noopener noreferrer" href="${url}">${url}</a></div>`));
            }
        }
    }
    return numSlideshares;
}
function createSlidesharesActionColumn(index, slideshare, numSlideshares) {
    let editIcon = $(`<img alt="edit" src='${g.profilesRootURL}/edit/images/Icon_Edit.gif'/>`);
    let deleteIcon = $(`<img alt="delete" src='${g.profilesRootURL}/edit/images/Icon_delete.gif'/>`);

    let upIcon = $(`<img alt="up" src='${g.profilesRootURL}/edit/images/Icon_Up.gif'/>`);
    let downIcon = $(`<img alt="down" src='${g.profilesRootURL}/edit/images/Icon_Down.gif'/>`);
    let blankSpan = $(`<span class="w18"></span>`);

    let iconDiv = $(`<div class="ms-3 d-flex justify-content-end w-50">`);

    if (index > 0) {
        iconDiv.append(upIcon);
    }
    else {
        iconDiv.append(blankSpan);
    }

    if (index+1 < numSlideshares) {
        iconDiv.append(downIcon);
    }
    else {
        iconDiv.append(blankSpan);
    }

    iconDiv.append(editIcon)  ;
    iconDiv.append(deleteIcon);

    console.log('--------- oppId ---------', slideshare.opportunityId);
    editIcon.on('click', function() {
        editSlideshare(slideshare.opportunityId);
    });
    deleteIcon.on('click', function() {
        deleteSlideshare(slideshare.opportunityId);
    });
    upIcon.on('click', function() {
        moveArrayItemUp(gEditProp.mentorSlideshare, index);
        saveAllSlideshare();
    });
    downIcon.on('click', function() {
        moveArrayItemDown(gEditProp.mentorSlideshare, index)
        saveAllSlideshare();
    });

    return iconDiv;
}

function clearAndCloseSlideshareForm() {
    clearSlideshareForm();
    closeSlideshareForm();
}

function clearSlideshareForm() {
    // clear
    $("#jobTitle").val('');
    $("#jobDescription").val('');
    $("#jobURL").val('');
    $("#students").prop("checked", false);
    $("#faculty").prop("checked", false);
    $("#residentsAndFellows").prop("checked", false);
}
function closeSlideshareForm() {
    // close
    $("#slideshareDetailsDiv").hide();
    $("#createSlideshareArrow").attr('src', gEditProp.rightArrow);
}
function slideshareInvalidities() {
    let validationMessages = [];
    let candidateUrl = $("#jobURL").val();
    if (candidateUrl && ! isValidURLRegex(candidateUrl)) {
        validationMessages.push('Please enter a URL, e.g., starting with http:// or https://');
    }
    return validationMessages;
}
function saveSlideshare(opportunityId) {
    let invalidities = slideshareInvalidities();
    if (invalidities.length) {
        alert(invalidities.join('\n'));
        return;
    }

    if (gEditProp.mentorSlideshare.length != 0 && gEditProp.mentorSlideshare.find(x => x.opportunityId == opportunityId) != undefined) {
        //edit existing 

        const indexToEdit = gEditProp.mentorSlideshare.findIndex(x => x.opportunityId == opportunityId);
        gEditProp.mentorSlideshare[indexToEdit].title = $("#jobTitle").val();
        gEditProp.mentorSlideshare[indexToEdit].jobDescription = $("#jobDescription").val();
        gEditProp.mentorSlideshare[indexToEdit].jobURL = $("#jobURL").val();
        gEditProp.mentorSlideshare[indexToEdit].categoryStudents = $("#students").prop("checked");
        gEditProp.mentorSlideshare[indexToEdit].categoryFaculty = $("#faculty").prop("checked");
        gEditProp.mentorSlideshare[indexToEdit].categoryFellowsAndPostDocs = $("#fellowsAndPostDocs").prop("checked");
        gEditProp.mentorSlideshare[indexToEdit].categoryResearchStaff = $("#researchStaff").prop("checked");

    } else {
        //add new
        opportunityId = crypto.randomUUID();
        let slideshare = {};
        slideshare.opportunityId = opportunityId;
        slideshare.title = $("#jobTitle").val();
        slideshare.jobDescription = $("#jobDescription").val();
        slideshare.jobURL = $("#jobURL").val();
        slideshare.categoryStudents = $("#students").prop("checked");
        slideshare.categoryFaculty = $("#faculty").prop("checked");
        slideshare.categoryFellowsAndPostDocs = $("#fellowsAndPostDocs").prop("checked");
        slideshare.categoryResearchStaff = $("#researchStaff").prop("checked");

        gEditProp.mentorSlideshare.push(slideshare);
    }
    saveAllSlideshare();
}
function saveAllSlideshare() {
    let searchParams = window.location.search;
    const urlParams = new URLSearchParams(searchParams);

    let subject = urlParams.get('subject');
    let url = gEditProp.addUpdateDataFunctionPrefix + subject +  "&p=" + gEditProp.getSlidesharePrnsUrl;
    editSaveViaPost(url, gEditProp.mentorSlideshare);
}
function loadSlideshare(slideshare) {
    $("#jobTitle").val(slideshare.title);
    $("#jobDescription").val(slideshare.jobDescription);
    $("#jobURL").val(slideshare.jobURL);
    $("#students").prop("checked", slideshare.categoryStudents);
    $("#faculty").prop("checked", slideshare.categoryFaculty);
    $("#fellowsAndPostDocs").prop("checked", slideshare.categoryFellowsAndPostDocs);
    $("#researchStaff").prop("checked", slideshare.categoryResearchStaff);
    return true;

}
function editSlideshare(opportunityId) {
    closeSlideshareForm(); // eg, if in midst of creation
    $("#slideshareDetailsDiv").show();
    let slideshare = gEditProp.mentorSlideshare.find(x => x.opportunityId == opportunityId);
    console.log('++++++++++++++++++++++++++++++ save will UPDATE opp')
    $("#saveSlideshare").off('click').on('click', function() {
        saveSlideshare(opportunityId);
    });
    loadSlideshare(slideshare);
}
function deleteSlideshare(opportunityId) {

    gEditProp.mentorSlideshare = gEditProp.mentorSlideshare.filter(x => x.opportunityId != opportunityId);

    let searchParams = window.location.search;
    const urlParams = new URLSearchParams(searchParams);
    let subject = urlParams.get('subject');

    let url = gEditProp.addUpdateDataFunctionPrefix + subject +  "&p=" + gEditProp.getSlidesharePrnsUrl;

    editSaveViaPost(url, gEditProp.mentorSlideshare);
}