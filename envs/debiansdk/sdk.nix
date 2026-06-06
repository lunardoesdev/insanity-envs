{ pkgs }:
pkgs.stdenv.mkDerivation {
  name = "litoli-sdk";
  src = pkgs.fetchurl {
    url = "https://github.com/lunardoesdev/litoli/releases/download/0.1.0/litoli-bookworm-x86_64-unknown-linux-gnu.tar.zst";
    hash = "sha256-FGo5zReqQ57bzI7462zODDR6mRW8xBP2c/9sGUd/FIA=";
  };
  nativeBuildInputs = [ pkgs.zstd ];
  dontUnpack = true;
  dontFixup = true;
  installPhase = ''
    mkdir -p $out
    tar --zstd -xf $src -C $out
  '';
}
