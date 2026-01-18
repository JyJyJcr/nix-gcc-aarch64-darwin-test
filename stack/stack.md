# Stack argument passing

This document describes the stack argument passing test.

## procedure

Clone this repository and move to this directory, then run

```bash
nix develop
clang -c sub.c
gcc -c main.c
gcc main.o sub.o -o main
./main
```

`main` is expected to print:

```txt
num:
  1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
num: 0
```

However, due to a GCC ABI implementation bug, it actually prints:

```txt
num:
  1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 10, 1, 11, 1
num: 5
```

`checks.aarch64-darwin.stackTest` performs this compilation using all 8 combinations of the compilers and check that all the resulting binaries exits with code 0.

## Explanation

aarch64-darwin uses a variant of AAPCS64, commonly refered to as DarwinPCS.

For first 8 integer arguments (including poniter), both ABIs use registers `x0` ~ `x7`. Remaining arguments are passed on the stack. The behavior then differs:

- AAPCS64 treats all stack arguments as 8-byte aligned
  (see [ARM AAPCS64 6.8.2 Parameter passing rules](https://github.com/ARM-software/abi-aa/blob/main/aapcs64/aapcs64.rst#682parameter-passing-rules), C. 16).
- In contrast, darwinpcs pack stack arguments as densely as possible, in order
  (see [Apple's documentation on ABI differences from AAPCS64](https://developer.apple.com/documentation/xcode/writing-arm64-code-for-apple-platforms#Respect-the-stacks-red-zone)).

In this case, the argumentss `i` ~ `n` are passed on the stack as follows:

- Under AAPCS64, they occupy `6 * 8 = 48` bytes.
- Under DarwinPCS, they occupy `6 * 4 = 24` bytes.

Although Nix GCC appears to apply Iain's patches (see [gcc/patches/default.nix](https://github.com/NixOS/nixpkgs/blob/2c3e5ec5df46d3aeee2a1da0bfedd74e21f4bf3a/pkgs/development/compilers/gcc/patches/default.nix#L193-L227)), this test shows that GCC still using AAPCS64 rather than DarwinPCS.
