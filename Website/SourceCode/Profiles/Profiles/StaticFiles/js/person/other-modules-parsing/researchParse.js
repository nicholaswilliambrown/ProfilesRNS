function emitLargeOrSmallResearchItem(elt, start, end, liDiv, i, lgVsSm) {

    // default small
    let idLgOrSm = gCommon.small;
    let displayDivClass = gCommon.showXsSmMdHideOthers;
    let col0Class = gCommon.cols3or12;
    let col1Class = gCommon.cols3or12;
    let col2Class = gCommon.cols6or12;

    // large
    if (lgVsSm) {
        idLgOrSm = gCommon.large;
        displayDivClass = gCommon.hideXsSmMdShowOthers;
        col2Class = `${gCommon.cols6or12} d-flex justify-content-end`;
    }

    let displayDiv = $(`<div class="${displayDivClass}"></div>`);
    liDiv.append(displayDiv);

    let colSpecs = [
        newColumnSpec(`${col0Class}`, spanify(elt.FundingID)),
        newColumnSpec(`${col1Class}`, spanify(elt.PrincipalInvestigatorName)),
        newColumnSpec(`${col2Class}`, spanify(`${start} - ${end}`))
    ];
    makeRowWithColumns(displayDiv, `research-${idLgOrSm}-${i}`, colSpecs);

    let grantBy = $(`<div>${elt.GrantAwardedBy}</div>`);
    displayDiv.append(grantBy);

    let label = $(`<div>${elt.AgreementLabel}</div>`);
    displayDiv.append(label);

    let role = $(`<span>Role: ${elt.RoleLabel}</span>`);
    displayDiv.append(role);
}

function emitResearchItems(contentDiv, sortedJson) {
    contentDiv.empty();

    let sortedLength = sortedJson.length;
    let numItemsToShow = gPerson.researcherUseRecent ? Math.min(gPerson.researcherNumRecent, sortedLength) : sortedLength;

    if (numItemsToShow) {
        contentDiv.append($('<hr>'));
        let ol = $('<ol></ol>');
        contentDiv.append(ol);

        for (let i = 0; i < numItemsToShow; i++) {
            let li = $('<li class="my-mb2"></li>');
            ol.append(li);
            let liDiv = $('<div></div>');
            li.append(liDiv);

            let elt = sortedJson[i];

            let start = yyyyDashMmDashDdStarTo(elt.StartDate, fromMatchToMmmDdYyyy);
            let end = yyyyDashMmDashDdStarTo(elt.StartDate, fromMatchToMmmDdYyyy);

            // large and small versions
            emitLargeOrSmallResearchItem(elt, start, end, liDiv, i, true);
            emitLargeOrSmallResearchItem(elt, start, end, liDiv, i, false);
        }
    }
}

function researcherParser(json, moduleTitle, miscInfo) {
    let accordionBannerTitle = miscInfo.bannerText;

    let innerAccordionInfo = makeAccordionDiv(moduleTitle, accordionBannerTitle, AccordionNestingOption.Nested)
    let innerPayloadDiv = innerAccordionInfo.payload;

    let sortedJson = sortArrayViaSortLabel(json, "SortOrder");

    let blurb = $(`<p>The research activities and funding listed below are automatically derived 
                from NIH ExPORTER and other sources, which might result in incorrect or missing 
                items. Faculty can <a href="${gCommon.loginUrl}">login</a> to make corrections and additions.</p>`);
    innerPayloadDiv.append(blurb);

    let mostRecent = $('<button class="link-ish" id="researchRecent">Most Recent</button>');
    let listAll = $('<button class="link-ish" id="researchAll">List All</button>');

    let numDiv = $('<div></div>');
    numDiv.append(mostRecent)
        .append(spanify(" | "))
        .append(listAll);
    innerPayloadDiv.append(numDiv);

    let contentDiv = $('<div></div>');
    innerPayloadDiv.append(contentDiv);

    mostRecent.on("click", function() {
        researchLengthActivateDeactivate(mostRecent, listAll);
        gPerson.researcherUseRecent = true;
        emitResearchItems(contentDiv, sortedJson);
    });
    listAll.on("click", function() {
        researchLengthActivateDeactivate(listAll, mostRecent);
        gPerson.researcherUseRecent = false;
        emitResearchItems(contentDiv, sortedJson);
    });
    mostRecent.click();

    emitResearchItems(contentDiv, sortedJson);

    return innerAccordionInfo.outerDiv;
}

function researchLengthActivateDeactivate(active, inactive) {
    active.addClass("research-length");
    active.removeClass("link-ish");
    active.attr("aria-current", true);

    inactive.addClass("link-ish");
    inactive.removeClass("research-length");
    inactive.removeAttr("aria-current");
}


