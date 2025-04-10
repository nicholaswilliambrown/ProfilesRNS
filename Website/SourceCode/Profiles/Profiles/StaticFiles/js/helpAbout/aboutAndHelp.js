async function setupHelpAndAbout(doSystematicBlurbs, andThen) {
    await commonSetup();

    moveContentByIdTo('aboutOrHelp', $('#mainDiv'));
    setupScrolling();

    $('.profilesTitleH').html(gBrandingConstants.profilesTitle);

    if (doSystematicBlurbs) {
        applySystematicBlurbs();
    }
    if (andThen) {
        andThen();
    }
}

function applySystematicBlurbs() {
    let topicClass = 'topic';
    let blurbClass = 'blurbForTopic';

    $(`.${topicClass}`).each((index, element) => {
        let elt = $(element);
        let sharedAttr = elt.attr('sharedAttr');
        let blurbAttrs = [];
        $(`.${blurbClass}[sharedAttr="${sharedAttr}"]`)
            .get() // to array
            .forEach(i => {
                blurbAttrs.push($(i).attr('blurb'));
            });

        hideEmptyTopics(sharedAttr, blurbAttrs);

        blurbAttrs.forEach(attr => {
            let elt = $(`div[blurb="${attr}"]`);
            let blurbText = gBrandingConstants[attr];
            $(elt).html(blurbText);
        });
    });
}
function hideEmptyTopics(sharedAttr, blurbAttrList) {
    let nonEmptyBlurbs = blurbAttrList.filter(ba =>
        gBrandingConstants[ba]);

    if ( ! nonEmptyBlurbs.length) {
        $(`div[sharedAttr="${sharedAttr}"]`).hide()
    }
}
function setupOverview() {
    $('#griffinA').attr('href', gAbout.griffinUrl);
    $('#rnsA').attr('href', gAbout.rnsUrl);
    $('#licenseA').attr('href', gAbout.licenseUrl);

    $('#whatIsIt').html(gBrandingConstants["aboutProfiles-whatIsIt"]);
    $('.aboutProfiles-profilesTitle').html(gBrandingConstants["aboutProfiles-profilesTitle"]);
    $('.aboutProfiles-profilesInstitution').html(gBrandingConstants["aboutProfiles-profilesInstitution"]);

    $('#calloutLhs').addClass(gCommon.cols5or12);
    $('#calloutRhs').addClass(gCommon.cols5or12);
}
function setupUseOurData() {
    $('.useOurData-sparqlContactA').html(gBrandingConstants["useOurData-sparqlContactName"]);
    $('.useOurData-sparqlContactA').attr('href', gBrandingConstants["useOurData-sparqlContactUrl"]);

    $('.useOurData-xmlSearchUrlA').html(gBrandingConstants["useOurData-xmlSearchUrl"]);
    $('.useOurData-xmlSearchUrlA').attr('href', gBrandingConstants["useOurData-xmlSearchUrl"]);

    $('.useOurData-oldXmlSearchUrlA').html(gBrandingConstants["useOurData-oldXmlSearchUrl"]);
    $('.useOurData-oldXmlSearchUrlA').attr('href', gBrandingConstants["useOurData-oldXmlSearchUrl"]);

    $('.useOurData-documentationUrlA').attr('href', gBrandingConstants["useOurData-documentationUrl"]);
    $('.useOurData-examplesUrlA').attr('href', gBrandingConstants["useOurData-examplesUrl"]);
}