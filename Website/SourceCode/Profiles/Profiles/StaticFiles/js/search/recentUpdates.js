function emitSidebarRecentUpdates() {
    // data comes in as strings, needs to be html objects
    // https://stackoverflow.com/questions/54186016/how-do-i-use-the-javascript-map-function-with-object-literals
    let items = gSearch.formData.ProfilesStats.map((item) =>
        ({lhs: spanify(item.count), rhs: spanify(item.label) }));

    let target = gSearch.lhsDiv;
    emitLeftColumnPairs(
        target,
        items,
        'count',
        'label',
        'Profiles',
        'Stats',
        'pStats',
        'statsClass');

    target.append($('<hr class="tightHr"/>'));

    emitLeftColumnPairs(target,
        [],
        '', '',
        'Recent', 'Updates',
        'rUpdates');

    $.get(gImpl.threeRecentActivitiesUrl, function(activities) {
        emitActivityRows(activities, target);

        // proceed w 'continuation'
        emitMoreUpdatesLink();
    });
}
function activityThumbnailAndDate(activity) {
    let date = dateStringToMDY_1(activity.createdDT.replace(/T.*/, ""));

    let personUrl = activity.URL;
    let name = `${activity.firstname} ${activity.lastname}`;
    let nameEntry = createAnchorElement(name, personUrl);

    let thumbnailUrl = gCommon.personThumbnailSchema
        .replace(gCommon.schemaPlaceholder, activity.nodeid);
    let thumbnail = $(`<img src="${thumbnailUrl}"/>`);

    let nameDateDiv = $('<div></div>');
    nameDateDiv.append(nameEntry);
    let dateDiv = divSpanifyTo(date, nameDateDiv, 'recentUpdateDate');
    nameDateDiv.append(dateDiv);
    return {thumbnail, nameDateDiv};
}

function emitActivityRows(activities, target) {
    for (let i=0; i<activities.length; i++) {
        let activity = activities[i];

        let {thumbnail, nameDateDiv} = activityThumbnailAndDate(activity);

        let pairRow = emitLeftColumnPairs(target,
            [{lhs: thumbnail, rhs: nameDateDiv}],
            '',
            '',
            '',
            '',
            `rUpdates${i}`,
            "",
            true);
        emitActivityBlurb(activity, pairRow);
    }
}
function emitLeftColumnPairs(target,
                             items,
                             lhs, rhs,
                             lHeader, rHeader,
                             idPrefix,
                             klass,
                             addHr) {
    if (! klass) {
        klass = "";
    }

    let colspecs = [
        newColumnSpec(`${gCommon.cols4or12} ${klass} pe-2 d-flex justify-content-end`),
        newColumnSpec(`${gCommon.cols8or12} ${klass} ps-0 d-flex justify-content-start `)
    ];

    let rowId = idPrefix;
    let row = makeRowWithColumns(target, rowId, colspecs, "bold");
    row.find(`#${rowId}Col0`).html(lHeader);
    row.find(`#${rowId}Col1`).html(rHeader);

    if (items.length > 0) {
        for (let i=0; i<items.length; i++) {
            let item = items[i];
            rowId = `${idPrefix}${i}`;
            row = makeRowWithColumns(target, rowId, colspecs);

            let col0 = row.find(`#${rowId}Col0`);
            let col1 = row.find(`#${rowId}Col1`);

            col0.append(item.lhs);
            col1.append(item.rhs);

            if (addHr) {
                target.append($('<hr class="tightHr"/>'));
            }
        }
    }

    // last row
    return row;
}
function emitActivityBlurb(activity, target) {
    let ru = gSearch.recentUpdateTokens;
    ru.peud = "Profiles.Edit.Utilities.DataIO";

    ru.AddPublication =         ru.peud + ".AddPublication";
    ru.AddCustomPublication =   ru.peud + ".AddCustomPublication";
    ru.UpdateSecuritySetting =  ru.peud + ".UpdateSecuritySetting"
    ru.AddUpdateFunding =       ru.peud + ".AddUpdateFunding"
    ru.Add =                    ru.peud + ".Add"
    ru.Update =                 ru.peud + ".Update"

    ru.ResearcherRole                   = "http://vivoweb.org/ontology/core#ResearcherRole";
    ru.PubmedLoadDisambiguationResults  = "[Profile.Data].[Publication.Pubmed.LoadDisambiguationResults]"
    ru.AddPMID                          = "Add PMID"
    ru.LoadProfilesData                 = "[Profile.Import].[LoadProfilesData]"
    ru.PersonInsert                           = "Person Insert"
    ru.FundingLoadDisambiguationResults = "[Profile.Data].[Funding.LoadDisambiguationResults]"
    ru.hasMemberRole                    = "http://vivoweb.org/ontology/core#hasMemberRole"
    
    let agreementLabel  = orNA(activity.AgreementLabel);
    let property        = orNA(activity.property);
    let methodName      = orNA(activity.methodName);
    let param1          = orNA(activity.param1);
    let param2          = orNA(activity.param2);
    let propertyLabel   = orNA(activity.propertyLabel);
    let groupName       = orNA(activity.groupName);

    let journalTitle    = orNA(activity.JournalTitle);
    if (property == ru.ResearcherRole) {
        journalTitle = agreementLabel;
    }

    let body = gCommon.NA;  // hope to provide a useful value below

    if (methodName == ru.AddPublication) {
        body = "added a publication from: " + journalTitle;
    }
    else if (methodName == ru.AddCustomPublication) {
        body = "added \"" + param1 + "\" into " + propertyLabel +
            " section : " + param2;
    }
    else if (methodName == ru.UpdateSecuritySetting) {
        body = "made \"" + propertyLabel + "\"public";
    }
    else if (methodName == ru.AddUpdateFunding) {
        body = "added a research activity or funding: " + journalTitle;
    }
    else if (methodName == ru.FundingLoadDisambiguationResults) {
        body = "has a new research activity or funding: " + journalTitle;
    }
    else if (property == ru.hasMemberRole) {
        body = "joined group: " + groupName;
    }
    else if (property == ru.Add) {
        if (param1 != gCommon.NA)
        {
            body = body = "added \"" + param1 + "\" into " + propertyLabel + " section";
        }
        else
        {
            body = "added \"" + propertyLabel + "\" section";
        }
    }
    else if (methodName == ru.Update) {
        if (param1 != gCommon.NA)
        {
            body = "updated \"" + param1 + "\" in " + propertyLabel + " section";
        }
        else
        {
            body = "updated \"" + propertyLabel + "\" section";
        }
    }
    else if (methodName == ru.PubmedLoadDisambiguationResults && param1 == ru.AddPMID) {
        body = "has a new publication listed from: " + journalTitle;
    }
    else if (methodName == ru.LoadProfilesData && param1 == ru.PersonInsert) {
        body = "has a new publication listed from: " + journalTitle;
    }
    else {
        body = `<b>(Need more blurb parsing logic) RAW DATA:</b> ${JSON.stringify(activity).replaceAll(":", ": ")}`;
    }

    divSpanifyTo(body, target, 'recentUpdateBlurb', 'ps-3');
}
