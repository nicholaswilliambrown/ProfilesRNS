function adjustChosenSort(results) {
    let currentFlavor = results.SearchQuery.Sort;
    let flavoredLi = $(`li[value="${currentFlavor}"]`);
    if ( ! flavoredLi.is(':visible')) {
        addUpdateSearchQueryKey(results, 'Sort', gSearch.defaultPeopleSort);
    }
}

function setupShowDropdown(results) {
    $(`.li-show`).on('click', clickLiShow);
    $(`.li-show input`).on('click', function(e) { clickInnerCheckbox(e, results); });

    let selected = fromResultsOrInit(
        results,
        ['SearchQuery', gSearch.selectedOptionalPeopleShowsKey],
        gSearch.initialOptionalPeopleShows);

    if (selected.length == 0) {
        adjustShowChoicesHeader(results);
    }
    else {
        selected.forEach((s) => {
            let elt = $(`.li-item input[value="${s}"]`);
            elt.click();
        });
    }

    $(`#showDropdown`).on('click', function() {
        $('.li-sort').hide();
        $('.li-show').toggle();

        if ($('.li-show:visible').length == 0) {
            adjustChosenSort(results);
            installSelectedShows(results);

            redoPeopleSearch(results);
        }
    });
}
function installSelectedShows(results) {
    let selected = harvestCheckedOptions('showCheck');
    addUpdateSearchQueryKey(results, gSearch.selectedOptionalPeopleShowsKey, selected);
}
function setupDropdownsAndInitialSelections() {
    let results = gSearch.searchPeopleResults;

    setupShowDropdown(results);

    let searchQuery = results.SearchQuery;
    let sortFlavor = searchQuery.Sort;
    let flavoredSortItem = $(`.li-sort[value="${sortFlavor}"]`);

    flavoredSortItem.addClass('selected');
    let selectedText = flavoredSortItem.html();

    let chosenSort = $('#sortDropdown').find('.theChosen');
    chosenSort.html(selectedText);

    syncSortOptionsToShownHeaders(results);

    $(`#sortDropdown`).on('click', function(e) {
        let target = $(e.target); // for debugging
        if ($('.li-show:visible').length > 0) { // need to harvest the show selections and redo
            adjustChosenSort(results);
            installSelectedShows(results);
            redoPeopleSearch(results);
        }

        $('.li-sort').toggle();
        $(`.li-sort[${gSearch.omitOptionalColumnSt}="${gSearch.omitOptionalColumnSt}"]`).hide();
    });

   $(`.li-sort`).on('click', function(e) { liSortClick(e, results); });
}
function liSortClick(e, results) {
    let target = $(e.target);

    let correspondingHeaderId = target.attr('name');
    let flavor = target.attr('value');
    addUpdateSearchQueryKey(results, 'Sort', flavor);

    let direction= gSearch.ascendingSt;
    if (flavor.match(gSearch.descendingValReSt)) {
        direction = gSearch.descendingSt;
    }

    let sortDisplayInfo = { headerId: correspondingHeaderId, direction: direction};
    addUpdateSearchQueryKey(results, gSearch.sortPeopleIconInfoKey, sortDisplayInfo);

    redoPeopleSearch(results);
}
function redoPeopleSearch(searchResults) {
    searchPost(
        gSearch.findPeopleUrl,
        gSearch.peoplePrefix,
        searchResults.SearchQuery,
        "searchPeopleResults.html");
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

    let target = $('#showDropdown').find('.theChosen');
    target.html(selectedSt);
}
function syncSortOptionsToShownHeaders(results) {
    $(`li.optional`).attr(gSearch.omitOptionalColumnSt, gSearch.omitOptionalColumnSt);
    let optionalShows = fromResultsOrInit(
        results,
        ['SearchQuery', gSearch.selectedOptionalPeopleShowsKey],
        gSearch.initialOptionalPeopleShows);
    optionalShows.forEach(s => {
        $(`li[name="${s}"]`).removeAttr(gSearch.omitOptionalColumnSt);
    });
}
function clickLiShow(e) {
    let target = $(e.target);
    e.stopPropagation();

    let checkbox = target.find('input');
    checkbox.click();
}
function clickInnerCheckbox(e, results) {
    let target = $(e.target);
    e.stopPropagation();

    target.parent().toggleClass('selected');
    adjustShowChoicesHeader(results);
}

