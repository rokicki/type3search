my $f1 = shift ;
$f1 =~ s/.ps// ;
$f2 = $f1 . "_2" ;
print "Adding encodings.\n" ;
system("perl addencodings.pl < $f1.ps > $f2.ps") ;
print "Converting $f1 to bitmaps.\n" ;
system("pstopnm -nocrop -xborder=0 -yborder=0 -dpi=1200 -pbm -textalphabits=1 $f1.ps") ;
print "Converting $f2 to bitmaps.\n" ;
system("pstopnm -nocrop -xborder=0 -yborder=0 -dpi=1200 -pbm -textalphabits=1 $f2.ps") ;
print "Comparing.\n" ;
for ($i="001"; ; $i++) {
   last if ! -f "$f1$i.pbm" ;
   system("./xorcnt $f1$i.pbm $f2$i.pbm") ;
}
