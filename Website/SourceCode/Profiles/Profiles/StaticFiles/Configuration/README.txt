
You can use your own headers and footers, AKA 'branding', and your own
strings for properties and blurbs, by editing / replacing these files:

    myBranding.json
    myBranding.js
    myBranding.css

For the blurbs in myBranding.json, you might use an editor with text-wrapping,
as each entry must occur on one (possibly long) line.

Compared to the supplied, default Catalyst JSON, your myBranding.json may not
need (m)any of the items supplied there. You need any items referenced in the
code that you use in your version of myBranding.js. Also, any items referenced
in the code (brandingUtil.js, aboutAndHelp.js, etc.) that customizes webpages.

In your version of myBranding.js, you may supply your own implementation of
    setupHeadIncludesAndTabTitle()
    emitBrandingHeader(targetId)
    emitBrandingFooter()

and perhaps
    emitPreFooter()

You might also supply other files (e.g., images) that your *.js can reference.

