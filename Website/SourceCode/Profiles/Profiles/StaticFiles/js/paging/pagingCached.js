
// es5 style. If es6 widespread enough, could use nicer 'class' syntax
function PagingCached(allTheItems, sizes, displayFn){
    this.allTheItems = allTheItems;
    this.currentPageSize = sizes[0];
    this.currentOffset = 0;
    this.sizes = sizes;
    this.displayFn = displayFn;
}

PagingCached.prototype.display = function(target) {
    let slice = this.allTheItems.slice(this.currentOffset, this.currentPageSize);
    this.displayFn(slice, target);
}
PagingCached.prototype.emitPagingRow = function(target, rowClass) {
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

    this.emitPerPageDropdown(col1);

    let numPages = this.emitPageOfAndTotalPages(col2);
    let currentPage = 0;
    this.emitPrevNext(col3);

    this.adjustNavigation(currentPage, numPages);
}

PagingCached.prototype.emitPerPageDropdown = function(columnTarget) {
    let that = this;

    let label = $('<label for="pageSizeSelect" class="mt-1">Per Page </label>');
    let pageSizeSelect = $('<select class="ms-1 mb-1" id="pageSizeSelect"></select>');

    columnTarget.append(label);
    columnTarget.append(pageSizeSelect);

    let sizes = this.sizes;

    let currentSize = this.currentPageSize;

    for (let i=0; i<sizes.length; i++) {
        let size = sizes[i];
        let selected = size == currentSize ? "selected" : "";
        let option = $(`<option ${selected} value=${size}>${size}</option>`);
        pageSizeSelect.append(option);
    }

    pageSizeSelect.on('change', function(e) {
        let selectTarget = $(e.target);

        let pageSize = Number(selectTarget.val());

        that.currentPageSize = pageSize;
        that.currentOffset = Math.floor(that.currentOffset / pageSize) * pageSize;

        let slice = that.allTheItems.slice(that.currentOffset, that.currentPageSize);
        that.displayFn(slice, columnTarget);
    });
}

// following have bullet-proofing in case the data is incomplete
PagingCached.prototype.getNumItemsPerPage = function(items) {
    let result = fromResultsOrInit(
        items,
        ['SearchQuery', 'Count'],
        1);
    return result;
}
PagingCached.prototype.getNumPages = function() {
    let numItems = this.allTheItems.length;
    let itemsPerPage = this.currentPageSize;

    let result = Math.ceil(numItems / itemsPerPage);
    if (! result) { // zero results
        result = 1; // 'page 1 of 1, not of 0
    }
    return result;
}

PagingCached.prototype.getCurrentPageNum = function() {
    let result = Math.floor(this.currentOffset / this.currentPageSize) + 1;
    return result;
}

