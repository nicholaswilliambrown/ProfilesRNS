async function setupSearchForm() {
    await setupPageStub(searchBodyStructure);

    let data = await getJsonData(gImpl.searchFormUrl);
    gSearch.formData = data;
    console.log("========> formData", data);

    let mainDiv = $('#mainDiv');
    mainDiv.addClass(gCommon.mainDivClasses);
    moveContentByIdTo("mainRow", mainDiv);

    setupRightAndLeftSides();

    // now mid-section
    gSearch.midSectionColspecs = [
        newColumnSpec(`${gCommon.cols3or12} d-flex justify-content-end pt-1 bold`),
        newColumnSpec(`${gCommon.cols5or12} d-flex justify-content-start`),
        newColumnSpec(`${gCommon.cols4or12} d-flex justify-content-start `)
    ];

    setupSearchSubmitAndNameSections();
    setupDropdowns();


    respectPriorCriteria(gSearch.peoplePrefix);
    respectPriorCriteria(gSearch.allElsePrefix);
}
function respectPriorCriteria(prefix) {
    let priorResultsKey = makeSearchResultsKey(prefix);
    let priorResults = JSON.parse(fromSession(priorResultsKey));
    console.log('session key: ', priorResultsKey);
    console.log('Criteria: ', prefix, priorResults);
    if (priorResults && priorResults.SearchQuery) { // bullet-proofing, in case results were json error}
        let searchInput = priorResults.SearchQuery.Keyword;
        let exactCheckbox = priorResults.SearchQuery.KeywordExact;

        restoreText(`${prefix}SearchInput`, searchInput);
        restoreCheck(`${prefix}ExactCheckbox`, exactCheckbox);

        if (prefix == gSearch.peoplePrefix) {
            let lnameInput = priorResults.SearchQuery.LastName;
            let fnameInput = priorResults.SearchQuery.FirstName;
            let institution = priorResults.SearchQuery.Institution;
            let institutionAllExcept = priorResults.SearchQuery.InstitutionExcept;
            let department = priorResults.SearchQuery.Department;
            let departmentAllExcept = priorResults.SearchQuery.DepartmentExcept;
            let facultyTypes = priorResults.SearchQuery.FacultyType;
            let otherOptions = priorResults.SearchQuery.OtherOptions;

            restoreText('lnameInput', lnameInput);
            restoreText('fnameInput', fnameInput);

            restoreCheck('institutionsAllExceptCheck', institutionAllExcept);
            restoreCheck('departmentsAllExceptCheck', departmentAllExcept);

            let nodesToClick = [];
            pushForRestore(institution, nodesToClick);
            pushForRestore(department, nodesToClick);
            pushForRestore(facultyTypes, nodesToClick);
            pushForRestore(otherOptions, nodesToClick);

            restoreDropdowns(nodesToClick);
        }
    }
}
function pushForRestore(candidate, target) {
    if (candidate) {
        // https://stackoverflow.com/questions/4059147/check-if-a-variable-is-a-string-in-javascript
        if (candidate.constructor === Array) {
            target.push(...candidate);
        }
        // https://stackoverflow.com/questions/767486/how-do-i-check-if-a-variable-is-an-array-in-javascript
        else if (typeof candidate === 'string') {
            target.push(candidate);
        }
    }
}
function restoreDropdowns(nodesToClick) {
    for (let i = 0; i < nodesToClick.length; i++) {
        let node = nodesToClick[i];
        $(`#${node}`).closest('li').click();
    }
    $('#dropbox2Col2').click(); // close the dropdowns by clicking outside
}
function restoreText(targetId, text) {
    if (text) {
        $(`#${targetId}`).val(text);
    }
}
function restoreCheck(targetId, checked) {
    if (checked) {
        $(`#${targetId}`).click();
    }
}
function emitMoreUpdatesLink() {
    let target = gSearch.lhsDiv;

    let anchor = createAnchorElement('<img src="../img/search/icon_squareArrow.gif"/> See more updates',
        gSearch.moreUpdatesUrl);

    let colspecs = [newColumnSpec(`${gCommon.cols12} ps-0 d-flex justify-content-start`,
        anchor)];
    let row = makeRowWithColumns(target, "moreUpdates", colspecs, "ms-0")

    target.append(row);
}

