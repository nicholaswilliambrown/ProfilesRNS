async function setupHelpAndAbout() {
    await commonSetup();

    moveContentByIdTo('aboutOrHelp', $('#mainDiv'));
    setupScrolling();

    $('.profilesTitleH').html(gBrandingConstants.profilesTitle);
}

function applyBlurb(generalClass) {
    $(`.${generalClass}`).each((index, elt) => {
        let blurbAttr = $(elt).attr('blurb');
        let blurbText = gBrandingConstants[blurbAttr];
        let blurbDiv = $(`<div>${blurbText}</div>`);
        $(elt).append(blurbDiv);
    });
}
