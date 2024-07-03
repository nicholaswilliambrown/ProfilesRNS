async function setupHistoryPage() {
    await commonSetup();

    let mainDiv = $('#mainDiv');
    moveContentByIdTo('historyDiv', mainDiv);

    let history = getOrInitHistory();
    let numItems = history.length;

    if (numItems > 0) {
        let ul = $('<ul></ul>');
        mainDiv.append(ul);

        for (let i = numItems - 1; i >= 0; i--) {
            let item = history[i];
            let anchor = createAnchorElement(item.display, item.url);

            let li = $(`<li class="historyLi"></li>`);
            li.append(anchor);

            ul.append(li);
        }
    }
}
