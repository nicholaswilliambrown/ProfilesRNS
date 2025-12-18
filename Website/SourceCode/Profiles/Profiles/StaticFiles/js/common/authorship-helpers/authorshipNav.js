
function addPublicationsFirstTwoHeaderItems(target, ignore3) {
    gPerson.topDiv1 = $(`<div class="auth_topDiv1">
        Publications listed below are automatically derived from 
        MEDLINE/PubMed and other sources, which might result in 
        incorrect or missing publications. Faculty can 
        <a class="link-ish" href="${gCommon.loginUrl}">login</a> to make corrections and additions.
    </div>`);

    target.append(gPerson.topDiv1);

    gPerson.authNavButtonNewest = createNavItemSpan("authNavButtonNewest"              ,
        "Newest",
        authNavNewest);
    gPerson.authNavButtonOldest = createNavItemSpan("authNavButtonOldest"              ,
        "Oldest",
        authNavOldest);
    gPerson.authNavButtonMostCited = createNavItemSpan("authNavButtonMostCited"        ,
        "Most&nbsp;Cited",
        authNavMostCited);
    gPerson.authNavButtonMostDiscussed = createNavItemSpan("authNavButtonMostDiscussed",
        "Most&nbsp;Discussed",
        authNavMostDiscussed);

    if (! ignore3) {
        if (gPerson.timeline) {
            gPerson.authNavButtonTimeline = createNavItemSpan("authNavButtonTimeline",
                "Timeline",
                authNavTimeline, "green");
        }
        if (gPerson.fieldSummary) {
            gPerson.authNavButtonFieldSummary = createNavItemSpan("authNavButtonFieldSummary",
                "Field&nbsp;Summary",
                authNavFieldSummary, "green");
        }
        gPerson.authNavButtonPlainText = createNavItemSpan("authNavButtonPlainText",
            "Plain&nbsp;Text",
            authNavPlainText);
    }

    gPerson.authNavCurrentNavItem = gPerson.authNavButtonNewest;

    let shortcuts = [   gPerson.authNavButtonNewest,
        gPerson.authNavButtonOldest,
        gPerson.authNavButtonMostCited,
        gPerson.authNavButtonMostDiscussed];

    if (! ignore3) {
        if (gPerson.authNavButtonTimeline) {
            shortcuts.push(gPerson.authNavButtonTimeline);
        }
        if (gPerson.authNavButtonFieldSummary) {
            shortcuts.push(gPerson.authNavButtonFieldSummary);
        }
        shortcuts.push(gPerson.authNavButtonPlainText);
    }

    emitNarrowShortcutsDiv(target, shortcuts);
    emitWideShortcutsDiv(target, shortcuts);
}
function emitWideShortcutsDiv(target, shortcuts) {
    let wideTarget = $(`<div class="wideShortcuts d-inline mt-2 ${gCommon.hideXsSmallShowOthers}"></div>`);
    target.append(wideTarget);

    let numShortcuts = shortcuts.length;
    for (let i=0; i<numShortcuts; i++) {
        // https://stackoverflow.com/questions/9549643/jquery-clone-not-cloning-event-bindings-even-with-on
        let shortcut = shortcuts[i].clone(true, true);
        wideTarget.append(shortcut);

        if (i == 0) {
            shortcut.addClass('ps-0');
        }
        shortcut.addClass('pt-0 pb-0')
        if (i < numShortcuts-1) {
            wideTarget.append($('<span class="d-inline"> | </span>'));
        }
    }
}
function emitNarrowShortcutsDiv(target, shortcuts) {
    let narrowTarget = $(`<div class="narrowShortcuts mb-4 ${gCommon.showXsSmallHideOthers}"></div>`);
    target.append(narrowTarget);

    let colSpecs = [];
    let numShortcuts = shortcuts.length;
    for (let i = 0; i < numShortcuts; i++) {
        // https://stackoverflow.com/questions/9549643/jquery-clone-not-cloning-event-bindings-even-with-on
        let shortcut = shortcuts[i].clone(true, true);
        shortcut.removeClass("d-inline");
        colSpecs.push(newColumnSpec("", shortcut));
    }

    makeRowWithColumns(narrowTarget, `uls-narrow`, colSpecs);
}

///////////////////////////////////////////////////
function authNavAdjustStyle(e) {
    $('.nav-link').removeClass("active").removeAttr("aria-current");
    $(e.target).addClass("active").attr("aria-current", true);
}
async function authNavNewest(e) {
    if (! gPerson.allPubsLoaded) {
        gPerson.currentUnfilteredPubs = gPerson.initialPubs;
    }

    authNavAdjustStyle(e);
    gPerson.sort = PubsSortOption.Newest;
    await applySortsFiltersLimits();
}
async function authNavOldest(e) {
    if (! gPerson.allPubsLoaded) {
        gPerson.currentUnfilteredPubs = await getSortedLimitedPubs(PubsLimitedSortParam.Oldest);
    }

    authNavAdjustStyle(e);
    gPerson.sort = PubsSortOption.Oldest;
    await applySortsFiltersLimits();
}
async function authNavMostCited(e) {
    if (! gPerson.allPubsLoaded) {
        gPerson.currentUnfilteredPubs = await getSortedLimitedPubs(PubsLimitedSortParam.MostCited);
    }

    authNavAdjustStyle(e);
    gPerson.sort = PubsSortOption.MostCited;
    await applySortsFiltersLimits();
}
async function authNavMostDiscussed(e) {
    if (! gPerson.allPubsLoaded) {
        await loadAllPubs();
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
    return ($(`.authNavButtonMostDiscussed`).hasClass('active'));
}

