#include <iostream>
#include <cstdio>
#include <cstdlib>
using namespace std ;
int w, h, d ;
void error(const char *s) {
   cerr << s << endl ;
   exit(0) ;
}
FILE *getit(const char *s) {
   FILE *f = fopen(s, "rb") ;
   if (f == 0)
      error("! can't open file") ;
   if (getc(f) != 'P' || getc(f) != '6' || getc(f) != 10)
      error("! not a PPM file?") ;
   int tw=-1, th=-1, td=-1 ;
   if (fscanf(f, "%d %d %d", &tw, &th, &td) != 3)
      error("! didn't get width/height") ;
   if (getc(f) != 10)
      error("! missing end newline") ;
   if (w == 0) {
      w = tw ;
      h = th ;
      d = td ;
   } else if (w != tw || h != th || d != td)
      error("! different sizes") ;
   return f ;
}
int main(int argc, char *argv[]) {
   FILE *f1 = getit(argv[1]) ;
   FILE *f2 = getit(argv[2]) ;
   printf("P6\n%d %d\n%d\n", w, h, d) ;
   while (1) {
      int c1 = getc(f1) ;
      int c2 = getc(f2) ;
      if (c1 < 0 && c2 < 0)
         break ;
      if (c1 < 0 || c2 < 0)
         error("! files are different length") ;
      putchar(c1^c2^255) ;
   }
}
