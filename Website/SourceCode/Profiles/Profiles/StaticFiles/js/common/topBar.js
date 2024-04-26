
function adjustMyPersonList() {
    $('#nav2Persons').html(`My Person List (${gCommon.numPersons})`);

    // todo: we might have more granular semantics based on 'this person'
    //   vis-a-vis elements of the list
    switch (gCommon.numPersons) {
        case 0:
            $('#addPersonList').show();

            $('#clearPersonList').hide();
            $('#removePersonList').hide();
            break;
        case 1:
            $('#removePersonList').show();

            $('#clearPersonList').hide();
            $('#addPersonList').hide();
            break;
        default:
            $('#clearPersonList').show();
            $('#addPersonList').hide();

            $('#removePersonList').hide();
    }
}

function setupTopNav() {
    let topNavbar = $('#topNavbar, #topNavbar2');

    setUrlByAnchorId("overviewA", gCommon.overviewAUrl);
    setUrlByAnchorId("openSourceSoftwareA", gCommon.openSourceSoftwareAUrl);
    setUrlByAnchorId("seeAllPagesA", gCommon.seeAllPagesAUrl);
    setUrlByAnchorId("topHome", gCommon.findPeopleUrlFromRoot);
    setUrlByAnchorId("helpA", gCommon.helpUrl);
    setUrlByAnchorId("logoutA", gCommon.logoutUrl);

    setupNavHistory(`${gCommon.cols12}`);

    setupNavSearch(topNavbar);

    $('#navbar1outerRow').addClass(`${gCommon.cols12}`);

    $('#fourItems').addClass(`${gCommon.cols5or12Lg}`);
    $('#longerItem').addClass(`${gCommon.cols7or12Lg}`);

    $(`#topNavHome`).addClass(`${gCommon.cols3or12}`);
    $(`#topNavAbout`).addClass(`${gCommon.cols3or12}`);
    $(`#topNavHelp`).addClass(`${gCommon.cols3or12}`);
    $(`#topNavHistory`).addClass(`${gCommon.cols3or12} ps-0`);

    $(`#topNavSearch`).addClass(`${gCommon.cols12} pe-2`);

    $(`#topNav2Edit`).addClass(`${gCommon.cols2or12}`);
    $(`#topNav2Proxies`).addClass(`${gCommon.cols2or12}`);
    $(`#topNav2Persons`).addClass(`${gCommon.cols2or12}`);
    $(`#topNav2Opportunity`).addClass(`${gCommon.cols2or12}`);
    $(`#topNav2Logout`).addClass(`${gCommon.cols1or12} pe-2`);

    $(`#topNav2White`).addClass(`${gCommon.cols3or12}`);

    adjustMyPersonList();

    topNavbar.find('div.dropdown').on("mouseenter", function (e) {
        showVsHideNavDropdown(e, true);
    });
    topNavbar.find('div.dropdown').on("mouseleave", function (e) {
        showVsHideNavDropdown(e, false);
    });


}

function addSearchForm(target, formClass, searchGlassClass, displayClass, sizeFlavor, justifyPos) {
    let displayDiv = $(`<div class="${displayClass}"></div>`);
    target.append(displayDiv);

    let form = $(`<form class="top ${formClass} d-flex justify-content-${justifyPos}">
                                <input class="form-control navSearchTerm ps-0" id="navSearchTerm${sizeFlavor}" type="search" aria-label="Search"
                                       placeholder=" Search Profiles (people, publications, concepts, etc.)">
                                <div id="searchGlassDiv${sizeFlavor}" class="searchGlassDiv">                              
                                    <img id="navSearchGlass${sizeFlavor}" 
                                        class="navSearchGlass searchMagGlass 
                                        ${searchGlassClass} pt-2 pe-2"/>
                                </div>
                                <div class="dropdown">
                                    <a class="search dropdown-toggle" href="#" id="navbarDropdown3${sizeFlavor}" role="button"
                                       data-bs-toggle="dropdown" aria-expanded="false">
                                        <img class="downArrow downArrow${sizeFlavor}">
                                    </a>
                                    <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="navbarDropdown3">
                                        <li><a id="findPeopleA${sizeFlavor}" class="dropdown-item" href="#">Find People</a></li>
                                        <li><a id="findEverythingA${sizeFlavor}" class="dropdown-item" href="#">Find Everything</a></li>
                                    </ul>
                                </div>
                            </form>`);
    displayDiv.append(form);
    setUrlByAnchorId(`findPeopleA${sizeFlavor}`, gCommon.findPeopleUrlFromRoot);
    setUrlByAnchorId(`findEverythingA${sizeFlavor}`, gCommon.findEverythingUrlFromRoot);
}

function setupNavSearch(topNavbar) {
    let navSearchItem = $('#topNavSearch');

    // large and small versions
    addSearchForm(navSearchItem, "formHeightDesktop",
        "searchMagGlassWide", gCommon.hideXsSmallShowOthers, gCommon.large, "end");
    addSearchForm(navSearchItem, "formHeightPhone",
        "searchMagGlassNarrow", gCommon.showXsSmallHideOthers, gCommon.small, "start");

    let searchGlass = $('.navSearchGlass:visible');
    let searchTerm = $('.navSearchTerm:visible');

    searchGlass.on("click", doNavSearch);

    searchTerm.on("keypress", function(e) {
        let keycode = e.keyCode || e.which;
        if(keycode == '13') {
            doNavSearch(e);
        }
    });

    topNavbar
        .find('.downArrow')
        .attr("src", `${gBasic.jsCommonImageFiles}arrowDown.png`);
    topNavbar
        .find('.searchMagGlass')
        .attr("src", `${gBasic.jsCommonImageFiles}blackMagnifyGlass.png`);
}
function doNavSearch(e) {
    e.preventDefault();
    e.stopPropagation();

    let searchTerm = $('.navSearchTerm:visible').val().trim();
    console.log(`searching: [${searchTerm}]`);

    let searchUrl = gCommon.emptySearchUrl;
    if (searchTerm) {
        let encodedTerm = encodeURI(searchTerm);
        let delta = gCommon.nonemptySearchUrlSchema.replace(gCommon.schemaPlaceholder, encodedTerm);
        searchUrl += delta;
    }
    console.log(`About to navigate to: [${searchUrl}]`);

    window.location.href = searchUrl;
}
function setupNavHistory() {
    // todo: prob a REST call -- or does client page keep track of whom we've seen before??
}
function addPersonToNavHistory(fname, lname, url) {
    let ul = $('#topHistoryDropdown');

    let numPersons = ul.find('.dropdown-item').length - 1; // don't count the "See All" item

    let personLi = $(`<li><a class="dropdown-item" href="${url}">${lname}, ${fname}</a></li>`);
    ul.prepend(personLi);

    let historyHtml = 'History' + (++numPersons > 0 ? ` (${numPersons})` : "");

    let ourA = ul.closest('.nav-item').find('.nav-link');
    ourA.html(historyHtml);
}
function showVsHideNavDropdown(e, showVsHide) {
    let jqItem = $(e.target);

    // start from correct parent 'nav-item'
    if (! jqItem.hasClass('nav-item')) {
        jqItem = jqItem.closest('.nav-item');
    }

    // if parent has a toggle child
    if (jqItem.find('.dropdown-toggle')) {

        // find and affect the ul sibling(s)
        let ul = jqItem.find('ul');
        if (showVsHide) {
            ul.show();
        }
        else {
            ul.hide();
        }
    }
}

function setUrlByAnchorId(aid, url) {
    $(`#${aid}`).attr('href', url);
}
