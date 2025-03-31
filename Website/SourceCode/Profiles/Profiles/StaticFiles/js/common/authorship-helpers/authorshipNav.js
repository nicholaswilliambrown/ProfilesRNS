
function addPublicationsFirstTwoHeaderItems(target, ignore3) {
    gPerson.topDiv1 = $(`<div class="auth_topDiv1">
        Publications listed below are automatically derived from 
        MEDLINE/PubMed and other sources, which might result in 
        incorrect or missing publications. Faculty can 
        <a class="link-ish" href="${gCommon.loginUrl}">login</a> to make corrections and additions.
    </div>`);

    target.append(gPerson.topDiv1);

    gPerson.authNavButtonNewest = createNavItemDiv("authNavButtonNewest"              ,
                                    "Newest",
                                    authNavNewest);
    gPerson.authNavButtonOldest = createNavItemDiv("authNavButtonOldest"              ,
                                    "Oldest",
                                    authNavOldest);
    gPerson.authNavButtonMostCited = createNavItemDiv("authNavButtonMostCited"        ,
                                    "Most Cited",
                                    authNavMostCited);
    gPerson.authNavButtonMostDiscussed = createNavItemDiv("authNavButtonMostDiscussed",
                                    "Most Discussed",
                                    authNavMostDiscussed);

    if (! ignore3) {
        if (gPerson.timeline) {
            gPerson.authNavButtonTimeline = createNavItemDiv("authNavButtonTimeline",
                "Timeline",
                authNavTimeline, "green");
        }
        if (gPerson.fieldSummary) {
            gPerson.authNavButtonFieldSummary = createNavItemDiv("authNavButtonFieldSummary",
                "Field Summary",
                authNavFieldSummary, "green");
        }
        gPerson.authNavButtonPlainText = createNavItemDiv("authNavButtonPlainText",
            "Plain Text",
            authNavPlainText);
    }

    gPerson.authNavCurrentNavItem = gPerson.authNavButtonNewest;

    let colSpecs = [
        newColumnSpec(`${gCommon.cols1or12}`, gPerson.authNavButtonNewest),
        newColumnSpec(`${gCommon.cols1or12}`, gPerson.authNavButtonOldest),
        newColumnSpec(`${gCommon.cols2or12}`, gPerson.authNavButtonMostCited),
        newColumnSpec(`${gCommon.cols2or12}`, gPerson.authNavButtonMostDiscussed)];

    if (! ignore3) {
        colSpecs.push(newColumnSpec(`${gCommon.cols2or12}`, gPerson.authNavButtonTimeline));
        if (gPerson.fieldSummary) {
            colSpecs.push(newColumnSpec(`${gCommon.cols2or12}`, gPerson.authNavButtonFieldSummary));
        }
        if (gPerson.timeline) {
            colSpecs.push(newColumnSpec(`${gCommon.cols2or12}`, gPerson.authNavButtonPlainText));
        }
    }
    makeRowWithColumns(target, `nav-uls`, colSpecs);

    gPerson.authNavButtonNewest.click();
}


///////////////////////////////////////////////////
function authNavAdjustStyle(e) {
    $('.nav-link').removeClass("active").removeAttr("aria-current");
    $(e.target).addClass("active").attr("aria-current", true);
}
async function authNavNewest(e) {
    if (! gPerson.clickedShowAll) {
        gPerson.currentUnfilteredPubs = gPerson.initialPubs;
    }

    authNavAdjustStyle(e);
    gPerson.sort = PubsSortOption.Newest;
    await applySortsFiltersLimits(true);
}
async function authNavOldest(e) {
    if (! gPerson.clickedShowAll) {
        gPerson.currentUnfilteredPubs = await getSortedLimitedPubs(PubsLimitedSortParam.Oldest);
    }

    authNavAdjustStyle(e);
    gPerson.sort = PubsSortOption.Oldest;
    await applySortsFiltersLimits(true);
}
async function authNavMostCited(e) {
    if (! gPerson.mostCitedPubs) {
        gPerson.mostCitedPubs = await getSortedLimitedPubs(PubsLimitedSortParam.MostCited);
    }
    gPerson.currentUnfilteredPubs = gPerson.mostCitedPubs;

    authNavAdjustStyle(e);
    gPerson.sort = PubsSortOption.MostCited;
    await applySortsFiltersLimits(true);
}
async function authNavMostDiscussed(e) {
    if (! gPerson.clickedShowAll) {
        gPerson.currentUnfilteredPubs = await getSortedLimitedPubs(PubsLimitedSortParam.MostDiscussed);
    }

    authNavAdjustStyle(e);
    gPerson.sort = PubsSortOption.MostDiscussed;

    gPerson.extraAltmetricApplySort = true;
    await applySortsFiltersLimits();
}

async function getSortedLimitedPubs(sortParam) {
    let personId = getAuthorNodeId();

    let sortUrl = `${g.apiBasePath}?s=${personId}&t=${sortParam.description}`;
    let data = await $.get(sortUrl);
    let result = data[0].ModuleData[0].Publications;
    return result;
}

function authNavPlainText(e) {
    authNavAdjustStyle(e);
    authShowPlainText();
}
function mostDiscussedTabIsActive() {
    return ($(`#authNavButtonMostDiscussed`).hasClass('active'));
}

