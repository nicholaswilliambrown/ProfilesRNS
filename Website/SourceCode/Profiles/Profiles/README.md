# ProfilesRNS_ModernUI
This is a minimum .Net solution designed for development and testing 
of a modern UI for Profiles RNS, both open source and Harvard Catalyst Versions. 

You can use your own headers and footers, AKA 'branding', by editing / replacing 
these files 
    myBranding.json, 
    myBranding.js and 
    myBranding.css.

Compared to the supplied, default Catalyst JSON, your myBranding.json may not need
(m)any of the items supplied there. You need any items referenced in the core code
(e.g., profilesUrl), or in the code that you use in your version if myBranding.js. 

In your version of myBranding.js, you supply your own implementations of
    emitBrandingHeadItems()
    emitBrandingHeader()
    emitBrandingFooter()

and optionally also
    emitPreFooter()
    setTabTitleAndFavicon(title)

You might also supply other files (e.g., images) that your *.js can reference.

As a simple comparison / sample, try using the supplied '_FooBranding' versions 
of the .json, .js and .css as the corresponding myBranding.*

