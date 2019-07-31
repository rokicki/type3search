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
#   Do the same for PFB files now.
#
open F, "find /usr/local/texlive/2016/texmf-dist/fonts/ -name '*.pfb' |" or die "Can't fork" ;
while (<F>) {
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
