#
#    Make a C file that includes the encodings from a given set of files,
#    ready to go, including the specific fonts for which the encodings
#    match.
#
my $pos = 0 ;
my $MAXLINE = 76 ;
sub emit {
   my $s = shift ;
   if (length($s) + $pos > $MAXLINE) {
      print "\n" ;
      $pos = 0 ;
   }
   print $s ;
   $pos += length($s) ;
}
sub endofline {
   if ($pos != 0) {
      print "\n" ;
      $pos = 0 ;
   }
}
for $f (glob "encs/*") {
   my $fontname = $f ;
   $fontname =~ s,encs/,, ;
   $fontname =~ s,\.enc$,, ;
   push @fonts, $fontname ;
   open F, "$f" or die "Can't read fontname" ;
   @e = (undef) x 256 ;
   while (<F>) {
      if (/^dup/) {
         chomp ;
         @f = split " ", $_ ;
         $num = $f[1] ;
         $nam = $f[2] ;
         $e[$num] = $nam ;
      }
   }
   close F ;
   $key = join(' ', map{$_?$_:"."}@e) ;
   if (!defined($seen{$key})) {
      $encname = "E_" .$fontname ;
      $seen{$key} = $encname ;
      emit("static const char *${encname}[256]={") ;
      for ($i=0; $i<256; $i++) {
         if (defined($e[$i])) {
            if ($i == 255) {
               emit('"'.$e[$i].'"};') ;
            } else {
               emit('"'.$e[$i].'",') ;
            }
         } else {
            if ($i == 255) {
               emit('0};') ;
            } else {
               emit('0,') ;
            }
         }
      }
      endofline() ;
   }
   $enc{$fontname} = $seen{$key} ;
}
emit("struct bmfontinfo{const char *fontname;const char **enc;};") ;
endofline() ;
emit("static struct bmfontinfo bmfontarr[]={") ;
for ($i=0; $i<@fonts; $i++) {
   my $fontname = $fonts[$i] ;
   my $entr = '{"'.$fontname.'",'.$enc{$fontname}.'}' ;
   if ($i+1==@fonts) {
      emit($entr) ;
   } else {
      emit($entr.',') ;
   }
}
emit("};") ;
endofline() ;
