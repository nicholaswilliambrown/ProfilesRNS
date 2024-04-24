function listParse(target, moduleJson) {
    console.log('================ list parse -----------------', moduleJson);

    let jsonData = moduleJson.ModuleData;

    let wideTarget = $(`<div class="${gCommon.hideXsSmMdShowOthers}"></div>`);
    let narrowTarget = $(`<div class="${gCommon.showXsSmMdHideOthers}"></div>`);

    target.append(wideTarget);
    target.append(narrowTarget)

    wideColumnsList(wideTarget, jsonData);
    narrowColumnsList(narrowTarget, jsonData);
}

function wideColumnsList(target, jsonData) {
    let uListLeft = $('<ul></ul>');
    let uListMidLeft = $('<ul></ul>');
    let uListMidRight = $('<ul></ul>');
    let uListRight = $('<ul></ul>');

    let colspecs = [
        newColumnSpec(`${gCommon.cols3or12}`, uListLeft),
        newColumnSpec(`${gCommon.cols3or12}`, uListMidLeft),
        newColumnSpec(`${gCommon.cols3or12}`, uListMidRight),
        newColumnSpec(`${gCommon.cols3or12}`, uListRight)
    ];
    makeRowWithColumns(target, "fourLists", colspecs, `mt-2`);

    let numItems = jsonData.length;
    for (let i = 0; i < numItems; i++) {
        let conn = jsonData[i];
        let name = conn.Name;

        // Urls should be in the form of display/person/xxxx. The form /profile/pid is deprecated
        let url = `${conn.URL}`;
        // bug: the urls might show up as //display, should be /display
        url = url.replace(/\/\//, "/");

        let whichList;
        if (i <= numItems / 4) {
            whichList = uListLeft;
        } else if (i > numItems / 4 && i <= numItems / 2) {
            whichList = uListMidLeft;
        } else if (i > numItems / 2 && i <= 3 * numItems / 4) {
            whichList = uListMidRight;
        } else {
            whichList = uListRight;
        }

        whichList.append($(`<li><a href="${url}">${name}</a></li>`));
    }
}
function narrowColumnsList(target, jsonData) {
    let uListLeft = $('<ul></ul>');
    let uListRight = $('<ul></ul>');

    let colspecs = [
        newColumnSpec(`${gCommon.cols6or12}`, uListLeft),
        newColumnSpec(`${gCommon.cols6or12}`, uListRight)
    ];
    makeRowWithColumns(target, "twoLists", colspecs, `mt-2 `);

    let numItems = jsonData.length;
    for (let i = 0; i < numItems; i++) {
        let conn = jsonData[i];
        let name = conn.Name;

        // Urls in the form of display/person/xxxx are favored, /profile/pid deprecated
        let url = `${conn.URL}`;

        let whichList;
        if (i <= numItems / 2) {
            whichList = uListLeft;
        } else {
            whichList = uListRight;
        }

        whichList.append($(`<li><a href="${url}">${name}</a></li>`));
    }
}

