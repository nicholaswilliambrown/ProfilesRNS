
// es5 style. If es6 widespread enough, could use nicer 'class' syntax
function Paging(redoSearchFn, searchUrl, getTotalFn, sizes){
    this.redoSearchFn = redoSearchFn;
    this.searchUrl = searchUrl;
    this.getTotalCountFn = getTotalFn;
    this.sizes = sizes;
}

Paging.prototype.emitPagingRow = function(target, rowClass, searchResults) {
    let colspecs = [
        newColumnSpec(`${gCommon.cols3or12} d-flex justify-content-start`),
        newColumnSpec(`${gCommon.cols3or12} d-flex justify-content-start`),
        newColumnSpec(`${gCommon.cols6or12} d-flex justify-content-end`)
    ];

    let rowIdPrefix = `paging`;
    $(`#${rowIdPrefix}Row`).remove();

    let row = makeRowWithColumns(target, rowIdPrefix, colspecs, rowClass);
    let col1 = row.find(`#${rowIdPrefix}Col0`);
    let col2 = row.find(`#${rowIdPrefix}Col1`);
    let col3 = row.find(`#${rowIdPrefix}Col2`);

    this.emitPerPageDropdown(col1, target, rowClass, searchResults);

    let numPages = this.emitPageOf(col2, searchResults);

    this.emitPrevNext(col3, searchResults);

    let currentPage = this.getCurrentPageNum(searchResults);
    this.adjustNavigation(currentPage, numPages);
}

Paging.prototype.emitPerPageDropdown = function(columnTarget,
                             rowTarget,
                             rowClass,
                             searchResults) {
    let that = this; // for embedded functions

    let label = $('<label for="pageSizeSelect" class="mt-1">Per Page </label>');
    let pageSizeSelect = $('<select class="ms-1 mb-1" id="pageSizeSelect"></select>');

    columnTarget.append(label);
    columnTarget.append(pageSizeSelect);

    let sizes = this.sizes;

    let currentSize = this.getNumItemsPerPage(searchResults);
    if ( ! sizes.includes(currentSize)) {
        currentSize = sizes[0];
    }
    
    for (let i=0; i<sizes.length; i++) {
        let size = sizes[i];
        let selected = size == currentSize ? "selected" : "";
        let option = $(`<option ${selected} value=${size}>${size}</option>`);
        pageSizeSelect.append(option);
    }

    pageSizeSelect.on('change', function(e) {
        let selectTarget = $(e.target);

        let pageSize = Number(selectTarget.val());

        searchResults.SearchQuery.Count = pageSize;

        let offset0 = searchResults.SearchQuery.Offset - 1; // 0 for page 1, 15 for page 2
        let newOffset0 = Math.floor(offset0 / pageSize) * pageSize;
        searchResults.SearchQuery.Offset = newOffset0 + 1;

        that.redoSearchFn(searchResults, that.searchUrl);
    });
}

