function twitterParser(json, moduleTitle, miscInfo) {
    let accordionBannerTitle = miscInfo.bannerText;

    let innerAccordionInfo = makeAccordionDiv(moduleTitle, accordionBannerTitle, AccordionNestingOption.Nested)
    let innerPayloadDiv = innerAccordionInfo.payload;

    for (let i=0; i<json.length; i++) {
        let elt = json[i];
        let name = elt.data;
        let url = `https://twitter.com/${name}`;

        let p = $(`<p></p>`);
        p.append($(`<a class="link-ish" href="${url}">Tweets by ${name}</a>`));

        innerPayloadDiv.append(p);
    }

    return innerAccordionInfo.outerDiv;
}
