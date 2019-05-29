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

Accented characters don't work well (we don't expect them to as they
are rendered as two separate characters).  Formatted copy doesn't
carry type styles (italic, sans-serif, sizes) but again, we really
don't expect that to work either.  Ligatures should definitely work,
however.  Kerns should work, without introducing extra word breaks.

One possibility I considered was that default PostScript fonts have a
size of one PostScript point, and thus must be scaled for use, but TeX
bitmap fonts are sizeless.  So I added a scale factor to check this;
so far this seems to work well.  Further testing and some detailed
analysis of floating point in the PostScript interpreter will be
necessary to bless this path.
