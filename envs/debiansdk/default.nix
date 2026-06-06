{ pkgs }:
let
  sdk = pkgs.callPackage ./sdk.nix { };
  rust = pkgs.rust-bin.stable.latest.default.override {
    targets = [ "x86_64-unknown-linux-gnu" ];
  };
  clang' = pkgs.llvmPackages.clang-unwrapped;
  binutils' = pkgs.llvmPackages.bintools-unwrapped;
in
pkgs.mkShell {
  LITOLI_SDK = "${sdk}";
  buildInputs = with pkgs; [
    cmake
    clang'
    llvm
    binutils'
    gnumake
    ninja
    autoconf
    automake
    libtool
    meson
    pkg-config
    zstd
    git
    xmake
    rust
  ];
  shellHook = ''
    export LITOLI_SDK="$LITOLI_SDK"
    export TARGET="x86_64-linux-gnu"
    export CC="${clang'}/bin/clang"
    export CXX="${clang'}/bin/clang++"
    export AS="$CC"
    export ASFLAGS="--target=$TARGET"
    export LD="$CC"
    export LD_FOR_TARGET="$LD"
    export AR=${binutils'}/bin/llvm-ar
    export RANLIB=${binutils'}/bin/llvm-ranlib
    export NM=${binutils'}/bin/llvm-nm
    export STRIP=${binutils'}/bin/llvm-strip
    export INCLUDEDIRS="$LITOLI_SDK/usr/include"
    export LIBDIRS="$LITOLI_SDK/usr/lib/x86_64-linux-gnu"
    export CFLAGS="-I$INCLUDEDIRS --sysroot=$LITOLI_SDK --target=$TARGET"
    export CXXFLAGS="-I$INCLUDEDIRS --sysroot=$LITOLI_SDK --target=$TARGET"
    export LDFLAGS="-fuse-ld=lld -Wl,--allow-shlib-undefined -Wl,--dynamic-linker=/lib64/ld-linux-x86-64.so.2 -L$LIBDIRS --target=$TARGET"

    export PKG_CONFIG_SYSROOT_DIR="$LITOLI_SDK"
    export PKG_CONFIG_LIBDIR="$LITOLI_SDK/usr/lib/pkgconfig:$LITOLI_SDK/usr/share/pkgconfig:$LITOLI_SDK/usr/lib/x86_64-linux-gnu/pkgconfig"

    export CPM_SOURCE_CACHE="$HOME/.cache/CPM"

    export CMAKE_LIBRARY_PATH="$LIBDIRS"
    export CMAKE_INCLUDE_PATH="$INCLUDEDIRS"

    export CARGO_BUILD_TARGET="x86_64-unknown-linux-gnu"
    export CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER="$LD"
    export CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_RUSTFLAGS="-C link-arg=-L$LIBDIRS -C link-arg=--sysroot=$LITOLI_SDK -C link-arg=-Wl,--dynamic-linker=/lib64/ld-linux-x86-64.so.2 -C link-arg=-fuse-ld=lld"

    echo "Litoli dev shell — LITOLI_SDK=$LITOLI_SDK"
  '';
}
