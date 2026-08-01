gLists.savedLists = {
    setup: async () => {
        console.log('savedLists');
        gLists.currentTab = 'savedLists';

        $('.modalupdate').show();

        if (!gLists.savedLists.done) {
            let target = $('#savedDisplaySelected');
            target.empty();
            parsePersonListData(gLists.manage.people, target);

            let url = `${g.profilesRootURL}/Lists/Default.aspx/SavedLists`;
            await $.get(url, function(result) {
                gLists.savedLists.data = JSON.parse(result);
                console.log('Saved Lists: ', gLists.savedLists.data);
            });

            $('#saveButton').on('click', function() {
                let name = $('#saveName').val();
                let url = `${g.profilesRootURL}/Lists/Default.aspx/Save?name=${name}`;
                $.get(url, function(result) {
                    console.log('List: ', name, ' saved');
                });
            })

            gLists.savedLists.done = true;
        }

        $('.modalupdate').hide();
    }
};

