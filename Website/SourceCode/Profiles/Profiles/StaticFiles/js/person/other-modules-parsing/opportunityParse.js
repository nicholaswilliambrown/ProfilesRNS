function opportunityParser(json, moduleTitle, miscInfo) {
    let accordionBannerTitle = miscInfo.bannerText;

    let opportunityInnerAccordionInfo = makeAccordionDiv(moduleTitle, accordionBannerTitle, AccordionNestingOption.Nested)
    let opportunityInnerPayloadDiv = opportunityInnerAccordionInfo.payload;

    let sortedJson = sortArrayViaSortLabel(json, "StartDate", true );

    for (let i=0; i<sortedJson.length; i++) {
        let elt = sortedJson[i];
        let p = $('<p></p>');

        let startDate = yyyyDashMmDashDdStarTo(elt.StartDate, fromMatchToDdMdYyyy);
        let endDate = yyyyDashMmDashDdStarTo(elt.EndDate, fromMatchToDdMdYyyy);

        opportunityInnerPayloadDiv.append(p);
        let loginSpan = gCommon.loggedIn ? "" : '<span className="f10">[login at prompt]</span>'
        let html = `
            <a class="link-ish" href="${elt.URI}">${elt.Title}</a> 
            ${loginSpan}
            <div class="mb-1 mt-1">Available: ${startDate}, Expires: ${endDate}</div>
            <div>${elt.Description}</div>
        `;
        p.html(html);
    }

    return opportunityInnerAccordionInfo.outerDiv;
}

