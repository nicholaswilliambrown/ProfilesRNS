
function appendEltFromBigString(elt, target) {
    // load via $.get(url) fails on some servers, status 301
    // So using JS string instead of html file
    // Perhaps try again with crossOriginAjax()

    target.append(elt);
}
async function setupPageStub(mainBodyStructure) {
    appendEltFromBigString(gCommon.mainDataContainer, $('body'));
    await loadBrandingAssets();

    setupSkipToContent();

    if (typeof emitPrefooter !== gCommon.undefined) { // supplied in myBranding.js
        emitPrefooter();
    }
    setupTopOfPageItems();
    loggedInShowHide();

    if (mainBodyStructure) {
        mainBodyStructure();
    }
}
async function commonSetup(mainBodyStructure) {
    // default is the rhs / lhs structure used on many pages
    if (!mainBodyStructure) {
        mainBodyStructure = setupMainStructure;
    }
    await setupPageStub(mainBodyStructure);

    setTabTitleAndFavicon();
}
async function commonSetupWithJson(moduleCompareFn) {
    await commonSetup();

    let pageJson = await getAndLogPageJson();

    let lhsModules, rhsModules;
    if (moduleCompareFn) {
        [lhsModules, rhsModules] =
            partitionModuleJsons(pageJson, moduleCompareFn);
    }

    return [pageJson, lhsModules, rhsModules];
}
function setupScrolling() {

    // When the user scrolls down from the top of the document, show the button
    window.onscroll = function () { scrollFunction() };

    let buttonsDiv = $(`
    <div id="rtnButtonsDiv">
        <div class="rtnBtnDiv" id="rtnBtnLgDiv">
            <button type="button" id="rtnBtnLg" class="rtnBtn" title="Go to top">Return to Top</button>
        </div>
        <div class="rtnBtnDiv" id="rtnBtnSmDiv">
            <button type="button" id="rtnBtnSm" class="rtnBtn" title="To top">To Top</button>
        </div>
    </div>`);
    $('body').append(buttonsDiv);

    $('#rtnBtnLg').addClass(gCommon.hideXsSmallShowOthers);
    $('#rtnBtnSm').addClass(gCommon.showXsSmallHideOthers);

    $('.rtnBtn').on("click", topFunction);

    //https://stackoverflow.com/questions/42441370/link-to-dynamically-created-div-on-another-page
    let potentialScrollTo = $(window.location.hash);
    if (potentialScrollTo.length > 0) {
        $('html, body').animate({
            scrollTop: $(potentialScrollTo).offset().top
        }, gCommon.scrollTime);
    }

    topFunction();
}

function scrollFunction() {
    let scrollTriggerHeight;
    let rtnBtnDiv = $(".rtnBtnDiv:visible");
    let rtnBtnDivId = rtnBtnDiv.attr("id");
    if (rtnBtnDivId == "rtnBtnLgDiv") {
        scrollTriggerHeight = 100;
    }
    else {
        scrollTriggerHeight = 25;
    }

    let pagePosition = (document.body.scrollTop || document.documentElement.scrollTop);

    if (pagePosition > scrollTriggerHeight)
    {
        $(".rtnBtnDiv").show();
    } else {
        $(".rtnBtnDiv").hide();
    }
    return true;
}

// When the user clicks on the button, scroll to the top of the document
function topFunction(e) {
    $('body,html').animate({ scrollTop: 0 }, gCommon.scrollTime);
    window.scrollTo({top: 0, behavior: 'smooth'});

    scrollFunction(); // button does not show at top 'scroll position'
    return true;
}

