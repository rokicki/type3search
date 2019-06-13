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
#
#   See if we can find a corresponding htf file to get Unicode code points.
#
sub loadhtf {
   @unicodemap = () ;
   my $fn = shift ;
   open F, "$fn.htf" or die "Can't open $fn.htf" ;
   my $head = scalar <F> ;
   chomp $head ;
   @f = split " ", $head ;
   my $lo = $f[1] ;
   my $hi = $f[2] ;
   my $cc ;
   my $unicodeseen = 0 ;
   for ($cc=$lo; $cc<=$hi; $cc++) {
      my $lin = scalar <F> ;
      chomp $lin ;
      $lin =~ s/''b/''/g ; # patch what looks like a bug in the htf file
      my @f = () ;
      my $q = substr($lin, 0, 1) ;
      my $at = 0 ;
      while (1) {
         $at++ while $at < length($lin) && substr($lin, $at, 1) le ' ' ;
         last if $at >= length($lin) ;
         last if substr($lin, $at, 1) eq '%' ; # ends with comment
         $tok = '' ;
         if (substr($lin, $at, 1) eq $q) { # quoted token
            $at++ ;
            $tok .= substr($lin, $at++, 1) while $at < length($lin) && substr($lin, $at, 1) ne $q ;
            $at++ ;
         } else {                          # whitespace-separated token
            $tok .= substr($lin, $at++, 1) while $at < length($lin) && substr($lin, $at, 1) gt ' ' ;
         }
         push @f, $tok ;
      }
      die "Did not see three tokens [@f] [$lin]" if @f != 3 ;
      die "Bad cc; expected $cc saw $f[2]" if $f[2] ne $cc ;
      # only pick up unicode code points
      if ($f[0] =~ /\&\#x([0-9a-fA-F]{4})/) {
         $unicodemap[$cc] = $1 ;
         $unicodeseen++ ;
      }
   }
   close F ;
   die "Did not see unicode code points" if $unicodeseen == 0 ;
   return 1 ;
}
sub searchhtf {
   my $fn = shift ;
   while ($fn ne '') {
      if (-f "$fn.htf") {
         return loadhtf($fn) ;
      }
      $fn = substr($fn, 0, length($fn)-1) ;
   }
   return 0 ;
}
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
   $keep = 0 ;
   $adobeglyph = 0 ;
   $nonadobeglyph = 0 ;
   @unicodemap = () ;
   @missingglyphs = () ;
   searchhtf($fn) ;
   %mapped = () ;
   open F, "$font" or die "Can't read $font" ;
   open G, ">encs/$fn.enc" or die "Can't write $font encoding" ;
   while (<F>) {
      if (/Encoding/) {
         $keep++ ;
      }
      # skip letters not in the tfm file
      next if $keep && /dup (\d+)/ && @exist && !$exist[$1] ;
      if ($keep) {
         if (/^dup/) {
            chomp ;
            m,dup (\d+) /(\S+) put, or die "Bad format in encoding line: [$_]\n" ;
            $cc = $1 ;
            $glyphname = $2 ;
            if (defined($unicode{$glyphname})) {
               $adobeglyph++ ;
            } else {
               $nonadobeglyph++ ;
               push @missingglyphs, $glyphname ;
               if (defined($unicodemap[$cc])) {
                  # Substitute the unicode version
                  $glyphname = "u$unicodemap[$cc]" ;
                  $mapped{$glyphname} = hex($unicodemap[$cc]) ;
               }
            }
            print G "dup $cc /$glyphname put\n" ;
         } else {
            print G $_ ;
            last if /readonly def/ ;
         }
      }
   }
   close F ;
   close G ;
   if (keys %mapped) {
      for (keys %mapped) {
         print "/$_ $mapped{$_} def\n" ;
      }
   }
   my $r = `md5 encs/$fn.enc` ;
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
