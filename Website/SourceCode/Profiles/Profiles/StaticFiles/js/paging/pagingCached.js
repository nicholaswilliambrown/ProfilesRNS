// es6 style now prevalent
class PagingCached {
    constructor(allTheItems, sizes, displayFn, itemsTarget, pagingTarget, label) {
        this.allTheItems = allTheItems;
        this.currentPageSize = sizes[0];
        this.currentOffset = 0;
        this.sizes = sizes;
        this.displayFn = displayFn;
        this.itemsTarget = itemsTarget;
        this.pagingTarget = pagingTarget;
        this.label = label;
    }

    gotoPage(pageNum) {
        this.currentOffset = (pageNum - 1) * this.currentPageSize;
        this.display();
    }

    display() {
        let slice = this.getCurrentSlice();
        this.displayFn(slice, this.itemsTarget);
        this.emitPagingRow();
    }

    emitPagingRow() {
        let colspecs = [
            newColumnSpec(`${gCommon.cols2or12} d-flex justify-content-center`),
            newColumnSpec(`${gCommon.cols3or12} d-flex justify-content-end pe-3`),
            newColumnSpec(`${gCommon.cols1or12} d-flex justify-content-center`),
            newColumnSpec(`${gCommon.cols4or12} d-flex justify-content-start ps-3`)];

        let rowIdPrefix = `paging` + this.label;
        $(`#${rowIdPrefix}Row`).remove();

        let row = makeRowWithColumns(this.pagingTarget, rowIdPrefix, colspecs, " myMs-0");
        let col1 = row.find(`#${rowIdPrefix}Col0`);
        let col2 = row.find(`#${rowIdPrefix}Col1`);
        let col3 = row.find(`#${rowIdPrefix}Col2`);
        let col4 = row.find(`#${rowIdPrefix}Col3`);

        this.emitPerPageDropdown(col1);

        let currentPageNum = this.getCurrentPageNum();
        this.emitPrev(col2);
        let numPages = this.emitPageOfAndTotalPages(col3, currentPageNum);
        this.emitNext(col4);

        this.prevNextClicks();

        this.adjustNavigation(currentPageNum, numPages);
    }

    emitPerPageDropdown(columnTarget) {
        let that = this;

        let label = $(`<label for="pageSizeSelect-${this.label}" class="mt-1">Per Page </label>`);
        let pageSizeSelect = $(`<select class="ms-1 mb-1" id="pageSizeSelect-${this.label}"></select>`);

        columnTarget.append(label);
        columnTarget.append(pageSizeSelect);

        let sizes = this.sizes;

        let currentSize = this.currentPageSize;

        for (let i = 0; i < sizes.length; i++) {
            let size = sizes[i];
            let selected = size == currentSize ? "selected" : "";
            let option = $(`<option ${selected} value=${size}>${size}</option>`);
            pageSizeSelect.append(option);
        }

        pageSizeSelect.on('change', function (e) {
            let selectTarget = $(e.target);

            let pageSize = Number(selectTarget.val());

            that.currentPageSize = pageSize;
            that.currentOffset = Math.floor(that.currentOffset / pageSize) * pageSize;

            that.display(that.itemsTarget);
        });
    }

    getNumPages() {
        let numItems = this.allTheItems.length;
        let itemsPerPage = this.currentPageSize;

        let result = Math.ceil(numItems / itemsPerPage);
        if (!result) { // zero results
            result = 1; // 'page 1 of 1, not of 0
        }
        return result;
    }

    getCurrentPageNum() {
        let result = Math.floor(this.currentOffset / this.currentPageSize) + 1;
        return result;
    }

    getCurrentSlice() {
        let offset = this.currentOffset;
        let result = this.allTheItems.slice(offset, offset + this.currentPageSize);
        return result;
    }

