
You can use your own headers and footers, AKA 'branding', by editing / replacing 
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

In your myBranding.json, you need at least
    profilesURL

You might also supply other files (e.g., images) that your *.js can reference.

As a simple comparison / sample, try using the supplied '_FooBranding' versions 
of the .json, .js and .css as the corresponding myBranding.*

