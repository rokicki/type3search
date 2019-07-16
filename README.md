Project:  Make PDFs generated by dvips with Type 3 bitmap fonts
support searching and copying text.

Status:  Works well for English-language text in Acrobat Reader,
Chrome PDF viewer, and OSX Preview.

Recent updates:  Changing way encoding files are stored for dvips
to reduce size and count of files and to allow future improvements
without changing the dvips binary.

# Introduction

In the spring of 2019 I was surprised to hear that PDFs generated
by TeX and dvips and ps2pdf did not support searching or copying
text.  Admittedly this is a rare path these days; most people are
using pdfTeX or using Type 1 fonts with dvips, but at least one
prominent user continues to use bitmap fonts.

There's no particularly good reason that PDF files generated from
Postscript with Type 1 fonts should be more searchable than PDF
files generated with bitmapped fonts---and I believe I've resolved
that particular issue at this point.  But going through Postscript
appears to restrict the ability to support other languages.

This github repository contains the experimental code I generated
in trying out ideas.  The companion repository 
https://github.com/rokicki/texlive-source is a fork of the TeXlive
source that contains the proposed limited changes to dvips to make
this work.

# Current Status

I have implemented the changes to dvips (except for making it
optional and fully documenting the implementation).
I also have the experimental
code in this directory so you can see the impact without
needing to rebuild dvips.

Right now, searching and copying text from English-language text
in TeX documents processed with dvips and bitmap fonts and
then through ps2pdf appears to work well.  This is on par with
what happens with dvips when using Type 1 fonts.  This is
true for Adobe Acrobat, OSX Preview, Chrome PDF Preview, and
Safari PDF Preview.  Firefox almost works but misinterprets
kerns and does not preserve word spaces.

Other languages do not work as well.  Accents show up as two
individual characters (and it is unpredictable whether the accent
precedes or follows the base letter).  While many composite or
non-English characters (like the fi ligature or the OE glyph or
the German Eszett or most Greek letters) work properly, some
(Cyrillic) do not.  Cutting and pasting tables works poorly (and
very differently across PDF renderers) but this is the case with
Type 1 fonts anyway.  Math fails almost completely.

Since the only bitmapped fonts that are generally used are from
Metafont sources, and these are almost completely dominated by
Computer Modern, and Computer Modern works well, perhaps this is
where we should let things stand.

# Historical note

The reason this does not just work goes back to my original code
in 1986, when I used the Postscript Type 3 font machinery for bitmapped
fonts just as a way to get the glyph bitmaps into the printer while
using as little printer memory as possible.  The original LaserWriter
had a paltry 170KB of memory (if I remember correctly) so it was
important to be as efficient as possible when downloading fonts.  The
idea that the output of dvips would be used to view and search a
document was not anything that I considered at the time.  So I made
the required Postscript /Encoding vector (which is completely unused
for rendering) be a minimal simple vector of short meaningless strings
just to satisfy the Postscript specification.  It is because this
Encoding vector is nonsense that search and copy have not worked all
these years---and it could have easily been fixed at any time.

# Things that need doing

Test with font compression.

Test with memory limited sectioning.

Write up TUG presentation.

# Phase two implementation

After finishing the initial implementation, and discussing it with
Karl, some improvements were suggested.

* Instead of having one file for each font (which would be 1465
new files if we supported all the MetaFont/Type 1 fonts in TeXLive),
have a single composite file that gives all the encodings for all
the fonts, sharing encodings between fonts that have identical
encodings.  This new file is relatively tiny (300K) compared to the
several megabytes separated files would have taken.

* Because of this simple solution, eliminate the built-in encodings
we planned to put into the dvips executable.

* Make dvips oblivious to the actual contents of the encoding; don't
try to pick out glyph names anymore.  Dvips doesn't do anything with
them anyway.

* Allow future file-driven extensions (without changing the dvips
executable) by allowing the encoding files to also include new
dictionaries or arbitrarily executable PostScript.  If someone can
figure out a way to get Unicode code points from PostScript into
PDF, this will permit non-English characters to work too.

Because of all of this the current implementation is in a state of
flux.  Everything in this repository should be up to date but the
dvips changes in the texlive branch are not updated yet.

# Rejected Ideas

During the course of experimentation and development, several
ideas were suggested, considered, tested, and ultimately rejected.
Here are those ideas and the reasons for rejection.

* Unicode glyph names, such as /u1234 or /uni1234.  I tried this
in a number of forms and was never able to get them to be recognized
as code points.  But the dvips code does support these if they can
be made to work somehow.

* Adding special dictionaries that give code point mappings for
glyph names.  Like the above suggestions, I tried this in a number
of ways but was not able to get it to work.  But the phase two
implementation will support this at the file level.

* Add in fake spaces so spaces are properly recognized.  This
would require too many changes to dvips and would not solve the
problem of some kerns being falsely interpreted as spaces.  The
current code (using font bounding boxes and idiomatic font scaling)
seems to work well in the viewers I tested.  Long term, for
accessibility, things like math should be given "alternate"
representations if these representations would successfully pass
through the ps2pdf pipeline, but I consider this out of scope
for now.

