function parsePerson(jsonArray, lhsModules, rhsModules) {

    google.charts.load('current', {'packages':['corechart']});
    google.charts.load('current', {'packages':['bar']});

    let anchorsAuthorModulesArray = [];

    for (let i=0; i<lhsModules.length; i++) {
        let moduleJson = lhsModules[i];
        parseModuleAndData(moduleJson, anchorsAuthorModulesArray);
    }

    let anchorAuthorModuleLinksDiv = $('<div id="anchorAuthorModuleLinksDiv" ' +
        'class="mb-3"></div>');
    let anchorsModuleLinksInnerDiv = $(`<div id="anchorsModuleLinksInnerDiv" 
                                            class="anchorLinksDiv ${gCommon.anchorLinksDivSpacing}"></div>`);

    anchorAuthorModuleLinksDiv.append(anchorsModuleLinksInnerDiv);
    let comboAuthorModuleAnchors = anchorsAuthorModulesArray.join(`<span class="me-1"> | </span>`);
    anchorsModuleLinksInnerDiv.html(comboAuthorModuleAnchors);

    let anchorsTarget = $('#modules-left-div').children().first();
    let anchorNetworkLinksDiv = setupExploreNetworks(anchorsTarget, rhsModules);

    anchorAuthorModuleLinksDiv.insertAfter(anchorNetworkLinksDiv);
}

function parseModuleAndData(moduleWithDataJson, anchorsMainArray) {
    let moduleTitle = moduleWithDataJson.DisplayModule.replace("Person\.", "");
    let moduleData = moduleWithDataJson.ModuleData;

    let moduleMainDiv = $('#modules-left-div');

    let parserInfo = whichParserInfo(moduleTitle, moduleMainDiv);
    let bannerText = parserInfo.misc.bannerText;

    let parser = parserInfo.parser;

    let parsedData = parser(moduleData, moduleTitle, parserInfo.misc);
    let targetDiv = parserInfo.target;

    let parentName= parserInfo.parentContainerName;
    let parentInfo;
    if (!targetDiv) {
        parentInfo = makeOuterModuleDiv(parentName, bannerText);
        targetDiv = parentInfo.payload;
        gPerson.cachedParentDiv[parentName] = targetDiv;
        moduleMainDiv.append(parentInfo.outerDiv);
    }

    let mainDivId = moduleMainDiv.attr("id");
    let anchorHtml;
    if (mainDivId == "modules-left-div" && bannerText) {
        anchorHtml = `<a class="link-ish me-1" href="#${moduleTitle}">${bannerText}</a>`;
        anchorsMainArray.push(anchorHtml);
    }

    targetDiv.append(parsedData);

    armTheTooltips(); // in case new ones have been added
}
function whichParserInfo(moduleTitle, defaultTarget) {
    let parser = defaultLeftSideParser;
    let sort = 2000; // high number
    let parentContainerName = "";
    let target = defaultTarget;
    let misc = { bannerText: "", blurb: ""};

    switch (moduleTitle) {
        case "GeneralInfo":
            parser = generalInfoParser;
            sort = 1;
            break;
        case "MentoringCurrentStudentOpportunities":
            parser = opportunityParser;
            sort = 11;
            parentContainerName = "Mentoring";
            misc.bannerText = "current student opportunities";
            break;
        case "EducationAndTraining":
            parser = educationParser;
            sort = 21;
            parentContainerName = "Biography";
            misc.bannerText = "education and training";
            break;
        case "AwardOrHonor":
            parser = awardParser;
            sort = 31;
            parentContainerName = "Biography";
            misc.bannerText = "awards";
            break;
        case "Overview":
            parser = overviewParser;
            sort = 41;
            parentContainerName = "Overview";
            misc.bannerText = "overview";
            break;
        case "FreetextKeyword":
            parser = keywordParser;
            sort = 51;
            parentContainerName = "Overview";
            misc.bannerText = "keywords";
            break;
        case "Websites":
            parser = websitesParser;
            sort = 61;
            parentContainerName = "Overview";
            misc.bannerText = "webpage";
            break;
        case "MediaLinks":
            parser = mediaParser;
            sort = 71;
            parentContainerName = "Overview";
            misc.bannerText = "media";
            break;
        case "ResearcherRole":
            parser = researcherParser;
            sort = 111;
            parentContainerName = "Research";
            misc.bannerText = "research activities and funding";
            break;
        case "ClinicalTrialRole":
            parser = trialsParser;
            sort = 121;
            parentContainerName = "Research";
            misc.bannerText = "clinical trials";
            break;
        case "FeaturedPresentations":
            parser = presentationsParser;
            sort = 131;
            parentContainerName = "Featured Content";
            misc.bannerText = "presentations";
            break;
        case "FeaturedVideos":
            parser = videosParser;
            sort = 141;
            parentContainerName = "Featured Content";
            misc.bannerText = "videos";
            break;
        case "Twitter":
            parser = twitterParser;
            sort = 151;
            parentContainerName = "Featured Content";
            misc.bannerText = "twitter";
            break;
        case "AuthorInAuthorship":
            parser = authorshipParser;
            sort = 161;
            parentContainerName = "Bibliographic";
            misc.bannerText = "selected publications";
            break;

        // No explicit default. Will use default values above
    }

    if (parentContainerName) {
        target = gPerson.cachedParentDiv[parentContainerName];
    }
    return {
        parser: parser,
        target: target,
        parentContainerName:parentContainerName,
        sort: sort,
        misc: misc
        };
}
function makeOuterModuleDiv(moduleTitle, accordionIndicator) {
    let result;

    let titleAsIdent = asIdentifier(moduleTitle);
    result = makeAccordionDiv(`${titleAsIdent}-outer`, moduleTitle, AccordionNestingOption.Unnested);

    //  2-part object from makeAccordionDiv()
    return result;
}

