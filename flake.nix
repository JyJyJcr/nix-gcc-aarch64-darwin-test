{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    #nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    #flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, ... }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs { inherit system; };
      stackTest = pkgs.stdenv.mkDerivation {
        pname = "stack-test";
        version = "1.0";
        nativeBuildInputs = [ pkgs.gcc ];
        src = self;

        buildPhase = ''
          clang -c stack/sub.c -o sub_c.o
          clang -c stack/main.c -o main_c.o
          gcc -c stack/sub.c -o sub_g.o
          gcc -c stack/main.c -o main_g.o
          mkdir build
          clang main_c.o sub_c.o -o build/ccc
          clang main_c.o sub_g.o -o build/ccg
          clang main_g.o sub_c.o -o build/cgc
          clang main_g.o sub_g.o -o build/cgg
          gcc main_c.o sub_c.o -o build/gcc
          gcc main_c.o sub_g.o -o build/gcg
          gcc main_g.o sub_c.o -o build/ggc
          gcc main_g.o sub_g.o -o build/ggg

          mkdir -p ./result
          echo "# kind exit-code" > ./summary.out
          for exe in ./build/*; do
            exe_base=''${exe##*/}
            rc=0
            ''${exe} > "./result/''${exe_base}.out" || rc=$?
            echo "''${exe_base} $rc" >> ./summary.out
          done
        '';

        checkPhase = ''
          echo "# kind exit-code" > ./expected_summary.out
          for exe in ./build/*; do
            exe_base=''${exe##*/}
            rc=0
            echo "''${exe_base} $rc" >> ./expected_summary.out
          done
          diff ./summary.out ./expected_summary.out

        '';

        installPhase = ''
          mkdir -p $out
          cp -r ./build $out
          cp ./summary.out $out
          cp -r ./result $out
        '';
      };
    in {
      packages.${system}.stackTest = stackTest;

      checks.${system}.stackTest = stackTest.overrideAttrs (old: {
        doCheck = true;
        installPhase = "mkdir -p $out";
      });

      devShells.${system}.default = pkgs.mkShell { packages = [ pkgs.gcc ]; };
    };
}

