#!perl
#
#   Pretend to be a new version of dvips that adds proper encodings to
#   type 1 bitmap fonts.  Run it with the name of a dvi file on the
#   input and it will generate a PDF file with Type 3 bitmaps.
#
sub usage {
   die "Usage:  perl fakedvi.pl foo\n" ;
}
my @safeargs = () ;
while (@ARGV && $ARGV[0] =~ /^-/) {
   push @safeargs, shift @ARGV ;
}
my $fn = shift ;
if (!defined($fn) || ! -f "$fn.dvi") {
   usage() ;
}
system("dvips -q -V1 $fn -o $fn-$$.ps") ;
system("perl addencodings.pl @safeargs < $fn-$$.ps > $fn.ps") ;
system("rm $fn-$$.ps") ;
system("ps2pdf $fn.ps") ;
