for $f (glob "fasc*.ps") {
   next if $f =~ /pkfix/ ;
   next if $f =~ /addenc/ ;
   $base = $f ;
   $base =~ s/\..*// ;
   system("ps2pdf $f $base-ps2pdf.pdf") ;
   system("pdftotext $base-ps2pdf.pdf") ;
   system("pstopdf $f -o $base-pstopdf.pdf") ;
   system("pdftotext $base-pstopdf.pdf") ;
   system("pkfix $f $base-pkfix.ps") ;
   system("ps2pdf $base-pkfix.ps $base-pkfix-ps2pdf.pdf") ;
   system("pdftotext $base-pkfix-ps2pdf.pdf") ;
   system("pstopdf $base-pkfix.ps -o $base-pkfix-pstopdf.pdf") ;
   system("pdftotext $base-pkfix-pstopdf.pdf") ;
   system("perl addencodings.pl < $f > $base-addenc.ps") ;
   system("ps2pdf $base-addenc.ps $base-addenc-ps2pdf.pdf") ;
   system("pdftotext $base-addenc-ps2pdf.pdf") ;
   system("pstopdf $base-addenc.ps -o $base-addenc-pstopdf.pdf") ;
   system("pdftotext $base-addenc-pstopdf.pdf") ;
}
