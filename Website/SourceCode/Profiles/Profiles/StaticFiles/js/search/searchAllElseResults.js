
async function setupSearchAllElseResults() {
    await setupPageStub(searchResultsBodyStructure);

    let specificContent = $('#searchPageMarkup');
    innerCurtainsDown(specificContent);

    let pagination = new Paging(
        redoAllElseSearch,
        gSearch.findEverythingElseUrl,
        getAllElseResultsCount,
        gPage.sizes);

    let resultsAsString = fromSession(makeSearchResultsKey(gSearch.allElse));
    let results = JSON.parse(resultsAsString);

    if (!results || !results.SearchQuery) { // sanity check
        alert(`Error with search results: ${resultsAsString}`);
    }


    console.log('Results: ', results);

    let mainDiv = $('#mainDiv');
    mainDiv.addClass(gCommon.mainDivClasses);
    moveContentByIdTo("searchPageMarkup", mainDiv);

    let count = getAllElseResultsCount(results);

    emitSearchResultCountAndRelatedLinks(
        results,
        `${gSearch.searchForm}/${gSearch.allElse}`,
        'Modify Search',
        count,
        'resultsDiv');
    if (count == 0) {
        $("#midDivInner").html("<div id='resultsDiv'></div>");
        $('#resultsDiv').html("<b>No matching results.</b>");
    } else {
        emitAllElseRhs(results, pagination);

        await emitResults(results);

        pagination.emitPagingRow($('#resultsDiv'),
            "pt-1 ms-1 me-1 borderOneSolid tableHeaderPagingRow",
            results);
    }
    innerCurtainsUp(specificContent);
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
    let titleDiv = $('<div class="mb-1 panelPassiveSearchCriteria"></div>');
    target.empty();
    target.append(titleDiv);
    titleDiv.append(spanify('Search Criteria', 'bold mb-4 '));

    addIfPresent({
        text: results.SearchQuery.Keyword,
        target: target,
        noBreak: 'noBreak'
    });

    target.append($('<hr class="tightHr"/>'));

    showAllElseFilters(target, results, pagination);

    target.append($('<hr class="tightHr"/>'));

    divSpanifyTo('Click "Why?" to see why a person matched the search.',
        target, 'fs12');
}
function showAllElseFilters(target, results) {
    let filters = results.Filters;
    divSpanifyTo('Filter by Type', target, 'bold');

    let allFilter = filters.filter(f => f.label == gSearch.allFilterLabel);
    let otherFilters = filters.filter(f => f.label !== gSearch.allFilterLabel);
    let orderedFilters = allFilter.concat(otherFilters);
    for (let i = 0; i < orderedFilters.length; i++) {
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
            span.on('click', function () {
                let selections = results.SearchQuery;
                initializePagingValues(selections, gPage.defaultPageSize, 1);
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
        gSearch.allElse,
        results.SearchQuery,
        gSearch.everythingElseResultsUrl);
}
function filterSearch(type, label, results) {
    let searchUrl = gSearch.findEverythingElseUrl + `&filterType=${type}`;
    addUpdateSearchQueryKey(results, gSearch.currentFilterKey, label);

    redoAllElseSearch(results, searchUrl);
}
function emitAllElseResultsHeader(colspecs, target) {
    let rowId = `allElseResultsHeader`;

    let row = makeRowWithColumns(target, rowId, colspecs, "borderOneSolid mt-2 tableHeaderPagingRow");

    row.find(`#${rowId}Col0`).append(spanify('Match', ' bold'));
    row.find(`#${rowId}Col1`).append(spanify('Type', ' bold'));
    row.find(`#${rowId}Col2`).append(spanify('Why', ' bold'));
}

function emitAllElseDataRows(results, colspecs, target) {
    if (results && results.Results) {
        let items = reverseSortArrayByWeight(results.Results);
        let backgroundColor = "tableOddRowColor";
        for (let i = 0; i < items.length; i++) {
            let item = items[i];

            let rowId = `allElseResults${i}`;
            if (i % 2) {
                backgroundColor = "tableOddRowColor";
            } else {
                backgroundColor = "";
            }
            let row = makeRowWithColumns(target, rowId, colspecs, "borderOneSolid bordE " + backgroundColor);

            let whyAnchor = createWhyLink(item, results);
            let labelAnchor = createAnchorElement(item.ClassLabel, item.URL, backgroundColor);

            row.find(`#${rowId}Col0`).append(item.Label);
            row.find(`#${rowId}Col1`).html(labelAnchor);
            row.find(`#${rowId}Col2`).append(whyAnchor);

            hoverLight(row);
        }
    }
}
