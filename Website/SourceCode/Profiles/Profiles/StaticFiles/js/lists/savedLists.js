gLists.savedLists = {
    setup: async () => {
        console.log('savedLists');
        $('.modalupdate').show();

        let target = $('#savedDisplaySelected');
        parsePersonListData(gLists.manage.people, target);

        $('.modalupdate').hide();
    }
};

