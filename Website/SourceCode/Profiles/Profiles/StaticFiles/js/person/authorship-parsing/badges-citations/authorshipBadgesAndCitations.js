function addBadgeSpans(linkItems, pub) {
    let bibo = pub.bibo_pmid;
    if (bibo) {
        let badgeSpan = $(`<span class="ms-4 me-4"><a class="__dimensions_badge_embed__" data-hide-zero-citations="true" 
                                data-style="small_rectangle" data-pmid="${bibo}"></a></span>`);

        let embedSpan = $(`<a class='altmetric-embed me-2' data-link-target='_blank' data-badge-popover='bottom' 
                                data-badge-type='4' data-hide-no-mentions='true' data-pmid="${bibo}"></a>`);

        linkItems.push(badgeSpan);
        linkItems.push(embedSpan);
    }
}
function addDimensionsBadgesAndCheckLabel() {
    $.when(window.__dimensions_embed.addBadges()).done(function () {
        setTimeout(function () {

            $(".__dimensions_Badge_Image svg").remove();
            $(".__dimensions_Badge_Image .__cits__").remove(); // dup prevented for 'mostDiscussed' / 'showAll'
            $(".__dimensions_Badge_Image").prepend(`<img alt="dimensions citations" class="__cits__" 
                    src=${gBrandingConstants.jsPersonImageFiles}citations.png>`);
            $(".__db_score.__db_score_normal").css("font-size", "10px");
            $(".__db_score.__db_score_normal").css("font-family", "arial");


            $('.__dimensions_badge_embed__').each(function () {
                if ($(this).attr('data-dimensions-badge-installed') === undefined) {
                    /////$(this).remove();
                }
            });
            $('[id*="spnHideOnNoAltmetric"]').each(function () {
                $(this).css("margin-left", "5px");
            });

            possiblyShowCitationsCategory();

            // now that it has been generated, style the
            //    'inner' <a> of altmetric
            $('a.altmetric-embed').find('a').addClass('link-ishB');
            $('a.__dimensions_badge_embed__').find('a.__dimensions_Link').addClass('link-ishB');
            $('a.__dimensions_badge_embed__').find('.__cits__').addClass('wrap3');
            $('a.__dimensions_badge_embed__').find('.__db_score').addClass('wrap3');
            $('a.__dimensions_badge_embed__').find('.__dimensions_png').hide();

        }, gPerson.waitForDimensions);
    });
}

function possiblyShowCitationsCategory() {
    let categoryLabels = $('.citations-category');

    categoryLabels.each(function() {
        let parent = $(this).parent();
        if (    (parent.find('.altmetric-embed').length > 0)
            ||  (parent.find('.__dimensions_badge_embed__').length > 0)
            ||  (parent.find('.pmc_citation').length > 0)) {
            parent.find('.citations-category').show();
        }
        else {
            console.log("both altmetric and dimensions are missing");
        }
    });
}

function digestInjectedBadges() {
    try {
        $.getScript("https://d1bxh8uas1mnw7.cloudfront.net/assets/embed.js", function () {
            setTimeout(function () {

                console.log('Reloaded embedded altmetric');
                $('.altmetric-embed.altmetric-hidden').each(function() {
                    $(this).remove();
                });
            }, gPerson.waitForAltmetric);

            addDimensionsBadgesAndCheckLabel();

            consoleAltmetricStats("About to maybeComputeAltmetricScores");

            // now that the embed.js had a chance to emit them...
            if (   mostDiscussedTabIsActive()
                && gPerson.numAltMetricTries < gPerson.maxAltMetricScoreTries
                && maybeComputeAltmetricScores()) {

                gPerson.numAltMetricTries++;
                applySortsFiltersLimits(); // this time more altmetric val's will help the sort
            }
        });
    }
    catch (e) {
        console.log('ERROR in digestInjectedBadges');
    }
}
function pmids(pub) {
    let pmcid = (pub.vivo_pmcid) ? `PMCID: <a href="${gPerson.pmcUrlStart}${pub.vivo_pmcid}">${pub.vivo_pmcid}</a>` : "";
    let pmid = (pub.bibo_pmid) ? `PMID: <a href="${gPerson.pmUrlStart}${pub.bibo_pmid}">${pub.bibo_pmid}</a>` : "";

    let idsArray = [];
    if (pmid) idsArray.push(pmid);
    if (pmcid) idsArray.push(pmcid);

    let result = idsArray.join("; ");
    return result;
}

function addPmcAndRcrCitations(linkItems, pub) {
    let pmcCitations = pub.PMCCitations;
    let rcrValue = pub.RelativeCitationRatio;
    let pmid = pub.bibo_pmid;
    let url = gPerson.pmcUrlCitedByTemplate.replace(gPerson.pucbtPlaceholder, pmid);

    if (pmcCitations) {
        let graphic = $(`<a href="${url}" class="link-ishB pmc_citation ms-0 me-2 pe-2">${pmcCitations}</a>`);
        graphic.css("background-image",
            `url("${gBrandingConstants.jsPersonImageFiles}PMC-citations.jpg")`);

        linkItems.push(graphic);
    }
    if (rcrValue > 0) {
        let rcrSpan = $(`<span class="me-2 ms-1 p-0 RCR-citations"><span class='RCR-count'>${rcrValue}</span></span>`);
        linkItems.push(rcrSpan);
    }
}

// display bottom-items we have collected for a given publication
function harvestBottomlinkItems(target, linkItems, prefixItem) {
    if (linkItems.length > 0) {
        // private copy. see https://stackoverflow.com/questions/7486085/copy-array-by-value
        let myLinkItems = linkItems.slice();

        if (prefixItem) {
            myLinkItems.unshift(prefixItem);
        }

        let div = $('<div class="wrap2 mt-1 me-1"></div>')
        target.append(div);
        for (let j=0; j<myLinkItems.length; j++) {
            div.append(myLinkItems[j]);
            div.append($('<span> </span>'));
        }
    }
}