PagingCached.prototype.emitPageOfAndTotalPages = function(columnTarget) {
    let that = this; // for embedded fns

    let labelB4 = $('<label for="pageNum" class="mt-1">Page </label>')
    let input = $('<input class="ms-1 me-1 pt-0 mb-1 pageNumInput" id="pageNum"/>');
    let labelF2 = $('<label for="pageNum" class="mt-1"> of </label>');

    let numPages = this.getNumPages();
    let total = spanify(numPages, "ms-1 mt-1");

    let currentPageNum = this.getCurrentPageNum();

    input.val(currentPageNum);
    input.on('keypress',function(e) {
        e.stopPropagation();

        if(e.which == 13) {
            let inputTarget = $(e.target);
            let newPageNum = that.adjustInputPageNumber(inputTarget, numPages);
            that.displayCurrentPage(newPageNum, items);
        }
    });
    columnTarget
        .append(labelB4)
        .append(input)
        .append(labelF2)
        .append(total);

    return numPages;
}
PagingCached.prototype.emitPrevNext = function(columnTarget) {
    let that = this; // for embedded functions

    let prevLabel = $(`<span id="prevLabel">
                            <span class="ms-2 link-ish prevNext mt-1 tableHeaderPagingRow">Prev</span>
                            <span class="ms-2 disablePageNav prevNext mt-1">Prev</span>
                    </span>`);
    let nextLabel = $(`<span id="nextLabel">
                            <span class="ms-2 link-ish prevNext mt-1 tableHeaderPagingRow">Next</span>
                            <span class="ms-2 disablePageNav prevNext mt-1">Next</span>
                    </span>`);

    let first = $(`<span id="first">
                    <img alt="arrowFirst" class="link-ish prevNext tableHeaderPagingRow" src="${gBrandingConstants.jsPagingImageFiles}arrow_first.gif">
                    <img alt="arrowFirst" class="disablePageNav prevNext" src="${gBrandingConstants.jsPagingImageFiles}arrow_first_d.gif">
                </span>`);
    let last =  $(`<span id="last">
                    <img alt="arrowLast" class="ms-2 link-ish prevNext tableHeaderPagingRow" src="${gBrandingConstants.jsPagingImageFiles}arrow_last.gif">
                    <img alt="arrowLast" class="ms-2 disablePageNav prevNext" src="${gBrandingConstants.jsPagingImageFiles}arrow_last_d.gif">
                </span>`);
    let prev =  $(`<span id="prev">
                    <img alt="arrowPrevious" class="ms-2 link-ish prevNext tableHeaderPagingRow" src="${gBrandingConstants.jsPagingImageFiles}arrow_prev.gif">
                    <img alt="arrowPrevious" class="ms-2 disablePageNav prevNext" src="${gBrandingConstants.jsPagingImageFiles}arrow_prev_d.gif">
                </span>`);
    let next =  $(`<span id="next">
                    <img alt="arrowNext" class="ms-2 link-ish prevNext tableHeaderPagingRow" src="${gBrandingConstants.jsPagingImageFiles}arrow_next.gif">
                    <img alt="arrowNext" class="ms-2 disablePageNav prevNext" src="${gBrandingConstants.jsPagingImageFiles}arrow_next_d.gif">
                </span>`);

    columnTarget.append(first)
        .append(prev)
        .append(prevLabel)
        .append(nextLabel)
        .append(next)
        .append(last);

    first.on('click', function() {
        if (that.getCurrentPageNum(items) != 1) {
            that.displayCurrentPage(1, items);
        }
    });
    last.on('click', function() {
        let numPages = that.getNumPages(items);

        if (that.getCurrentPageNum(items) != numPages) {
            that.displayCurrentPage(numPages, items);
        }
    });

    prev.on(        'click', function() {that.pageBefore(items);});
    prevLabel.on(   'click', function() {that.pageBefore(items);});
    nextLabel.on(   'click', function() {that.pageAfter (items);});
    next.on(        'click', function() {that.pageAfter (items);});
}
PagingCached.prototype.vetAndGotoPage = function(pageNum, items) {
    let numPages = this.getNumPages(items);

    if (this.allowPageNumber(pageNum, numPages)) {
        this.displayCurrentPage(pageNum, items);
    }
}
PagingCached.prototype.pageBefore = function(items) {
    let currentPage = this.getCurrentPageNum(items);
    this.vetAndGotoPage(currentPage - 1, items);
}
PagingCached.prototype.pageAfter = function(items) {
    let currentPage = this.getCurrentPageNum(items);
    this.vetAndGotoPage(currentPage + 1, items);
}
PagingCached.prototype.allowPageNumber = function(num, numPages) {
    let result = num > 0 && num <= numPages; // optimistic
    return result;
}
PagingCached.prototype.adjustInputPageNumber = function(input, numPages) {
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
PagingCached.prototype.adjustNavigation = function(pageNum, numPages) {
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
PagingCached.prototype.ableElt = function(elt, which) {
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
PagingCached.prototype.sum = (a, b) => {
    return a + b;
}

// for jest testing -- 'module' does not exit in browser context
//        and jest does not seem to support (modern) ESM export/import
if (typeof module !== 'undefined' &&
    typeof module.exports !== 'undefined'  ) {
    // Use module.exports to make function visible to node tests
    module.exports.PagingCached = PagingCached;
}

