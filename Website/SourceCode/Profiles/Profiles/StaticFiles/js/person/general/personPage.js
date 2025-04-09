async function personReady() {
    let lhsModules, rhsModules, hiddenModules;
    [lhsModules, rhsModules, hiddenModules] = await personPreload();

    try {
        setupAnchorDivs($('#GeneralInfo-top'));
        populateLhsAnchors();

        let jsonArray = await myGetPageJson();
        // second, fuller version of data
        [lhsModules, rhsModules, hiddenModules] = partitionFullModules(jsonArray);

        initAuthorNodeId(jsonArray, "Person.Label");

        let numPersonsListed = tryMatchUrlParam(/numPersons=(\d+)/);
        gCommon.numPersons = numPersonsListed ? Number(numPersonsListed) : 0;

        console.log("jsonArray", jsonArray);
        setupScrolling();

        await parsePerson(
            jsonArray,
            lhsModules,
            rhsModules,
    function() {
                let loadNotices = $(`.loadInProgress`);
                loadNotices.remove();

                let tentatives = $(`.${gCommon.tentative}`);
                let tentLhsParents = tentatives.closest('.accordion-body.unnested');
                let parentInnerButton = tentatives.closest('.accordion-button.unnested');
                let outerDiv = tentatives.closest('div.accordion.unnested').parent();

                // bright potential failed to manifest
                tentatives.remove();
                tentLhsParents.remove();
                if (!parentInnerButton.children().length) {
                    let outerDivId = outerDiv.attr('id');
                    outerDiv.remove();
                    if (outerDivId) {
                        let anchorId = outerDivId.replace('-outer', '');
                        let anchor = $('#modules-left-div').find(`a[href="#${anchorId}"`);
                        anchor.remove();
                    }
                }
                // SkeletonPattern needs to call unHideFooter()
                // Alternatively, innerCurtainsUp() calls it
                unHideFooter();

                // could not populate these anchors in skeleton, need url info
                populateRhsAnchors(true);

                $('.authNavButtonNewest').click();
            });
    }
    catch (complaint) {
        let stack = Error().stack;
        alert(`Oops: ${complaint} (See console)`);

        console.log(complaint);
    }
}

// https://stackoverflow.com/questions/3552461/how-do-i-format-a-date-in-javascript
function yyyyDashMmDashDdStarTo(dateString, rearrangeMatchFn) {
    let match = dateString.match(/(....)-(..)-(..).*/);
    if (! match || ! rearrangeMatchFn) {
        console.log(`Cannot parse dateString: ${dateString}`);
        return dateString;
    }

    let result = rearrangeMatchFn(match);
    return result;
}
function fromMatchToDdMdYyyy(matchYMD) {
    return `${matchYMD[3]}/${matchYMD[2]}/${matchYMD[1]}`
}
function fromMatchToMmmDdYyyy(matchYMD) {
    let mmm = gCommon.monthNames[Number(matchYMD[2]) - 1];
    return `${mmm} ${Number(matchYMD[3])}, ${matchYMD[1]}`
}
function comparePersonLhsModules(m1, m2) {
    return compareLhsModules(m1, m2, "Person", whichParserInfo);
}


// https://stackoverflow.com/questions/32057153/can-jquery-getscript-show-the-file-as-a-resource-in-chrome-developer-tools
//
// Could be useful if we don't want to mention all the *.js in person.html
function loadDevToolVisibleScript(scriptPath, continuation) {
    // not sure how / whether similar result might come via jquery
    let deferred = $.Deferred();
    let script = document.createElement('script');
    script.src = scriptPath;
    script.onload = function () {
        deferred.resolve();
        if (continuation) {
            continuation;
        }
    }
    script.onerror = function() {
        deferred.reject();
    }

    /****
     * https://byby.dev/js-wait-for-multiple-promises#:~:text=Using%20async%2Fawait,is%20either%20fulfilled%20or%20rejected%20.
     *
     * You can use promises with async/await by declaring an async function
     * and using the await keyword before a call to a function that returns
     * a promise. This makes the code wait at that point until the promise
     * is settled, meaning it is either fulfilled or rejected. When the
     * promise is fulfilled, the value of the await expression becomes that
     * of the fulfilled value of the promise. If the promise is rejected,
     * the await expression throws the rejected value.
     */

    document.body.appendChild(script);
    return deferred.promise();
}
function parsePersonModulesAndData(
    moduleWithDataJson,
    whichInfo,
    accordionCache,
    andThen) {

    let moduleTitle = getModuleEltTitle(moduleWithDataJson);
    if (gPerson.fleshySkeleton.get(moduleTitle)) {
        // this data was already presented in the early skeleton
        return;
    }
    let targetDiv = getTargetUntentavizeIfSo(moduleTitle);

    let moduleData = moduleWithDataJson.ModuleData;

    let moduleMainDiv = $('#modules-left-div');

    let parserInfo = whichInfo(moduleTitle, moduleMainDiv);

    let parser = parserInfo.parser;

    let parsedData = parser(moduleData, moduleTitle, parserInfo.misc);

    targetDiv.append(parsedData);

    if (andThen) {
        andThen();
    }
}



