gEditProp.slideshares = [];

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
    let url = gEditProp.getDataFunctionPrefix + subject + "&p=" + gEditProp.getSlideshareOntologyUrl;

    $('#slideshareDetailsDiv').hide(); // at least initially
    $('#cancelSlideshareEdit').on('click', clearAndCloseSlideshareForm);

    let numCurrentSlideshares = await getDataViaPost(url, emitSlideshares);
    await cardinalityPattern({
        createItemOverallDivId: 'createSlideshareDiv',
        itemDetailsDivId:       'slideshareDetailsDiv',
        currentItemsDivId:      'slideshareDiv',
        togglingArrowImgId:     'createSlideshareArrow',
        saveItemId:             'saveSlideshare',
        saveItemFn:             () => {saveSlideshare('')},
        createItemFn:           clearSlideshareForm,
        numItems:               numCurrentSlideshares,
        itemType:               'slideshare',
        }
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
            <div>Navigate to your slideshare presentation. E.g., here is one that Griffin Weber has <br/>
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
                    <li>Select and copy the 'iframe' code</li>
                    <li>Paste that code below on this Profiles editing page, as the entry for 'Slideshare Embedding Code'</li>
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
                <div class="inputLabel">Slideshare Title</div>
                <div><input type="text" id="slideshareTitle" /></div>
                <div class="inputLabel">Slideshare Description</div>
                <div><textarea rows="4" cols="40" id="slideshareDescription"></textarea></div>
                <div class="inputLabel">Slideshare Embedding Code</div>
                <div><textarea rows="4" cols="40" id="slideshareEmbedCode"></textarea></div>
                <div id="slideshareItself"></div>
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
function emitSlideshares(slideshareData) {
    if (! slideshareData[0]) {
        return; // none to emit
    }

    let slideshareArray = slideshareData[0].Data;
    let numSlideShares = 0;
    console.log('set numSS = 0');

    if (Array.isArray(slideshareArray)) {
        let slideshareDiv = $('#slideshareDiv');

        if (slideshareArray.length != 0) {
            gEditProp.slideshares = slideshareArray;
            console.log('numSS == ', numSlideShares);
            numSlideShares = slideshareArray.length;

            let rowId = 'slideshareHeader';
            let row = makeRowWithColumns(slideshareDiv, rowId, gEditProp.colSpecsJobOuterTwoCols, 'ebordS ebordE ebordT ebordB topRow');
            row.find(`#${rowId}Col0`).append($(`<div>Slideshare</div>`));
            row.find(`#${rowId}Col1`).append($(`<div>Action</div>`));
        }
        else {
            slideshareDiv.append("No slideshares have been added.");
        }

        let numSlideshares = gEditProp.slideshares.length;
        for (let i=0; i<numSlideshares; i++) {
            let slideshare = gEditProp.slideshares[i];

            let oddEven = i%2 ? 'oddRow' : 'evenRow';

            let overallRowId = slideshare.slideshareId;
            let overallRow = makeRowWithColumns(slideshareDiv, overallRowId, gEditProp.colSpecsJobOuterTwoCols, oddEven + ' ebordS ebordE ebordB');
            let actionCol = createSlidesharesActionColumn(i, slideshare, numSlideshares);
            overallRow.find(`#${overallRowId}Col1`).append(actionCol);

            let slideshareTitleDiv = $(`<div class="bold">${i + 1}. ${slideshare.title}</div>`);
            let slideshareDescDiv = $(`<div class="">${slideshare.description}</div>`);

            //let slideshareEmbedCode = iframeDecode(slideshare.code);   // decoded version for profile display
            let slideshareEmbedCode = slideshare.code;
            let slideshareEmbedDiv = $(`<div class="">${slideshareEmbedCode}</div>`);

            let col0 = overallRow.find(`#${overallRowId}Col0`);
            col0.append(slideshareTitleDiv);
            col0.append(slideshareDescDiv);
            col0.append(slideshareEmbedDiv);
        }
    }
    return numSlideShares;
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

    console.log('--------- slideshareId ---------', slideshare.slideshareId);
    editIcon.on('click', function() {
        editSlideshare(slideshare.slideshareId);
    });
    deleteIcon.on('click', function() {
        deleteSlideshare(slideshare.slideshareId);
    });
    upIcon.on('click', function() {
        moveArrayItemUp(gEditProp.slideshares, index);
        saveAllSlideshares();
    });
    downIcon.on('click', function() {
        moveArrayItemDown(gEditProp.slideshares, index)
        saveAllSlideshares();
    });

    return iconDiv;
}

function clearAndCloseSlideshareForm() {
    clearSlideshareForm();
    closeSlideshareForm();
}

function clearSlideshareForm() {
    // clear
    $("#slideshareTitle").val('');
    $("#slideshareDescription").val('');
    $("#slideshareEmbedCode").val('');
}
function closeSlideshareForm() {
    // close
    $("#slideshareDetailsDiv").hide();
    $("#createSlideshareArrow").attr('src', gEditProp.rightArrow);
}
function isValidSlideshareEmbedRegex(code) {
    const pattern = new RegExp(
        "^<iframe.*$"
    );
    return !!pattern.test(code);
}

function slideshareInvalidities() {
    let validationMessages = [];
    let candidateEmbed = $("#slideshareEmbedCode").val();
    if ( ! isValidSlideshareEmbedRegex(candidateEmbed)) {
        validationMessages.push('Please carefully re-copy and enter your desired slideshare embedding code');
    }
    return validationMessages;
}
function saveSlideshare(slideshareId) {
    let invalidities = slideshareInvalidities();
    if (invalidities.length) {
        alert(invalidities.join('\n'));
        return;
    }

    if (gEditProp.slideshares.length != 0 && gEditProp.slideshares.find(x => x.slideshareId == slideshareId) != undefined) {
        //edit existing 

        const indexToEdit = gEditProp.slideshares.findIndex(x => x.slideshareId == slideshareId);
        gEditProp.slideshares[indexToEdit].title = $("#slideshareTitle").val();
        gEditProp.slideshares[indexToEdit].description = $("#slideshareDescription").val();
        gEditProp.slideshares[indexToEdit].code = $("#slideshareEmbedCode").val();

    } else {
        //add new
        slideshareId = crypto.randomUUID();
        let slideshare = {};
        slideshare.slideshareId = slideshareId;
        slideshare.title = $("#slideshareTitle").val();
        slideshare.description = $("#slideshareDescription").val();
        slideshare.code = $("#slideshareEmbedCode").val();

        gEditProp.slideshares.push(slideshare);
    }
    saveAllSlideshares();
}
async function saveAllSlideshares() {
    let searchParams = window.location.search;
    const urlParams = new URLSearchParams(searchParams);

    let subject = urlParams.get('subject');
    let url = gEditProp.addUpdateDataFunctionPrefix + subject +  "&p=" + gEditProp.getSlideshareOntologyUrl;
    let stringySlidesArray = iframeEncode(JSON.stringify(gEditProp.slideshares));
    await editSaveViaPost(url, {Data: stringySlidesArray, SearchableData:"SlideShare"});
}
function loadSlideshare(slideshare) {
    $("#slideshareTitle").val(slideshare.title);
    $("#slideshareDescription").val(slideshare.description);
    $("#slideshareEmbedCode").val(iframeDecode(slideshare.code));
    return true;

}
function editSlideshare(slideshareId) {
    closeSlideshareForm(); // eg, if in midst of creation
    $("#slideshareDetailsDiv").show();
    let slideshare = gEditProp.slideshares.find(x => x.slideshareId == slideshareId);
    console.log('++++++++++++++++++++++++++++++ save will UPDATE opp')
    $("#saveSlideshare").off('click').on('click', function() {
        saveSlideshare(slideshareId);
    });
    loadSlideshare(slideshare);
}
async function deleteSlideshare(slideshareId) {

    gEditProp.slideshares = gEditProp.slideshares.filter(x => x.slideshareId != slideshareId);

    let searchParams = window.location.search;
    const urlParams = new URLSearchParams(searchParams);
    let subject = urlParams.get('subject');

    let url = gEditProp.addUpdateDataFunctionPrefix + subject +  "&p=" + gEditProp.getSlideshareOntologyUrl;

    await editSaveViaPost(url, gEditProp.slideshares);
}