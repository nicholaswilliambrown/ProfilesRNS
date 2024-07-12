
function generalInfoParser(json, moduleTitle) {
    let dataDiv = makeModuleTitleDiv(moduleTitle);
    let jsonElt = json[0];

    setTabTitleAndFavicon(`${jsonElt.FirstName} ${jsonElt.LastName}`);

    let nameForHistory = `${jsonElt.LastName}, ${jsonElt.FirstName}`;
    addItemToNavHistory(nameForHistory, window.location.href);

    let giDiv = $(`<div id="giDiv" class="mb-3"></div>`);
    dataDiv.append(giDiv);

    let vcfName = jsonElt.FirstName + '_' + jsonElt.LastName;
    let nameA = $(`<h2>${jsonElt.DisplayName}</h2>`);
    let nameDiv = $('<div class="gi_fullName"></div>');
    giDiv.append(nameDiv);
    nameDiv.append(nameA);

    let affiliationArray = sortArrayViaSortLabel(jsonElt.Affiliation, "SortOrder");
    let mainAffiliation = affiliationArray[0];

    let bigRow = giOuterTwoColumns(giDiv, "giOuter");
    let bigLeft = bigRow.find('#giOuterCol0');
    let bigRight = bigRow.find('#giOuterCol1');

    emitHeadshot(bigRight, jsonElt);
    let wideLeft = $(`<div class="${gCommon.hideXsSmallShowOthers}"></div>`);
    let narrowLeft = $(`<div class="${gCommon.showXsSmallHideOthers}"></div>`);
    bigLeft.append(wideLeft);
    bigLeft.append(narrowLeft);

    emitMainPosition(wideLeft, mainAffiliation, jsonElt, vcfName,
        "wide", true);
    if (affiliationArray.length > 1) {
        emitOtherPositions(wideLeft, affiliationArray,
            "wide", true);
    }
    emitMainPosition(narrowLeft, mainAffiliation, jsonElt, vcfName,
        "narrow", false);
    if (affiliationArray.length > 1) {
        emitOtherPositions(narrowLeft, affiliationArray,
            "narrow", false);
    }

    return giDiv;
}
function emitMainPosition(target, mainAffiliation, jsonElt, name, idSuffix, wideVsNarrow) {
    giTwoColumnInfo(target, spanify("Title"), spanify(mainAffiliation.Title),
        `giTitleM${idSuffix}`, wideVsNarrow);
    giTwoColumnInfo(target, spanify("Institution"), spanify(mainAffiliation.InstitutionName),
        `giInstitutionM${idSuffix}`, wideVsNarrow);
    giTwoColumnInfo(target, spanify("Department"), spanify(mainAffiliation.DepartmentName),
        `giDeptM${idSuffix}`, wideVsNarrow);
    giTwoColumnInfo(target, spanify("Address"), spanify(jsonElt.AddressLine1),
        `giAddr1M${idSuffix}`, wideVsNarrow);
    giTwoColumnInfo(target, spanify(""),        spanify(jsonElt.AddressLine2),
        `giAddr2M${idSuffix}`, wideVsNarrow);
    giTwoColumnInfo(target, spanify(""),        spanify(jsonElt.AddressLine3),
        `giAddr3M${idSuffix}`, wideVsNarrow);
    giTwoColumnInfo(target, spanify(""),        spanify(jsonElt.AddressLine4),
        `giAddr4M${idSuffix}`, wideVsNarrow);
    giTwoColumnInfo(target, spanify("Phone"),   spanify(jsonElt.Phone),
        `giPhoneM${idSuffix}`, wideVsNarrow);
    if (jsonElt.Email) {
        giTwoColumnInfo(target, spanify("Email"), spanify(jsonElt.Email),
            `giEmailM${idSuffix}`, wideVsNarrow);
    }

    let vCardSpan = $('<span></span>');
    let vCardContent = createVcardContent(jsonElt);
    let vcardUrl = `data:text;base64,${btoa(vCardContent)}`;
    let vcardAnchor = $(`<a class="link-ish" target="_blank" 
                            href="${vcardUrl}"
                            download="${name}.vcf">Download vCard</a>`);
    vCardSpan.append(vcardAnchor);

    if (! gCommon.loggedIn) {
        let canLoginUrl = gCommon.loginUrl;
        let canLoginAnchor = $(`<a class="link-ish black" href="${canLoginUrl}"> (login for email)</a>`);
        vCardSpan.append(canLoginAnchor);
    }

    giTwoColumnInfo(target, spanify("vCard"), vCardSpan,
        `giVcardM${idSuffix}`, wideVsNarrow);
}
function emitOtherPositions(target, affiliationArray, idSuffix, wideVsNarrow) {
    let othersHeading = $('<div class="giOthersHeading mt-2">Other Positions</div>');
    target.append(othersHeading);

    for (let i=1; i<affiliationArray.length; i++) {
        let affiliation = affiliationArray[i];
        giTwoColumnInfo(target, spanify("Title"), spanify(affiliation.Title),
            `giTitle${i}${idSuffix}`, wideVsNarrow);
        giTwoColumnInfo(target, spanify("Institution"), spanify(affiliation.InstitutionName),
            `giInstitution${i}${idSuffix}`, wideVsNarrow);
        giTwoColumnInfo(target, spanify("Department"), spanify(affiliation.DepartmentName),
            `giDept${i}${idSuffix}`, wideVsNarrow);
    }
}
function emitHeadshot(target, jsonElt) {
    let headshot;
    if (jsonElt.ImageURL) {
        headshot = $(`<img class="headshot" 
            width="120px" 
            height="160px" 
            src="${jsonElt.ImageURL}"></img>`);
    }
    else {
        headshot = $(`<div>(No headshot available)</div>`);
    }
    target.append(headshot);
}
function giTwoColumnInfo(target, left, right, idLabel, wideVsNarrow) {
    let displayClass = wideVsNarrow ? "d-flex justify-content-end" : "";
    let margin = wideVsNarrow ? "" : "mb-2";

    let colSpecs = [
        newColumnSpec(`pe-1 ${gCommon.cols3or12} ${displayClass}`, left),
        newColumnSpec(`pe-1 ${gCommon.cols9or12} justify-content-start`, right)
    ];

    makeRowWithColumns(target, idLabel+'Wide', colSpecs, `me-3 ${margin}`);
}
function giOuterTwoColumns(target, idLabel) {
    let colSpecs = [
        newColumnSpec(`pe-1 ${gCommon.cols8or12}`),
        newColumnSpec(`pe-1 ${gCommon.cols4or12}`)
    ];
    let row = makeRowWithColumns(target, idLabel, colSpecs);
    return row;
}
function createVcardContent(jsonElt) {
    let affiliation = jsonElt.Affiliation;

    let title = "";
    let org = "";
    if (affiliation && affiliation.length > 0) {
        title = escapeComma(`TITLE:${affiliation[0].Title}\n`);
        org = escapeComma(`ORG:${affiliation[0].InstitutionName}\n`);
    }
    let phone = "";
    if (jsonElt.Phone) {
        phone = escapeComma(`TEL;type=WORK;type=VOICE;type=pref:${jsonElt.Phone}\n`);
    }
    let address = "";
    for (let i=1; i<=4; i++) {
        let addrLine = jsonElt[`AddressLine${i}`];
        if (addrLine) {
            address += escapeComma(addrLine) + "\\n";
        }
    }
    if (address) {
        address = address.replace(/\\n$/, "");
        address = `ADR;type=WORK;type=pref:;;${address}\n`;
    }

    let result =
`BEGIN:VCARD
VERSION:3.0
N:${escapeComma(jsonElt.LastName)};${escapeComma(jsonElt.FirstName)};;;\n` +
    `${title}${org}${phone}${address}URL;type=WORK;type=pref:${window.location.href}
NOTE:
END:VCARD`;
    return result;
}
function escapeComma(input) {
    let result = input.replace(/,/g, "\\,");
    return result;
}
