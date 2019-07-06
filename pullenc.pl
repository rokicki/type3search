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
#   Find fonts that appear to have both mf and pfb files.  Match by name
#   but keep track of directory.
#
open F, "find /usr/local/texlive/2016/texmf-dist/fonts/source -name '*.mf' |" or die "Can't fork" ;
$ignorethese{$_}++ for qw(test bzrsetup local ligature gamma) ;
while (<F>) {
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
#
#   Do the same for PFB files now.  Except here we explicitly drop the
#   rune fonts and the cbfonts; there are just too many of the latter,
#   and the former have some issue with missing TFM files, and in general
#   we just don't want to do all the fonts.  We also drop the cmcyr fonts.
#
open F, "find /usr/local/texlive/2016/texmf-dist/fonts/ -name '*.pfb' |" or die "Can't fork" ;
while (<F>) {
   next if /cbfonts/ ;
   next if /allrunes/ ;
   next if /cmcyr/ ;
   chomp ;
   $fullname = $_ ;
   $basename = $fullname ;
   $basename =~ s,.*/,, ;
   $basename =~ s,.pfb$,, ;
   next if !$seen{$basename} ; # only look at PFBs that have MF source files
   if (defined($pfbseen{$basename})) {
      print "For $basename see $pfbseen{$basename} and $fullname\n" ;
   }
   $pfbseen{$basename} = $fullname ;
}
my $files = scalar keys %pfbseen ;
print "Saw $files PFB files with matching METAFONT source.\n" ;
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
open F, "find /usr/local/texlive/2016/texmf-dist/fonts/ -name '*.tfm' |" or die "Can't fork" ;
while (<F>) {
   chomp ;
   $fullname = $_ ;
   $basename = $fullname ;
   $basename =~ s,.*/,, ;
   $basename =~ s,.pfb$,, ;
   next if !$pfbseen{$basename} ;
   $tfmseen{$basename}++ ;
}
my $files = scalar keys %pfbseen ;
my $tfmfiles = $files ;
print "Saw $files PFB files with matching METAFONT source.\n" ;
print "Saw $tfmfiles TFM files for these.\n" ;
#
#
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
@fontfilelist = sort { $a cmp $b } values %pfbseen ;
$seq = 0 ;
$cnt = @fontfilelist ;
$oldslash = $/ ;
for $font (@fontfilelist) {
   $fn = $font ;
   $fn =~ s,.*/,, ;
   $fn =~ s,.pfb,, ;
   $seq++ ;
   @exist = (0) x 256 ;
   $/ = $oldslash ;
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
   $adobeglyph = 0 ;
   $nonadobeglyph = 0 ;
   @missingglyphs = () ;
   $killit = 0 ;
   undef $/ ;
   @lines = split /[\n\r]+/, <F> ;
   @actualenc = ('/.notdef') x 256 ;
   $chars = 0 ;
   $isstandard = 0 ;
   for (@lines) {
      next if /^ *%/ ;
      # skip letters not in the tfm file
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
   } else {
      if ($chars == 0) {
         print "Not finding anything useful for $font\n" ;
         next ;
      }
      @badchars = () ;
      for ($i=0; $i<@exist; $i++) {
         if ($exist[$i] && $actualenc[$i] eq '/.notdef') {
            push @badchars, $i ;
         }
      }
      if (@badchars) {
         print "Font $font chars in TFM but not in PFB: [@badchars]\n" ;
      }
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
         $j++ while $j < 256 && $actualenc[$j] eq '/.notdef' ;
         if ($j-$i > 2) {
            cmdout($j-$i) ;
            specialout('{') ;
            nameout('/.notdef') ;
            specialout('}') ;
            cmdout('repeat') ;
            $i = $j ;
         } else {
            nameout($actualenc[$i]) ;
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
