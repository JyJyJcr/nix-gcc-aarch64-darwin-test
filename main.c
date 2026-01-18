#include <stdio.h>
extern int num(int a, int b, int c, int d, int e, int f, int g, int h, // register
               int i, int j, int k, int l, int m, int n);              // stack
int main() {
    printf("num:\n");
    int r_num = num(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14);
    printf("num: %d\n", r_num);
    return r_num;
}
