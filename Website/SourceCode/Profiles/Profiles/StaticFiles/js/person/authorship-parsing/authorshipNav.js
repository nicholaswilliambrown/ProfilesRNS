
function addPublicationsFirstTwoHeaderItems(target) {
    gPerson.topDiv1 = $(`<div class="auth_topDiv1">
        Publications listed below are automatically derived from 
        MEDLINE/PubMed and other sources, which might result in 
        incorrect or missing publications. Faculty can 
        <a class="link-ish" href="${gCommon.loginUrl}">login</a> to make corrections and additions.
    </div>`);

    target.append(gPerson.topDiv1);

    gPerson.authNavButtonNewest = addAuthNavItem("authNavButtonNewest"              ,
                                    "Newest",
                                    authNavNewest);
    gPerson.authNavButtonOldest = addAuthNavItem("authNavButtonOldest"              ,
                                    "Oldest",
                                    authNavOldest);
    gPerson.authNavButtonMostCited = addAuthNavItem("authNavButtonMostCited"        ,
                                    "Most Cited",
                                    authNavMostCited);
    gPerson.authNavButtonMostDiscussed = addAuthNavItem("authNavButtonMostDiscussed",
                                    "Most Discussed",
                                    authNavMostDiscussed);
    gPerson.authNavButtonTimeline = addAuthNavItem("authNavButtonTimeline"          ,
                                    "Timeline",
                                    authNavTimeline , "green"    );
    gPerson.authNavButtonFieldSummary = addAuthNavItem("authNavButtonFieldSummary"  ,
                                    "Field Summary",
                                    authNavFieldSummary, "green" );
    gPerson.authNavButtonPlainText = addAuthNavItem("authNavButtonPlainText"        ,
                                    "Plain Text",
                                    authNavPlainText);

    gPerson.authNavCurrentNavItem = gPerson.authNavButtonNewest;

    let colSpecs = [
        newColumnSpec(`${gCommon.cols1or12}`, gPerson.authNavButtonNewest),
        newColumnSpec(`${gCommon.cols1or12}`, gPerson.authNavButtonOldest),
        newColumnSpec(`${gCommon.cols2or12}`, gPerson.authNavButtonMostCited),
        newColumnSpec(`${gCommon.cols2or12}`, gPerson.authNavButtonMostDiscussed),
        newColumnSpec(`${gCommon.cols2or12}`, gPerson.authNavButtonTimeline),
        newColumnSpec(`${gCommon.cols2or12}`, gPerson.authNavButtonFieldSummary),
        newColumnSpec(`${gCommon.cols2or12}`, gPerson.authNavButtonPlainText)
    ];
    makeRowWithColumns(target, `nav-uls`, colSpecs);
}
function addAuthNavItem(id, text, clickFn, aClass) {
    if (!aClass) {
        aClass = "";
    }
    // trivial href's accomplish getting the link to be tab-able, for accessibility
    let div = $(`<div class="hiZ nav-item"><button class="link-ish nav-link ${aClass}" id="${id}">${text}</button></div>`);
    div.on("click", clickFn);
    return div;
}


///////////////////////////////////////////////////
function authNavAdjustStyle(e) {
    $('.nav-link').removeClass("active").removeAttr("aria-current");
    $(e.target).addClass("active").attr("aria-current", true);
}
function authNavNewest(e) {
    authNavAdjustStyle(e);
    gPerson.sort = PubsSortOption.Newest;
    applySortsFiltersLimits(true);
}
function authNavOldest(e) {
    authNavAdjustStyle(e);
    gPerson.sort = PubsSortOption.Oldest;
    applySortsFiltersLimits(true);
}
function authNavMostCited(e) {
    authNavAdjustStyle(e);
    gPerson.sort = PubsSortOption.MostCited;
    applySortsFiltersLimits(true);
}
async function authNavMostDiscussed(e) {
    authNavAdjustStyle(e);
    gPerson.sort = PubsSortOption.MostDiscussed;

    gPerson.extraAltmetricApplySort = true;
    await applySortsFiltersLimits();
}

function authNavPlainText(e) {
    authNavAdjustStyle(e);
    authShowPlainText();
}
function mostDiscussedTabIsActive() {
    return ($(`#authNavButtonMostDiscussed`).hasClass('active'));
}

