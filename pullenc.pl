use strict ;
use File::Find ;
#
my $texlivedir = "/usr/local/texlive/2019/texmf-dist" ;
#
my $writeindividualfiles = 0 ;
#
#   Let's read the glyph names that are predefined in the AGL from the
#   AGLFN; these are the only bare names we really should use.
#
my %aglnames ;
open F, "agl/aglfn.txt" or die "Can't read the aglfn" ;
while (<F>) {
   next if /^#/ ; # skip comments
   chomp ;
   my @f = split /;/, $_ ;
   die "Bad line in aglfn" if @f != 3 ;
   $aglnames{$f[1]} = $f[0] ;
}
close F ;
#
#   Now we scan the directory provided above, locating all Metafont,
#   pfb, pfa, tfm, and enc files, and store their locations by their
#   base names.
#
my %fullpath ;
my $filecount = 0 ;
sub findaux {
   my $fn = $_ ;
   my $basename ;
   my $ext ;
   ($basename, $ext) = /(.*)\.(.*)/ or return ;
   $ext eq 'tfm' or $ext eq 'pfb' or $ext eq 'pfa' or $ext eq 'mf' or
                    $ext eq 'enc' or return ;
   $fullpath{$basename}{$ext} = $File::Find::name ;
   $filecount++ ;
}
find(\&findaux, "$texlivedir/fonts") ;
print "Found $filecount files of possible interest.\n" ;
#
#   Read a PFB or a PFA file for its encoding.
#
my @exist ;
sub readpfbpfaencoding {
   my $fn = shift ;
   open F, "$fn" or die "Can't read $fn" ;
   local $/ = undef ;
   my @lines = split /[\n\r]+/, <F> ;
   my @actualenc = ('/.notdef') x 256 ;
   my $isstandard = 0 ;
   my $i ;
   for (@lines) {
      next if /^ *%/ ;
      # this shows up in a number of PFB files to remap characters.
      if (/dup dup 161 10 getinterval 0 exch putinterval dup dup 173 23 getinterval 10 exch putinterval dup dup 127 exch 196 get put/) {
         for ($i=0; $i<10; $i++) {
            print "Bad remap 1\n" if $actualenc[$i] ne '/.notdef' ;
            $actualenc[$i] = $actualenc[161+$i] ;
         }
         for ($i=0; $i<23; $i++) {
#  disable this message; too alarming
#           print "Bad remap 2 $i $actualenc[10+$i] $actualenc[173+$i]\n" if $actualenc[10+$i] ne '/.notdef' && $actualenc[10+$i] ne $actualenc[173+$i] ;
            $actualenc[10+$i] = $actualenc[173+$i] ;
         }
         print "Bad remap 3\n" if $actualenc[127] ne '/.notdef' ;
         $actualenc[127] = $actualenc[196] ;
         next ;
      }
      next if /dup  *(\d+)/ && @exist && !$exist[$1] ;
      $isstandard++ if /Encoding/ && /StandardEncoding/ ;
      if (m,dup  *(\d+) *(/\S+)  *put,) {
         my $glyphname = $2 ;
         my $code = $1 ;
         $actualenc[$code] = $glyphname ;
      }
   }
   close F ;
   if ($isstandard) {
      return ('StandardEncoding') ;
   } else {
      die "Bad length [@actualenc] from $fn" if @actualenc != 256 ;
      return @actualenc ;
   }
}
#
#   Read a TFM file, only to find what characters really exist.
#
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
#
#   Find the built psfonts.map file and read it.  Only keep lines that match
#   things we saw MF source for and have a TFM file for.
#
my %exist ;
my %encoding ;
open H, "$texlivedir/fonts/map/dvips/updmap/psfonts.map" or die "Can't read psfonts.map" ;
while (<H>) {
   next if /^\s*%/ ;
   my @f = split " ", $_ ;
   next if !$fullpath{$f[0]}{"mf"} || !$fullpath{$f[0]}{"tfm"} ;
   /<([-_a-zA-Z0-9]+).(pf[ab])/ or warn $_ ;
   my $pfbname = $1 ;
   my $pfbext = $2 ;
   die "Missing font $1 $2" if !$fullpath{$1}{$2} ;
   my $basename = $f[0] ;
   if (/reencode/i) {  # locate and read the encoding file
      /<\[?([-_a-zA-Z0-9]+).enc/ or warn $_ ;
      my $fn = $fullpath{$1}{"enc"} ;
      die "Missing encoding $1 enc" if !$fn ;
      open G, $fn or die "Can't read encoding file" ;
      my @tokens = () ;
      # tokenize into an array
      while (<G>) {
         chomp ;
         s/%.*// ;
         while (m,(/[^ ]+),g) {
            push @tokens, $1 ;
         }
      }
      close G ;
      die "Misread encoding file $fn" if @tokens != 257 ;
      shift @tokens ;
      for (@tokens) {
         die "Space in parsed token?" if / / ;
      }
      $encoding{$basename} = [@tokens] ;
   } else { # locate and read the PFB/PFA file
      my $fn = $fullpath{$pfbname}{$pfbext} ;
      die "Missing PFB or PFA file $pfbname $pfbext" if !$fn ;
      $encoding{$basename} = [readpfbpfaencoding($fn)] ;
   }
   $exist{$basename} = [readtfm($fullpath{$basename}{"tfm"})] ;
}
close H ;
$filecount = scalar keys %exist ;
print "Found $filecount encoded files to include.\n" ;
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
my @enc ;
sub writeenc {
   $linepos = 0 ;
   if (@enc == 1) {
      print G "StandardEncoding\n" ;
   } else {
      specialout('[') ;
      my $i = 0 ;
      while ($i < 256) {
         my $j = $i ;
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
}
my %enctofonts ;
for my $font (keys %exist) {
#
#   At this point we should have an encoding from either the PFB/PFA
#   file or the encoding file.
#
#   We read the characters actually defined.  We used to use tftopl but
#   that turned out to be really slow, so we actually read the files
#   themselves.
#
   @enc = @{$encoding{$font}} ;
   @exist = @{$exist{$font}} ;
   my $adobeglyph = 0 ;
   my $nonadobeglyph = 0 ;
   my @missingglyphs = () ;
   if (@enc == 1) {
      # standard; ignore
   } elsif (@enc == 256) {
      my @badchars = () ;
      for (my $i=0; $i<@exist; $i++) {
         if ($exist[$i] && $enc[$i] eq '/.notdef') {
            push @badchars, $i ;
         }
      }
      if (@badchars) {
         print "Font $font chars in TFM but not in Encoding: [@badchars]\n" ;
      }
      for (my $i=0; $i<256; $i++) {
         if (!$exist[$i]) {
            $enc[$i] = '/.notdef' ;
         }
         my $glyphname = substr($enc[$i], 1) ;
         next if $glyphname eq '.notdef' ;
         if (defined($aglnames{$glyphname})) {
            $adobeglyph++ ;
         } else {
            $nonadobeglyph++ ;
            push @missingglyphs, $glyphname ;
         }
      }
   } else {
      die "Bad enc length " . (scalar @enc) . " [@enc]" ;
   }
   $encoding{$font} = [@enc] ;
   if ($writeindividualfiles) {
      open G, ">encs/dvips-$font.enc" or die "Can't write $font encoding" ;
      writeenc() ;
      close G ;
   }
   my $r = join ',',@enc ;
   if (!defined($enctofonts{$r})) { # first time we saw this encoding
      print "For font $font saw $adobeglyph Adobe glyphs and $nonadobeglyph non-Adobe glyphs\n" ;
      if (@missingglyphs) {
         my $s = "   [@missingglyphs]" ;
         if (length($s) > 75) {
            $s = substr($s, 0, 70) . "...]" ;
         }
         print "$s\n" ;
      }
   }
   push @{$enctofonts{$r}}, $font ;
}
open G, ">encs/dvips-all.enc" or die "Can't write dvips-all.enc" ;
for (sort { $a cmp $b } keys %enctofonts) {
   for (sort {$a cmp $b} @{$enctofonts{$_}}) {
      print G "$_:\n" ;
   }
   @enc = @{$encoding{$enctofonts{$_}[0]}} ;
   writeenc() ;
}
close G ;
