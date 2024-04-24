
/*
function setupWidthButton() {
    let dims;
    $(window).resize(function() {
        w = $(window).width();
        h = $(window).height();
        dims = `${w} x ${h}`;
        $('#widthButtonDiv').html(dims);
    });
}
*/

async function personReady() {
    try {
        let [jsonArray, lhsModules, rhsModules] = await commonSetupWithJson(comparePersonModules);

        //setupWidthButton();

        let numPersonsListed = tryMatchUrlParam(/numPersons=(\d+)/);
        gCommon.numPersons = numPersonsListed ? Number(numPersonsListed) : 0;

        setupScrolling();

        parsePerson(jsonArray, lhsModules, rhsModules);
    }
    catch (complaint) {
        let stack = Error().stack;
        alert(`Oops: ${complaint} (See console)`);

        console.log(complaint);
    }
}
function armTheTooltips() {
    // see https://stackoverflow.com/questions/67615880/tooltip-didnt-hide-after-click-on-element-bootstrap-v5-0
    $('[data-bs-toggle="tooltip"]').tooltip(); // enable BS tooltips
    $('[data-bs-toggle="tooltip"]').on('click', function () {
        $(this).tooltip('dispose');
    });
}
function asIdentifier(input) {
    let result = input.replace(/\W/g, "");
    return result;
}
// https://stackoverflow.com/questions/3552461/how-do-i-format-a-date-in-javascript
function yyyyDashMmDashDdStarTo(dateString, rearrangeMatchFn) {
    let match = dateString.match(/(....)-(..)-(..).*/);
    if (! match || ! rearrangeMatchFn) {
        console.log(`Cannot parse dateString: ${dateString}`);
        return;
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


function pushStringSpan(targetArray, input) {
    targetArray.push(spanify(input));
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




