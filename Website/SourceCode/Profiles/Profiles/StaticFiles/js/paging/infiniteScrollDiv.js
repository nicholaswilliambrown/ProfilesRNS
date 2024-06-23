
// es5 style. If es6 widespread enough, could use nicer 'class' syntax
function InfiniteScrollDiv(getMoreFn, target, divClass, emitRows, freezeDuringMore) {
    this.getMoreFn = getMoreFn;
    this.target = target;
    this.divClass = divClass;
    this.emitRows = emitRows;
    this.freezeDuringMore = freezeDuringMore;
}

InfiniteScrollDiv.prototype.init = async () => {
    this.div = $(`<div id="scrollDiv" class="${this.divClass}"></div>`);
    target.append(this.div);

    let windowHeight75 = window.innerHeight * .75;
    this.div.css("max-height", windowHeight75);

    // https://stackoverflow.com/questions/6271237/detecting-when-user-scrolls-to-bottom-of-div-with-jquery
    let that = this;
    this.div.on('scroll', async function() {
        let scrollTop = $(this).scrollTop();
        let innerHeight = $(this).innerHeight();
        let scrollHeight = this.scrollHeight - 1;
        //console.log(`Scroll top, innerH, scrollH: ${scrollTop}, ${innerHeight}, ${scrollHeight}`)
        if(scrollTop + innerHeight >= scrollHeight) {
            console.log('end reached');
            await that.getAndEmitData();
        }
    });

    this.allowMore = true;

    await that.getAndEmitData();
}
InfiniteScrollDiv.prototype.freezeScroll = function(e) {
    e.preventDefault();
}
InfiniteScrollDiv.prototype.getAndEmitData = async function() {
    if (this.allowMore) {
        this.sayMore();
        let items = await this.getMoreFn();
        this.unSayMore();

        this.emitRows(items, this.div);
    }
}
InfiniteScrollDiv.prototype.unSayMore = function() {
    this.div.find('.scrollMore').remove();
    this.div.removeClass('disableScrollDiv');
    this.div.off("scroll", this.freezeScroll);
    this.allowMore = true;
}
InfiniteScrollDiv.prototype.sayMore = function() {
    if (this.freezeDuringMore) {
        this.div.on("scroll", this.freezeScroll);
        this.div.addClass('disableScrollDiv');
    }
    // in any case
    this.allowMore = false;

    this.div.find('.scrollMore').remove();
    this.div.append($('<div class="scrollMore">... LOADING ...</div>'));
    let sentinel = $('<div class="scrollMore"></div>')
    this.div.append(sentinel);
    sentinel[0].scrollIntoView(false);
}
InfiniteScrollDiv.prototype.sum100 = (a, b) => {
    return a + b + 100;
}

// for jest testing -- 'module' does not exit in browser context
//        and jest does not seem to support (modern) ESM export/import
if (typeof module !== 'undefined' &&
    typeof module.exports !== 'undefined'  ) {
    // Use module.exports to make function visible to node tests
    module.exports.InfiniteScrollDiv = InfiniteScrollDiv;
}
