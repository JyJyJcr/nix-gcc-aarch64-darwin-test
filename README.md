# nix-gcc-aarch64-darwin-test

this is a nix gcc test on aarch64-darwin.

currently you can observe:

- the ABI imcompatibility in stack.

## stack args

```bash
nix develop
clang -c sub.c
gcc main.c sub.o -o main
./main
```

expected to print

```txt
num:
  1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
num: 0
```

but actually

```txt
num:
  1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 10, 1, 11, 1
num: 5
```

### Explanation

aarch64-darwin uses variant of aapcs64 (seems commonly called darwinpcs).

for first 8 integer arguments (include poniter?), both use register x0 ~ x7, and the remained arguments are put to stack.

aapcs64 treat all arguments as 8byte-aligned. (see [ARM's aapcs64 doc 6.8.2 Parameter passing rules](https://github.com/ARM-software/abi-aa/blob/main/aapcs64/aapcs64.rst#682parameter-passing-rules) C. 16)
on the contrast, darwinpcs pack them as dense as possible in order (see [Apple's doc for abi difference from aapcs64](https://developer.apple.com/documentation/xcode/writing-arm64-code-for-apple-platforms#Respect-the-stacks-red-zone))

in our case, the args i,j,k,l,m,n are put to stack, and takes 8 x 6 = 48 bytes in aapcs64, but 4 x 6 = 24 bytes in darwinpcs.

nix gcc seemingly use iains' patch (see [gcc/patches/default.nix](https://github.com/NixOS/nixpkgs/blob/2c3e5ec5df46d3aeee2a1da0bfedd74e21f4bf3a/pkgs/development/compilers/gcc/patches/default.nix#L193-L227)), but above example shows the gcc still using aapcs64.
