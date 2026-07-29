gLists.savedLists = {
    setup: async () => {
        console.log('savedLists');
        $('.modalupdate').show();

        let target = $('#savedDisplaySelected');
        target.empty();
        parsePersonListData(gLists.manage.people, target);

        $('.modalupdate').hide();
    }
};

