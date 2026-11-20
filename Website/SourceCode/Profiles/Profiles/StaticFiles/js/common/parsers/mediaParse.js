
function mediaParse(json, moduleTitle, miscInfo, explicitTarget) {
    let innerPayloadDiv = getTargetUntentavizeIfSo(moduleTitle, explicitTarget);

    let sortedJson = sortArrayViaSortLabel(json, "SortOrder");

    for (let i=0; i<sortedJson.length; i++) {

        let elt = sortedJson[i];
        let url = elt.URL;

        let faviconUrl = faviconUrlFor(url);

        // word wrap pattern
        let item = $(`<p class="wrap2 ms-0">
                        <span class="faviconSpan"><img src="${escapeHTML(faviconUrl)}" 
                            aria-hidden="true" alt="" width="16" height="16"></span>
                        <a class="link-ish" href="${escapeHTML(safeUrl(url))}">${escapeHTML(elt.WebPageTitle)}</a> 
                         (${escapeHTML(elt.PublicationDate)})</p>`);
        let colSpecs = [
            newColumnSpec(`${gCommon.cols12}`)
        ];
        let row = makeRowWithColumns(innerPayloadDiv, `media-${i}`, colSpecs);

        row.find(`#media-${i}Col0`).append(item);
    }
}
