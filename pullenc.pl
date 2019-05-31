for $font (glob "/usr/local/texlive/2016/texmf-dist/fonts/type1/public/amsfonts/*/*.pfb") {
   $fn = $font ;
   $fn =~ s,.*/,, ;
   $fn =~ s,.pfb,, ;
   @exist = () ;
   open F, "tftopl $fn |" or die "Can't run tftopl" ;
   while (<F>) {
      if (/^\(CHARACTER O (\d+)/) {
         $exist[oct($1)] = 1 ;
      } elsif (/^\(CHARACTER C (\S)/) {
         $exist[ord($1)] = 1 ;
      }
   }
   close F ;
   open F, "$font" or die "Can't read $font" ;
   open G, ">$fn.enc" or die "Can't write $font encoding" ;
   $keep = 0 ;
   while (<F>) {
      if (/Encoding/) {
         $keep++ ;
      }
      # skip letters not in the tfm file
      next if $keep && /dup (\d+)/ && @exist && !$exist[$1] ;
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
