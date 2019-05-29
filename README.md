This is a test of making searchable PDF files when using Type 3 bitmap
fonts with the plain \TeX, dvips, ps2pdf toolchain.

I've mocked up what I think should happen in {\tt addencodings.pl}.
To use it, create a dvi file, process it with {\tt dvips -V1}, stream
the PostScript result through addencodings.pl, and convert to PDF with
ps2pdf.  The script fakedvips.pl does all of this.  So to run:

    tex searchsample
    perl fakedvips.pl searchsample

and then run searchsample.pdf through all the PDF viewers you can find
and make sure searching and cutting/pasting from the document works
correctly.

These are the issues we have seen so far:

After addencodings.pl, OSX Preview puts spaces in the middle of
words (od, be) and also doesn't properly pull text from some
paragraphs (layout; seems to be autorecognizing tables).  This does
not happen with any other setup.  Also, preview paste-with-formatting
is *much* too tiny (though paste-without-formatting works okay).
Finally, the select with preview is too short by about half.  I think
OSX Preview is guessing metrics for the bitmap fonts that are way off,
and this is triggering odd behavior including separating what should
be a continuous line into what it thinks are text columns.  This would
also explain why its turning small positive kerns into spaces.  This
is supported by the formatted paste generating an incredibly tiny
font size.

After addencodings.pl, Chrome pdf preview drops ligatures, and the
select is ugly ransom-style.  Otherwise, search and cut and paste
seem to work well.

After addencodings.pl, Adobe Acrobat appears to work well.

Accented characters don't work well (we don't expect them to as they
are rendered as two separate characters).  Formatted copy doesn't
carry type styles (italic, sans-serif, sizes) but again, we really
don't expect that to work either.  Ligatures should definitely work,
however.  Kerns should work, without introducing extra word breaks.
