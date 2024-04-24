
function overviewParser(json, moduleTitle, miscInfo) {
    let accordionBannerTitle = miscInfo.bannerText;

    let overviewInnerAccordionInfo = makeAccordionDiv(moduleTitle, accordionBannerTitle, AccordionNestingOption.Nested)
    let overviewInnerPayloadDiv = overviewInnerAccordionInfo.payload;

    let sortedJson = sortArrayViaSortLabel(json, "sortOrder");

    for (let i=0; i<sortedJson.length; i++) {
        let elt = sortedJson[i];

        let lines = elt.value.split("\n");
        for (let j=0; j<lines.length; j++) {
            let line = lines[j];
            let item = $(`<div class="mb-2">${line}</div>`);
            overviewInnerPayloadDiv.append(item);
        }
    }

    return overviewInnerAccordionInfo.outerDiv;
}