// following have bullet-proofing in case the data is incomplete
Paging.prototype.getNumItemsPerPage = function(searchResults) {
    let result = fromResultsOrInit(
        searchResults,
        ['SearchQuery', 'Count'],
        1);
    return result;
}
Paging.prototype.getNumPages = function(searchResults) {
    let result;
    let numItems = this.getTotalCountFn(searchResults);

    let itemsPerPage = this.getNumItemsPerPage(searchResults);

    if (itemsPerPage) {
        result = Math.ceil(numItems / itemsPerPage);
    }
    if (! result) { // zero results
        result = 1; // 'page 1 of 1, not of 0
    }
    return result;
}
Paging.prototype.getCurrentPageNum = function(searchResults) {
    let perPage = this.getNumItemsPerPage(searchResults);
    let offset1 = fromResultsOrInit(
        searchResults,
        ['SearchQuery', 'Offset'],
        1);

    let result = this.offset1AndPerPageToNum(offset1, perPage);
    return result;
}
Paging.prototype.offset1AndPerPageToNum = function(offset1, perPage) {
    let result;
    if (perPage != 0) { // shouldn't ever be 0
        result = Math.floor((offset1 - 1) / perPage) + 1;
    }
    return result;
}
Paging.prototype.pageNumAndSizeToOffset1 = function(pageNum, size) {
    let result = ((pageNum - 1) * size) + 1;
    return result;
}
Paging.prototype.emitPageOf = function(columnTarget, searchResults) {
    let that = this; // for embedded fns

    let labelB4 = $('<label for="pageNum" class="mt-1">Page </label>')
    let input = $('<input class="ms-1 me-1 pt-0 mb-1 pageNumInput" id="pageNum"/>');
    let labelF2 = $('<label for="pageNum" class="mt-1"> of </label>');

    let numPages = this.getNumPages(searchResults);
    let total = spanify(numPages, "ms-1 mt-1");

    let currentPageNum = this.getCurrentPageNum(searchResults);

    input.val(currentPageNum);
    input.on('keypress',function(e) {
        e.stopPropagation();

        if(e.which == 13) {
            let inputTarget = $(e.target);
            let newPageNum = that.adjustInputPageNumber(inputTarget, numPages);
            that.reloadWithNewPageNum(newPageNum, searchResults);
        }
    });
    columnTarget
        .append(labelB4)
        .append(input)
        .append(labelF2)
        .append(total);

    return numPages;
}
Paging.prototype.emitPrevNext = function(columnTarget, searchResults) {
    let that = this; // for embedded functions

    let prevLabel = $(`<span id="prevLabel">
                            <span class="ms-2 link-ish prevNext mt-1">Prev</span>
                            <span class="ms-2 disablePageNav prevNext mt-1">Prev</span>
                    </span>`);
    let nextLabel = $(`<span id="nextLabel">
                            <span class="ms-2 link-ish prevNext mt-1">Next</span>
                            <span class="ms-2 disablePageNav prevNext mt-1">Next</span>
                    </span>`);

    let first = $(`<span id="first">
                    <img class="link-ish prevNext" src="${gBrandingConstants.jsPagingImageFiles}arrow_first.gif">
                    <img class="disablePageNav prevNext" src="${gBrandingConstants.jsPagingImageFiles}arrow_first_d.gif">
                </span>`);
    let last =  $(`<span id="last">
                    <img class="ms-2 link-ish prevNext" src="${gBrandingConstants.jsPagingImageFiles}arrow_last.gif">
                    <img class="ms-2 disablePageNav prevNext" src="${gBrandingConstants.jsPagingImageFiles}arrow_last_d.gif">
                </span>`);
    let prev =  $(`<span id="prev">
                    <img class="ms-2 link-ish prevNext" src="${gBrandingConstants.jsPagingImageFiles}arrow_prev.gif">
                    <img class="ms-2 disablePageNav prevNext" src="${gBrandingConstants.jsPagingImageFiles}arrow_prev_d.gif">
                </span>`);
    let next =  $(`<span id="next">
                    <img class="ms-2 link-ish prevNext" src="${gBrandingConstants.jsPagingImageFiles}arrow_next.gif">
                    <img class="ms-2 disablePageNav prevNext" src="${gBrandingConstants.jsPagingImageFiles}arrow_next_d.gif">
                </span>`);

    columnTarget.append(first)
        .append(prev)
        .append(prevLabel)
        .append(nextLabel)
        .append(next)
        .append(last);

    first.on('click', function() {
        if (that.getCurrentPageNum(searchResults) != 1) {
            that.reloadWithNewPageNum(1, searchResults);
        }
    });
    last.on('click', function() {
        let numPages = that.getNumPages(searchResults);

        if (that.getCurrentPageNum(searchResults) != numPages) {
            that.reloadWithNewPageNum(numPages, searchResults);
        }
    });

    prev.on(        'click', function() {that.pageBefore(searchResults);});
    prevLabel.on(   'click', function() {that.pageBefore(searchResults);});
    nextLabel.on(   'click', function() {that.pageAfter (searchResults);});
    next.on(        'click', function() {that.pageAfter (searchResults);});
}
Paging.prototype.vetAndGotoPage = function(pageNum, searchResults) {
    let numPages = this.getNumPages(searchResults);

    if (this.allowPageNumber(pageNum, numPages)) {
        this.reloadWithNewPageNum(pageNum, searchResults);
    }
}
Paging.prototype.pageBefore = function(searchResults) {
    let currentPage = this.getCurrentPageNum(searchResults);
    this.vetAndGotoPage(currentPage - 1, searchResults);
}
Paging.prototype.pageAfter = function(searchResults) {
    let currentPage = this.getCurrentPageNum(searchResults);
    this.vetAndGotoPage(currentPage + 1, searchResults);
}
Paging.prototype.reloadWithNewPageNum = function(pageNum, searchResults) {
    let size = this.getNumItemsPerPage(searchResults);
    let offset1 = this.pageNumAndSizeToOffset1(pageNum, size);
    searchResults.SearchQuery.Offset = offset1;

    this.redoSearchFn(searchResults, this.searchUrl);
}
Paging.prototype.allowPageNumber = function(num, numPages) {
    let result = num > 0 && num <= numPages; // optimistic
    return result;
}
Paging.prototype.adjustInputPageNumber = function(input, numPages) {
    let val = input.val();
    let goodNumber = false;
    if ($.isNumeric(val)) {
        val = Number(val);
        if (val>0 && val<=numPages) {
            goodNumber = true;
        }
    }
    if (! goodNumber) {
        val = 1;
    }
    input.val(val);
    return val;
}
Paging.prototype.adjustNavigation = function(pageNum, numPages) {
    let firstAndPrevEnabled = true;
    let lastAndNextEnabled = true;;

    if (pageNum == 1) {
        firstAndPrevEnabled = false;
        lastAndNextEnabled = true;
    }
    else if (pageNum == numPages) {
        firstAndPrevEnabled = true;
        lastAndNextEnabled = false;
    }

    this.ableElt($('#prev'), firstAndPrevEnabled);
    this.ableElt($('#prevLabel'), firstAndPrevEnabled);
    this.ableElt($('#first'), firstAndPrevEnabled);

    this.ableElt($('#next'), lastAndNextEnabled);
    this.ableElt($('#nextLabel'), lastAndNextEnabled);
    this.ableElt($('#last'), lastAndNextEnabled);
}
Paging.prototype.ableElt = function(elt, which) {
    elt.prop("disabled", ! which);
    if (which) {
        elt.find('.link-ish').show();
        elt.find('.disablePageNav').hide();
    }
    else {
        elt.find('.link-ish').hide();
        elt.find('.disablePageNav').show();
    }
}
Paging.prototype.sum = (a, b) => {
    return a + b;
}
Paging.prototype.searchResults = (count) => {
    let results = {
        "SearchQuery": {
            "Keyword": "kidney",
            "KeywordExact": false,
            "LastName": "",
            "FirstName": "",
            "InstitutionExcept": false,
            "Institution": "",
            "InstitutionName": "",
            "DepartmentExcept": false,
            "Department": "",
            "DepartmentName": "",
            "FacultyType": [],
            "FacultyTypeName": [],
            "OtherOptions": [],
            "OtherOptionsName": [],
            "Sort": "relevance",
            "SearchType": "people",
            "Count": 25,
            "Offset": 26,
            "selectedOptionalShows": [
                "InstitutionName"
            ]
        },
        "Count": 419,
        "People": [
            {
                "DepartmentName": "Pathology",
                "DisplayName": "Bradley E. Bernstein, M.D., Ph.D.",
                "FacultyRank": "Full Professor",
                "InstitutionName": "Dana-Farber Cancer Institute",
                "NodeID": 39078,
                "PersonID": 86,
                "URL": "/display/39078",
                "Weight": 0.035,
                "SortOrder": 43
            },
            {
                "DepartmentName": "Medicine",
                "DisplayName": "Katherine Phoenix Liao, M.D.",
                "FacultyRank": "Associate Professor",
                "InstitutionName": "Brigham and Women's Hospital",
                "NodeID": 38372,
                "PersonID": 454,
                "URL": "/display/38372",
                "Weight": 0.039,
                "SortOrder": 40
            },
            {
                "DepartmentName": "Cell Biology",
                "DisplayName": "David Jonathan Glass, M.D.",
                "FacultyRank": "Lecturer",
                "InstitutionName": "Harvard Medical School",
                "NodeID": 39010,
                "PersonID": 7417,
                "URL": "/display/39010",
                "Weight": 0.037,
                "SortOrder": 41
            },
            {
                "DepartmentName": "Emeritus",
                "DisplayName": "David Clapham, M.D., Ph.D.",
                "FacultyRank": "Full Professor",
                "InstitutionName": "Harvard Medical School",
                "NodeID": 38033,
                "PersonID": 11196,
                "URL": "/display/38033",
                "Weight": 0.055,
                "SortOrder": 32
            },
            {
                "DepartmentName": "Health Care Policy",
                "DisplayName": "Nancy Lynn Keating, M.D.",
                "FacultyRank": "Full Professor",
                "InstitutionName": "Harvard Medical School",
                "NodeID": 39168,
                "PersonID": 17235,
                "URL": "/display/39168",
                "Weight": 0.057,
                "SortOrder": 29
            },
            {
                "DepartmentName": "Biomedical Informatics",
                "DisplayName": "Zak Kohane, M.D.,Ph.D.",
                "FacultyRank": "Full Professor",
                "InstitutionName": "Harvard Medical School",
                "NodeID": 38222,
                "PersonID": 25477,
                "URL": "/display/38222",
                "Weight": 0.049,
                "SortOrder": 34
            },
            {
                "DepartmentName": "Immunology",
                "DisplayName": "Roderick Terry Bronson, D.V.M.",
                "FacultyRank": "Lecturer",
                "InstitutionName": "Harvard Medical School",
                "NodeID": 38262,
                "PersonID": 29701,
                "URL": "/display/38262",
                "Weight": 0.032,
                "SortOrder": 46
            },
            {
                "DepartmentName": "Systems Biology",
                "DisplayName": "Timothy J. Mitchison, Ph.D.",
                "FacultyRank": "Full Professor",
                "InstitutionName": "Harvard Medical School",
                "NodeID": 38270,
                "PersonID": 31112,
                "URL": "/display/38270",
                "Weight": 0.039,
                "SortOrder": 39
            },
            {
                "DepartmentName": "Emeritus",
                "DisplayName": "David Curtis Wilbur, M.D.",
                "FacultyRank": "Full Professor",
                "InstitutionName": "Harvard Medical School",
                "NodeID": 38288,
                "PersonID": 33203,
                "URL": "/display/38288",
                "Weight": 0.043,
                "SortOrder": 38
            },
            {
                "DepartmentName": "Medicine",
                "DisplayName": "Soumya Raychaudhuri, M.D., Ph.D.",
                "FacultyRank": "Full Professor",
                "InstitutionName": "Brigham and Women's Hospital",
                "NodeID": 38324,
                "PersonID": 38398,
                "URL": "/display/38324",
                "Weight": 0.053,
                "SortOrder": 33
            },
            {
                "DepartmentName": "Biomedical Informatics",
                "DisplayName": "Susanne E. Churchill, Ph.D.",
                "FacultyRank": "",
                "InstitutionName": "Harvard Medical School",
                "NodeID": 38414,
                "PersonID": 52132,
                "URL": "/display/38414",
                "Weight": 0.031,
                "SortOrder": 48
            },
            {
                "DepartmentName": "Biomedical Informatics",
                "DisplayName": "Peter Park, Ph.D.",
                "FacultyRank": "Full Professor",
                "InstitutionName": "Harvard Medical School",
                "NodeID": 38477,
                "PersonID": 62138,
                "URL": "/display/38477",
                "Weight": 0.058,
                "SortOrder": 27
            },
            {
                "DepartmentName": "Health Policy and Management",
                "DisplayName": "Arnold M. Epstein",
                "FacultyRank": "Full Professor",
                "InstitutionName": "Harvard T.H. Chan School of Public Health",
                "NodeID": 38487,
                "PersonID": 63506,
                "URL": "/display/38487",
                "Weight": 0.06,
                "SortOrder": 26
            },
            {
                "DepartmentName": "Immunology",
                "DisplayName": "Arlene Helen Sharpe, M.D., Ph.D.",
                "FacultyRank": "Full Professor",
                "InstitutionName": "Harvard Medical School",
                "NodeID": 38975,
                "PersonID": 68774,
                "URL": "/display/38975",
                "Weight": 0.043,
                "SortOrder": 37
            },
            {
                "DepartmentName": "Medicine",
                "DisplayName": "Wolfram Goessling, Ph.D., M.D.",
                "FacultyRank": "Full Professor",
                "InstitutionName": "Massachusetts General Hospital",
                "NodeID": 38982,
                "PersonID": 69357,
                "URL": "/display/38982",
                "Weight": 0.056,
                "SortOrder": 30
            },
            {
                "DepartmentName": "Emeritus",
                "DisplayName": "Thomas Livingston Benjamin, Ph.D.",
                "FacultyRank": "Full Professor",
                "InstitutionName": "Harvard Medical School",
                "NodeID": 39051,
                "PersonID": 81861,
                "URL": "/display/39051",
                "Weight": 0.032,
                "SortOrder": 47
            },
            {
                "DepartmentName": "Emeritus",
                "DisplayName": "Daniel Adino Goodenough, Ph.D.",
                "FacultyRank": "Full Professor",
                "InstitutionName": "Harvard Medical School",
                "NodeID": 39058,
                "PersonID": 82701,
                "URL": "/display/39058",
                "Weight": 0.047,
                "SortOrder": 36
            },
            {
                "DepartmentName": "Medicine",
                "DisplayName": "Daniel Aran Solomon, M.D.",
                "FacultyRank": "Assistant Professor",
                "InstitutionName": "Brigham and Women's Hospital",
                "NodeID": 39104,
                "PersonID": 90778,
                "URL": "/display/39104",
                "Weight": 0.037,
                "SortOrder": 42
            },
            {
                "DepartmentName": "BCMP",
                "DisplayName": "Joseph Beyene, Ph.D.",
                "FacultyRank": "Other Faculty",
                "InstitutionName": "Harvard Medical School",
                "NodeID": 38581,
                "PersonID": 128233,
                "URL": "/display/38581",
                "Weight": 0.056,
                "SortOrder": 31
            },
            {
                "DepartmentName": "Biomedical Informatics",
                "DisplayName": "Matthew Brendon Might, Ph.D.",
                "FacultyRank": "Lecturer",
                "InstitutionName": "Harvard Medical School",
                "NodeID": 38651,
                "PersonID": 139711,
                "URL": "/display/38651",
                "Weight": 0.031,
                "SortOrder": 50
            },
            {
                "DepartmentName": "Systems Biology",
                "DisplayName": "Chris Sander, Ph.D.",
                "FacultyRank": "Lecturer",
                "InstitutionName": "Harvard Medical School",
                "NodeID": 38664,
                "PersonID": 141511,
                "URL": "/display/38664",
                "Weight": 0.048,
                "SortOrder": 35
            },
            {
                "DepartmentName": "Harvard Program in Therapeutic Science",
                "DisplayName": "Kenichi Shimada, Ph.D.",
                "FacultyRank": "Other Faculty",
                "InstitutionName": "Harvard Medical School",
                "NodeID": 38677,
                "PersonID": 143755,
                "URL": "/display/38677",
                "Weight": 0.032,
                "SortOrder": 45
            },
            {
                "DepartmentName": "Biomedical Informatics",
                "DisplayName": "Kun-Hsing Yu, Ph.D., M.D.",
                "FacultyRank": "Assistant Professor",
                "InstitutionName": "Harvard Medical School",
                "NodeID": 38768,
                "PersonID": 154707,
                "URL": "/display/38768",
                "Weight": 0.057,
                "SortOrder": 28
            },
            {
                "DepartmentName": "Biomedical Informatics",
                "DisplayName": "Jake June-Koo Lee, Ph.D., M.D.",
                "FacultyRank": "",
                "InstitutionName": "Harvard Medical School",
                "NodeID": 38789,
                "PersonID": 157668,
                "URL": "/display/38789",
                "Weight": 0.034,
                "SortOrder": 44
            },
            {
                "DepartmentName": "Medicine",
                "DisplayName": "Rachelly Normand, Ph.D.",
                "FacultyRank": "Fellow or Post Doc",
                "InstitutionName": "Massachusetts General Hospital",
                "NodeID": 39487,
                "PersonID": 193215,
                "URL": "/display/39487",
                "Weight": 0.031,
                "SortOrder": 49
            }
        ]
    }

    let people = [];
    for (let i=1; i<=count; i++) {
        let person = {
            "DepartmentName": `Dept${i}`,
            "DisplayName": `Name${i}`,
            "FacultyRank": "Assistant Professor",
            "InstitutionName": `Inst${i}`,
            "NodeID": 39045,
            "PersonID": 8005,
            "URL": "/display/39045",
            "Weight": 0.256,
            "SortOrder": 7
        }
        people.push(person);
    }
    return people;
}

// for jest testing -- 'module' does not exit in browser context
//        and jest does not seem to support (modern) ESM export/import
if (typeof module !== 'undefined' &&
    typeof module.exports !== 'undefined'  ) {
    // Use module.exports to make function visible to node tests
    module.exports.Paging = Paging;
}

