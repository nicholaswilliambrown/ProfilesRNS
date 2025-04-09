

function authorshipParser(json, moduleTitle, miscInfo, explicitTarget) {
    let ignore3 = miscInfo.ignore3Tabs;

    let authorshipInnerPayloadDiv = getTargetUntentavizeIfSo(moduleTitle, explicitTarget);

    gPerson.authorshipJson = json[0];

    gPerson.clickedShowAll = false;
    gPerson.initialPubs = gPerson.authorshipJson.Publications;
    gPerson.limitSize = gPerson.initialPubs.length;
    gPerson.currentUnfilteredPubs = gPerson.initialPubs;

    gPerson.totalAvailablePubs = gPerson.authorshipJson.PublicationsCount;

    gPerson.timeline = gPerson.authorshipJson.Timeline;
    gPerson.fieldSummary = gPerson.authorshipJson.FieldSummary;

    addPublicationsFirstTwoHeaderItems(authorshipInnerPayloadDiv, ignore3);

    let authorshipInnerDiv = $('<div></div>');
    authorshipInnerPayloadDiv.append(authorshipInnerDiv);

    gPerson.authorshipInnerDiv = authorshipInnerDiv;

    gPerson.authNavCurrentNavItem.click();
}

function emitBlurbAndLimitDiv() {
    gPerson.pmcBlurb = $(`<div class="auth_topDiv2 mt-2">
        <b>PMC Citations</b> indicate the number of times the publication was 
        cited by articles in PubMed Central, and the <b>Altmetric</b> score 
        represents citations in news articles and social media. 
        (Note that publications are often cited in additional ways 
        that are not shown here.) <b>Fields</b> are based on how the National 
        Library of Medicine (NLM) classifies the publication's journal 
        and might not represent the specific topic of the publication. 
        <b>Translation</b> tags are based on the publication type and the MeSH 
        terms NLM assigns to the publication. Some publications 
        (especially newer ones and publications not in PubMed) might 
        not yet be assigned Field or Translation tags.) Click a Field 
        or Translation tag to filter the publications.
    </div>`);

    gPerson.authorshipInnerDiv.append(gPerson.pmcBlurb);
    gPerson.possiblyLimitedPubs = gPerson.currentUnfilteredPubs;

    if (gPerson.limitOption == PubsLimitOption.Limit &&
        (
            gPerson.currentUnfilteredPubs.length < gPerson.totalAvailablePubs
            || gPerson.limitSize < gPerson.totalAvailablePubs
        )) {

        let limitSpan = $(`<span id="limitSpan"></span>`)
        let divLimit = $(`<div id="divLimit" class="mt-3">Displaying </div>`);
        let showAll = $('<button class="link-ish showAllPubs">Show All</button>')

        gPerson.authorshipInnerDiv.append(divLimit);
        gPerson.limitSpan = limitSpan;

        divLimit.append(limitSpan);
        divLimit.append(showAll);

        showAll.on("click", async function() {
            gPerson.clickedShowAll = true;
            gPerson.limitOption = PubsLimitOption.All;
            gPerson.currentUnfilteredPubs = await getSortedLimitedPubs(PubsLimitedSortParam.All);

            await applySortsFiltersLimits();
        })
    }
}
async function authorshipInnerParser() {
    if ( ! gPerson.authorshipInnerDiv) {
        return; // called too soon
    }

    gPerson.authorshipInnerDiv.empty();
    emitBlurbAndLimitDiv();

    let orderedList = $("<ol></ol>");
    gPerson.authorshipInnerDiv.append(orderedList);

    let pubs = getSortedFilteredLimitedPubs(gPerson.sort, gPerson.fieldFilters, gPerson.translationFilters, gPerson.limitOption);
    gPerson.currentDisplayedPubs = pubs;
    for (let i=0; i<pubs.length; i++) {
        let pub = pubs[i];

        let authorsAndTitle = pub.prns_informationResourceReference;
        let ids = pmids(pub);

        let pubLi = $(`<li id="p${i}"></li>`);
        orderedList.append(pubLi);

        let authorsAndTitleSpan = $(`<span class="authorsAndTitle">${authorsAndTitle} ${ids}.</span>`);
        pubLi.append($('<hr/>')).append(authorsAndTitleSpan);

        authorsAndTitleSpan.find("a").addClass("link-ish");

        let bottomLinksBadges = [];
        let bottomLinksFields = [];
        let bottomLinksTranslations = [];

        addPmcAndRcrCitations(bottomLinksBadges, pub);
        addBadgeSpans(bottomLinksBadges, pub);

        addFields(bottomLinksFields, pub);
        addTranslations(bottomLinksTranslations, pub);

        let citationTitleSpan = $(`<span class="citations-category me-1 pubBadgeField">Citations: </span>`);

        harvestBottomlinkItems(pubLi, bottomLinksBadges, citationTitleSpan);
        harvestBottomlinkFieldsTranslations(pubLi, bottomLinksFields, bottomLinksTranslations);
        
    }
    await digestInjectedBadges();
}

function updateLimitSpan(numDisplayed) {
    if (gPerson.limitSpan){
        gPerson.limitSpan.html(`${numDisplayed} of ${gPerson.totalAvailablePubs} total Publications`);
    }
}

async function applySortsFiltersLimits(resetTries) {

    if (resetTries) {
        gPerson.numAltMetricTries = 1;
    }
    await authorshipInnerParser();

    showTransOrFieldUnchecked('fieldOrTrans');

    for (let i=0; i<gPerson.fieldFilters.length; i++) {
        let field = gPerson.fieldFilters[i];
        showTransOrFieldChecked(field);
    }
    for (let j=0; j<gPerson.translationFilters.length; j++) {
        let trans = gPerson.translationFilters[j];
        showTransOrFieldChecked(trans);
    }
    armTheTooltips();
}
function getSortedFilteredLimitedPubs(sortOption, fieldFilters, translationFilters, limitOption) {
    let pubs = gPerson.currentUnfilteredPubs;
    switch(sortOption) {
        case PubsSortOption.Newest:
            pubs = sortPubsByNewest(pubs);
            break;
        case PubsSortOption.Oldest:
            pubs = sortPubsByOldest(pubs);
            break;
        case PubsSortOption.MostCited:
            pubs = sortByCitationThenNewest(pubs);
            break;
        case PubsSortOption.MostDiscussed:
            pubs = sortByAltmetricThenReverseChron(pubs);
            break;
    }
    let pubsLimit;
    switch(limitOption) {
        case PubsLimitOption.Limit:
            pubsLimit = gPerson.limitSize;
            break;
        case PubsLimitOption.All:
            pubsLimit = pubs.length;
            break;
        default:
            console.log("bad limitOption: ", limitOption);
    }

    let filteredResults = [];
    for (let i=0; i<pubs.length; i++) {
        let pub = pubs[i];

        if (passesTransOrFieldFilters(pub)) {
            filteredResults.push(pub);
        }
    }
    let numFilteredResults = filteredResults.length;
    if (numFilteredResults > pubsLimit) {
        numFilteredResults = pubsLimit;
        filteredResults = filteredResults.slice(0, pubsLimit);
    }

    updateLimitSpan(numFilteredResults);

    return filteredResults;
}

