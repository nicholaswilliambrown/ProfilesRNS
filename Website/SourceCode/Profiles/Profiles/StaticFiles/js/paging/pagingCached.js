
// es5 style. If es6 widespread enough, could use nicer 'class' syntax
function PagingCached(allTheItems, sizes, displayFn, itemsTarget, pagingTarget, label) {
    this.allTheItems = allTheItems;
    this.currentPageSize = sizes[0];
    this.currentOffset = 0;
    this.sizes = sizes;
    this.displayFn = displayFn;
    this.itemsTarget = itemsTarget;
    this.pagingTarget = pagingTarget;
    this.label = label;
}
PagingCached.prototype.gotoPage = function(pageNum) {
    this.currentOffset = (pageNum - 1) * this.currentPageSize;
    this.display();
}

PagingCached.prototype.display = function() {
    let slice = this.getCurrentSlice();
    this.displayFn(slice, this.itemsTarget);
    this.emitPagingRow();
}
PagingCached.prototype.emitPagingRow = function() {
    let colspecs = [
        newColumnSpec(`${gCommon.cols5or12} d-flex justify-content-center`),
        newColumnSpec(`${gCommon.cols1or12} d-flex justify-content-center`),
        newColumnSpec(`${gCommon.cols5or12} pt-1 ps-4 ms-3`)
    ];

    let rowIdPrefix = `paging`+this.label;
    $(`#${rowIdPrefix}Row`).remove();

    let row = makeRowWithColumns(this.pagingTarget, rowIdPrefix, colspecs, " myMs-0");
    let col1 = row.find(`#${rowIdPrefix}Col0`);
    let col2 = row.find(`#${rowIdPrefix}Col1`);
    let col3 = row.find(`#${rowIdPrefix}Col2`);

    this.emitPerPageDropdown(col1);

    let currentPageNum = this.getCurrentPageNum();
    let numPages = this.emitPageOfAndTotalPages(col2, currentPageNum);
    this.emitPrevNext(col3);

    this.adjustNavigation(currentPageNum, numPages);
}

PagingCached.prototype.emitPerPageDropdown = function(columnTarget) {
    let that = this;

    let label = $('<label for="pageSizeSelect" class="mt-1">Per Page </label>');
    let pageSizeSelect = $(`<select class="ms-1 mb-1" id="pageSizeSelect-${this.label}"></select>`);

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

        that.display(that.itemsTarget);
    });
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
PagingCached.prototype.getCurrentSlice = function() {
    let offset = this.currentOffset;
    let result = this.allTheItems.slice(offset, offset + this.currentPageSize);
    return result;
}

PagingCached.prototype.emitPageOfAndTotalPages = function(pageOfColumn, currentPageNum) {
    let that = this; // for embedded fns

    let labelB4 = $('<label for="pageNum" class="mt-1">Page </label>')
    let input = $(`<input class="ms-1 me-1 mb-1 pageNumInput" id="pageNum-${this.label}"/>`);
    let labelF2 = $('<label for="pageNum" class="mt-1"> of </label>');

    let numPages = this.getNumPages();
    let total = spanify(numPages, "ms-1 mt-1");

    input.val(currentPageNum);
    input.on('keypress',function(e) {
        e.stopPropagation();

        if(e.which == 13) {
            let inputTarget = $(e.target);
            let newPageNum = that.adjustInputPageNumber(inputTarget, numPages);
            that.currentOffset = (newPageNum - 1) * that.currentPageSize;
            that.display(pageOfColumn);
        }
    });
    pageOfColumn
        .append(labelB4)
        .append(input)
        .append(labelF2)
        .append(total);

    return numPages;
}
PagingCached.prototype.emitPrevNext = function(columnTarget) {
    let that = this; // for embedded functions

    let prevLabel = $(`<span id="prevLabel-${this.label}">
                            <span class="ms-2 link-ish prevNext mt-1 tableHeaderPagingRow">Prev</span>
                            <span class="ms-2 disablePageNav prevNext mt-1">Prev</span>
                    </span>`);
    let nextLabel = $(`<span id="nextLabel-${this.label}">
                            <span class="ms-2 link-ish prevNext mt-1 tableHeaderPagingRow">Next</span>
                            <span class="ms-2 disablePageNav prevNext mt-1">Next</span>
                    </span>`);

    let first = $(`<span id="first-${this.label}">
                    <img alt="arrowFirst" class="link-ish prevNext tableHeaderPagingRow" src="${gBrandingConstants.jsPagingImageFiles}arrow_first.gif">
                    <img alt="arrowFirst" class="disablePageNav prevNext" src="${gBrandingConstants.jsPagingImageFiles}arrow_first_d.gif">
                </span>`);
    let last =  $(`<span id="last-${this.label}">
                    <img alt="arrowLast" class="ms-2 link-ish prevNext tableHeaderPagingRow" src="${gBrandingConstants.jsPagingImageFiles}arrow_last.gif">
                    <img alt="arrowLast" class="ms-2 disablePageNav prevNext" src="${gBrandingConstants.jsPagingImageFiles}arrow_last_d.gif">
                </span>`);
    let prev =  $(`<span id="prev-${this.label}">
                    <img alt="arrowPrevious" class="ms-2 link-ish prevNext tableHeaderPagingRow" src="${gBrandingConstants.jsPagingImageFiles}arrow_prev.gif">
                    <img alt="arrowPrevious" class="ms-2 disablePageNav prevNext" src="${gBrandingConstants.jsPagingImageFiles}arrow_prev_d.gif">
                </span>`);
    let next =  $(`<span id="next-${this.label}">
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
        if (that.getCurrentPageNum() != 1) {
            that.gotoPage(1);
        }
    });
    last.on('click', function() {
        let lastPage = that.getNumPages();
        if (that.getCurrentPageNum() != lastPage) {
            that.gotoPage(lastPage);
        }
    });

    prev.on(        'click', function() {that.pageBefore();});
    prevLabel.on(   'click', function() {that.pageBefore();});
    nextLabel.on(   'click', function() {that.pageAfter ();});
    next.on(        'click', function() {that.pageAfter ();});
}
PagingCached.prototype.vetAndGotoPage = function(pageNum) {
    let numPages = this.getNumPages();

    if (this.allowPageNumber(pageNum, numPages)) {
        this.gotoPage(pageNum);
    }
}
PagingCached.prototype.pageBefore = function() {
    let currentPage = this.getCurrentPageNum();
    this.vetAndGotoPage(currentPage - 1);
}
PagingCached.prototype.pageAfter = function() {
    let currentPage = this.getCurrentPageNum();
    this.vetAndGotoPage(currentPage + 1);
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

