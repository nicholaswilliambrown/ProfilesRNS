

function keywordParser(json, moduleTitle, miscInfo) {
    let accordionBannerTitle = miscInfo.bannerText;

    let innerAccordionInfo = makeAccordionDiv(moduleTitle, accordionBannerTitle, AccordionNestingOption.Nested)
    let innerPayloadDiv = innerAccordionInfo.payload;

    let sortedJson = sortArrayViaSortLabel(json, "SortOrder");

    for (let i=0; i<sortedJson.length; i++) {
        let elt = sortedJson[i];

        let encodedKeyword = encodeURI(elt.Value);
        let url = gImpl.personKeywordSearchUrl.replace(gImpl.personKeywordSearchUrlPlaceHolder, encodedKeyword);

        let div = $(`<div class="ps-4"><a class="link-ish" href="${url}">${elt.Value}</a></div>`);
        innerPayloadDiv.append(div);
    }

    return innerAccordionInfo.outerDiv;
}
