
function generalInfoParser(json, moduleTitle) {
    let dataDiv = makeModuleTitleDiv(moduleTitle);
    let jsonElt = json[0];

    setTabTitleAndOrFavicon(`${jsonElt.FirstName} ${jsonElt.LastName}`);

    let nameForHistory = `${jsonElt.LastName}, ${jsonElt.FirstName}`;
    addItemToNavHistory(nameForHistory, window.location.href);

    let giDiv = $(`<div id="giDiv" class="mb-3"></div>`);
    dataDiv.append(giDiv);

    let vcfName = jsonElt.FirstName + '_' + jsonElt.LastName;

    // ----- now handled by addTitleFromPreLoad()
    // let nameA = $(`<h2>${jsonElt.DisplayName}</h2>`);
    // let nameDiv = $('<div class="page-title"></div>');
    // giDiv.append(nameDiv);
    // nameDiv.append(nameA);

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
async function emitMainPosition(target, mainAffiliation, jsonElt, name, idSuffix, wideVsNarrow) {
    let lhsClass = wideVsNarrow ? 'generalInfoLabels' : 'generalInfoLabels';
    twoColumnInfo(target, spanify("Title", lhsClass), spanify(mainAffiliation.Title),
        `giTitleM${idSuffix}`, wideVsNarrow);
    twoColumnInfo(target, spanify("Institution", lhsClass), spanify(mainAffiliation.InstitutionName),
        `giInstitutionM${idSuffix}`, wideVsNarrow);
    twoColumnInfo(target, spanify("Department", lhsClass), spanify(mainAffiliation.DepartmentName),
        `giDeptM${idSuffix}`, wideVsNarrow);
    twoColumnInfo(target, spanify("Address", lhsClass), spanify(jsonElt.AddressLine1),
        `giAddr1M${idSuffix}`, wideVsNarrow);
    twoColumnInfo(target, spanify(""),        spanify(jsonElt.AddressLine2),
        `giAddr2M${idSuffix}`, wideVsNarrow);
    twoColumnInfo(target, spanify(""),        spanify(jsonElt.AddressLine3),
        `giAddr3M${idSuffix}`, wideVsNarrow);
    twoColumnInfo(target, spanify(""),        spanify(jsonElt.AddressLine4),
        `giAddr4M${idSuffix}`, wideVsNarrow);
    twoColumnInfo(target, spanify("Phone", lhsClass),   spanify(jsonElt.Phone),
        `giPhoneM${idSuffix}`, wideVsNarrow);
    if (jsonElt.Email) {
        twoColumnInfo(target, spanify("Email", lhsClass), spanify(jsonElt.Email),
            `giEmailM${idSuffix}`, wideVsNarrow);
    }
    else if (jsonElt.EmailEncrypted) {
        let emailImage = await getEmailImage(jsonElt.EmailEncrypted);
        twoColumnInfo(target, spanify("Email", lhsClass), emailImage,
            `giEmailM${idSuffix}`, wideVsNarrow);
    }
    let orcid = jsonElt.ORCID;
    if (orcid) {
        let orcDiv = $('<div></div>');
        let orcLabel = spanify('ORCID', 'me-1 boldBlue');
        let orcImage = $(`<img class="pb-1" src="${gBrandingConstants.jsPersonImageFiles}orcid_16x16.gif"/>`);
        orcDiv.append(orcLabel)
        orcDiv.append(orcImage);

        let link = createAnchorElement(orcid, `${gCommon.personOrcidUrlPrefix}${orcid}`);

        twoColumnInfo(target, orcDiv, link,
            `orcidM${idSuffix}`, wideVsNarrow);
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

    twoColumnInfo(target, spanify("vCard", lhsClass), vCardSpan,
        `giVcardM${idSuffix}`, wideVsNarrow);
}
function emitOtherPositions(target, affiliationArray, idSuffix, wideVsNarrow) {
    let othersHeading = $('<div class="giOthersHeading mt-2">Other Positions</div>');
    target.append(othersHeading);

    for (let i=1; i<affiliationArray.length; i++) {
        let affiliation = affiliationArray[i];
        twoColumnInfo(target, spanify("Title", "generalInfoLabels"), spanify(affiliation.Title),
            `giTitle${i}${idSuffix}`, wideVsNarrow);
        twoColumnInfo(target, spanify("Institution","generalInfoLabels"), spanify(affiliation.InstitutionName),
            `giInstitution${i}${idSuffix}`, wideVsNarrow);
        twoColumnInfo(target, spanify("Department","generalInfoLabels"), spanify(affiliation.DepartmentName),
            `giDept${i}${idSuffix}`, wideVsNarrow);
    }
}
function emitHeadshot(target, jsonElt) {
    let headshotDiv = $('<div id="headshot"></div>');
    if (jsonElt.ImageURL) {
        headshot = $(`<div><img class="headshot" 
            width="auto" 
            height="160px" 
            src="${jsonElt.ImageURL}"></div>`);
        headshotDiv.append(headshot);
    }
    else {
        headshotDiv = $(``);
    }
    if (jsonElt.SupportHTML) {
        let template = `
            <div class="popover" role="tooltip">
                <div class="popover-arrow"></div>
                <h3 class="popover-header popTitle m-0 pb-0"></h3>
                <div class="popover-body popContent m-0 pt-1 pb-0"></div>
                <div class="popClose m-0 p-1"> (click in this message to close) </div>
            </div>`
        // help from https://www.tutorialrepublic.com/twitter-bootstrap-tutorial/bootstrap-popovers.php
        //   (the BS 5 docs are somewhat impenetrable)
        let spanForPopup = $(`<button class="link-ish bs-pop moreInfoButton" 
                            data-bs-placement="bottom" 
                            data-bs-title="Profile Help"
                            data-bs-trigger="focus"
                            data-bs-toggle="popover">
                            ${gPerson.supportHowMsg}
                            </button>`)
                            // data-bs-custom-class="popContent"
        headshotDiv.append(spanForPopup);
        spanForPopup.popover({
            template: template,
            content: jsonElt.SupportHTML
        });
    }
    target.append(headshotDiv);
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
    let email = jsonElt.Email ? "\nEmail;TYPE=work:" + jsonElt.Email : "";

    let result =
`BEGIN:VCARD
VERSION:3.0
N:${escapeComma(jsonElt.LastName)};${escapeComma(jsonElt.FirstName)};;;\n` +
    `${title}${org}${phone}${address}URL;type=WORK;type=pref:${window.location.href}${email}
NOTE:
END:VCARD`;
    return result;
}
function escapeComma(input) {
    let result = input.replace(/,/g, "\\,");
    return result;
}
async function getEmailImage(emailEcrypted) {
    emailEcrypted = encodeURIComponent(emailEcrypted);
    let result = await $(`<img src="${gCommon.personEmailToImageUrlPrefix}${emailEcrypted}"/>`);
    return result;
}