gLists.savedLists = {
    setup: async () => {
        console.log('savedLists');
        gLists.currentTab = 'savedLists';

        $('.modalupdate').show();

        if (!gLists.savedLists.done) {
            let target = $('#savedDisplaySelected');
            target.empty();
            parsePersonListData(gLists.manage.people, target);
            gLists.savedLists.done = true;
        }

        $('.modalupdate').hide();
    }
};

