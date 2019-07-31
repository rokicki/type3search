$num = "000001" ;
while (-f "fasc1a-$num.ppm") {
   system("./xor fasc1a-$num.ppm fasc1a-2--$num.ppm > t1.ppm") ;
   system("open t1.ppm") ;
   print "Waiting . . ." ;
   scalar <> ;
   $num++ ;
}
