
function emitSidebarRecentUpdates() {
    if (gSearch.formData) { // bullet-proofing
        emitSidebarHelper(true);
        emitSidebarHelper(false);
    }
}

function emitSidebarHelper(wideVsNarrow) {
    // data comes in as strings, needs to be html objects
    // https://stackoverflow.com/questions/54186016/how-do-i-use-the-javascript-map-function-with-object-literals
    let items = gSearch.formData.ProfilesStats.map((item) =>
        ({lhs: spanify(item.count), rhs: spanify(item.label) }));

    let responsiveTarget = gSearch.lhsDiv;
    let wideTarget = $(`<div class="${gCommon.hideXsSmallShowOthers} ps-2"></div>`);
    let narrowTarget = $(`<div class="${gCommon.showXsSmallHideOthers} mb-3"></div>`);
    responsiveTarget.append(wideTarget).append(narrowTarget);

    let colSpecsWide = [
        newColumnSpec(`${gCommon.cols4or12} pe-2 d-flex justify-content-end`),
        newColumnSpec(`${gCommon.cols8or12} ps-0 d-flex justify-content-start `)
    ];
    let colSpecsNarrow = [
        newColumnSpec(`${gCommon.cols4or12} pe-2 d-flex justify-content-start`),
        newColumnSpec(`${gCommon.cols8or12} ps-2 d-flex justify-content-start pb-2`)
    ];

    let colSpecs = wideVsNarrow ? colSpecsWide : colSpecsNarrow;
    let target = wideVsNarrow ? wideTarget : narrowTarget;

    emitProfileStats({
        target:     target,
        items:      items,
        colSpecs:   colSpecs,
        lHeader:    'Profiles',
        rHeader:    'Stats',
        idPrefix:   'pStats',
        klass:      'statsClass',
        });

    target.append($('<hr class="tightHr"/>'));

    emitLeftColumnPairs({
        target: target,
        items: [],
        colSpecs:   colSpecs,
        lHeader: 'Recent',
        rHeader: 'Updates',
        idPrefix: 'rUpdates'
    });

    let dataUrl = activityUrlFromSchema(
        gSearch.activityDetailsUrl,
        gSearch.activityPreviewCount,
        gSearch.activityCurrentHighId);

    $.get(dataUrl, function(activities) {
        console.log("Activities: ", activities);
        emitActivityLhsRows(activities, target);

        // proceed w 'continuation'
        emitMoreUpdatesLink(target);
    });
}
function activityThumbnailAndDate(activity) {
    let date = dateStringToMDY_strings(activity.createdDT.replace(/T.*/, ""));

    let personUrl = activity.URL;
    let name = `${activity.firstname} ${activity.lastname}`;
    let nameEntry = createAnchorElement(name, personUrl);

    let thumbnailUrl = gCommon.personThumbnailSchema
        .replace(gCommon.schemaPlaceholder, activity.nodeid);
    let thumbnail = $(`<img src="${thumbnailUrl}" alt="thumbnail" />`);

    let nameDateDiv = $('<div></div>');
    nameDateDiv.append(nameEntry);
    let dateDiv = divSpanifyTo(date, nameDateDiv, 'recentUpdateDate');
    nameDateDiv.append(dateDiv);
    return {thumbnail, nameDateDiv};
}

function emitActivityLhsRows(activities, target) {
    for (let i=0; i<activities.length; i++) {
        let activity = activities[i];

        emitLhsActivity(activity, i, target);
    }
}
function emitLhsActivity(activity, i, target) {

    let blurb = emitActivityBlurb(activity);
    if (blurb) {
        let {thumbnail, nameDateDiv} = activityThumbnailAndDate(activity);

        let colSpecs = [
            newColumnSpec(`${gCommon.cols4or12} pe-2 d-flex justify-content-end`),
            newColumnSpec(`${gCommon.cols8or12} ps-0 d-flex justify-content-start `)
        ];

        let pairRow = emitLeftColumnPairs( {
            target:   target,
            items:    [{lhs: thumbnail, rhs: nameDateDiv}],
            lHeader: '',
            rHeader: '',
            idPrefix: `rUpdates${i}`,
            colSpecs: colSpecs,
            addHr:    true
        });

        divSpanifyTo(blurb, pairRow, 'recentUpdateBlurb', 'ps-3');
    }
}

function emitProfileStats(options) {
    emitLeftColumnPairs(options);
}
function emitLeftColumnPairs(options) {
    let target           = options.target; 
    let items            = options.items; 
    let lHeader          = options.lHeader;
    let rHeader          = options.rHeader;
    let idPrefix         = options.idPrefix; 
    let addHr            = options.addHr;
    let colSpecs         = options.colSpecs;
    let klass            = options.klass;

    let rowId = idPrefix;
    let row = makeRowWithColumns(target, rowId, colSpecs, "bold");
    row.find(`#${rowId}Col0`).html(lHeader);
    row.find(`#${rowId}Col1`).html(rHeader);

    if (items.length > 0) {
        for (let i=0; i<items.length; i++) {
            let item = items[i];
            rowId = `${idPrefix}${i}`;
            row = makeRowWithColumns(target, rowId, colSpecs);

            let col0 = row.find(`#${rowId}Col0`);
            let col1 = row.find(`#${rowId}Col1`);

            if (klass) {
                col0.addClass(klass);
                col1.addClass(klass);
            }
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
function emitActivityBlurb(activity) {
    let blurb = activity.label;

    while (blurb.match(/\$\w+/)) {
        let match = blurb.match(/\$\w+/);
        let dollarKeyword = match[0];
        let keyword = dollarKeyword.replace(/\$/, "");
        let replacement = activity[keyword] ? activity[keyword] : `::${keyword}::`;

        blurb = blurb.replace(dollarKeyword, replacement);
    }
    return blurb;
}