function setupRightAndLeftSides() {
    emitSidebarRecentUpdates();

    let mostTodayStr = 'MostViewedDay';
    let mostMonthStr = 'MostViewedMonth'
    gSearch.rhsDiv.addClass("t30s"); // but not added in corresponding results page
    gSearch.rhsDiv.append($(`<div id="${mostTodayStr}" class="bold mb-2">Most viewed (today)</div>`));
    gSearch.rhsDiv.append($(`<hr class="tightHr"/>`));
    gSearch.rhsDiv.append($(`<div id="${mostMonthStr}" class="bold mt-2">Most viewed (month)</div>`));

    emitMosts(mostTodayStr);
    emitMosts(mostMonthStr);
}
function emitMosts(whichMost) {
    if (gSearch.formData[whichMost]) {
        let data = sortArrayViaSortLabel(gSearch.formData[whichMost], 'NumberOfQueries', true);
        ;
        let target = $(`#${whichMost}`);

        for (let i = 0; i < data.length; i++) {
            let item = data[i];
            let nameUrl = $(`<a href="#" class="link-ish unbold">${item.Phrase}</a>`);

            let div = $('<div class="mt-1"></div>');
            div.append(nameUrl);
            target.append(div);
        }
    }
}
function setupSearchSubmitAndNameSections() {
    setupOneSearchSubmitSection(
        gSearch.peoplePrefix,
        "Research Topics",
        'Find People by Research Topic or Name',
        searchPeopleFn);

    setupOneSearchSubmitSection(
        gSearch.allElsePrefix,
        'Keywords',
        'Find Publications, Projects, Concepts and More',
        searchEverythingFn);
}
function collectKeywordSelections(searchInput, exactCheckbox) {
    let selections = {};
    selections.Keyword = searchInput.val();
    selections.KeywordExact = exactCheckbox.is(':checked');

    return selections;
}
function collectNames(lnameInput, fnameInput, selections) {
    selections.LastName = lnameInput.val();
    selections.FirstName = fnameInput.val();
}
function searchPeopleFn(searchInput, exactCheckbox, lnameInput, fnameInput) {
    let selections = collectKeywordSelections(searchInput, exactCheckbox);
    collectNames(lnameInput, fnameInput, selections);

    collectDropdownSelections(selections);
    // misc addition: foreshadowing sorting
    selections.Sort = "relevance";
    selections.SearchType = gSearch.peoplePrefix;
    initializePagingValues(selections, gPage.defaultPageSize, 0);

    //alert(`Json (from people tab): ${JSON.stringify(selections)}`);
    searchPost(
        gImpl.findPeopleUrl,
        gSearch.peoplePrefix,
        selections,
        "default.aspx?PersonResults");
}
function searchEverythingFn(searchInput, exactCheckbox) {
    let selections = collectKeywordSelections(searchInput, exactCheckbox);

    selections.SearchType = gSearch.allElsePrefix;

    // new search starts with 'All' filter
    addUpdateSearchQuery(selections, gSearch.currentFilterKey, gSearch.allFilterLabel);
    initializePagingValues(selections, gPage.defaultPageSize, 0);

    //alert(`Json (from everything tab): ${JSON.stringify(selections)}`);
    searchPost(
        gImpl.findEverythingElseUrl,
        gSearch.allElsePrefix,
        selections,
        "default.aspx?EverythingResults");
}
function setupOneSearchSubmitSection(idPrefix, label, title, searchFn) {
    let outerTarget = $(`#${idPrefix}`);
    let boxTarget = $(`#${idPrefix}Box`);
    let rowId = `${idPrefix}1`;

    let titleDiv = $(`<div class="bigTitle mb-2">${title}</div>`);
    outerTarget.prepend(titleDiv);

    let row = makeRowWithColumns(boxTarget, rowId, gSearch.midSectionColspecs,  "pb-1 mt-0 mb-2");

    let searchInput = $(`<input id="${idPrefix}SearchInput" class="w-100 ps-2" type="search" aria-label="Search">`);
    let searchButton = $(`<img id="${idPrefix}SearchButton" src="../img/search/search.jpg" alt="Search">`);
    let exactCheckbox = $(`<input id="${idPrefix}ExactCheckbox" type="checkbox" aria-label="Exact match"/>`);
    // separate label for checkbox, so only precise clicks on box have effect
    let checkboxLabel = $(`<label class="ms-2"> Search for exact phrase</label>`);

    let checkboxSpan = $('<span></span>');
    checkboxSpan.append(exactCheckbox);
    checkboxSpan.append(checkboxLabel);

    row.find(`#${rowId}Col0`).html(label);
    row.find(`#${rowId}Col1`).append(searchInput);
    row.find(`#${rowId}Col2`).append(searchButton);

    rowId = `${idPrefix}2`;
    row = makeRowWithColumns(boxTarget, rowId, gSearch.midSectionColspecs,  "pb-1 mt-0 mb-2");
    row.find(`#${rowId}Col1`).append(checkboxSpan);

    let fname, lname; // undef for allElse, but present for people
    if (idPrefix == gSearch.peoplePrefix) {
        [lname, fname] = emitTwoNamesInput(boxTarget);
    }

    searchButton.on('click', function() {
        searchFn(searchInput, exactCheckbox, lname, fname);
    });
}
function emitTwoNamesInput(target) {
    let rowId = `${gSearch.lnameInputSt}`;
    let row = makeRowWithColumns(target, rowId, gSearch.midSectionColspecs,  "pb-1 mt-0 mb-2");

    let lnameInput = $(`<input id="${gSearch.lnameInputSt}" class="w-100">`);
    row.find(`#${rowId}Col0`).html('Last Name');
    row.find(`#${rowId}Col1`).append(lnameInput);

    rowId = `${gSearch.fnameInputSt}`;
    row = makeRowWithColumns(target, rowId, gSearch.midSectionColspecs,  "pb-1 mt-0 mb-2");

    let fnameInput = $(`<input id="${gSearch.fnameInputSt}" class="w-100">`);
    row.find(`#${rowId}Col0`).html('First Name');
    row.find(`#${rowId}Col1`).append(fnameInput);

    return [lnameInput, fnameInput];
}
