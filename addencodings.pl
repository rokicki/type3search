#
#   Given a dvips file with bitmap fonts, add the appropriate font
#   encodings.
#
my @names ;
my $loc ;
sub emit {
   my $s = shift ;
   if ($loc + 1 + length($s) > 75) {
      print "\n" ;
      $loc = 0 ;
   }
#  if ($loc) {
#     print " " ;
#     $loc++ ;
#  }
   print $s ;
   $loc += length($s) ;
}
my $encnum = 0 ;
sub emitnames {
   my $i ;
   for ($i=0; $i<256; $i++) {
      if (defined($names[$i]) && $names[$i] eq '/.notdef') {
         $names[$i] = undef ;
      }
   }
   my $k = join ',', map{$_ || '?'}@names ;
   if (defined($enc{$k})) {
      print "/IEn $enc{$k} def\n" ;
      return ;
   } else {
      $enc{$k} = "EN$encnum" ;
      $encnum++ ;
   }
   $loc = 0 ;
   emit("/$enc{$k}\[") ;
   for ($i=0; $i<256; $i++) {
      if (!defined($names[$i])) {
         my $j = $i + 1 ;
         while ($j < 256 && !defined($names[$j])) {
            $j++ ;
         }
         if ($j-$i > 2) {
            emit(" ".($j-$i) . "{/.notdef}repeat") ;
            $i = $j - 1 ;
         } else {
            emit("/.notdef") ;
         }
      } else {
         emit($names[$i]) ;
      }
   }
   emit("]def/IEn $enc{$k} def") ;
   print "\n" ;
}
@k = () ;
$keep = 0 ;
$fn = undef ;
$lastcc = 0 ;
sub scansizes {
   $str = join '', @k ;
   $at = -1 ;
   $llx = 0 ;
   $lly = 0 ;
   $urx = 0 ;
   $ury = 0 ;
   $end = length($str) ;
   while (1) {
      $at = index($str, ">", $at+1) ;
      last if $at < 0 ;
      $endhex = $at - 1 ;
      $at++ ;
      @numargs = () ;
      while (1) {
         $at++ while $at < $end && substr($str, $at, 1) le ' ' ;
         last if $at >= $end ;
         $c = substr($str, $at, 1) ;
         if ($c eq '-' || ('0' le $c && $c le '9')) {
            $num = '' ;
            while ($c eq '-' || ('0' le $c && $c le '9')) {
               $num .= $c ;
               $at++ ;
               $c = substr($str, $at, 1) ;
            }
            push @numargs, 0 + $num ;
         } else {
            last ;
         }
      }
      next if $c eq '<' && @numargs == 0 ;
      die "Fail saw $c" if $c ne 'D' && $c ne 'I' ;
      die "Bad args" if $c eq 'D' && @numargs != 1 && @numargs != 6 ;
      die "Bad args" if $c eq 'I' && @numargs != 0 && @numargs != 5 ;
      if ($c eq 'D') {
         $lastcc = $numargs[-1] ;
      } else {
         $lastcc++ ;
      }
      if (@numargs < 4) {
         # find the previous 10 hex digits
         $digs = '' ;
         while ($endhex > 0 && length($digs) < 10) {
            $c = substr($str, $endhex, 1) ;
            if (('0' le $c && $c le '9') || ('A' le $c && $c le 'Z')) {
               $digs = $c . $digs ;
            } else {
               die "Bad char in hex string" if $c gt ' ' && $c ne '<' && $c ne '>' ;
            }
            $endhex-- ;
         }
         die "Did not find ten digs" if length($digs) != 10 ;
         for ($i=0; $i<5; $i++) {
            splice(@numargs, $i, 0, hex(substr($digs, 2*$i, 2))) ;
         }
      }
      $numargs[2] = 128 - $numargs[2] ;
      $numargs[3] = $numargs[3] - 127 ;
      $minx = -$numargs[2] - 1 ;
      $maxx = $numargs[0] - $numargs[2] + 1 ;
      $miny = $numargs[3] - $numargs[1] - 1 ;
      $maxy = $numargs[3] + 1 ;
      $llx = $minx if $minx < $llx ;
      $lly = $miny if $miny < $lly ;
      $urx = $maxx if $maxx > $urx ;
      $ury = $maxy if $maxy > $ury ;
   }
}
while (<>) {
   if (/^%EndDVIPSBitmapFont/) {
      print "/OIEn IEn def /OFBB FBB def\n" ;
      if (open E, "encs/$fn.enc") {
         @names = () ;
         while (<E>) {
            if (m,dup (\d+) (/\S+) put,) {
               $names[$1] = $2 ;
            }
         }
         close E ;
         emitnames() ;
      } else {
         warn "Cannot find encoding for $fn.enc" ;
         print "/IEn StandardEncoding def\n" ;
      }
      scansizes() ;
      print "/FBB[$llx $lly $urx $ury]def\n" ;
      print for @k ;
      print "/IEn OIEn def /FBB OFBB def\n" ;
      $keep = 0 ;
   }
   if ($keep) {
      push @k, $_ ;
   } else {
      print ;
   }
   if (/^%DVIPSBitmapFont/) {
      @k = () ;
      $keep = 1 ;
      chomp ;
      @f = split " ", $_ ;
      $fn = $f[2] ;
   }
}
