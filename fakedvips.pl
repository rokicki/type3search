#!perl
#
#   Pretend to be a new version of dvips that adds proper encodings to
#   type 1 bitmap fonts.  Run it with the name of a dvi file on the
#   input and it will generate a PDF file with Type 3 bitmaps.
#
my $fn = shift ;
sub usage {
   die "Usage:  perl fakedvi.pl foo\n" ;
}
if (!defined($fn) || ! -f "$fn.dvi") {
   usage() ;
}
system("dvips -V1 $fn -o $fn-$$.ps") ;
system("perl addencodings.pl < $fn-$$.ps > $fn.ps") ;
system("rm $fn-$$.ps") ;
system("ps2pdf $fn.ps") ;
