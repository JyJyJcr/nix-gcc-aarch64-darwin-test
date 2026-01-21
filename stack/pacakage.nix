{ stdenv, gcc }:

let
  name = "stack-test";
  ver = "1.0";
in stdenv.mkDerivation {
  pname = "${name}";
  version = ver;

  meta = {
    description = "A test package to verify gcc abi stack parameter passing";
    #     license = lib.licenses.gpl3;
  };

  nativeBuildInputs = [ gcc ];
  src = ./.;

  buildPhase = ''
    clang -c sub.c -o sub_c.o
    clang -c main.c -o main_c.o
    gcc -c sub.c -o sub_g.o
    gcc -c main.c -o main_g.o
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
}
