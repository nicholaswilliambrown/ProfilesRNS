function videosParser(json, moduleTitle, miscInfo, explicitTarget) {
    let innerPayloadDiv = getTargetUntentavizeIfSo(moduleTitle, explicitTarget);

    // module data  has (??) one extra level of nesting
    let jsonData = json[0].data;

    let [lhs, rhs] = setupImgBigSmallAndLabel(innerPayloadDiv, 'youtubes');
    for (let i=0; i<jsonData.length; i++) {

        let elt = jsonData[i];

        // https://smallbusiness.chron.com/start-video-youtube-specific-time-58611.html
        elt.url = elt.url.replace(/&t=/, "#t=");
        let url = elt.url.replace(/watch.v=/, "embed/");
        let vid = elt.url.replace(/.*watch.v=/, "vi/");
        let vidForSrc = `https://img.youtube.com/${vid}/mqdefault.jpg`
                        .replace(/(.*)(#t=\w+)(.*)/, "$1$3$2");
        let mediaClass = 'youtubes';


        // to see the title, must place pointer on the (thin) border
        let iframe = $(`<iframe 
                class="video-iframe ${mediaClass}" 
                src="${escapeHTML(safeUrl(url))}" 
                title="YouTube video player (${i})" 
                frameborder="0" 
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
                allowfullscreen></iframe>`);
        let thumbImg = $(`<img alt="Show video: ${escapeHTML(elt.name)}" 
                                class="video-thumb" 
                                src="${escapeHTML(vidForSrc)}">`);
        let label = $(`<span class="video-name"> ${escapeHTML(elt.name)}</span>`);

        fillInBigSmallLabel(iframe, thumbImg, label, i, lhs, rhs, mediaClass);
    }
}
