// Not async: callers append this function's return value, and jQuery 4 would show a Promise
// as the text "[object Promise]". The slides arrive later and are filled in by the callback.
function presentationsParser(json, moduleTitle, miscInfo, explicitTarget) {
    let innerPayloadDiv = getTargetUntentavizeIfSo(moduleTitle, explicitTarget);

    let author = json[0].data;
    let [lhs, rhs] = setupImgBigSmallAndLabel(innerPayloadDiv, 'presentations');

    let url = gPerson.slideshareUrlStart + author;
    $.get(url)
        .done(function (presentations) {
            if (!Array.isArray(presentations) || !presentations.length) {
                lhs.closest('.row').remove();
                complainNoPresentations(innerPayloadDiv, `====> No presentations found`);
                return;
            }
            for (let i = 0; i < presentations.length; i++) {
                let presentation = presentations[i];
                let title = presentation.title;
                let thumb = presentation.thumb;
                let embedKey = presentation.embedKey;
                let mediaClass = 'presentations';

                // to see the title, must place pointer on the (thin) border
                let iframe = $(`<iframe 
                    class="video-iframe" 
                    src="https://www.slideshare.net/slideshow/embed_code/key/${escapeHTML(embedKey)}?startSlide=1" 
                    title="Presentation (${i})" 
                    allowfullscreen></iframe>`);
                let thumbImg = $(`<img alt="thumbnail for slideshare ${escapeHTML(title)}" class="video-thumb" src="${escapeHTML(thumb)}">`);
                let label = $(`<span class="video-name">${escapeHTML(title)}</span>`)

                fillInBigSmallLabel(iframe, thumbImg, label, i, lhs, rhs, mediaClass);
            }
        })
        .fail(function (e) {
            lhs.closest('.row').remove();
            complainNoPresentations(innerPayloadDiv,
                'Could not fetch presentations',
                `====Unable to $.get(), url: ${url}. Error: ${e.status}, ${e.responseText}`);
        });
}
function complainNoPresentations(target, msg, details) {
    let problemWithPresentations = $(`<div class="ms-4 fw-bold">${msg}</div>`);
    target.append(problemWithPresentations);
    if (details) {
        console.log(`===> ` + details);
    }
}
