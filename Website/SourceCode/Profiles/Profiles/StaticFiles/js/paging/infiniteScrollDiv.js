
// es5 style. If es6 widespread enough, could use nicer 'class' syntax
function InfiniteScrollDiv(getMoreFn, target, divClass, emitRowsFn, freezeDuringMore) {
    this.getMoreFn = getMoreFn;
    this.target = target;
    this.divClass = divClass;
    this.emitRowsFn = emitRowsFn;
    this.freezeDuringMore = freezeDuringMore;
}

// correct 'this' might be available after init(),
//   we will use 'that' to be safe  %^$#$@&^%!!
InfiniteScrollDiv.prototype.init = async (that) => {
    let theDiv = $(`<div id="scrollDiv" class="${that.divClass}"></div>`);

    that.div = theDiv;
    that.target.append(theDiv);

    let windowHeight75 = window.innerHeight * .75;
    theDiv.css("max-height", windowHeight75);

    // https://stackoverflow.com/questions/6271237/detecting-when-user-scrolls-to-bottom-of-div-with-jquery
    theDiv.on('scroll', async function() {
        let scrollTop = $(this).scrollTop();
        let innerHeight = $(this).innerHeight();
        let scrollHeight = $(that.target).innerHeight() - 1;
        console.log(`Scroll top, innerH, scrollH: ${scrollTop}, ${innerHeight}, ${scrollHeight}`)
        if(scrollTop + innerHeight >= scrollHeight) {
            console.log('end reached');
            await that.getAndEmitData(that);
        }
    });

    that.allowMore = true;

    await that.getAndEmitData(that);
}
InfiniteScrollDiv.prototype.freezeScroll = function(e) {
    e.preventDefault();
}
InfiniteScrollDiv.prototype.getAndEmitData = async function(that) {
    if (that.allowMore) {
        that.sayMore(that);
        let items = await that.getMoreFn();
        that.unSayMore(that);

        if (items.constructor === Array && items.length > 0) {
            that.emitRowsFn(items, that.div);
        }
        else {
            console.log(`Empty array or non-array (error message?): ${JSON.stringify(items)}`);
        }
    }
}
InfiniteScrollDiv.prototype.unSayMore = function(that) {
    that.div.find('.scrollMore').remove();
    that.div.removeClass('disableScrollDiv');
    that.div.off("scroll", that.freezeScroll); // jquery elt has off()
    that.allowMore = true;
}
InfiniteScrollDiv.prototype.sayMore = function(that) {
    if (that.freezeDuringMore) {
        that.div.on("scroll", that.freezeScroll);
        that.div.addClass('disableScrollDiv');
    }
    // in any case
    that.allowMore = false;

    that.div.find('.scrollMore').remove();
    that.div.append($('<div class="scrollMore">... LOADING ...</div>'));
    let sentinel = $('<div class="scrollMore"></div>')
    that.div.append(sentinel);
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
