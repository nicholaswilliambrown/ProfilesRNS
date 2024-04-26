

function exploreParser(json, anchorsDiv) {
    let moduleTitle = json.DisplayModule;
    let blurb = exploreModuleInfo(moduleTitle).blurb;

    let dataDiv = makeModuleTitleDiv(moduleTitle);
    let exploreDiv = $(`<div class="exploreDiv"></div>`);
    dataDiv.append(exploreDiv);

    exploreDiv.append($("<hr>"));

    let elt = json.ModuleData[0];
    let title = $(`<div class="explore_title">${elt.Title} (${elt.Count})</div>`);
    exploreDiv.append(title);

    if (blurb) {
        let blurbDiv = $(`<div class="exploreBlurbDiv">${blurb}</div>`);
        exploreDiv.append(blurbDiv);
        blurbDiv.hide();

        let moreInfoButton = $(`<img src="${gBasic.jsCommonImageFiles}info.png" class="noBorder">`);
        title.append(spanify(" "))
            .append(moreInfoButton);

        moreInfoButton.on("click", function() {
            toggleVisibility(blurbDiv);
        })
    }

    let sortedConnections = sortArrayViaSortLabel(elt.Connections, "Sort");

    for (let i=0; i<sortedConnections.length; i++) {
        let connection = sortedConnections[i];
        let label = connection.Label;
        let url = connection.URL;

        exploreDiv.append($(`<div><a href="${url}" class="link-ish explore_connection_label">${label}</a></div>`));
    }
    // large/small variants
    exploreDiv.append($(`<div class="mt-2 explore-parent"><a href="${elt.ExploreLink}" 
        class="${gCommon.hideXsSmallShowOthers} link-ish greenButton explore_connection_link_bg">Explore</a></div>`));
    exploreDiv.append($(`<div class="mt-3 explore-parent"><a href="${elt.ExploreLink}" 
        class="${gCommon.showXsSmallHideOthers} link-ish greenButton explore_connection_link_sm">Explore</a></div>`));

    if (anchorsDiv) {
        let anchorHtml = `<a class="link-ish green me-1" href="#${moduleTitle}">${moduleTitle}</a>`;
        anchorsDiv.push(anchorHtml);
    }

    let mainRightDivId = $('#modules-right-div');
    mainRightDivId.append(dataDiv);
}
function emitHeaderForExplores(lastname) {
    let theirNetworkDiv = $(`<div class="theirNetworkDiv"></div>`);
    let theirNetworkTitle = $(`<div class="boldCrimson">${lastname}'s Networks</div>`);
    let theirNetworkBlurb = $('<div class="theirNetworkBlurb">Click the <span class="green bold">Explore</span> buttons for ' +
        'more information and interactive visualizations!</div>');

    $('#modules-right-div').append(theirNetworkDiv);
    theirNetworkDiv.append(theirNetworkTitle)
        .append(theirNetworkBlurb);
}