    emitPageOfAndTotalPages(pageOfColumn, currentPageNum) {
        let that = this; // for embedded fns

        let labelB4 = $(`<label for="pageNum-${this.label}" class="mt-1">Page </label>`)
        let input = $(`<input class="ms-1 me-1 mb-1 pageNumInput" id="pageNum-${this.label}"/>`);
        let labelF2 = $('<span class="mt-1"> of </span>');

        let numPages = this.getNumPages();
        let total = spanify(numPages, "ms-1 mt-1");

        input.val(currentPageNum);
        input.on('keypress', function (e) {
            e.stopPropagation();

            if (e.which == 13) {
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

    emitPrev(columnTarget) {
        let that = this; // for embedded functions

        this.prevLabel = $(`<button class="noBorder" id="prevLabel-${this.label}">
                         <span class="enablePageNav link-ish prevNext mt-1 tableHeaderPagingRow">Prev</span>
                         <span class="disablePageNav prevNext mt-1">Prev</span>
                        </button>`);
        this.first = $(`<button class="noBorder ps-0 pe-0" id="first-${this.label}">
                        <img alt="arrowFirst" class="enablePageNav link-ish prevNext tableHeaderPagingRow" src="${gBrandingConstants.jsPagingImageFiles}arrow_first.gif">
                        <img alt="arrowFirst" class="disablePageNav prevNext" src="${gBrandingConstants.jsPagingImageFiles}arrow_first_d.gif">
                        </button>`);
        this.prev = $(`<button class="noBorder ps-2 pe-0" id="prev-${this.label}">
                        <img alt="arrowPrevious" class="enablePageNav link-ish prevNext tableHeaderPagingRow" src="${gBrandingConstants.jsPagingImageFiles}arrow_prev.gif">
                        <img alt="arrowPrevious" class="disablePageNav prevNext" src="${gBrandingConstants.jsPagingImageFiles}arrow_prev_d.gif">
                        </button>`);

        columnTarget.append(this.first)
                    .append(this.prev)
                    .append(this.prevLabel);
    }
    emitNext(columnTarget) {
        let that = this; // for embedded functions

        this.nextLabel = $(`<button class="noBorder" id="nextLabel-${this.label}">
                         <span class="enablePageNav link-ish prevNext mt-1 tableHeaderPagingRow">Next</span>
                         <span class="disablePageNav prevNext mt-1">Next</span>
                        </button>`);
        this.next = $(`<button class="noBorder ps-0 pe-0" id="next-${this.label}">
                        <img alt="arrowNext" class="enablePageNav link-ish prevNext tableHeaderPagingRow" src="${gBrandingConstants.jsPagingImageFiles}arrow_next.gif">
                        <img alt="arrowNext" class="disablePageNav prevNext" src="${gBrandingConstants.jsPagingImageFiles}arrow_next_d.gif">
                    </button>`);
        this.last = $(`<button class="noBorder ps-2 pe-0" id="last-${this.label}">
                        <img alt="arrowLast" class="enablePageNav link-ish prevNext tableHeaderPagingRow" src="${gBrandingConstants.jsPagingImageFiles}arrow_last.gif">
                        <img alt="arrowLast" class="disablePageNav prevNext" src="${gBrandingConstants.jsPagingImageFiles}arrow_last_d.gif">
                        </button>`);

        columnTarget.append(this.nextLabel)
                    .append(this.next)
                    .append(this.last);
    }
    prevNextClicks() {
        this.first.on('click', function () {
            if (that.getCurrentPageNum() != 1) {
                that.gotoPage(1);
            }
        });
        this.last.on('click', function () {
            let lastPage = that.getNumPages();
            if (that.getCurrentPageNum() != lastPage) {
                that.gotoPage(lastPage);
            }
        });

        this.prev.on('click', function () {
            that.pageBefore();
        });
        this.prevLabel.on('click', function () {
            that.pageBefore();
        });
        this.nextLabel.on('click', function () {
            that.pageAfter();
        });
        this.next.on('click', function () {
            that.pageAfter();
        });
    }

    vetAndGotoPage(pageNum) {
        let numPages = this.getNumPages();

        if (this.allowPageNumber(pageNum, numPages)) {
            this.gotoPage(pageNum);
        }
    }

    pageBefore() {
        let currentPage = this.getCurrentPageNum();
        this.vetAndGotoPage(currentPage - 1);
    }

    pageAfter() {
        let currentPage = this.getCurrentPageNum();
        this.vetAndGotoPage(currentPage + 1);
    }

    allowPageNumber(num, numPages) {
        let result = num > 0 && num <= numPages; // optimistic
        return result;
    }

    adjustInputPageNumber(input, numPages) {
        let val = input.val();
        let goodNumber = false;
        if ($.isNumeric(val)) {
            val = Number(val);
            if (val > 0 && val <= numPages) {
                goodNumber = true;
            }
        }
        if (!goodNumber) {
            val = 1;
        }
        input.val(val);
        return val;
    }

    adjustNavigation(pageNum, numPages) {
        let firstAndPrevEnabled = true;
        let lastAndNextEnabled = true;

        if (pageNum == 1) {
            firstAndPrevEnabled = false;
            lastAndNextEnabled = true;
        } else if (pageNum == numPages) {
            firstAndPrevEnabled = true;
            lastAndNextEnabled = false;
        }

        this.ableElt(this.prev, firstAndPrevEnabled);
        this.ableElt(this.prevLabel, firstAndPrevEnabled);
        this.ableElt(this.first, firstAndPrevEnabled);

        this.ableElt(this.next, lastAndNextEnabled);
        this.ableElt(this.nextLabel, lastAndNextEnabled);
        this.ableElt(this.last, lastAndNextEnabled);
    }

    ableElt(elt, which) {
        elt.prop("disabled", !which);
        if (which) {
            elt.find('.enablePageNav').removeAttr('hidden');
            elt.find('.disablePageNav').attr('hidden', true);
        } else {
            elt.find('.enablePageNav').attr('hidden', true);
            elt.find('.disablePageNav').removeAttr('hidden');
        }
    }

}
