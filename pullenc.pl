for $font (glob "/usr/local/texlive/2016/texmf-dist/fonts/type1/public/amsfonts/*/*.pfb") {
   $fn = $font ;
   $fn =~ s,.*/,, ;
   $fn =~ s,.pfb,, ;
   open F, "$font" or die "Can't read $font" ;
   open G, ">$fn.enc" or die "Can't write $font encoding" ;
   $keep = 0 ;
   while (<F>) {
      if (/Encoding/) {
         $keep++ ;
      }
      print G $_ if $keep ;
      if ($keep && /readonly def/) {
         last ;
      }
   }
   close F ;
   close G ;
   my $r = `md5 $fn.enc` ;
   chomp $r ;
   @f = split " ", $r ;
   $r = $f[-1] ;
   push @{$f{$r}}, $fn ;
}
for (keys %f) {
   print "$_: @{$f{$_}}\n" ;
}
