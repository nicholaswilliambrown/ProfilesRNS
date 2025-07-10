
The branding apparatus aims to make it relatively straight-forward to use
configurations in order to switch between different variations for displaying
the Profiles pages.

In addition to Catalyst and OpenSource configurations, we supply a Foo configuration,
representing a fictional (satirical) institution. Foo may be good for experimenting
with the features of the branding setup.

For your institution's branding, you can use your own headers and footers, and
your own particular values for properties and text-snippets, by modifying these files:

    myBranding.json
    myBranding.js
    myBranding.css

For the text-snippets in myBranding.json, you might use an editor with text-wrapping,
as each entry must occur on one (possibly long) line.

In myBranding.js, you may supply your own implementation of

    setupHeadIncludesAndTabTitle()
    emitBrandingHeader()
    emitBrandingFooter()

You might also supply other resources, e.g., images that your own *.js or *.html
can reference.

EG... track profilesTitle to help page.
... track a url
... look at emitFooter
