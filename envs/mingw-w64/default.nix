{
  pkgs,
  inputs,
  stdenv,
  makeWrapper,
  ...
}:
let
  pkgsCross = import inputs.nixpkgs {
    config.allowUnfree = true;
    config.android_sdk.accept_license = true;
    config.allowUnsupportedSystem = true;
    localSystem = stdenv.hostPlatform.system;
    crossSystem = {
      config = "x86_64-w64-mingw32";
    };
    overlays = [ (import inputs.rust-overlay) ];
  };
  rust-toolchain = pkgsCross.pkgsBuildHost.rust-bin.stable.latest.default.override {
    targets = [ "x86_64-pc-windows-gnu" ];
  };

  cmake-mingw = stdenv.mkDerivation {
    name = "cmake-wrapper";
    nativeBuildInputs = [ makeWrapper ];
    buildCommand = ''
      mkdir -p $out/bin
      makeWrapper ${pkgs.cmake}/bin/cmake $out/bin/cmake \
        --add-flags "-DCMAKE_BUILD_TYPE=Release" \
        --add-flags "-DCMAKE_SYSTEM_NAME=Windows"
    '';
  };

  dummy = pkgsCross.stdenv.mkDerivation {
    name = "cross-setup";
    src = pkgsCross.writeText "dummy.c" "int main() { return 0; }";
    phases = [ "configurePhase" ];
    nativeBuildInputs = with pkgsCross; [
      cmake
      meson
      ninja
      pkg-config
    ];
    configurePhase = ''
      echo "Running configurePhase — hooks are now active"
    '';
    installPhase = "mkdir -p $out";
  };

in
pkgsCross.callPackage (
  {
    cmake,
    gnumake,
    ninja,
    autoconf,
    automake,
    libtool,
    meson,
    pkg-config,
    zstd,
    git,
    xmake,
    mkShell,
    windows,
    file,
    buildPackages,
    stdenv,
  }:
  mkShell {
    buildInputs = [
      pkgsCross.windows.pthreads
    ];

    inputsFrom = [ dummy ];

    nativeBuildInputs = [
      gnumake
      ninja
      autoconf
      automake
      libtool
      cmake
      pkg-config
      zstd
      git
      xmake
      file
    ];

    shellHook = ''
      export CPM_SOURCE_CACHE="$HOME/.cache/CPM"
    '';
  }
) { }
