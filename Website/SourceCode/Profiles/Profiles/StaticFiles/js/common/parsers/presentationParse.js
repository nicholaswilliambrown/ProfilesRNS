async function presentationsParser(json, moduleTitle, miscInfo, explicitTarget) {
    let innerPayloadDiv = getTargetUntentavizeIfSo(moduleTitle, explicitTarget);

    let author = json[0].data;
    let [lhs, rhs] = setupImgBigSmallAndLabel(innerPayloadDiv, 'presentations');

    let url = gPerson.slideshareUrlStart + author;
    try {
        await $.get(url, function (presentations) {
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
        });
    }
    catch (e) {
        console.log(`====Unable to $.get(), url: ${url}. Error: ${e.status}, ${e.responseText}`);
    }
}
