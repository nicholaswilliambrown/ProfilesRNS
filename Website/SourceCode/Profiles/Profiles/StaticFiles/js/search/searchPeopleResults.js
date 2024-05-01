
async function setupSearchPeopleResults() {
    let pagination = new Paging(
        redoPeopleSearch,
        gSearch.findPeopleUrl,
        getPeopleResultsCount,
        gPage.sizes);

    //let data = await getJsonData("../json/fake-data/SearchPersonResults.json");
    let resultsAsString = fromSession(makeSearchResultsKey(gSearch.people));
    let results = JSON.parse(resultsAsString);
    gSearch.searchPeopleResults = results;

    if (! results || ! results.SearchQuery) { // sanity check
        alert(`Error with search results: ${resultsAsString}`);
    }
    console.log('Results: ', results);

    await setupPageStub(searchResultsBodyStructure);

    let mainDiv = $('#mainDiv');
    mainDiv.addClass(gCommon.mainDivClasses);
    moveContentByIdTo("mainRow", mainDiv);

    // not all usages of the below use 'count' from results
    emitSearchResultCountAndBackTo(results, `searchForm.html?${gSearch.people}`, 'Modify Search', results.Count);

    $('#sortDropdownDiv').addClass(`${gCommon.cols3or12}`);
    $('#showDropdownDiv').addClass(`${gCommon.cols3or12}`);

    hideLiItems();

    setupDropdownsAndInitialSelections();
    emitCriteriaOnRhs(results, true);

    emitPeopleResults();

    pagination.emitPagingRow($('#resultsDiv'),
        "pt-1 ms-1 me-1 bordersRow",
        results);
}
function getPeopleResultsCount(results) {
    let result = results.Count ? results.Count : 0;
    return result;
}
function emitPeopleResults() {
    let results = gSearch.searchPeopleResults;
    let target = $('#resultsDiv');
    target.empty();

    let optionalShows = fromResultsOrInit(
        results,
        ['SearchQuery', gSearch.selectedOptionalPeopleShowsKey],
        gSearch.initialOptionalPeopleShows);

    let colspecs = makePpleSearchResultsColspecs(optionalShows);

    emitPeopleResultsHeader(results, optionalShows, colspecs, target);
    emitDataRows(results, optionalShows, colspecs, target);
}
function emitPeopleResultsHeader(results, optionalShows, colspecs, target) {
    let rowId = `peopleResultsHeader`;
    let row = makeRowWithColumns(target, rowId, colspecs,  "bordersRow mt-2");

    // always 1st is Name and last is Why, middle columns can vary
    let column = row.find(`#${rowId}Col0`);
    column.attr(gSearch.columnNameSt, 'DisplayName');
    column.append(spanify('Name', `${gSearch.sortableSt} bold`));
    for (let i=0; i<optionalShows.length; i++) {
        let rawShow = optionalShows[i];
        let displayShow = gSearch.peopleResultDisplay[rawShow];
        column = row.find(`#${rowId}Col${i+1}`);
        column.attr(gSearch.columnNameSt, rawShow)
        column.append(spanify(displayShow, `${gSearch.sortableSt} bold`));
    }
    row.find(`#${rowId}Col${colspecs.length-1}`).append(spanify('Why', ' bold'));

    // all columns except last / Why are sortable, so can use triangle-images
    for (let i=0; i<colspecs.length - 1; i++) {
        let column = row.find(`#${rowId}Col${i}`);
        column.append(spanify(
            `<img src="${gBasic.jsSearchImageFiles}sort_asc.gif" alt="sort ${gSearch.ascendingSt}">`,
            `${gSearch.sortDisplaySt} ${gSearch.ascendingSt}`));
        column.append(spanify(
            `<img src="${gBasic.jsSearchImageFiles}sort_desc.gif" alt="sort ${gSearch.descendingSt}">`,
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
function emitDataRows(results, optionalShows, colspecs, target) {
    let items = results.People; // [relevance] sort is requested/fulfilled by/in back-end

    if (items) {
        for (let i = 0; i < items.length; i++) {
            let item = items[i];

            let rowId = `peopleResults${i}`;
            let row = makeRowWithColumns(target, rowId, colspecs, "bordersRow bordE");

            // always 1st is Name and last is Why, middle columns can vary
            let column = row.find(`#${rowId}Col0`);
            column.append(createAnchorElement(item.DisplayName, item.URL));

            for (let i = 0; i < optionalShows.length; i++) {
                let show = optionalShows[i];
                column = row.find(`#${rowId}Col${i + 1}`);
                column.append(spanify(item[show]));
            }

            column = row.find(`#${rowId}Col${colspecs.length - 1}`);
            column.append(createWhyLink(item, results));

            let rhsPreview = () => previewPerson(item);
            let hidePreview = () => {
                gSearch.rhsDiv2.empty();
            }
            hoverLight(row, rhsPreview, hidePreview);
        }
    }
}
function previewPerson(item) {
    let target = gSearch.rhsDiv2;

    addIfPresent(item.FirstLastName, target); // in prod, is it in our json?
    addIfPresent(item.DisplayName, target);
    addIfPresent(item.FacultyRank, target);
    addIfPresent(item.InstitutionName, target);
    addIfPresent(item.DepartmentName, target);
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
function makePpleSearchResultsColspecs(optionalShows) {
    let numOptShows = optionalShows.length;
    let columnWidths, classRef;

    switch (numOptShows) {
        case 0:
            columnWidths = {first: 8, last:4};
            break;
        case 1:
            columnWidths = {first:5, mid:5, last:2};
            break;
        case 2:
            columnWidths = {first:3, mid:3, last:2};
            break;
        case 3:
            columnWidths = {first:3, mid:2, last:2};
            break;
    }

    classRef = `cols${columnWidths.first}or12`;
    let colspecs = [newColumnSpec(` pt-1 pb-1 bordE ${gCommon[classRef]}`)];

    for (let i=0; i<optionalShows.length; i++) {
        classRef = `cols${columnWidths.mid}or12`;
        colspecs.push(newColumnSpec(` pt-1 pb-1 bordE ${gCommon[classRef]}`));
    }

    classRef = `cols${columnWidths.last}or12`;
    colspecs.push(newColumnSpec(` pt-1 pb-1 t-center ${gCommon[classRef]}`));

    return colspecs;
}

