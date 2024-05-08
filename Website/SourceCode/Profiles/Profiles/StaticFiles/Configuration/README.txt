
You can use your own headers and footers, AKA 'branding', and your own
strings for properties and blurbs, by editing / replacing
these files 
    myBranding.json, 
    myBranding.js and 
    myBranding.css.

Compared to the supplied, default Catalyst JSON, your myBranding.json may not
need (m)any of the items supplied there. You need any items referenced in the
code that you use in your version of myBranding.js.

In your version of myBranding.js, you supply your own implementations of
    setupHeadAndTabTitle()
    emitBrandingHeader()
    emitBrandingFooter()

and optionally also
    emitPreFooter()
    setTabTitleAndFavicon(title)

You might also supply other files (e.g., images) that your *.js can reference.

You can run the Bash script, checkFolder.bash to compare the json, js and css files
in this folder with the corresponding ones in a sub-folder. Initially, there should
be no difference between these files and the corresponding OpenSource files.

