#
#   Check for bad fontbb by iterating over fonts and within a font over
#   characters.
#
for $font (glob "encs/*") {
   $fn = $font ;
   $fn =~ s,.*/,, ;
   $fn =~ s,.enc,, ;
   @exist = () ;
   print "Checking $fn" ;
   open F, "tftopl $fn |" or die "Can't run tftopl" ;
   while (<F>) {
      if (/^\(CHARACTER O (\d+)/) {
         $exist[oct($1)] = 1 ;
      } elsif (/^\(CHARACTER C (\S)/) {
         $exist[ord($1)] = 1 ;
      }
   }
   close F ;
   for ($i=0; $i<256; $i++) {
      next if !$exist[$i] ;
      if ($i > 32 && $i < 127) {
         print " ", chr($i) ;
      } else {
         print " [", $i, "]" ;
      }
      open F, ">t.tex" or die "Can't write t.tex" ;
      print F "\\nopagenumbers\\font\\norm=$fn \\norm\\char$i \\bye\n" ;
      close F ;
      system("tex t > /dev/null") ;
      system("perl fakedvips.pl t") ;
      system("pdftopng t.pdf t.png 2>&1 | grep -v Config") ;
   }
   print "\n" ;
}
