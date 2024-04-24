
async function setupSearchAllElseResults() {
    let pagination = new Paging(
        redoAllElseSearch,
        gImpl.findEverythingElseUrl,
        getAllElseResultsCount,
        gPage.sizes);

    //let data = await getJsonData("../json/fake-data/SearchPersonResults.json");
    let resultsAsString = fromSession(makeSearchResultsKey(gSearch.allElsePrefix));
    gSearch.searchAllElseResults = JSON.parse(resultsAsString);
    let results = gSearch.searchAllElseResults;

    if (! results || ! results.SearchQuery) { // sanity check
        alert(`Error with search results: ${resultsAsString}`);
    }
    console.log('Results: ', results);

    await setupPageStub(searchResultsBodyStructure);

    let mainDiv = $('#mainDiv');
    mainDiv.addClass(gCommon.mainDivClasses);
    moveContentByIdTo("mainRow", mainDiv);

    let count = getAllElseResultsCount(results);

    emitSearchResultCountAndBackTo(results, 'searchForm.html', 'Modify Search', count);
    emitAllElseRhs(results, pagination);

    emitResults(results);

    pagination.emitPagingRow($('#resultsDiv'),
        "pt-1 ms-1 me-1 bordersRow",
        results);
}
function getAllElseResultsCount(results) {
    let filters = results.Filters;
    let desiredFilterName = results.SearchQuery[gSearch.currentFilterKey];
    let desiredFilter = filters.find((f) => f.label == desiredFilterName);
    let result = desiredFilter.count;
    return result;
}
function emitResults(results) {
    let target = $('#resultsDiv');
    target.empty();

    let colspecs = [
        newColumnSpec(`${gCommon.cols8or12} bordE `),
        newColumnSpec(`${gCommon.cols2or12} bordE t-center`),
        newColumnSpec(`${gCommon.cols2or12} pe-0 `)];

    emitAllElseResultsHeader(colspecs, target);
    emitAllElseDataRows(results, colspecs, target);
}
function emitAllElseRhs(results, pagination) {
    let target = gSearch.rhsDiv;
    let titleDiv = $('<div class="mb-1"></div>');
    target.empty();
    target.append(titleDiv);
    titleDiv.append(spanify('Search Criteria', 'bold mb-4'));

    addIfPresent(results.SearchQuery.Keyword, target);

    target.append($('<hr class="tightHr"/>'));

    showAllElseFilters(target, results, pagination);

    target.append($('<hr class="tightHr"/>'));

    divSpanifyTo('Click "Why?" to see why a person matched the search.',
                        target, 'fs12');
}
function showAllElseFilters(target, results) {
    let filters = results.Filters;
    divSpanifyTo('Filter By Type', target, 'bold');

    let allFilter = filters.filter(f => f.label == gSearch.allFilterLabel);
    let otherFilters = filters.filter(f => f.label !== gSearch.allFilterLabel);
    let orderedFilters = allFilter.concat(otherFilters);
    for (let i=0; i<orderedFilters.length; i++) {
        let filter = orderedFilters[i];

        let klass;
        let span = spanify(filter.label + ` (${filter.count})`);

        if (filter.label == fromResultsOrInit(
            results,
            ['SearchQuery', gSearch.currentFilterKey],
            gSearch.defaultFilterLabel)) {
            klass = "greyFilter bold fs12";
        }
        else {
            klass = "link-ish fs12";
            span.on('click', function() {
                let selections = results.SearchQuery;
                initializePagingValues(selections, gPage.defaultPageSize, 0);
                filterSearch(filter.type, filter.label, results);
            });
        }

        let div = $(`<div class="${klass}"></div>`);
        div.append(span);
        target.append(div)
    }
}
function redoAllElseSearch(results, url) {
    searchPost(
        url,
        gSearch.allElsePrefix,
        results.SearchQuery,
        "searchAllElseResults.html");
}
function filterSearch(type, label, results) {
    gPage.searchUrl  = gImpl + `?filterType=${type}`;
    addUpdateResultsSearchQuery(results, gSearch.currentFilterKey, label);

    redoAllElseSearch(results, gPage.searchUrl);
}
function emitAllElseResultsHeader(colspecs, target) {
    let rowId = `allElseResultsHeader`;

    let row = makeRowWithColumns(target, rowId, colspecs,  "bordersRow mt-2");

    row.find(`#${rowId}Col0`).append(spanify('Match', ' bold'));
    row.find(`#${rowId}Col1`).append(spanify('Type', ' bold'));
    row.find(`#${rowId}Col2`).append(spanify('Why', ' bold'));
}

function emitAllElseDataRows(results, colspecs, target) {
    let items = reverseSortArrayByWeight(results.Results);

    if (items) {
        for (let i = 0; i < items.length; i++) {
            let item = items[i];

            let rowId = `allElseResults${i}`;
            let row = makeRowWithColumns(target, rowId, colspecs, "bordersRow bordE");

            let whyAnchor = createWhyLink(item, results);
            row.find(`#${rowId}Col0`).html(item.Label);
            row.find(`#${rowId}Col1`).html(item.ClassLabel);
            row.find(`#${rowId}Col2`).append(whyAnchor);

            hoverLight(row);
        }
    }
}

