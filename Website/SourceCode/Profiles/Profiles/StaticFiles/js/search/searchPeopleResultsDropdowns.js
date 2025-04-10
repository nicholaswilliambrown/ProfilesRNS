function setupDropdownsDisplay() {
    $('body').on('click', function() {
        hideBothDropdowns();
    });
}
function setupDropdownsAndInitialSelections(results) {
    setupShowDropdown(results);
    setupSortDropdown(results);

    $(`.li-sort`).on('click', function(e) {
        clickLiSort(e, results);
    });
}
function setupDropdownControllers() {
    // customize position of controlled dropdowns
    $('.ulDiv ul').css('top', '32px');

    let allUlProxies = $('.proxyDd');

    allUlProxies.on('click', function(e) {
        e.stopPropagation();
        let thisOne = $(this);

        let thisUlId = thisOne.attr('dd');
        let thisUl = $(`#${thisUlId}`);
        let otherUlId = thisOne.attr('other');
        let otherUl = $(`#${otherUlId}`);

        if (otherUl.is(':visible')) {
            resultsDdHide(otherUl);
        }
        resultsDdToggle(thisUl);
    });
}
function getDdId(dd) {
    let id = dd.attr('id');
    return id;
}
function resultsDdToggle(dd) {
    if (dd.is(':visible')) {
        resultsDdHide(dd);
    }
    else {
        resultsDdShow(dd);
    }
}
function hideBothDropdowns() {
    $('.ulDropdown').each( function() { resultsDdHide($(this)); } );
}
function resultsDdShow(dd) {
    dd.removeClass('d-none');
    dd.show();
}
function resultsDdHide(dd) {
    if (dd.is(':visible')) {
        dd.hide();
        if (getDdId(dd) == 'showDropdown') {
            applyShowsFromDropdown(); // this may redo search
        }
    }
}
function updateSearchWithShows(results) {
    let selected = harvestCheckedOptions('showCheck').sort();
    addUpdateSearchQueryKey(results, gSearch.selectedOptionalPeopleShowsKey, selected);
    return selected;
}
function setupShowDropdown(results) {
    $(`.li-show`).on('click', clickLiShow);

    let selected = fromResultsOrInit(
        results,
        ['SearchQuery', gSearch.selectedOptionalPeopleShowsKey],
        gSearch.defaultOptionalPeopleShows);

    gSearch.initialShowSelected = selected.sort();

    if (selected.length == 0) {
        adjustShowChoicesHeader(results);
    }
    else {
        selected.forEach((s) => {
            let elt = $(`.li-item input[value="${s}"]`);
            elt.click();
        });
    }
}
function setupSortDropdown(results) {
    let searchQuery = results.SearchQuery;
    let sortFlavor = searchQuery.Sort;

    gSearch.initialSortFlavor = sortFlavor;

    let flavoredSortItem = $(`.li-sort[value="${sortFlavor}"]`);

    flavoredSortItem.addClass('selected');
    let selectedText = flavoredSortItem.html();
    $('#sortButton').html(selectedText);

    syncSortOptionsToShownHeaders(results);
}
function applyShowsFromDropdown() {
    let selected = updateSearchWithShows(gSearch.results);

    if (JSON.stringify(selected) != JSON.stringify(gSearch.initialShowSelected)) {
        redoPeopleSearch(gSearch.results);
    }
}
function redoPeopleSearch(searchResults) {
    searchPost(
        gSearch.findPeopleUrl,
        gSearch.people,
        searchResults.SearchQuery,
        gSearch.peopleResultsUrl);
}
function adjustShowChoicesHeader(results) {
    let selected = harvestCheckedOptions('showCheck');
    addUpdateSearchQueryKey(results, gSearch.selectedOptionalPeopleShowsKey, selected);

    let howMany = selected.length;
    let selectedSt = gSearch.selectedSt;

    if (howMany == 0) {
        selectedSt = gSearch.noneSt + selectedSt;
    }
    else if (howMany == 3) {
        selectedSt = `All ${selectedSt} (${howMany})`;
    }
    else {
        selectedSt = selected.map(n => gSearch.peopleResultDisplay[n]).join(",");
    }

    let comparison = $('#showDropdown').find('.initial');
    selectedSt = ellipsizeToFit(selectedSt, comparison, $('#dropDownMarker').width());

    let target = $('#showButton');
    target.html(selectedSt);
}
function syncSortOptionsToShownHeaders(results) {
    $(`li.optional`).attr(gSearch.omitOptionalColumnSt, gSearch.omitOptionalColumnSt);
    let optionalShows = fromResultsOrInit(
        results,
        ['SearchQuery', gSearch.selectedOptionalPeopleShowsKey],
        gSearch.defaultOptionalPeopleShows);

    optionalShows.forEach(s => {
        $(`li[name="${s}"]`).removeAttr(gSearch.omitOptionalColumnSt);
    });
    $(`li[${gSearch.omitOptionalColumnSt}]`).addClass('d-none');
}
function clickLiSort(e, results) {
    let target = $(e.target);

    let correspondingHeaderId = target.attr('name');
    let flavor = target.attr('value');
    addUpdateSearchQueryKey(results, 'Sort', flavor);

    let direction = gSearch.ascendingSt;
    if (flavor.match(gSearch.descendingValReSt)) {
        direction = gSearch.descendingSt;
    }

    let sortDisplayInfo = { headerId: correspondingHeaderId, direction: direction};
    addUpdateSearchQueryKey(results, gSearch.sortPeopleIconInfoKey, sortDisplayInfo);

    if (flavor != gSearch.initialSortFlavor) {
        redoPeopleSearch(results);
    }
}
function clickLiShow(e) {
    e.stopPropagation(); // body click aggressively reload

    let target = $(e.target);
    target.toggleClass('selected');

    let checkbox = target.find('input');
    checkbox.click();

    adjustShowChoicesHeader(gSearch.results);
}

