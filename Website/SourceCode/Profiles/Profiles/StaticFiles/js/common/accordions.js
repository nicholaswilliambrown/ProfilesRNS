function makeOuterModuleDiv(moduleTitle) {
    let result;

    let titleAsIdent = asIdentifier(moduleTitle);
    result = makeAccordionDiv(`${titleAsIdent}-outer`, moduleTitle, AccordionNestingOption.Unnested);

    //  2-part object from makeAccordionDiv()
    return result;
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
                                    class="clipboardMainButton clipboardItem">
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

    let ariaSpan = $(`<span aria-hidden="true" class="clipboardItem visually-hidden">${informativeText}</span>`);
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
    accordionId = underSpace(accordionId);

    let nested = (nestingOption == AccordionNestingOption.Nested);

    let accordionBodyId = `${asIdentifier(buttonText)}-${nestingOption.description}-inner`;
    let accordionOuterDiv = $(`<div id="${accordionId}"></div>`);

    let nestingClass = nestingOption.description;
    let accordionConstruct = $(`<div id="accordion${accordionId}" class="${nestingClass} accordion"></div>`);
    let accordionHeaderAndBody = $(`<div class="${nestingClass} accordion-item">`);
    let accordionHeader = $(`<div class="accordion-header" id="accordionHeader${accordionId}"></div>`);

    let accordionHeaderRow = makeAccordionHeaderRow(accordionHeaderAndBody, accordionHeader, accordionId);

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
function makeAccordionHeaderRow(target, accordionHeader, idLabel) {
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
