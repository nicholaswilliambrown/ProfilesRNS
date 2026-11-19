// Sort and Show on the people search results page (a11y): Sort is a native <select>, and Show is
// a disclosure button with a group of labelled checkboxes. Neither acts on change: re-running the
// search is a new page load, so both wait for the Apply Filters button.

function setupDropdownControllers() {
    let showButton = $('#showButton');
    setupFilterToggle(showButton, $('#showGroup'), $('#showUlDiv'));
    closeFilterGroupsOnOutsideClick();

    // ticking a column updates the button's summary, and offers sorting by it right away;
    // unticking a displayed column hides it at once (ticking it again brings it back)
    $('.showCheck').on('change', function() {
        let selected = harvestCheckedOptions('showCheck');
        showShownColumnsSummary(selected);
        syncSortOptionsToColumns(selected);
        hideUntickedColumns(selected);
    });

    $('#applyFiltersButton').on('click', function() {
        applyFilters(gSearch.results);
    });
}
function setupDropdownsAndInitialSelections(results) {
    setupShowDropdown(results);
    setupSortDropdown(results);
}
function getShownOptionalColumns(results) {
    return fromResultsOrInit(
        results,
        ['SearchQuery', gSearch.selectedOptionalPeopleShowsKey],
        gSearch.defaultOptionalPeopleShows);
}

// ---------- Show ----------
function setupShowDropdown(results) {
    let selected = getShownOptionalColumns(results);
    gSearch.initialShowSelected = [...selected].sort();
    gSearch.displayedColumns = [...selected];

    $('.showCheck').each(function() {
        this.checked = gSearch.initialShowSelected.includes(this.value);
    });
    showShownColumnsSummary(gSearch.initialShowSelected);
}
// Columns that came with the results can be hidden and re-shown without a search;
// a column that wasn't in them still needs Apply Filters, which fetches its data.
function hideUntickedColumns(selected) {
    let displayable = getShownOptionalColumns(gSearch.results).filter(c => selected.includes(c));
    if (JSON.stringify(displayable) != JSON.stringify(gSearch.displayedColumns)) {
        gSearch.displayedColumns = displayable;
        redisplayPeopleColumns(gSearch.results, displayable);
    }
}
function showShownColumnsSummary(selected) {
    let howMany = selected.length;
    let summary;

    if (howMany == 0) {
        summary = gSearch.noneSt + gSearch.selectedSt;
    }
    else if (howMany == 3) {
        summary = `All${gSearch.selectedSt} (${howMany})`; // selectedSt starts with a space
    }
    else {
        // in the checkboxes' order (selected may be sorted alphabetically);
        // peopleResultDisplay values may hold entities (Faculty&nbsp;Rank), hence .html()
        summary = $('.showCheck').get()
            .map(c => c.value)
            .filter(v => selected.includes(v))
            .map(v => gSearch.peopleResultDisplay[v])
            .join(", ");
    }
    $('#showButton .theChosen').html(summary);
}

// ---------- Sort ----------
function setupSortDropdown(results) {
    let select = $('#sortSelect');
    let sortFlavor = results.SearchQuery.Sort;

    gSearch.initialSortFlavor = sortFlavor;
    // every option, before syncSortOptionsToColumns drops the ones for hidden columns
    gSearch.allSortOptions = select.find('option').clone();

    syncSortOptionsToColumns(getShownOptionalColumns(results));

    if (sortFlavor) {
        select.val(sortFlavor);
    }
    else {
        select.prop('selectedIndex', -1); // as before: no sort shown when the query had none
    }
}
// Offer sorting only by the given columns (those shown, or ticked under Show). Options are
// removed rather than hidden, since Safari ignores display:none / hidden on <option>.
// The selected sort is always kept, so the select still shows it.
function syncSortOptionsToColumns(optionalColumns) {
    let select = $('#sortSelect');
    let current = select.prop('selectedIndex') >= 0 ? select.val() : gSearch.initialSortFlavor;

    let kept = gSearch.allSortOptions.filter(function() {
        let option = $(this);
        return ! option.hasClass('optional')
            || optionalColumns.includes(option.attr('data-name'))
            || option.val() === current;
    });
    select.empty().append(kept.clone());

    if (current) {
        select.val(current);
    }
    else {
        select.prop('selectedIndex', -1);
    }
}

// ---------- Apply Filters ----------
// One search with both the chosen sort and the chosen columns; nothing happens if neither changed.
function applyFilters(results) {
    let changed = false;

    let selected = harvestCheckedOptions('showCheck').sort();
    if (JSON.stringify(selected) != JSON.stringify(gSearch.initialShowSelected)) {
        addUpdateSearchQueryKey(results, gSearch.selectedOptionalPeopleShowsKey, selected);
        changed = true;
    }

    let option = $('#sortSelect').find('option:selected');
    let flavor = option.val();
    if (flavor && flavor != gSearch.initialSortFlavor) {
        addUpdateSearchQueryKey(results, 'Sort', flavor);

        let direction = flavor.match(gSearch.descendingValReSt) ? gSearch.descendingSt : gSearch.ascendingSt;
        let sortDisplayInfo = { headerId: option.attr('data-name'), direction: direction};
        addUpdateSearchQueryKey(results, gSearch.sortPeopleIconInfoKey, sortDisplayInfo);
        changed = true;
    }

    if (changed) {
        closeFilterGroup($('#showButton'));
        redoPeopleSearch(results);
    }
}
// a click on a column header sorts by it right away (searchPeopleResults.js),
// along with any column changes not yet applied
function sortByColumn(columnName, direction) {
    let option = gSearch.allSortOptions
        .filter(`[data-name="${columnName}"][data-dir="${direction}"]`);
    if (option.length) {
        let select = $('#sortSelect');
        if ( ! select.find(`option[value="${option.val()}"]`).length) {
            select.append(option.clone()); // its column was unticked under Show but not yet applied
        }
        select.val(option.val());
        applyFilters(gSearch.results);
    }
}

function redoPeopleSearch(searchResults) {
    searchPost(
        gSearch.findPeopleUrl,
        gSearch.people,
        searchResults.SearchQuery,
        gSearch.peopleResultsUrl);
}
