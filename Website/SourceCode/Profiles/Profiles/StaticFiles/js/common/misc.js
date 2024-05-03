
// handy if pid was in page url. O'wise may need backend to supply in json
gCoauthor.personId = personUriPid();

function personUriFromUrlPath() {
    let url = window.location.href;

    let result = url.replace(/.*(\/display\/\d+).*/, "$1");
    return result;
}
function personUriPid() {
    let result = personUriFromUrlPath().replace("/display/", "");
    return result;
}
function tryForLoggedInAsQp() {
    return tryMatchUrlParam(/(loggedIn)/);
}
function tryMatchUrlParam(regex) {
    // returns $1 from regex, so make sure to set up for $1
    let wSearch = window.location.search;
    let match = wSearch.match(regex);

    let result = match ? match[1] : "";
    return result;
}
function defaultLeftSideParser(moduleJson, moduleTitle) {
    let parseResult = $('<div></div>');

    let thisIsWhereDiv = $(`<hr/><div class="bold green">
        The following data (if any) is what we will display (nicely) for Module: ${moduleTitle}</div>`)
    console.log("append??", parseResult);
    parseResult.append(thisIsWhereDiv);

    displayJson(parseResult, moduleJson);

    return parseResult;
}
function stringifyJson(json) {
    return JSON.stringify(json, null, 2);
}
function displayJson(target, json) {
    let diagnostic = $(`<div>${stringifyJson(json)}</div>`);
    target.append(diagnostic);
}
function dynamicGetWidth(text, tempTarget) {
    // you don't get width until you are plugged into DOM
    let span = $(`<span>${text}</span>`);
    tempTarget.append(span);

    let result = span.width();
    span.detach(); // stop exploiting tempTarget

    return result;
}
function ellipsizeToFit(text, target, extraWidth) {
    let result = text;

    let targetWidth = target.width();

    let dotsWidth = dynamicGetWidth('...', target);
    let textWidth = dynamicGetWidth(text, target);

    if (textWidth + extraWidth > targetWidth) {
        while (textWidth + extraWidth + dotsWidth > targetWidth) {
            text = text.substring(0, text.length - 1);
            textWidth = dynamicGetWidth(text, target);
        }
        result = text + "...";
    }
    return result;
}
function initialCapital(input) {
    return input.charAt(0).toUpperCase() + input.substring(1);
}
function dateStringToDate(dateString) {
    let date = new Date(dateString);
    return date;
}
function dateToNumsYMD(date) {
    let year = date.getFullYear();
    let month = date.getMonth();
    let day = date.getDate();

    let result = [year, month, day];

    return result;
}
function dateStringToMDY_1(dateString) {
    let date = dateStringToDate(dateString);
    let [year, month, day] = dateToNumsYMD(date);

    // zero-index
    day++;

    // second row of monthNames
    month = gCommon.monthNames[month + 12];

    let result = `${month} ${day}, ${year}`;
    return result;
}
function orNA(input) {
    let result = input ? input : gCommon.NA;
    return result;
}
function toSession(key, object) {
    let stringy = JSON.stringify(object);
    window.sessionStorage.setItem(key, stringy);
}
function fromSession(key) {
    let stringy = window.sessionStorage.getItem(key);

    let result = JSON.parse(stringy);
    return result;
}
function fromSessionOrInit(key, init) {
    let candidate = fromSession(key);
    if (null == candidate) {
        candidate = init;
        toSession(key, candidate);
    }
    return candidate;
}
