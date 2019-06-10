This is a test of making searchable PDF files when using Type 3 bitmap
fonts with the plain \TeX, dvips, ps2pdf toolchain.

I've mocked up what I think should happen in {\tt addencodings.pl}.
To use it, create a dvi file, process it with {\tt dvips -V1}, stream
the PostScript result through addencodings.pl, and convert to PDF with
ps2pdf.  The script fakedvips.pl does all of this.  So to run:

    tex searchsample
    perl fakedvips.pl searchsample

and then run searchsample.pdf through all the PDF viewers you can find
and make sure searching and cutting/pasting from the document work
correctly.

Accented characters don't work well (we don't expect them to as they
are rendered as two separate characters).  Formatted copy doesn't
carry type styles (italic, sans-serif, sizes) but again, we really
don't expect that to work either.  Ligatures should definitely work,
however.  Kerns should work, without introducing extra word breaks.

Design choices:

* Make it work properly even if they only have the dvips executable.
That is, make it compatible with existing tex.pro files and not
(absolutely) require the bitmap encoding files.

* Put any needed new code in a specific file, and make these changes
an option (for now) in case any issues arise.  I'm not sure if the
default should be on or off; my guess would be on.

* Make it transparent.  If someone designs new Metafont fonts, they
should be able to specify an encoding in a file and have dvips work
properly with that.

* Ensure there is no conflict with existing names.  For instance,
encoding files can be prefixed with dvips- (as in dvips-cmr10.enc).
Perhaps use a different prefix.

So no changes to tex.pro (this has little to no impact; the needed
changes can be put inline pretty easily).  Also, search for encoding
files, but if they are not found, rely on internal definitions for
the existing Type 1 fonts based on what exists today.