# Chronological Notes

When I first started this, I thought it was going to be easy; just put
a proper Encoding vector on the bitmap fonts and all the PDF viewers
would do the right thing.  That was not to be.

But even to get the encoding required me to do a little bit of work.
Since PDF with Type 1 versions of the CM fonts worked properly, and
to maximize compatibility, I decided to pull the encoding vectors
directly from the Type 1 fonts supplied with TeXlive.  This was easy
to do with a little bit of Perl.  Those encoding vectors include
some re-encodings of some characters, presumably to make the fonts
more useful in ISO-8859-1 or related environments; since dvips will
never use those duplicated character positions because they don't
exist in the TFM files or bitmapped fonts, I removed those.  This
gave me a set of encodings, one per bitmapped font.  I generated these
for all the AMS-supplied type-1 fonts (under type1/public/amsfonts);
this included all Computer Modern fonts, the LaTeX line and circle
drawing fonts, the Euler fonts, the AMS extra symbol fonts, the
extra Computer Modern fonts, and the Cyrillic fonts.  I modified dvips
to use the appropriate encoding for downloaded fonts, and tried
previewing.  You can test this on your own dvi files with a command
such as the following:

    perl fakedvips.pl --nofontbb --noscale yourdvibasename

Or you can view searchsample-nofontbb-noscale.pdf in this repository.

## A note on testing

PDF viewers appear to implement searching and copying text in
the same way, by a process called text extraction.  To test search,
rather than searching for individual words, it's often easier to
just copy the entire document and paste it into another program
and verify that the pasted text is correct.  This lets you find
text that is successfully extracted, and thus searchable, as well
as text that is not successfully extracted, and it also gives you
an idea of what might have gone wrong.

But it is still important to test it using the actual GUI.  First,
when you search, it is important that the searched-for term shows
up appropriately highlighted, usually in yellow, with a box that
is at least close to the correct size.  Also, just attempting to
copy different text regions (and witnessing the selection highlighting
that takes place) can show surprising results.

Finally, since different viewers use different implementations of
PDF rendering and text extraction, it is important to test different
PDF viewers.  I did all my testing on a 2015 Macbook Pro, so the
viewers available to me were Acrobat Reader, the Chrome PDF
previewer, the Firefox PDF previewer, and the Preview application
built in to OSX.

In all cases it is useful to compare the results against the same
dvi file processed through dvips with type 1 fonts and ps2pdf.

In this repository I am including searchsample.tex, the test file I
am using for much of this work.

You can see the Type 1 pdf here as searchsampleT1.pdf.

## Results: Just Add Encoding

After adding the encoding to the bitmap fonts, I opened the PDF
file in Acrobat Reader, and things worked well.  Search, copy,
and highlighting were all as expected.  Ligatures worked.  I was
done!  Right?

Next I moved on to OSX Preview.  Copy did not appear to work at all;
there was no highlighting.  Search appeared to work somewhat; some
words were found, others were not, but again, highlighting failed.
The big surprise though was when I tried to copy the whole document
(with control-A control-C) and paste it into another program (I used
Google Docs): I did indeed get text, but it was miniscule; Docs
showed the font size at 1 pt.  I next tried "paste without formatting"
where I was in for an even greater surprise; the text appeared to be
there, but it appeared to be randomly permuted, with fragments of
sentences mixed with other fragments in no discernable order.  Many
of the words were split (p ossible, numb er).  Ligatures worked.
So this was definitely a fail.

My next attempt was Chrome.  To view a file with Chrome, I used the
Python HTTP Server by running this command in the repository
directory:

    python -m SimpleHTTPServer

This let me visit http://localhost:8080/simplesearch.pdf and view the
file the way it would appear to a visitor.  In the Chrome PDF viewer,
ligatures did not work (the word first was not found).  In addition,
selecting text gave odd selection boxes; each word had its own box
that was sized to the characters of that word, like a ransom note.
On the other hand, the text that was copied did appear to be copied
in linear order and the selection boxes were functional, if not pretty.

I also tested Safari, and it behaved in pretty much the same way as
OSX Preview, so I will not say anything more about Safari here.

The Firefox previewer behaved a lot like OSX Preview, but not exactly.
No significant highlighting was observed either in search or in copy.
(There were tiny lines under some words but they were almost too small
to see.)
When copying, all the words were run together with no spaces; indeed,
I could find direct concatenations of words such as 'theboardthe'.
The pasted font size was tiny, again one pixel.

In all viewers, the PDF with Type 1 fonts worked fine.

With a bit of thinking it was clear that the different PDF previewers
were using different ways to extract the text.  The PDF viewers are
apparently attempting to determine what characters are parts of words,
separate words, and determine the overall text flow using heuristics.
In addition, they apparently are attempting to derive the font size
using distinct techniques.

It would have been possible at this point to throw up my hands and
say Acrobat Reader is working well, so it must be doing it right, and
all the remaining issues are just bugs in the other PDF previewers.
But I was not willing to do that; few people use Acrobat Reader anymore
for anything.

## Results: Encoding and Font Size

