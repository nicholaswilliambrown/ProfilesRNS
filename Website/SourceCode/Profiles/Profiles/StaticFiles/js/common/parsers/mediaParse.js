
function mediaParse(json, moduleTitle, miscInfo, explicitTarget) {
    let innerPayloadDiv = getTargetUntentavizeIfSo(moduleTitle, explicitTarget);

    let sortedJson = sortArrayViaSortLabel(json, "SortOrder");

    for (let i=0; i<sortedJson.length; i++) {

        let elt = sortedJson[i];
        let url = elt.URL;

        let faviconUrl = `https://www.google.com/s2/favicons?domain=${url}`;

        // word wrap pattern
        let item = $(`<p class="wrap2 ms-0">
                        <span class="faviconSpan"><img src="${faviconUrl}" aria-hidden="true" width="16'" height="16"></span>
                        <a class="link-ish" href="${url}">${elt.WebPageTitle}</a> 
                         (${elt.PublicationDate})</p>`);
        let colSpecs = [
            newColumnSpec(`${gCommon.cols12}`)
        ];
        let row = makeRowWithColumns(innerPayloadDiv, `media-${i}`, colSpecs);

        row.find(`#media-${i}Col0`).append(item);
    }
}
