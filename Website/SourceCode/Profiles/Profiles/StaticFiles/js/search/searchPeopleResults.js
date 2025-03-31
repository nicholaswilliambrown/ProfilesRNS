
async function setupSearchPeopleResults() {
    await setupPageStub(searchResultsBodyStructure);

    let specificContent = $('#searchPageMarkup');
    innerCurtainsDown(specificContent);

    let pagination = new Paging(
        redoPeopleSearch,
        gSearch.findPeopleUrl,
        getPeopleResultsCount,
        gPage.sizes);

    let resultsAsString = fromSession(makeSearchResultsKey(gSearch.people));
    let results = JSON.parse(resultsAsString);

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
        'sortDropdownDiv');

    $('#sortDropdownDiv').addClass(`${gCommon.cols3or12} ulDiv`);
    $('#showDropdownDiv').addClass(`${gCommon.cols3or12} ulDiv`);
    dropdownVisibilityAdjustToOverlaps();

    hideLiItems();

    if (results.Count) {
        setupDropdownsAndInitialSelections(results);
    }
    else {
        $('.peopleResultDropdown').hide();
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
        gSearch.initialOptionalPeopleShows);

    let keyword = results.SearchQuery.Keyword;
    let colspecs = makePpleSearchResultsColspecs(optionalShows, keyword);
    emitPeopleResultsHeader(results, optionalShows, colspecs, target, keyword);
    emitPeopleDataRows(results, optionalShows, colspecs, target, keyword);
}
function assembleSearchOtherLink(results) {
    let target = $('#resultsDiv');
    let keyword = results.SearchQuery.Keyword;

    if (keyword &&
        !results.SearchQuery.FirstName &&
        !results.SearchQuery.LastName) {

        let directUrl = `${g.directLink}?keyword=${keyword}&searchtype=people`;
        let searchArrow = $(`<img src="${gBrandingConstants.jsSearchImageFiles}arrowRight.png" class="me-1"/>`);
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

    // always 1st is Name and last is Why, middle columns can vary
    let column = row.find(`#${rowId}Col0`);
    column.attr(gSearch.columnNameSt, 'DisplayName');
    column.append(spanify('Name', `${gSearch.sortableSt} bold`));
    for (let i = 0; i < optionalShows.length; i++) {
        let rawShow = optionalShows[i];
        let displayShow = gSearch.peopleResultDisplay[rawShow];
        column = row.find(`#${rowId}Col${i + 1}`);
        column.attr(gSearch.columnNameSt, rawShow)
        column.append(spanify(displayShow, `${gSearch.sortableSt} bold`));
    }
    if (keyword) {
        row.find(`#${rowId}Col${colspecs.length - 1}`).append(spanify('Why', ' bold'));
    }

    let sortableHighIndex = keyword ? colspecs.length - 1 : colspecs.length;
    // all columns except Why are sortable, so can use triangle-images
    for (let i = 0; i < sortableHighIndex; i++) {
        let column = row.find(`#${rowId}Col${i}`);
        column.append(spanify(
            `<img src="${gBrandingConstants.jsSearchImageFiles}sort_asc.gif" alt="sort ${gSearch.ascendingSt}">`,
            `${gSearch.sortDisplaySt} ${gSearch.ascendingSt}`));
        column.append(spanify(
            `<img src="${gBrandingConstants.jsSearchImageFiles}sort_desc.gif" alt="sort ${gSearch.descendingSt}">`,
            `${gSearch.sortDisplaySt} ${gSearch.descendingSt}`));
    }
    row.find(`.${gSearch.sortableSt}`).parent().on('click', syncSortDropdownToHeaders);

    // initial display of header's sort arrows
    row.find(`.${gSearch.sortDisplaySt}`).hide();

    let sortIconInfo = results.SearchQuery[gSearch.sortPeopleIconInfoKey]; // { headerId, direction}
    if (sortIconInfo) {
        let sortIcon = row.find(`div[columnname="${sortIconInfo.headerId}"]`).find(`.${sortIconInfo.direction}`);
        sortIcon.show();
    }
}
function emitPeopleDataRows(results, optionalShows, colspecs, target, keyword) {
    if (results.People && results.People.length > 0) {
        let items = sortArrayViaSortLabel(results.People, "SortOrder");
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

    let header = $(e.target).closest('div');
    let columnName = header.attr(gSearch.columnNameSt);

    let newSortDirection = gSearch.ascendingSt;
    let currentVisibleSortable = header.find(`.${gSearch.sortDisplaySt}:visible`);
    if (currentVisibleSortable.length > 0 && currentVisibleSortable.hasClass(gSearch.ascendingSt)) {
        newSortDirection = gSearch.descendingSt;
    }

    let li = $(`li[name=${columnName}][dir=${newSortDirection}]`);

    li.click();
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

