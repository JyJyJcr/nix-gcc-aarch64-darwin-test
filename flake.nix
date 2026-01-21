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
      gcc-unwrapped-patched = pkgs.gcc.cc.overrideAttrs (old: {
        configureFlags = old.configureFlags
          ++ [ "--build=aarch64-apple-darwin" ];
        configurePlatforms = [ ];
        patches = old.patches ++ [ ./any-aarch64-darwin.patch ];
        #pkgs.lib.filter (x: x != "target") old.configurePlatforms;
      });
      gcc-patched = pkgs.wrapCC (gcc-unwrapped-patched);

      stackTest-patched = stackTest.override { gcc = gcc-patched; };
    in {
      packages.${system} = {
        stackTest = stackTest;
        stackTest-patched = stackTest-patched;
        fftwTest = fftwTest;
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
        fftwTest = fftwTest.overrideAttrs (old: {
          doCheck = true;
          installPhase = "mkdir -p $out";
        });
      };

      devShells.${system}.default = pkgs.mkShell { packages = [ pkgs.gcc ]; };
    };
}

