async function setupSearchWhyResults() {

    let resultsAsString = fromSession(makeSearchResultsKey(gSearch.whyPrefix));
    let results = JSON.parse(resultsAsString);
    gSearch.searchWhyResults = results;
    console.log('Results: ', results);

    await setupPageStub(searchResultsBodyStructure);
    setupScrolling();

    let mainDiv = $('#mainDiv');
    mainDiv.addClass(gCommon.mainDivClasses);
    moveContentByIdTo("mainRow", mainDiv);

    emitCriteriaOnRhs(results, false);

    let returnUrl = results.SearchQuery.SearchType == gSearch.peoplePrefix ? 'searchPeopleResults.html' :
        'searchAllElseResults.html'
    emitSearchResultCountAndBackTo(results, returnUrl, 'Back to Search Results');

    let target = $('#resultsDiv');
    target.empty();

    emitGraphicAndItsHeader(results, target, returnUrl);

    emitWhyDirectResults(results, target);
    emitWhyIndirectResults(results, target);
}
function emitGraphicAndItsHeader(results, target, returnUrl) {
    let header = $(`<div>This page shows the details of why an item matched 
                            the keywords from your search.</div>`);
    target.append(header);

    let colspecs = [
        newColumnSpec(` p-1 d-flex justify-content-end ${gCommon.cols2or12}`),
        newColumnSpec(` p-1 d-flex justify-content-center align-items-center ${gCommon.cols8or12}`),
        newColumnSpec(` p-1 d-flex justify-content-start ${gCommon.cols2or12}`)
    ];
    let rowId = `whyResultsGraphic`;
    let row = makeRowWithColumns(target, rowId, colspecs, "bordersRow mt-2");

    let resultsAnchor = createAnchorElement('Search Results', returnUrl);
    row.find(`#${rowId}Col0`).append(resultsAnchor);

    row.find(`#${rowId}Col1`).append(makeArrowedConnectionLine());

    let personAnchor = whyPersonLink(results);
    row.find(`#${rowId}Col2`).append(personAnchor);
}
function emitWhyDirectResults(results, target) {

    let matches = results.Connections.DirectMatchList;
    if (matches
        && matches.constructor === Array
        && matches.length > 0) {

        emitResultsIntro(
            'One or more keywords matched the following properties of',
            results, target);

        emitWhyResultsHeader(target, 'Property', 'Value');
        emitWhyDirectMatches(matches, target);
    }
}
function emitResultsIntro(blurb, results, target) {
    let personAnchor = whyPersonLink(results);
    let div = $(`<div class="mt-3">${blurb} </div>`);
    div.append(personAnchor);
    target.append(div);
}
function emitWhyIndirectResults(results, target) {

    let matches = results.Connections.IndirectMatchList;
    if (matches
        && matches.constructor === Array
        && matches.length > 0) {

        emitResultsIntro(
            'One or more keywords matched the following items that are connected to',
            results, target);

        emitWhyResultsHeader(target, 'Item Type', 'Name');
        emitWhyIndirectMatches(matches, target);
    }
}
function makeWhyColspecs(isBold) {
    let boldClass = isBold ? "bold" : "";
    let colspecs = [
        newColumnSpec(` pt-1 pb-1 ${boldClass} d-flex justify-content-center  align-items-center bordE ${gCommon.cols3or12}`),
        newColumnSpec(` pt-1 pb-1 ${boldClass} d-flex justify-content-center ${gCommon.cols9or12}`),
    ];
    return colspecs;
}
function emitWhyResultsHeader(target, title1, title2) {
    let colspecsBold = makeWhyColspecs(true);

    let rowId = `whyResultsHeader`;
    let row = makeRowWithColumns(target, rowId, colspecsBold, "bordersRow bordTop mt-3");

    row.find(`#${rowId}Col0`).html(title1);
    row.find(`#${rowId}Col1`).html(title2);
}

function emitWhyDirectMatches(matches, target) {
    let colspecsMeek = makeWhyColspecs(false);

    for (let i = 0; i < matches.length; i++) {
        let item = matches[i];

        let rowId = `directMatches${i}`;
        let row = makeRowWithColumns(target, rowId, colspecsMeek, "bordersRow bordE");

        row.find(`#${rowId}Col0`).html(item.Name);
        row.find(`#${rowId}Col1`).html(item.Value);
    }
}

function emitWhyIndirectMatches(matches, target) {
    let colspecsMeek = makeWhyColspecs(false);

    matches = reverseSortArrayByWeight(matches);
    for (let i = 0; i < matches.length; i++) {
        let item = matches[i];

        let rowId = `indirectMatches${i}`;
        let row = makeRowWithColumns(target, rowId, colspecsMeek, "bordersRow bordE");

        let urlEntry = createAnchorElement(item.Label, item.URI);
        row.find(`#${rowId}Col0`).html(item.ClassName);
        row.find(`#${rowId}Col1`).append(urlEntry);
    }
}
function whyPersonLink(results) {
    let url = gImpl.personUrlPrefix + results.ConnectionNode.NodeID;
    let label = results.ConnectionNode.Label;

    return createAnchorElement(label, url);
}
