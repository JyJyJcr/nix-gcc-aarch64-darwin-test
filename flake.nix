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
      stackTest = pkgs.callPackage ./stack/pacakage.nix { };
      fftwTest = pkgs.callPackage ./fftw/pacakage.nix { };
      gcc-unwrapped-patched = pkgs.callPackage ({ lib, stdenv, ... }@args:
        let
          toKernelVer = osxVer:
            let
              major = lib.toIntBase10 (lib.versions.major osxVer);
              minor = lib.toIntBase10 (lib.versions.minor osxVer);
              kernel = if major == 10 then
              # macOS 10.x
                minor + 4
              else if (11 <= major && major <= 15) then
              # macOS 11.x to 15.x
                major + 9
              else
              # macOS 26.x and later
                major - 1;
            in kernel;

        in (pkgs.gcc.cc.override args).overrideAttrs (old: {
          patches = old.patches ++ [ ./darwin-version-insertion.patch ];

          env = old.env // {
            nix_darwin_host_version = if stdenv.hostPlatform.isDarwin then
              toKernelVer stdenv.hostPlatform.darwinMinVersion
            else
              "";
            nix_darwin_build_version = if stdenv.buildPlatform.isDarwin then
              toKernelVer stdenv.buildPlatform.darwinMinVersion
            else
              "";
            nix_darwin_target_version = if stdenv.targetPlatform.isDarwin then
              toKernelVer stdenv.targetPlatform.darwinMinVersion
            else
              "";
          };
        })) { };

      gcc-patched = pkgs.wrapCC (gcc-unwrapped-patched);
      gfortran-patched = pkgs.wrapCC (gcc-unwrapped-patched.override {
        name = "gfortran";
        langFortran = true;
        langCC = false;
        langC = false;
        profiledCompiler = false;
      });

      stackTest-patched = stackTest.override { gcc = gcc-patched; };
      fftwTest-patched = fftwTest.override { gfortran = gfortran-patched; };

      stackTest-workaround = pkgs.callPackage ./stack/pacakage.nix {
        flags = "-fstack-use-cumulative-args";
      };
    in {

      packages.${system} = {
        stackTest = stackTest;
        stackTest-patched = stackTest-patched;
        stackTest-workaround = stackTest-workaround;
        fftwTest = fftwTest;
        fftwTest-patched = fftwTest-patched;
        gcc-unwrapped-patched = gcc-unwrapped-patched;
        gcc-patched = gcc-patched;
      };

      checks.${system} = {
        stackTest = stackTest.overrideAttrs (old: {
          doCheck = true;
          installPhase = "mkdir -p $out";
        });
        stackTest-patched = stackTest-patched.overrideAttrs (old: {
          doCheck = true;
          installPhase = "mkdir -p $out";
        });
        stackTest-workaround = stackTest-workaround.overrideAttrs (old: {
          doCheck = true;
          installPhase = "mkdir -p $out";
        });
        fftwTest = fftwTest.overrideAttrs (old: {
          doCheck = true;
          installPhase = "mkdir -p $out";
        });
        fftwTest-patched = fftwTest-patched.overrideAttrs (old: {
          doCheck = true;
          installPhase = "mkdir -p $out";
        });
      };

      devShells.${system}.default = pkgs.mkShell { packages = [ pkgs.gcc ]; };
    };
}

