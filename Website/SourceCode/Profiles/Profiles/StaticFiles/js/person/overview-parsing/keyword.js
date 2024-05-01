

function keywordParser(json, moduleTitle, miscInfo) {
    let accordionBannerTitle = miscInfo.bannerText;

    let innerAccordionInfo = makeAccordionDiv(moduleTitle, accordionBannerTitle, AccordionNestingOption.Nested)
    let innerPayloadDiv = innerAccordionInfo.payload;

    let sortedJson = sortArrayViaSortLabel(json, "SortOrder");

    for (let i=0; i<sortedJson.length; i++) {
        let elt = sortedJson[i];

        let div = $(`<div class="ps-4 link-ish">${elt.Value}</div>`);
        div.on('click', function() {minimalPeopleSearch(elt.Value)});

        innerPayloadDiv.append(div);
    }

    return innerAccordionInfo.outerDiv;
}
