function setupListsCluster() {
    console.log("------------iframe is loaded");
    $('body').on('click', () => {
        console.log('---------------- iframe itself notices click!')
    });
}