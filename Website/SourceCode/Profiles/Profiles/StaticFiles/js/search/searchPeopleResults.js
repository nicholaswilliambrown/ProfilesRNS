
async function setupSearchPeopleResults() {
    await setupPageStub(searchResultsBodyStructure);

    let resultsAsString = fromSession(makeSearchResultsKey(gSearch.people));
    let results = JSON.parse(resultsAsString);
    gSearch.results = results;

    let specificContent = $('#searchPageMarkup');
    //innerCurtainsDown(specificContent);

    let pagination = new Paging(
        redoPeopleSearch,
        gSearch.findPeopleUrl,
        getPeopleResultsCount,
        gPage.sizes);

    if (!results || !results.SearchQuery) { // sanity check
        alert(`Error with search results: ${resultsAsString}`);
    }
    console.log('Results: ', results);

    let mainDiv = $('#mainDiv');
    mainDiv.addClass(gCommon.mainDivClasses);
    moveContentByIdTo("searchPageMarkup", mainDiv);

    // not all usages of the below use 'count' from results
    emitSearchResultCountAndRelatedLinks(
        results,
        `${gSearch.searchForm}/${gSearch.people}`,
        'Modify Search',
        results.Count,
        'dropdownsDiv');

    setupDropdownControllers();

    if (results.Count) {
        setupDropdownsAndInitialSelections(results);
    }
    else {
        $('#dropdownsDiv').hide();
    }

    let keyword = results.SearchQuery.Keyword;
    emitCriteriaOnRhs(results, keyword);

    if (results.Count == 0) {
        let midInner = $("#midDivInner");
        let noResultsDiv = $(`<div class='ps-0'><b>No matching results.</b></div>`);
        midInner.append(noResultsDiv);

        let searchQuery = results.SearchQuery;
        if (searchQuery.SearchType == gSearch.people && searchQuery.Keyword) {
            let url = `${gSearch.otherInstitutions}&${searchQuery.Keyword}`;
            emitLinkTo(midInner, 'Search Other Institutions', url);
        }

    }
    else {
        // leave enough room that few results can display hover without changing table height
        $('#resultsDiv').css('min-height', '250px');
        await emitPeopleResults(results);

        pagination.emitPagingRow($('#resultsDiv'),
            "pt-1 ms-1 me-1 borderOneSolid tableHeaderPagingRow",
            results);

        assembleSearchOtherLink(results);
    }
    innerCurtainsUp(specificContent);
}
function getPeopleResultsCount(results) {
    let result = results.Count ? results.Count : 0;
    return result;
}
function emitPeopleResults(results) {
    let target = $('#resultsDiv');
    target.empty();

    let optionalShows = fromResultsOrInit(
        results,
        ['SearchQuery', gSearch.selectedOptionalPeopleShowsKey],
        gSearch.defaultOptionalPeopleShows);

    let keyword = results.SearchQuery.Keyword;
    let colspecs = makePpleSearchResultsColspecs(optionalShows, keyword);
    emitPeopleResultsHeader(results, optionalShows, colspecs, target, keyword);
    emitPeopleDataRows(results, optionalShows, colspecs, target, keyword);
}
// Redraw the table with only the given optional columns, from the data already loaded
// (no new search), leaving the paging row and other content below it in place.
// Used when a column is unticked under Show, before Apply Filters.
function redisplayPeopleColumns(results, optionalShows) {
    let target = $('#resultsDiv');
    target.children('[id^="peopleResults"]').remove(); // header row and data rows

    let keyword = results.SearchQuery.Keyword;
    let colspecs = makePpleSearchResultsColspecs(optionalShows, keyword);
    let fresh = $('<div></div>');
    emitPeopleResultsHeader(results, optionalShows, colspecs, fresh, keyword);
    emitPeopleDataRows(results, optionalShows, colspecs, fresh, keyword);
    target.prepend(fresh.children());
}
function assembleSearchOtherLink(results) {
    let target = $('#resultsDiv');
    let keyword = results.SearchQuery.Keyword;

    if (keyword &&
        !results.SearchQuery.FirstName &&
        !results.SearchQuery.LastName) {

        let directUrl = `${g.directLink}?keyword=${keyword}&searchtype=people`;
        let searchArrow = $(`<img src="${gBrandingConstants.jsSearchImageFiles}arrowRight.png" 
                                 alt="arrowRight" class="me-1"/>`);
        let searchOtherA = createAnchorElement('Search Other Institutions', directUrl);
        let searchOtherSpan = $('<span class="mt-2 d-flex justify-content-end"></span>');

        target.append(searchOtherSpan);
        searchOtherSpan.append(searchArrow)
            .append(searchOtherA);
    }
}
function emitPeopleResultsHeader(results, optionalShows, colspecs, target, keyword) {
    let rowId = `peopleResultsHeader`;
    let row = makeRowWithColumns(target, rowId, colspecs, "borderOneSolid mt-2 tableHeaderPagingRow");

    let sortIconInfo = results.SearchQuery[gSearch.sortPeopleIconInfoKey]; // { headerId, direction}

    // always 1st is Name and last is Why, middle columns can vary.
    // All columns except Why are sortable: each header is a <button> (keyboard reachable),
    // holding its label and the triangle shown for the current sort.
    let sortableColumns = ['DisplayName', ...optionalShows];
    for (let i = 0; i < sortableColumns.length; i++) {
        let columnName = sortableColumns[i];
        let column = row.find(`#${rowId}Col${i}`);
        column.attr(gSearch.columnNameSt, columnName);
        column.append(makeSortHeaderButton(columnName, sortIconInfo));
    }
    if (keyword) {
        row.find(`#${rowId}Col${colspecs.length - 1}`).append(spanify('Why', ' bold'));
    }

    row.find(`button.${gSearch.sortableSt}`).on('click', syncSortDropdownToHeaders);
}
function makeSortHeaderButton(columnName, sortIconInfo) {
    // peopleResultDisplay values may hold entities (Faculty&nbsp;Rank), hence html
    let button = $(`<button type="button" class="${gSearch.sortableSt} sortHeaderButton bold"></button>`);
    button.append(spanify(gSearch.peopleResultDisplay[columnName]));

    // the triangles are decorative (alt=""); the current sort is spoken via the hidden text
    let ascIcon = spanify(
        `<img src="${gBrandingConstants.jsSearchImageFiles}sort_asc.gif" alt="">`,
        `${gSearch.sortDisplaySt} ${gSearch.ascendingSt}`);
    let descIcon = spanify(
        `<img src="${gBrandingConstants.jsSearchImageFiles}sort_desc.gif" alt="">`,
        `${gSearch.sortDisplaySt} ${gSearch.descendingSt}`);
    ascIcon.hide();
    descIcon.hide();
    button.append(ascIcon).append(descIcon);

    if (sortIconInfo && sortIconInfo.headerId == columnName) {
        let ascending = sortIconInfo.direction == gSearch.ascendingSt;
        (ascending ? ascIcon : descIcon).show();
        button.append(spanify(`, sorted ${ascending ? 'ascending' : 'descending'}`, 'visually-hidden'));
    }
    return button;
}
function emitPeopleDataRows(results, optionalShows, colspecs, target, keyword) {
    let items = sortArrayViaSortLabel(results.People, "SortOrder");
    if (items && items.length > 0) {
        let backgroundColor = "tableOddRowColor";
        for (let i = 0; i < items.length; i++) {
            let item = items[i];

            let rowId = `peopleResults${i}`;
            if (i % 2) {
                backgroundColor = "tableOddRowColor";
            } else {
                backgroundColor = "";
            }


            let row = makeRowWithColumns(target, rowId, colspecs, "borderOneSolid bordE " + backgroundColor);

            // always 1st is Name and last is Why, middle columns can vary
            let column = row.find(`#${rowId}Col0`);
            column.append(createAnchorElement(item.DisplayName, item.URL, backgroundColor));

            for (let i = 0; i < optionalShows.length; i++) {
                let show = optionalShows[i];
                column = row.find(`#${rowId}Col${i + 1}`);
                column.append(spanify(item[show]));
            }

            if (keyword) {
                column = row.find(`#${rowId}Col${colspecs.length - 1}`);
                column.append(createWhyLink(item, results));
            }

            let rhsPreview = () => previewPerson(item);
            let hidePreview = () => {
                gSearch.rhsDiv2.remove();
            }
            hoverLight(row, rhsPreview, hidePreview);
        }
    }
}
function previewPerson(item) {
    let target = $('<div id="innerRhsDiv2" class="p-2 fs12"></div>');
    gSearch.outerRhs.append(target);
    gSearch.rhsDiv2 = target;

    addIfPresent({text: item.FirstLastName,     target: target, klass: 'bold'}); // in prod, is it in our json?
    addIfPresent({text: item.DisplayName,       target: target, klass: 'bold'});
    addIfPresent({text: item.FacultyRank,       target: target});
    addIfPresent({text: item.InstitutionName,   target: target});
    addIfPresent({text: item.DepartmentName,    target: target});
}
function syncSortDropdownToHeaders(e) {
    e.stopPropagation();

    let header = $(e.currentTarget).closest(`[${gSearch.columnNameSt}]`);
    let columnName = header.attr(gSearch.columnNameSt);

    let newSortDirection = gSearch.ascendingSt;
    let currentVisibleSortable = header.find(`.${gSearch.sortDisplaySt}:visible`);
    if (currentVisibleSortable.length > 0 && currentVisibleSortable.hasClass(gSearch.ascendingSt)) {
        newSortDirection = gSearch.descendingSt;
    }

    sortByColumn(columnName, newSortDirection);
}
function makePpleSearchResultsColspecs(optionalShows, keyword) {
    let numOptShows = optionalShows.length;
    let columnWidths, classRef;

    if (keyword) {
        switch (numOptShows) {
            case 0:
                columnWidths = { first: 8, last: 4 };
                break;
            case 1:
                columnWidths = { first: 5, mid: 5, last: 2 };
                break;
            case 2:
                columnWidths = { first: 3, mid: 3, last: 2 };
                break;
            case 3:
                columnWidths = { first: 3, mid: 2, last: 2 };
                break;
        }
    }
    else {
        switch (numOptShows) {
            case 0:
                columnWidths = { first: 12 };
                break;
            case 1:
                columnWidths = { first: 6, mid: 6 };
                break;
            case 2:
                columnWidths = { first: 4, mid: 4 };
                break;
            case 3:
                columnWidths = { first: 3, mid: 3 };
                break;
        }
    }

    classRef = `cols${columnWidths.first}or12`;
    let colSmall = "colSmall";    
    let colspecs = [newColumnSpec(` pt-1 pb-1 bordE colSmall ${gCommon[classRef]}`)];
    let bordE = "bordE";
    
    for (let i = 0; i < optionalShows.length; i++) {
        classRef = `cols${columnWidths.mid}or12`;
        if (!keyword) {
            bordE = (i == (optionalShows.length-1) ? "" : bordE)
        }
        else { bordE = (i == (optionalShows.length) ? "" : bordE) }
        colSmall = "colSmall" + i;
        colspecs.push(newColumnSpec(` pt-1 pb-1 ${bordE} ${colSmall} ${gCommon[classRef]}`));
    }

    if (keyword) {
        classRef = `cols${columnWidths.last}or12`;
        colSmall = `colSmall${optionalShows.length}`;
        colspecs.push(newColumnSpec(` pt-1 pb-1 t-center ${colSmall} ${gCommon[classRef]}`));
    }

    return colspecs;
}

