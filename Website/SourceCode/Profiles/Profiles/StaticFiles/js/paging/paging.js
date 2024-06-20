
// es5 style. If es6 widespread enough, could use nicer 'class' syntax
function Paging(redoSearch, searchUrl, getTotal, sizes){
    this.redoSearchFn = redoSearch;
    this.searchUrl = searchUrl;
    this.getTotalCount = getTotal;
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

    let label = $('<label for="pageSelect" class="mt-1">Per Page </label>');
    let select = $('<select class="ms-1 mb-1" id="pageSelect"></select>');

    columnTarget.append(label);
    columnTarget.append(select);

    let sizes = this.sizes;

    let currentSize = this.getNumItemsPerPage(searchResults);
    if (! sizes.indexOf(currentSize) == -1) {
        currentSize = sizes[0];
    }
    
    for (let i=0; i<sizes.length; i++) {
        let size = sizes[i];
        let selected = size == currentSize ? "selected" : "";
        let option = $(`<option ${selected} value=${size}>${size}</option>`);
        select.append(option);
    }

    select.on('change', function(e) {
        let selectTarget = $(e.target);

        let size = Number(selectTarget.val());

        searchResults.SearchQuery.Count = size;
        let newOffset = Math.floor(searchResults.SearchQuery.Offset / size) * size;
        searchResults.SearchQuery.Offset = newOffset;

        that.redoSearchFn(searchResults, that.searchUrl);
    });
}

// following have bullet-proofing in case the data is incomplete
Paging.prototype.getNumItemsPerPage = function(searchResults) {
    let result = fromResultsOrInit(
        searchResults,
        ['SearchQuery', 'Count'],
        0);
    return result;
}
Paging.prototype.getNumPages = function(searchResults) {
    let result;
    let numItems = this.getTotalCount(searchResults);

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
    let offset = fromResultsOrInit(
        searchResults,
        ['SearchQuery', 'Offset'],
        0);

    let result = this.offsetAndPerPageToNum(offset, perPage);
    return result;
}
Paging.prototype.offsetAndPerPageToNum = function(offset, perPage) {
    let result;
    if (perPage != 0) { // shouldn't ever occur
        result = Math.floor(offset / perPage) + 1;
    }
    return result;
}
Paging.prototype.pageNumAndSizeToOffset = function(pageNum, size) {
    let result = (pageNum - 1) * size;
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
    let offset = this.pageNumAndSizeToOffset(pageNum, size);
    searchResults.SearchQuery.Offset = offset;

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

// Use module.exports to make function visible to node tests
module.exports.sum = (a, b) => {
    return a + b;
}