The worst failures were with Preview and Safari, so I decided to start
with them.  It was apparent that they had no idea what size the fonts
actually were, and I thought perhaps the reason they were seeing small
positive horizontal kerns as word spaces indicated that they were using
their derived font size to separate horizontal spacing into kerns and
word spacing (and as I would soon see, column spacing).  Presumably
Adobe Reader is determining the font size from the actual glyphs
themselves because everything highlighted nicely there.

A standard Postscript font has a design size of 1 big point (the basic
unit for PostScript rendering); to get a normal text size of, say,
10 points, one uses scalefont to modify one of the base fonts.  The
type 3 bitmapped fonts created by dvips did not do that; they assume
the transformation matrix is a simple identity matrix and that the
font will only be rendered at the specific bit-for-bit size, so no
scaling is done.

I further modified my addencoding program to modify the font definitions
to define standard one big point base fonts (by giving a FontMatrix value
appropriate for such a font) and scale the font for
use.  I then tested that result.  You can follow along using the following
command:

    perl fakedvips.pl --nofontbb yourdvibasename

Or you can view searchsample-nofontbb.pdf in this repository.

Once again, Acrobat just worked, no issues.

OSX Preview still did not highlight the text, but when I
used copy and paste, the resulting text did have the intended
font size.  Further, small horizontal kerns were no longer seen
as word spaces so words such as possible were searchable.
Finally, the text was no longer randomly permuted; columns of
text were recognized as such.  So a big improvement, but not quite
there yet.

In Chrome, ligatures still failed, but this time highlighting and
selections worked well, with appropriate boxes and full
lines of text highlighted properly without the ransom note
appearance.

In Firefox, selection worked better, except adjacent words had
their own highlighting with the spaces un-highlighted.  When
copying the text from the document, again all the words were run
together with no word spacing.  Despite no regular word
spaces being recognized as such, small positive kerns were treaed as
word spaces.

So while there were some improvements we were not yet working
acceptably.

## Results:  Encoding and Font Bounding Box

I then tried to think of other ways that PDF renderers might determine
appropriate font metrics required to do the font extraction.  Every
font is required to have a /FontBBox entry.  Normally this gives
the cumulative bounding box of all the characters in a font. But
it is permitted to be
all zeros, and dvips takes advantage of this.  But perhaps this matrix was
being used by PDF rendering programs for font metrics, and the zero values
were throwing off some programs.  So I modified my test script to
calculate and add this information.  You can follow along with this
command:

    perl fakedvips.pl --noscale yourdvibasename

Or you can view searchsample-noscale.pdf in this repository.

To isolate dependencies, in this section we will present the results
with just the font bounding box and the encoding vector, not using the
font scaling described in the previous section.

Again Acrobat had no problems.

OSX Preview finally gave us selection boxes---but the selection boxes
were too short by about 30% (consistently, across different fonts and
font sizes.)  When cutting and pasting, the resulting text was only
a single point high again.  When pasting without formatting to get
readable text, we see that small horizontal kerns are again seen as
word spaces.  And further, now that we can see what is being selected
with the mouse, we notice that any rivers in paragraphs are being
treated as column separations; all text to the left of a river is
treated as a continuous flow and put in a sequence before any text
to the right of the river.  This explains the random permutation of
the text we saw in our initial testing.  It's quite shocking to see
this behavior in the UI!

In Chrome, the ransom-style highlighting appeared again.  Further,
surprisingly, copying from Chrome now generated one-point-high text;
adding a correct font bounding box actually caused a regression in
behavior for Chrome.  Oddly, ligatures still failed.

In Firefox, no change of behavior was observed when adding the Encoding
and a proper font bounding box.

## Results:  Encoding, Scaling, and Font Bounding Box

With all these various types of failures, is there any hope things
can be made to work?  We tried by setting the encoding, using
idiomatic PostScript font scaling, and also giving a proper font
bounding box.  You can try this with the following command:

    perl fakedvips.pl yourdvibasename

Or you can view searchsample.pdf in this repository.

Once again, Acrobat just worked.

Preview worked well, except the highlighting boxes were still about
30% too short.  (This did not happen with Type 1 fonts; the highlighting
boxes were just fine there.)  Cut and paste worked fine, with none of
the incorrect column inference from rivers, nor the problem with small
kerns treated as word spaces.

Chrome worked well, although the font size for a ten point font was
inferred somehow as 12.5 points instead, so the text was a little
larger than intended.  Suddenly ligatures worked; somehow ligatures
in Chrome need a proper font bounding box, font scaling, and the
proper encoding to be recognized.

Firefox did not work as well.  Word spaces were still not recognized;
all the words were run together as before, even though small positive
kerns were treated as word spaces.  When using Type 1 fonts instead of
Type 3 bitmaps, none of these problems appeared.  I believe I have
found the bug in the Firefox plugin source, and will be submitting a
pull request.

# Implementation: Design Choices

* Make it work properly even if they only have the dvips executable
(and, now, a file containing the encodings for the standard fonts).
Make it compatible with existing tex.pro files and not
require individual bitmap encoding files for each font.

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
