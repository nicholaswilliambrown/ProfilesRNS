function searchPost(url, prefix, selections, resultPage) {
    console.log("Searching: ", selections);
    let stringCriteria = JSON.stringify(selections);

    console.log('--------stringCriteria for post----------');
    console.log(stringCriteria);

    $.post(url, stringCriteria, function(results) {
        if (results.constructor === Array
            && results.length == 1
            && results[0].ErrorMessage !== gCommon.undefined) {

            console.log(`Error message from back-end: "${results[0].ErrorMessage}"
                    \nFrom Post of: 
                    <${stringCriteria}>`);
        }
        else {
            let stringResults = JSON.stringify(results);
            let resultsKey = makeSearchResultsKey(prefix);
            // https://stackoverflow.com/questions/13734893/javascript-how-do-i-open-a-new-page-and-pass-json-data-to-it
            toSession(resultsKey, stringResults);
            window.location.href = resultPage;
        }
    });
}function searchBodyStructure() {
    let lhsDiv = $('#lhsDiv');
    gSearch.lhsDiv = lhsDiv;

    let midDiv = $('#midDiv');
    let outerRhs = $('#rhsDiv');
    gSearch.rhsDiv = outerRhs;

    lhsDiv.addClass("col-12 col-sm-12 col-md-2 col-lg-2 col-xl-2 col-xxl-2 ");
    midDiv.addClass("col-12 col-sm-12 col-md-8 col-lg-8 col-xl-8 col-xxl-8 ");
    outerRhs.addClass("col-12 col-sm-12 col-md-2 col-lg-2 col-xl-2 col-xxl-2 ps-1");

    let innerRhsDiv = $('<div id="innerRhsDiv" class="p-2"></div>');
    outerRhs.append(innerRhsDiv);
}
function searchResultsBodyStructure() {
    let midDiv = $('#midDiv');
    let outerRhs = $('#rhsDiv');
    gSearch.rhsDiv = outerRhs;

    midDiv.addClass("col-12 col-sm-12 col-md-10 col-lg-10 col-xl-10 col-xxl-10 ");
    outerRhs.addClass("col-12 col-sm-12 col-md-2 col-lg-2 col-xl-2 col-xxl-2 ps-1 pe-0");

    let innerRhsDiv = $('<div id="innerRhsDiv" class="p-2"></div>');
    outerRhs.append(innerRhsDiv);
    let innerRhsDiv2 = $('<div id="innerRhsDiv2" class="p-2 fs12"></div>');
    gSearch.rhsDiv2 = innerRhsDiv2;
    outerRhs.append(innerRhsDiv2);
}
function hideLiItems() {
    $('.li-item').hide();
}
function harvestCheckedOptions(prefix) {
    let result = [];

    let elts = $(`.${prefix}`); // prefix also used as class
    elts.each((i,c) =>
    {
        if ($(c).is(':checked')) {
            result.push($(c).attr('value'));
        }
    } );

    return result;
}
function fromResultsOrInit(results, pathKeys, init) {
    let candidate;

    if (typeof results !== 'undefined') {
        candidate = results;
        for (let i=0; i<pathKeys.length; i++) {
            let key = pathKeys[i];
            if ( typeof candidate[key] === 'undefined') {
                candidate = init;
                break;
            }
            candidate = candidate[key];
        }
    }
    return candidate;
}
function addUpdateSearchQueryKey(results, key, value) {
    addUpdateSearchQuery(results.SearchQuery, key, value);
}
function addUpdateSearchQuery(searchQuery, key, value) {
    searchQuery[key] = value;
}
function collectMiscInitialPeopleSelections(selections) {
    // misc addition: foreshadowing sorting
    selections.Sort = "relevance";
    selections.SearchType = gSearch.people;
    initializePagingValues(selections, gPage.defaultPageSize, 1);
}
function initializePagingValues(selections, size, offset1) {
    selections.Count = size;
    selections.Offset = offset1;
}
function createWhyLink(item, results) {
    let whySpan = spanify('Why?', 'link-ish');
    whySpan.on('click', function() {
        searchWhy(item, results);
    })
    return whySpan;
}
function searchWhy(item, results) {
    let whyUrl = gSearch.whyUrl;
    let searchQuery = results.SearchQuery;
    searchQuery.NodeID = item.NodeID;

    searchPost(
        whyUrl,
        'Why',
        searchQuery,
        'searchWhyResults.html'
        );
}

function makeSearchResultsKey(prefix) {
    return `search${initialCapital(prefix)}ResultsKey`;
}
function minimalPeopleSearch(term) {
    let selections = {};
    selections.Keyword = term;
    selections.LastName = "";
    selections.FirstName = "";
    selections.InstitutionName = "";
    selections.DepartmentName = "";
    selections.FacultyTypeName = "";
    selections.OtherOptionsName = [];

    selections.KeywordExact = false;
    selections.DepartmentExcept = false;
    selections.InstitutionExcept = false;

    collectMiscInitialPeopleSelections(selections);

    searchPost(
        gSearch.findPeopleUrl,
        gSearch.people,
        selections,
        "searchPeopleResults.html");
}
function emitCriteriaOnRhs(results, withWhy) {
    let target = $('#innerRhsDiv');

    let titleDiv = $('<div class="mb-1"></div>');
    target.empty();
    target.append(titleDiv);
    titleDiv.append(spanify('Search Criteria', 'bold mb-4'));

    addIfPresent(results.SearchQuery.Keyword, target);
    addIfPresent(results.SearchQuery.LastName, target);
    addIfPresent(results.SearchQuery.FirstName, target);
    addIfPresent(results.SearchQuery.InstitutionName, target);
    addIfPresent(results.SearchQuery.DepartmentName, target);
    addIfPresent(results.SearchQuery.FacultyTypeName, target);
    addIfPresent(results.SearchQuery.OtherOptionsName, target);

    if (withWhy) {
        target.append($('<hr class="tightHr"/>'));
        divSpanifyTo('Click "Why?" to see why a person matched the search.',
            target, 'fs12');
    }
}
function emitSearchResultCountAndBackTo(results, url, backText, count) {
    let target = $('#midDiv');
    url = gBrandingConstants.htmlFiles + url;

    let countDetail = (typeof count !== gCommon.undefined) ? ` (${count})` : "";
    // calling title a row adds the negative 12 margin
    let title = $(`<h2 class="row boldCrimson">Search Results Details${countDetail}</h2>`);

    let backToArrow = $(`<img src="${gBrandingConstants.jsSearchImageFiles}arrowLeft.png" class="me-1"/>`);
    let backTo = createAnchorElement(backText, url);
    let backToDiv = $('<div class="d-flex justify-content-end"></div>');
    backToDiv.append(backToArrow).append(backTo);
    target.prepend(backToDiv);
    target.prepend(title);
}
function addIfPresent(text, target, klass) {
    if (typeof text !== gCommon.undefined && text) {
        divSpanifyTo(text, target, klass);
    }
}
function activityUrlFromSchema(urlSchema, desiredCount, lastId) {
    let result = urlSchema
        .replace(gCommon.schemaPlaceholder, desiredCount)
        .replace(gCommon.schemaPlaceholder2, lastId);
    return result;
}
