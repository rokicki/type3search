#
#   Let's read the glyph names that are predefined in the AGL from the
#   AGLFN; these are the only bare names we really should use.
#
open F, "agl/aglfn.txt" or die "Can't read the aglfn" ;
while (<F>) {
   next if /^#/ ; # skip comments
   chomp ;
   @f = split /;/, $_ ;
   die "Bad line in aglfn" if @f != 3 ;
   $unicode{$f[1]} = $f[0] ;
}
close F ;
my $count = scalar keys %unicode ;
print "Read $count glyph names from the Adobe Glyph Names for New Fonts.\n" ;
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
   $adobeglyph = 0 ;
   $nonadobeglyph = 0 ;
   @missingglyphs = () ;
   while (<F>) {
      if (/Encoding/) {
         $keep++ ;
      }
      # skip letters not in the tfm file
      next if $keep && /dup (\d+)/ && @exist && !$exist[$1] ;
      if ($keep) {
         print G $_ ;
         last if /readonly def/ ;
         next if /Encoding 256 array/ || /0 1 255/ ;
         chomp ;
         m,dup (\d+) /(\S+) put, or die "Bad format in encoding line: [$_]\n" ;
         $glyphname = $2 ;
         if (defined($unicode{$glyphname})) {
            $adobeglyph++ ;
         } else {
            $nonadobeglyph++ ;
            push @missingglyphs, $glyphname ;
         }
      }
   }
   close F ;
   close G ;
   my $r = `md5 $fn.enc` ;
   chomp $r ;
   @f = split " ", $r ;
   $r = $f[-1] ;
   if (!defined($f{$r})) { # first time we saw this encoding
      print "For font $fn saw $adobeglyph Adobe glyphs and $nonadobeglyph non-Adobe glyphs [@missingglyphs]\n" ;
   }
   push @{$f{$r}}, $fn ;
}
for (keys %f) {
   print "$_: @{$f{$_}}\n" ;
}
