
function exploreFullParser(moduleJson, postSkeleton) {
    let moduleTitle = getModuleEltTitle(moduleJson);
    let exploreDiv;

    if (postSkeleton) {
        exploreDiv = gPerson.innerTargetCache[moduleTitle];
        exploreDiv.empty();
        exploreDiv.removeClass(gCommon.tentative);
    }
    else {
        exploreDiv = $(`<div id=${asIdentifier(moduleTitle)}-top></div>`);
        $('#modules-right-div').append(exploreDiv);
    }

    exploreDiv.append($("<hr class='tightHr'>"));

    let elt = moduleJson.ModuleData[0];

    if ( !elt.Count && !elt.Connections) {
        return;
    }

    let blurb = exploreModuleInfo(moduleTitle).blurb;

    let eltCount = elt.Count ? `(${elt.Count})` : "";
    let eltTitle = elt.Title ? `${elt.Title}` : "";
    let titleId = asIdentifier(eltTitle);
    let title = $(`<h3 id="rhs_${titleId}" class="_rhs explore_title">${escapeHTML(eltTitle)} ${escapeHTML(eltCount)}</h3>`);

    exploreDiv.append(title);

    if (blurb) {
        let blurbDiv = $(`<div class="exploreBlurbDiv">${escapeHTML(blurb)}</div>`);
        exploreDiv.append(blurbDiv);
        blurbDiv.hide();

        title.append(spanify(" "))
            .append(makeMoreInfoButton(eltTitle, blurbDiv));
    }

    if (elt.Connections) {
        let sortedConnections = sortArrayViaSortLabel(elt.Connections, "Sort");

        for (let i = 0; i < sortedConnections.length; i++) {
            let connection = sortedConnections[i];
            let label = connection.Label;
            let url = connection.URL;

            exploreDiv.append($(`<div><a href="${escapeHTML(safeUrl(url))}" class="link-ish explore_connection_label">${escapeHTML(label)}</a></div>`));
        }
    }
    if (moduleTitle != 'PhysicalNeighbour.Top5') {
        if (elt.ExploreLink) {
            emitExploreButton(exploreDiv, elt.ExploreLink);
        }
        else { // same department is missing the explore link,
                // build the search from its info
            emitExploreButton(exploreDiv, function() {
                minimalPeopleSearchByDept(
                    elt.SearchQuery.Institution.toString(),
                    elt.SearchQuery.Department.toString(),
                    elt.SearchQuery.DepartmentName);
            });
        }
    }
}
function emitNameHeaderForExplores(name) {
    if ($('#theirNetworkDiv').length) {
        // prepopulated in skeleton
        return;
    }
    let theirNetworkDiv = $(`<div id="theirNetworkDiv" class="theirNetworkDiv ">                                                            
                             </div>`);

    let theirNetworkTitle = $(`<div class="boldNetworks">${escapeHTML(name)}'s Networks</div>`);
    let theirNetworkBlurb = $('<div class="theirNetworkBlurb">Click the <span class="green bold">Explore</span> buttons for ' +
        'more information and interactive visualizations!</div>');

    $('#modules-right-div').append(theirNetworkDiv);
    theirNetworkDiv.append(theirNetworkTitle)
        .append(theirNetworkBlurb);
}

