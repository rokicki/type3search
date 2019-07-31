sub readtfm {
   my $fn = shift ;
   my $fh ;
   open $fh, "<", $fn or die "Can't read $fn\n" ;
   binmode $fh ;
   local $/ = undef ;
   my $s = <$fh> ;
   my $lh = vec($s, 1, 16) ;
   my $bc = vec($s, 2, 16) ;
   my $ec = vec($s, 3, 16) ;
   my @exist = (0) x 256 ;
   my $c ;
   for ($c=$bc; $c<=$ec; $c++) {
      $exist[$c] = 1 if 0 != vec($s, 6+$lh+$c-$bc, 32) ;
   }
   return @exist ;
}
my $fn = shift ;
@exist = readtfm($fn) ;
print @exist ;
print "\n" ;
