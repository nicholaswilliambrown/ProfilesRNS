
//////////////////////////////////////////////////////////
//////   You will probably supply your own versions of
//////
//////   emitBrandingHeadItems()
//////   emitBrandingHeader()
//////   emitBrandingFooter()
//////
//////        and maybe also
//////   emitPreFooter()
//////   setTabTitleAndFavicon(title)
//////
//////////////////////////////////////////////////////////

async function emitBrandingHeadItems() {
    let head = $('head');
    head.prepend('<link rel="stylesheet" type="text/css" ' +
        `media="screen, projection" href="${gCommon.brandingConstants.headerFooterCssUrl}">`);

    $.getScript(gCommon.brandingConstants.headerFooterJsUrl);

    let faviconHref = `href="${gCommon.brandingConstants.iconUrlBase}/favicon.ico"`;
    head.append(`<link rel="icon" type="image/x-icon" ${faviconHref}>`);
    head.append(`<link rel="shortcut icon" type="image/x-icon" ${faviconHref}>`);
}
async function emitBrandingHeader() {

    $('body').prepend(`<div id="brandingBanner"></div>`);

    // versions for small and large
    let largeBannerDiv = $(`<div class="${gCommon.hideXsSmallShowOthers}"></div>`);
    $('#brandingBanner').append(largeBannerDiv);

    let smallBannerDiv = $(`<div class="${gCommon.showXsSmallHideOthers}"></div>`);
    $('#brandingBanner').append(smallBannerDiv);

    crossOriginAjax(gCommon.brandingConstants.headerUrl, function (bannerHtml) {
        responsiveBanner(largeBannerDiv, gCommon.large, bannerHtml);
        responsiveBanner(smallBannerDiv, gCommon.small, bannerHtml);
    });
}
async function emitBrandingFooter() {

    let brandingFooter = $(`<div id="brandingFooter"></div>`);
    $('body').append(brandingFooter);

    // versions for small and large
    let largeFooterDiv = $(`<div class="${gCommon.hideXsSmallShowOthers}"></div>`);
    brandingFooter.append(largeFooterDiv);

    let smallFooterDiv = $(`<div class="${gCommon.showXsSmallHideOthers}"></div>`);
    brandingFooter.append(smallFooterDiv);

    crossOriginAjax(gCommon.brandingConstants.footerUrl, function (footerHtml) {
        // small and large versions
        responsiveFooter(largeFooterDiv, gCommon.large, footerHtml);
        responsiveFooter(smallFooterDiv, gCommon.small, footerHtml);

        continuallySizeFooter();
    });
}
function emitPrefooter() {
    let movingPreFooter = $('body').find('#preFooter').detach();

    movingPreFooter.addClass(`mb-2`);
    movingPreFooter.find('#preFooterRight').addClass(`${gCommon.mainRightCols}`);

    let preFooterLeft = movingPreFooter.find('#preFooterLeft');
    preFooterLeft.addClass(`${gCommon.mainLeftCols}`);

    const blurb = `Local representatives can answer questions about the Profiles website or help
        with editing a profile or issues with profile data. For assistance
        with this profile: HMS/HSDM faculty should contact contact@catalyst.harvard.edu.
        For faculty or fellow appointment updates and changes, please ask your
        appointing department to contact HMS. For fellow personal and
        demographic information, contact HMS Human Resources at human_resources@hms.harvard.edu.
        For faculty personal and demographic information, contact
        HMS Office for Faculty Affairs at facappt@hms.harvard.edu.`;
    preFooterLeft.append($(`<p>${blurb}</p>`));

    $('#markPreFooter').append(movingPreFooter);
}
function setTabTitleAndFavicon(title) {
    $(document).prop('title', title + gCommon.brandingConstants.tabTitleSuffix);

    let homeUrl = gCommon.brandingConstants.homeUrl;
    let faviconHref = `href="${homeUrl}/favicon.ico"`;
    let head = $('head');
    head.append(`<link rel="icon" type="image/x-icon" ${faviconHref}>`);
    head.append(`<link rel="shortcut icon" type="image/x-icon" ${faviconHref}>`);
}

//////////////////////////////////////////////////////////
////// the below are probably only of interest to the
//////    default-provided Harvard Catalyst branding

function getBrandingLogo() {
    let logo = $(`<a href="${gCommon.brandingConstants.brandingHomeUrl}" 
        className="main-logo" title="${gCommon.brandingConstants.logoTitle}">
        <img src="${gCommon.brandingConstants.logoUrl}"
            alt="${gCommon.brandingConstants.logoAlt}"></a>`);
    return logo;
}

