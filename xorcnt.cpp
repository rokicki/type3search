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
   return f ;
}
int bc[256] ;
int main(int argc, char *argv[]) {
   FILE *f1 = getit(argv[1]) ;
   FILE *f2 = getit(argv[2]) ;
   long long cnt = 0 ;
   for (int i=1; i<256; i++)
      bc[i] = bc[i&(i-1)] + 1 ;
   while (1) {
      int c1 = getc(f1) ;
      if (c1 == EOF)
         break ;
      int c2 = getc(f2) ;
      if (c1 != c2)
         cnt += bc[c1^c2] ;
   }
   cout << argv[1] << " " << argv[2] << " " << cnt << endl ;
}