function makeHeaderRow(target, accordionHeader, idLabel) {
    colSpecs = [
        newColumnSpec(`${gCommon.cols6}`),
        newColumnSpec(`${gCommon.cols5}`),
        newColumnSpec(`${gCommon.cols1} d-flex justify-content-end`)
    ];
    let row = makeRowWithColumns(target, idLabel, colSpecs,
        `row-${idLabel} accordionHeaderHolder`);

    let buttonColumn = row.find(`#${idLabel}Col0`);
    buttonColumn.append(accordionHeader);

    return row;
}

function displayClipboardForNestedAccordion(bannerText, accordionIdLabel, accordionHeaderRow) {
    let clipboard = $(`<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi-clipboard" viewBox="0 0 16 16">
                            <path d="M4 1.5H3a2 2 0 0 0-2 2V14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V3.5a2 2 0 0 0-2-2h-1v1h1a1 1 0 0 1 1 1V14a1 1 0 0 1-1 1H3a1 1 0 0 1-1-1V3.5a1 1 0 0 1 1-1h1v-1z"/>
                            <path d="M9.5 1a.5.5 0 0 1 .5.5v1a.5.5 0 0 1-.5.5h-3a.5.5 0 0 1-.5-.5v-1a.5.5 0 0 1 .5-.5h3zm-3-1A1.5 1.5 0 0 0 5 1.5v1A1.5 1.5 0 0 0 6.5 4h3A1.5 1.5 0 0 0 11 2.5v-1A1.5 1.5 0 0 0 9.5 0h-3z"/>
                           </svg>`);
    let informativeText = `Click here to copy the '${bannerText}' Profile section URL to your clipboard.`;
    let clipboardButton = $(`<button    data-bs-toggle="tooltip"
                                            data-bs-custom-class="clipboardButtonTitle" 
                                            data-bs-placement="top"
                                            title="${informativeText}"
                                    class="clipboardMainButton">
                                </button>`);
    clipboardButton.append(clipboard);
    clipboardButton.on("click", function (e) {
        let unanchoredLocation = window.location.href.replace(/#.*/, "");
        let gotoLocation = `${unanchoredLocation}#accordionHeader${accordionIdLabel}`;
        console.log(window.location, "gotoLocation: " + gotoLocation);

        window.navigator.clipboard.writeText(gotoLocation);
    });
    let clipColumn = accordionHeaderRow.find(`#${accordionIdLabel}Col2`);

    clipColumn.append(clipboardButton);

    let ariaSpan = $(`<span aria-hidden="true" class="visually-hidden">${informativeText}</span>`);
    clipColumn.append(ariaSpan);
}

/**
 *
 * @param accordionId  -- the id of the 'outerDiv' that encloses the accordion construct
 * @param buttonText        -- text of the accordion's title, which is also the expand/collapse button
 * @param nestingOption     -- unnested accordion could contain (in its payload) some (nested) accordions
 * @returns {{payload: (*|jQuery|HTMLElement), outerDiv: (*|jQuery|HTMLElement)}}
 *
 * For unnested accordions, the thing you expand/collapse is the content of interest.
 * For nested accordions, the first-level expand/collapse holds 'inner' (not further nested) accordions
 */
function makeAccordionDiv(accordionId, buttonText, nestingOption) {
    let nested = (nestingOption == AccordionNestingOption.Nested);

    let accordionBodyId = asIdentifier(buttonText) + "-inner";
    let accordionOuterDiv = $(`<div id="${accordionId}"></div>`);

    let nestingClass = nestingOption.description;
    let accordionConstruct = $(`<div id="accordion${accordionId}" class="${nestingClass} accordion"></div>`);
    let accordionHeaderAndBody = $(`<div class="${nestingClass} accordion-item">`);
    let accordionHeader = $(`<div class="accordion-header" id="accordionHeader${accordionId}"></div>`);

    let accordionHeaderRow = makeHeaderRow(accordionHeaderAndBody, accordionHeader, accordionId);

    let accordionButton = $(`<button 
                        class="accordion-button ${nestingClass}" 
                        type="button" 
                        data-bs-toggle="collapse" 
                        data-bs-target="#collapse${accordionId}" 
                        aria-expanded="false" 
                        aria-controls="collapse${accordionId}"
                        > ${buttonText}
                </button>`);
    let accordionCollapse = $(`<div 
                        id="collapse${accordionId}"
                        class="accordion-collapse collapse show" 
                        aria-labelledby="accordionHeader${accordionId}" 
                        data-bs-parent="#accordion${accordionId}"
                        >`);
    accordionCollapse.addClass( "accordion-collapse collapse");

    let accordionBody = $(`<div class="accordion-body accordion-body${accordionId} ${nestingClass}" id="${accordionBodyId}"></div>`);

    accordionOuterDiv.append(accordionConstruct);
    accordionConstruct.append(accordionHeaderAndBody);
    accordionHeaderAndBody.append(accordionHeaderRow);
    accordionHeaderAndBody.append(accordionCollapse);

    if (nested) {
        displayClipboardForNestedAccordion(buttonText, accordionId, accordionHeaderRow);
    }
    else {
        accordionBody.addClass(gCommon.bsMarginsPaddingIncreasing);
    }
    accordionHeader.append(accordionButton);
    accordionCollapse.append(accordionBody);

    return { outerDiv: accordionOuterDiv, payload: accordionBody };
}



