
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

    // Real buttons in a labelled navigation region (a11y O3): keyboard users can Tab to them,
    // screen readers hear "Next page, button", and unavailable ones are truly disabled.
    // Each button holds an enabled and a disabled look; ableElt() shows one and hides the other.
    // The arrow pictures are decorative (alt=""): the button's aria-label names it.
    let img = (file) => `${gBrandingConstants.jsPagingImageFiles}${file}`;

    let first = $(`<button type="button" id="first" class="pagingButton" aria-label="First page">
                    <img alt="" class="link-ish prevNext tableHeaderPagingRow" src="${img('arrow_first.gif')}">
                    <img alt="" class="disablePageNav prevNext" src="${img('arrow_first_d.gif')}">
                </button>`);
    let prev =  $(`<button type="button" id="prev" class="pagingButton ms-2" aria-label="Previous page">
                    <img alt="" class="link-ish prevNext tableHeaderPagingRow" src="${img('arrow_prev.gif')}">
                    <img alt="" class="disablePageNav prevNext" src="${img('arrow_prev_d.gif')}">
                    <span class="ms-1 link-ish prevNext tableHeaderPagingRow">Prev</span>
                    <span class="ms-1 disablePageNav prevNext">Prev</span>
                </button>`);
    let next =  $(`<button type="button" id="next" class="pagingButton ms-2" aria-label="Next page">
                    <span class="me-1 link-ish prevNext tableHeaderPagingRow">Next</span>
                    <span class="me-1 disablePageNav prevNext">Next</span>
                    <img alt="" class="link-ish prevNext tableHeaderPagingRow" src="${img('arrow_next.gif')}">
                    <img alt="" class="disablePageNav prevNext" src="${img('arrow_next_d.gif')}">
                </button>`);
    let last =  $(`<button type="button" id="last" class="pagingButton ms-2" aria-label="Last page">
                    <img alt="" class="link-ish prevNext tableHeaderPagingRow" src="${img('arrow_last.gif')}">
                    <img alt="" class="disablePageNav prevNext" src="${img('arrow_last_d.gif')}">
                </button>`);

    let nav = $('<nav class="pagingNav d-flex align-items-center" aria-label="Search results pages"></nav>');
    nav.append(first)
        .append(prev)
        .append(next)
        .append(last);
    columnTarget.append(nav);

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
    // same result as $.isNumeric (removed in jQuery 4) for input strings
    if (typeof val === "string" && val.trim() !== "" && isFinite(val)) {
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
    // also right when there is only one page: then all four are disabled
    let firstAndPrevEnabled = pageNum > 1;
    let lastAndNextEnabled = pageNum < numPages;

    this.ableElt($('#prev'), firstAndPrevEnabled);
    this.ableElt($('#first'), firstAndPrevEnabled);

    this.ableElt($('#next'), lastAndNextEnabled);
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

// for jest testing -- 'module' does not exit in browser context
//        and jest does not seem to support (modern) ESM export/import
if (typeof module !== 'undefined' &&
    typeof module.exports !== 'undefined'  ) {
    // Use module.exports to make function visible to node tests
    module.exports.Paging = Paging;
}