function setTabTitleAndFavicon(title) {
    if (!title) {
        title = window.location.pathname
            .replace(/.*\//, "")
            .replace(".html", "");
    }

    // which one?
    $(document).prop('title', title + gBrandingConstants.tabTitleSuffix);
    $(document).attr('title', title + gBrandingConstants.tabTitleSuffix);

    let faviconHref = `href="${gBrandingConstants.faviconUrl}"`;
    let head = $('head');
    head.append(`<link rel="icon" type="image/x-icon" ${faviconHref}>`);
    head.append(`<link rel="shortcut icon" type="image/x-icon" ${faviconHref}>`);
}
function setupMainStructure() {
    let mainDiv = $('#mainDiv');
    mainDiv.addClass(gCommon.mainDivClasses);

    let leftDiv = $('#modules-left-div');
    let rightDiv = $('#modules-right-div');

    leftDiv.addClass(gCommon.mainLeftCols);
    rightDiv.addClass(gCommon.mainRightCols);
}
function setupSkipToContent() {
    let skipButton = $(`<button id="skipButton" class="skip-to-main-content-link">Skip to main content</button>`);
    $('body').prepend(skipButton);
    skipButton.on("click", function() {
        location.href = "#mainDiv";
    })
}
async function getJsonData(url) {
    let result;
    try {
        await $.getJSON(url, function (data) {
            result = data;
        })
    } catch {
        alert(`Oops, cannot load this page's Data, (url: <${url}>)`);
        console.trace();
        result = [];
    }
    return result;
}
function partitionModuleJsons(jsonArray, lhsCompareFn) {
    let lhs = [];
    let rhs = [];

    jsonArray.forEach(arr => {
        if (arr.DisplayModule == "Person.Label") {
            let json = arr.ModuleData[0];

            // NB: person page gets corresponding info from its 'generalInfo'
            parseLabelInfo(json);
        }
        else if (arr.DisplayModule == "Coauthor.Timeline") {
            lhs.push(arr);
        }
        else if (arr["ModuleData"][0]
                && arr["ModuleData"][0]["ExploreLink"]) {
            rhs.push(arr);
        }
        else {
            lhs.push(arr);
        }
    })

    lhs = sortModules(lhs, lhsCompareFn);
    rhs = sortModules(rhs, compareExploreModules);

    return [lhs, rhs];
}
function makeModuleTitleDiv(moduleTitle) {
    let result = $(`<div id="${moduleTitle}"></div>`);
    return result;
}
function setupTopOfPageItems() {
    setUrlByAnchorId("loginA", gCommon.loginUrl);

    setupTopNav();
}
function loggedInShowHide() {
    gCommon.loggedIn = tryForLoggedInAsQp();

    if (gCommon.loggedIn) {
        $('#inviteLoginDiv').hide();
        $('#topNavbar2').show();
    }
    else {
        $('#inviteLoginDiv').show();
        $('#topNavbar2').hide();
    }
}
function makeRowWithColumns(target, idLabel, columnSpecArray, rowClass) {
    if (!rowClass) {
        rowClass = "";
    }
    let row = $(`<div id="${idLabel}Row" class="row ${rowClass}"></div>`);
    target.append(row);

    for (let i=0; i<columnSpecArray.length; i++) {
        let colSpec = columnSpecArray[i];
        let col = $(`<div class="${colSpec.classes}" id="${idLabel}Col${i}"></div>`);
        col.append(colSpec.value)
        row.append(col);
    }
    return row; // may be useful in caller
}
function newColumnSpec(classes, value) {
    if (value === undefined) value = $('<span></span>');

    return {classes: classes, value: value};
}
function spanify(content, klass) {
    let klassAttr = klass ? `class="${klass}"` : "";
    let span = $(`<span ${klassAttr}>${content}</span>`);
    return span;
}
function divSpanifyTo(content, target, spanClass, divClass) {
    let klassAttr = divClass ? `class="${divClass}"` : "";
    let div = $(`<div ${klassAttr}></div>`);
    div.append(spanify(content, spanClass));
    target.append(div);
    return div;
}
function toggleVisibility(togglingDiv, andThen) {

    if (togglingDiv.is(":visible")) {
        // may not need both of these two
        togglingDiv.hide();
        togglingDiv.addClass('d-none');

    }
    else {
        togglingDiv.removeClass('d-none');
        togglingDiv.show();
    }
    if (andThen) {
        andThen(togglingDiv);
    }
}
function getModuleData(modulesJson, displayName) {
    let result = null;
    let matchingModule = modulesJson
        .filter(m => m.DisplayModule == displayName);
    if (matchingModule.length == 1) {
        result = matchingModule[0].ModuleData;
    }
    return result;
}

function parseLabelInfo(json) {
    gCommon.fname = json.FirstName;
    gCommon.lname = json.LastName;
    gCommon.flName = `${json.FirstName} ${json.LastName}`;
    gCommon.displayName = json.DisplayName;
    gCommon.preferredPath = json.PreferredPath;
}
function getPersonLastname() {
    return gCommon.lname;
}
function getPersonFirstLastName() {
    return gCommon.flName;
}
function getPersonDisplayName() {
    return gCommon.displayName;
}

function setupExploreNetworks(target, rhsModules) {
    let lastname = getPersonLastname();
    emitHeaderForExplores(lastname);

    let anchorsNetworkArray = [];

    for (let i=0; i<rhsModules.length; i++) {
        let moduleJson = rhsModules[i];
        exploreParser(moduleJson, anchorsNetworkArray);
    }
    let result = emitNetworkLinks(anchorsNetworkArray, target);
    return result;
}
function emitNetworkLinks(anchorsNetworkArray, target) {
    let anchorNetworkLinksDiv = $(`<div id="anchorNetworkLinksDiv" 
            class="${gCommon.showXsSmallHideOthers} mb-3"></div>`);
    let anchorsNetworkInnerDiv = $(`<div id="anchorsNetworkInnerDiv" 
                                    class="network-links anchorLinksDiv ${gCommon.anchorLinksDivSpacing}"></div>`);

    anchorNetworkLinksDiv.append(anchorsNetworkInnerDiv);
    let comboNetworkAnchors = anchorsNetworkArray.join(`<span class="me-1"> | </span>`);
    anchorsNetworkInnerDiv.html(comboNetworkAnchors);

    anchorNetworkLinksDiv.insertAfter(target);
    return anchorsNetworkInnerDiv;
}
async function getAndLogPageJson() {
    await getPageJSON();
    let result = g.pageJSON;

    console.log("Page Json:", result);
    return result;
}
function compareLhsModules(m1, m2) {
    let m1Name = m1.DisplayModule.replace("Coauthor.", "");
    let m2Name = m2.DisplayModule.replace("Coauthor.", "");

    return compareStringsForSort(m1Name, m2Name);
}
function rememberArraySizeOfJsonModule(pageJson, moduleName, sessionKey) {
    let jsonArray = getModuleData(pageJson, moduleName);
    if (jsonArray) {
        toSession(sessionKey, String(jsonArray.length));
    }
}
function getEltBackTo(backUrl, backLabel) {
    let backArrow = $(`<img src="/StaticFiles/img/common/arrowLeft.png"
                         class="me-1" alt="">`);
    let returnA = createAnchorElement(`Back to ${backLabel}`, backUrl);
    returnA.prepend(backArrow);

    return returnA;
}
function emitCommonTopOfLhs(topLhsDiv, thingLabel, numThings, backUrl, backLabel) {
    let fullName = getPersonDisplayName();
    $('.topOfPageItems').append($(`<h2 class="boldCrimson">${fullName}</h2>`));

    let returnElt = getEltBackTo(backUrl, backLabel);
    let numThingsContent = numThings ? `(${numThings})` : "";

    let colspecs1 = [
        newColumnSpec(`${gCommon.cols6or12}`,
            spanify(`<strong>${thingLabel} ${numThingsContent}</strong>`)),
        newColumnSpec(`${gCommon.cols6or12} d-flex justify-content-end`,
            returnElt),
    ];
    makeRowWithColumns(topLhsDiv, "topLhs", colspecs1);
}
function createFlavorTabs(flavorArray) {
    // see https://getbootstrap.com/docs/5.0/components/navs-tabs/

    let tabChoicesDiv = $(`<div id="tabChoicesDiv" class="tabChoices container ps-0 mb-2 pe-0"></div>`);
    let navUl = $('<ul class="nav"></ul>');

    tabChoicesDiv.append(navUl);

    for (flavor of flavorArray) {
        let li = $(`<li class="nav-item">
                        <a id="navTo${flavor}" class="tabTopHat nav-link">${flavor}</a>
                    </li>`);
        navUl.append(li);
    }
    return tabChoicesDiv;
}
function createTimelineDiv(blurb) {
    let timelineDiv = $(`<div id="moveableContentDiv">
        <div id="divTimelineGraph">
            <div id="timelineGraphInner">
                <div class='tabInfoText mt-2 mb-2 pb-2'>
                    <div id="timelineBlurb">${blurb}</div>
                    <hr class="tightHr"/>
                </div>
            </div>
            <div style="clear:both;text-align:left;">
                <br/>
                To see the data from this visualization as text,
                <a id="toDivTimelineText" tabindex="0" class="link-ish">
                    click here.</a>
            </div>
        </div>
        <div id="divTimelineText">
            <div id="timelineTextInner" class="mt-2">
            </div>
            <br/>
            To return to the timeline,
            <a id="toDivTimeline" tabindex="0" class="link-ish">
                click here.</a>
        </div>
    </div>`);

    return timelineDiv;
}
function createTopLhsDiv() {
    let lhsDiv = $('#modules-left-div');
    let topLhsDiv = $(`<div id="topLhsDiv"></div>`);
    lhsDiv.append(topLhsDiv);

    return topLhsDiv;
}
function emitTopOfLhsAndExplores(params) {
    
    let topLhsDiv = createTopLhsDiv();
    let numThings = fromSession(params.numThingsKey);

    let profileUrl = `${gCommon.preferredPath}`;
    emitCommonTopOfLhs(topLhsDiv, params.thingsLabel, numThings,
        profileUrl, 'Profile');

    topLhsDiv.append(params.descriptionDiv);

    appendEltFromBigString(params.thingTabs, topLhsDiv);

    params.adjustTabs();

    setupExploreNetworks(params.descriptionDiv, params.rhsModules);
}
function createAnchorElement(text, url) {
    let result = $(`<a class="link-ish" href="${url}">${text}</a>`);
    return result;
}
function moveContentTo(item, target) {
    item.detach().appendTo(target);
}
function moveContentByIdTo(itemId, target) {
    let item = $(`#${itemId}`);
    moveContentTo(item, target);
}
function hoverLight(elt, inThen, outThen) {
    elt.on('mouseenter', function () {
        $(this).toggleClass("hoverDark");
        if (inThen) {
            inThen();
        }
    })
        .on('mouseleave', function () {
            $(this).toggleClass("hoverDark");
            if (outThen) {
                outThen();
            }
        });
}
function makeArrowedConnectionLine() {
    let left = $(`<img class="connectionArrow" src="/StaticFiles/img/common/connection_left.gif" alt="Left Arrow"/>`);
    let line = $('<span class="w-100 connectionLine"></span>');
    let right = $(`<img class="connectionArrow" src="/StaticFiles/img/common/connection_right.gif" alt="Right Arrow" />`);

    let doubleArrow = $('<span class="w-100 d-flex justify-content-center"></span>');
    doubleArrow.append(left).append(line).append(right);

    return doubleArrow;
}