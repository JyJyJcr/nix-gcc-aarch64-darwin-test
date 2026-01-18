#include <stdio.h>

int num(int a, int b, int c, int d, int e, int f, int g, int h, // register
        int i, int j, int k, int l, int m, int n) {             // stack
    printf("  %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d\n", a, b, c, d, e, f, g, h, i, j, k, l, m, n);
    return (a != 1)    //
           + (b != 2)  //
           + (c != 3)  //
           + (d != 4)  //
           + (e != 5)  //
           + (f != 6)  //
           + (g != 7)  //
           + (h != 8)  //
           + (i != 9)  //
           + (j != 10) //
           + (k != 11) //
           + (l != 12) //
           + (m != 13) //
           + (n != 14);
}
