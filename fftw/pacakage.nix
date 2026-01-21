{ stdenv, fftw, gfortran, pkg-config }:

let
  name = "fftw-test";
  ver = "1.0";
in stdenv.mkDerivation {
  pname = "${name}";
  version = ver;

  meta = {
    description = "A test package to verify gfortran abi on fftw3 calls";
    #     license = lib.licenses.gpl3;
  };

  buildInputs = [ fftw ];
  nativeBuildInputs = [ gfortran pkg-config ];

  src = ./.;

  buildPhase = ''
    mkdir build
    gfortran main.f03 -o build/main $(pkg-config --libs --cflags fftw3)

    mkdir -p ./result
    build/main > out.txt
  '';

  checkPhase = ''
    echo " hello" >> expected_out.txt
    echo " succ" >> expected_out.txt
    diff out.txt expected_out.txt
  '';

  installPhase = ''
    mkdir -p $out
    cp -r ./build $out
    cp ./out.txt $out
  '';
}
