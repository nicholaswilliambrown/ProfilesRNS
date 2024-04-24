function videosParser(json, moduleTitle, miscInfo) {
    let accordionBannerTitle = miscInfo.bannerText;

    let innerAccordionInfo = makeAccordionDiv(moduleTitle, accordionBannerTitle, AccordionNestingOption.Nested)
    let innerPayloadDiv = innerAccordionInfo.payload;

    // module data  has (??) one extra level of nesting
    let jsonData = json[0].data;
    for (let i=0; i<jsonData.length; i++) {

        let elt = jsonData[i];
        let url = elt.url.replace(/watch.v=/, "embed/");
        let vid = elt.url.replace(/.*watch.v=/, "vi/");

        let iframe = `<iframe class="video-iframe" src="${url}" 
            title="YouTube video player" frameborder="0" 
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
            allowfullscreen></iframe>`;
        let thumb = $(`<img alt="thumbnail for youtube ${vid}" class="video-thumb" src="https://img.youtube.com/${vid}/mqdefault.jpg">`);
        let label = $(`<scan class="video-name"> ${elt.name}</scan>`);

        innerPayloadDiv.append(iframe);
        innerPayloadDiv.append(thumb);
        innerPayloadDiv.append(label);
    }

    return innerAccordionInfo.outerDiv;
}
function presentationsParser(json, moduleTitle, miscInfo) {
    let accordionBannerTitle = miscInfo.bannerText;

    let innerAccordionInfo = makeAccordionDiv(moduleTitle, accordionBannerTitle, AccordionNestingOption.Nested)
    let innerPayloadDiv = innerAccordionInfo.payload;

    let author = json[0].data;
    let url = gPerson.slideshareUrlStart + author;
    $.get(url, function(presentations) {
        for (let i=0; i<presentations.length; i++) {
            let presentation = presentations[i];
            let title = presentation.title;
            let thumb = presentation.thumb;
            let embedKey = presentation.embedKey;

            let iframe = $(`<iframe class="video-iframe" src="https://www.slideshare.net/slideshow/embed_code/key/${embedKey}?startSlide=1" 
             allowfullscreen></iframe>`);
            let thumbImg = $(`<img alt="thumbnail for slideshare ${title}" class="video-thumb" src="${thumb}">`);
            let titleSpan = $(`<span class="video-name">${title}</span>`)

            innerPayloadDiv.append(iframe);
            innerPayloadDiv.append(thumbImg);
            innerPayloadDiv.append(titleSpan);
        }
    })

    return innerAccordionInfo.outerDiv;
}