function crossOriginAjax(url, success) {
    $.ajax({
        url: url,
        crossOrigin: true,
        crossDomain: true,
        success: success,
        error: function (msg) {
            console.log(msg);
        },
        cache: false // turning off the cache so that changes in common assets can be dynamically loaded without CRRC needing to be restarted
    });
}

function responsiveFooter(target, heightFlavor, footerHtml) {
    let editedHtml = footerHtml
        .replace("copyright-row", "myCopyrightRow")
        .replace('<footer class="', '<footer class="mayHelpResponsiveness ');
    target.html(editedHtml);

    let copyrightMt = heightFlavor == gCommon.small ? "mt-2" : "";
    console.log(`copy height <${copyrightMt}>`);

    let footer = target.find('footer');
    let linksTarget = footer.find('.inner._ci_clearfix')[0];
    let colSpecsLinks = [
        newColumnSpec(`${gCommon.cols12} d-flex justify-content-end`)
    ];
    let linksRow = makeRowWithColumns($(linksTarget), `rFooterLinks${heightFlavor}`,
        colSpecsLinks, "ms-0 me-0");


    let copyrightTarget = footer.find('.inner._ci_clearfix')[0];
    let colSpecsCopyright = [
        newColumnSpec(`${gCommon.cols12} ps-0 d-flex justify-content-start`),
    ];
    let copyrightRow = makeRowWithColumns($(copyrightTarget), `rFooterCopyright${heightFlavor}`,
        colSpecsCopyright, `${copyrightMt} ms-0 me-0`);

    let navElt = footer.find('nav').detach();
    let copyrightElt = footer.find('.myCopyrightRow').detach();
    console.log("detached nav elt", navElt);

    linksRow.find(`#rFooterLinks${heightFlavor}Col0`).append(navElt);
    copyrightRow.find(`#rFooterCopyright${heightFlavor}Col0`).append(copyrightElt);
}


function continuallySizeFooter() {

    placeFooter();

    setInterval(function () {
        placeFooter();
    }, 200);
}

function placeFooter() {

    let footer = '#shared-asset-tool-footer';

    let footerPushDownId = 'footer-push-down';
    let footerPushDownDiv = $('#' + footerPushDownId);

    if (footerPushDownDiv.length == 0) {
        $(footer).before('<div id="' + footerPushDownId + '"></div>');
    }

    let winHeight = $(window).height();
    let bodyHeight = $('body').height() - footerPushDownDiv.height();

    if (bodyHeight < winHeight) {
        footerPushDownDiv.height(winHeight - bodyHeight);
    }

    $(footer).css("clear: both");
}

// if we get served a responsive banner, then no need for 'surgery' in this function
function responsiveBanner(target, heightFlavor, bannerHtml) {
    let assetHeaderId = "shared-asset-tool-header";
    let newAssetHeaderId = assetHeaderId + heightFlavor;

    bannerHtml = bannerHtml.replace(assetHeaderId, newAssetHeaderId);
    target.html(bannerHtml);

    // what is yt*  ??
    $('#yt_article_summary_widget_wrapper').remove();

    let banner = target;

    banner.find('.inner').css("width", "100%");
    banner.find('._ci_shared_asset.tool-page').css("width", "100% !important");
    banner.find('.container._ci_clearfix').css("width", "100%");
    banner.find('.container._ci_clearfix').css("padding", "0");
    $(`#${newAssetHeaderId}.tool-page`).addClass(`mayHelpResponsiveness${heightFlavor}`);

    banner.css("margin-bottom", "40px");

    let titleOrig = banner.find('h1');
    let subTitle = banner.find('h4');

    let myTitle = titleOrig.detach();
    let mySubTitle = subTitle.detach();
    banner.find('.main-logo').remove();

    let rDivLogo = $(`<div class="rDivLogo${heightFlavor}"></div>`);
    let rDivTitles = $(`<div class="rDivTitles${heightFlavor}"></div>`);

    // class="img-fluid" for <img> didn't work, distorted proportions
    //   -- Thus adjustBanner()
    let logo = getBrandingLogo();

    rDivTitles.append(myTitle).append(mySubTitle);
    rDivLogo.append(logo);

    let responsiveBannerDiv = $('<div class="responsiveBannerDiv"></div>');

    banner.find(".inner").prepend(responsiveBannerDiv);

    let colSpecs = [
        newColumnSpec(`${gCommon.cols4or12} rDivLogo`),
        newColumnSpec(`${gCommon.cols8or12} ps-4 pe-2 mt-2 rDivTitles`)
    ];
    let row = makeRowWithColumns(responsiveBannerDiv, `rBanner${heightFlavor}`, colSpecs, "ms-0 me-0");

    row.find(`#rBanner${heightFlavor}Col0`).append(rDivLogo);
    row.find(`#rBanner${heightFlavor}Col1`).append(rDivTitles);
}
