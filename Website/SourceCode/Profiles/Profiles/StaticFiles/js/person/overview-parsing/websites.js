
function websitesParser(json, moduleTitle, miscInfo) {
    let accordionBannerTitle = miscInfo.bannerText;

    let innerAccordionInfo = makeAccordionDiv(moduleTitle, accordionBannerTitle, AccordionNestingOption.Nested)
    let innerPayloadDiv = innerAccordionInfo.payload;

    let sortedJson = sortArrayViaSortLabel(json, "SortOrder");

    for (let i=0; i<sortedJson.length; i++) {
        let elt = sortedJson[i];
        let url = elt.URL;

        let faviconUrl = `https://www.google.com/s2/favicons?domain=${url}`;

        // word wrap pattern
        let item = $(`<p class="wrap2 ${gCommon.bsMarginVarying}">
                        <span class="faviconSpan"><img src="${faviconUrl}" aria-hidden="true" width="16'" height="16"></span>
                        <a class="link-ish" href="${url}">${elt.WebPageTitle}</a></p>`);
        let colSpecs = [
            newColumnSpec(`${gCommon.cols12}`)
        ];
        let row = makeRowWithColumns(innerPayloadDiv, `media-${i}`, colSpecs);

        row.find(`#media-${i}Col0`).append(item);
    }

    return innerAccordionInfo.outerDiv;
}