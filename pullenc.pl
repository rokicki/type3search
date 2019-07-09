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
# print "Read $count glyph names from the Adobe Glyph Names for New Fonts.\n" ;
#
#   Find fonts that appear to have both mf and pfb files.  Match by name
#   but keep track of directory.
#
$mfread = 0 ;
open F, "find /usr/local/texlive/2016/texmf-dist/fonts/source -name '*.mf' |" or die "Can't fork" ;
$ignorethese{$_}++ for qw(test bzrsetup local ligature gamma) ;
while (<F>) {
   $mfread++ ;
   chomp ;
   $fullname = $_ ;
   $basename = $fullname ;
   $basename =~ s,.*/,, ;
   $basename =~ s,.mf$,, ;
   next if $ignorethese{$basename} ;
   if (defined($seen{$basename})) {
      print "For $basename see $seen{$basename} and $fullname\n" ;
   }
   $seen{$basename} = $fullname ;
}
print "Saw $mfread METAFONT files.\n" ;
#
#   Find the built psfonts.map file and read it.  Only keep lines that match
#   things we saw MF source for.
#
my $matchingpsfonts = 0 ;
open F, "/usr/local/texlive/2016/texmf-dist/fonts/map/dvips/updmap/psfonts.map" or die "Can't read psfonts.map" ;
while (<F>) {
   next if /^\s*%/ ;
   @f = split " ", $_ ;
   next if !$seen{$f[0]} ;
   /<([-_a-zA-Z0-9]+).pf[ab]/ or warn $_ ;
   $fontfile{$f[0]} = $1 ;
   $needpfbfile{$1}++ ;
   $matchingpsfonts++ ;
   if (/reencode/i) {
      /<\[?([-_a-zA-Z0-9]+).enc/ or warn $_ ;
      $encfile{$f[0]} = $1 ;
      $needencfile{$1}++ ;
   }
}
close F ;
print "Saw $matchingpsfonts matching PostScript fonts.\n" ;
#
#   Now find encoding files.  For now we only store their location.
#
my $encfilesread = 0 ;
open F, "find /usr/local/texlive/2016/texmf-dist/fonts -name '*.enc' |" or die "Can't fork" ;
while (<F>) {
   chomp ;
   $fullname = $_ ;
   $basename = $fullname ;
   $basename =~ s,.*/,, ;
   $basename =~ s,.enc$,, ;
   if ($needencfile{$basename}) {
      die "Duplicated encoding file?" if $foundencfile{$basename} ;
      $foundencfile{$basename}++ ;
      $encfullpath{$basename} = $fullname ;
      $encfilesread++ ;
      open G, "$fullname" or die "Can't read encoding file $fullname" ;
      @tokens = () ;
      # tokenize into an array
      while (<G>) {
         chomp ;
         s/%.*// ;
         while (m,(/[^ ]+),g) {
            push @tokens, $1 ;
         }
      }
      close G ;
      die "Misread encoding file $fullname" if @tokens != 257 ;
      shift @tokens ;
      for (@tokens) {
         die "Space in parsed token?" if / / ;
      }
      $encoding{$basename} = [@tokens] ;
   }
}
close F ;
print "Read $encfilesread encoding files.\n" ;
#
#   Did we find all needed encoding files?
#
for (keys %needencfile) {
   die "Missing encoding file $_" if !$foundencfile{$_} ;
}
#
#   Do the same for PFB files now.  Except here we explicitly drop the
#   rune fonts and the cbfonts; there are just too many of the latter,
#   and the former have some issue with missing TFM files, and in general
#   we just don't want to do all the fonts.  We also drop the cmcyr fonts.
#
my $pfbfilesseen = 0 ;
open F, "find /usr/local/texlive/2016/texmf-dist/fonts/ -name '*.pfb' -o -name '*.pfa' |" or die "Can't fork" ;
while (<F>) {
#  next if /cbfonts/ ;
#  next if /allrunes/ ;
#  next if /cmcyr/ ;
   chomp ;
   $fullname = $_ ;
   $basename = $fullname ;
   $basename =~ s,.*/,, ;
   $basename =~ s,.pf[ab]$,, ;
   next if !$needpfbfile{$basename} ;
   $pfbfilesseen++ ;
   die "Double seen PFB file?" if defined($pfbseen{$basename}) ;
   $pfbseen{$basename} = $fullname ;
}
print "Saw $pfbfilesseen PFB or PFA files.\n" ;
my $files = scalar keys %pfbseen ;
#
#   Instead of pfb files we should read afm files.  We tried this, but we
#   are missing almost all afm files for the pfb analogs of Metafont fonts
#   so we don't do this.
#
if (0) {
   open F, "find /usr/local/texlive/2016/texmf-dist/fonts/ -name '*.afm' |" or die "Can't fork" ;
   while (<F>) {
      next if /cbfonts/ ;
      next if /allrunes/ ;
      next if /cmcyr/ ;
      chomp ;
      $fullname = $_ ;
      $basename = $fullname ;
      $basename =~ s,.*/,, ;
      $basename =~ s,.afm$,, ;
      next if !$seen{$basename} ; # only look at AFMs that have MF source files
      if (defined($afmseen{$basename})) {
         print "For $basename see $afmseen{$basename} and $fullname\n" ;
      }
      $afmseen{$basename} = $fullname ;
   }
#
#   Compare PFB and AFM keys.
#
   for $k (keys %afmseen) {
      print "Saw AFM for $k but no PFB\n" if !defined($pfbseen{$k}) ;
   }
   for $k (keys %pfbseen) {
      print "Saw PFB for $k but no AFM\n" if !defined($afmseen{$k}) ;
   }
}
#
#   Make sure we have tfm files for all of these.
#
my $tfmfilesseen = 0 ;
open F, "find /usr/local/texlive/2016/texmf-dist/fonts/ -name '*.tfm' |" or die "Can't fork" ;
while (<F>) {
   chomp ;
   $fullname = $_ ;
   $basename = $fullname ;
   $basename =~ s,.*/,, ;
   $basename =~ s,.tfm$,, ;
   next if !defined($fontfile{$basename}) ;
   $tfmfilesseen++ ;
   $tfmseen{$basename}++ ;
}
my @deleteme = () ;
for (keys %fontfile) {
   if (!defined($tfmseen{$_})) {
      push @deleteme, $_ ;
   }
}
for (@deleteme) {
   delete $fontfile{$_} ;
}
print "Saw $tfmfilesseen TFM files; skipping ", (scalar @deleteme), " possibly good font files.\n" ;
my $linepos = 0 ;
my $lastwasspecial = 1 ;
my $maxline = 76 ;
sub endofline {
   print G "\n" ;
   $lastwasspecial = 1 ;
   $linepos = 0 ;
}
sub cmdout {
   my $s = shift ;
   endofline() if $linepos + length($s) > $maxline ;
   if (!$lastwasspecial) {
      print G " " ;
      $linepos++ ;
   }
   print G $s ;
   $linepos += length($s) ;
   $lastwasspecial = 0 ;
}
sub specialout {
   my $s = shift ;
   endofline() if $linepos + length($s) > $maxline ;
   print G $s ;
   $linepos += length($s) ;
   $lastwasspecial = 1 ;
}
sub nameout {
   my $s = shift ;
   $lastwasspecial = 1 ;
   cmdout($s) ;
}
#
$seq = 0 ;
$oldslash = $/ ;
my $pfbfilesread = 0 ;
for $font (keys %needpfbfile) {
   $pfbfilesread++ ;
   open F, "$pfbseen{$font}" or die "Can't read $font ($pfbseen{$font})" ;
   undef $/ ;
   @lines = split /[\n\r]+/, <F> ;
   @actualenc = ('/.notdef') x 256 ;
   $chars = 0 ;
   $isstandard = 0 ;
   for (@lines) {
      next if /^ *%/ ;
      # this shows up in a number of PFB files to remap characters.
      if (/dup dup 161 10 getinterval 0 exch putinterval dup dup 173 23 getinterval 10 exch putinterval dup dup 127 exch 196 get put/) {
         for ($i=0; $i<10; $i++) {
            print "Bad remap 1\n" if $actualenc[$i] ne '/.notdef' ;
            $actualenc[$i] = $actualenc[161+$i] ;
         }
         for ($i=0; $i<23; $i++) {
            print "Bad remap 2 $pfbseen{$font} $i $actualenc[10+$i] $actualenc[173+$i]\n" if $actualenc[10+$i] ne '/.notdef' && $actualenc[10+$i] ne $actualenc[173+$i] ;
            $actualenc[10+$i] = $actualenc[173+$i] ;
         }
         print "Bad remap 3\n" if $actualenc[127] ne '/.notdef' ;
         $actualenc[127] = $actualenc[196] ;
         next ;
      }
      next if /dup  *(\d+)/ && @exist && !$exist[$1] ;
      $isstandard++ if /Encoding/ && /StandardEncoding/ ;
      if (m,dup  *(\d+) *(/\S+)  *put,) {
         $glyphname = $2 ;
         $code = $1 ;
         $actualenc[$code] = $glyphname ;
         $chars++ ;
         if (defined($unicode{$glyphname})) {
            $adobeglyph++ ;
         } else {
            $nonadobeglyph++ ;
            push @missingglyphs, $glyphname ;
         }
      }
   }
   close F ;
   if ($isstandard) {
      die "Standard encoding, but also saw defs in $font" if $chars ;
      $pfbenc{$font} = ['StandardEncoding'] ;
   } else {
      $pfbenc{$font} = [@actualenc] ;
   }
   $/ = $oldslash ;
}
print "Read $pfbfilesread PFB files.\n" ;
for $font (keys %fontfile) {
#
#   At this point we should have an encoding from either the PFB/PFA
#   file or the encoding file.
#
#   We read the characters actually defined with tftopl.
#
   $fn = $font ;
   $seq++ ;
   @exist = (0) x 256 ;
   $/ = $oldslash ;
   open F, "tftopl $fn 2>/dev/null |" or die "Can't run tftopl" ;
   while (<F>) {
      if (/^\(CHARACTER O (\d+)/) {
         $exist[oct($1)] = 1 ;
      } elsif (/^\(CHARACTER C (\S)/) {
         $exist[ord($1)] = 1 ;
      }
   }
   close F ;
   $adobeglyph = 0 ;
   $nonadobeglyph = 0 ;
   @missingglyphs = () ;
   @enc = () ;
   $isstandard = 0 ;
   if ($encfile{$font}) {
      $fromencfile++ ;
      @enc = @{$encoding{$encfile{$font}}} ;
   } elsif ($fontfile{$font}) {
      $frompfbfile++ ;
      @enc = @{$pfbenc{$fontfile{$font}}} ;
   } else {
      die "No encoding for $font\n" ;
   }
   if (@enc == 1) {
      die "Expected standard encoding but got [@enc]" if $enc[0] ne 'StandardEncoding' ;
      $isstandard = 1 ;
   } elsif (@enc == 256) {
      for ($i=0; $i<256; $i++) {
         $glyphname = substr($enc[$i], 1) ;
         next if $glyphname eq '.notdef' ;
         $chars++ ;
         if (defined($unicode{$glyphname})) {
            $adobeglyph++ ;
         } else {
            $nonadobeglyph++ ;
            push @missingglyphs, $glyphname ;
         }
      }
      @badchars = () ;
      for ($i=0; $i<@exist; $i++) {
         if ($exist[$i] && $enc[$i] eq '/.notdef') {
            push @badchars, $i ;
         }
      }
      if (@badchars) {
         print "Font $font chars in TFM but not in Encoding: [@badchars]\n" ;
      }
   } else {
      die "Bad enc length " . (scalar @enc) . " [@enc]" ;
   }
   $/ = $oldslash ;
   open G, ">encs/$fn.enc" or die "Can't write $font encoding" ;
   $linepos = 0 ;
   if ($isstandard) {
      print G "StandardEncoding\n" ;
   } else {
      specialout('[') ;
      $i = 0 ;
      while ($i < 256) {
         $j = $i ;
         $j++ while $j < 256 && $enc[$j] eq '/.notdef' ;
         if ($j-$i > 2) {
            cmdout($j-$i) ;
            specialout('{') ;
            nameout('/.notdef') ;
            specialout('}') ;
            cmdout('repeat') ;
            $i = $j ;
         } else {
            nameout($enc[$i]) ;
            $i++ ;
         }
      }
      specialout(']') ;
      endofline() ;
   }
   close G ;
   my $r = `md5 encs/$fn.enc` ;
   chomp $r ;
   @f = split " ", $r ;
   $r = $f[-1] ;
   if (!defined($f{$r})) { # first time we saw this encoding
      print "For font $fn saw $adobeglyph Adobe glyphs and $nonadobeglyph non-Adobe glyphs\n" ;
      if (@missingglyphs) {
         $s = "   [@missingglyphs]" ;
         if (length($s) > 75) {
            $s = substr($s, 0, 70) . "...]" ;
         }
         print "$s\n" ;
      }
      $validagl{$r} = $adobeglyph ;
      $invalidagl{$r} = $nonadobeglyph ;
   }
   push @{$f{$r}}, $fn ;
}
open F, ">encs/dvips-all.enc" or die "Can't write dvips-all.enc" ;
for (keys %f) {
   $fontc = @{$f{$_}} ;
   print "$_: $validagl{$_} $invalidagl{$_} $fontc @{$f{$_}}\n" ;
   for (@{$f{$_}}) {
      print F "$_:\n" ;
   }
   open G, "encs/$f{$_}[0].enc" or die "Can't read file" ;
   while (<G>) {
      print F $_ ;
   }
   close G ;
}
close F ;
print "Got encoding $fromencfile from encoding file and $frompfbfile from pfb file.\n" ;
