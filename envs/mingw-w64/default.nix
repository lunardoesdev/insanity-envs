{ pkgs }:
let
  # MinGW-w64 SDK from nixpkgs (provides headers/libs for x86_64-w64-mingw32)
  mingwSdk = pkgs.buildPackages.mingw_w64 or pkgs.mingw_w64;

  # Unwrapped Clang and LLVM tools (lld, llvm-ar, etc.)
  clang' = pkgs.llvmPackages.clang-unwrapped;
  binutils' = pkgs.llvmPackages.bintools-unwrapped;

  # Desired Windows target triple
  target = "x86_64-pc-windows-gnu";

  # Actual sysroot subdirectory used by MinGW-w64 in nixpkgs
  # (the package installs headers/libs into $out/x86_64-w64-mingw32)
  mingwSubdir = "x86_64-w64-mingw32";
in
pkgs.mkShell {
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
    # Optional: Rust with MinGW target support
    (rust-bin.stable.latest.default.override {
      targets = [ target ];
    })
  ];

  shellHook = ''
    export MINGW_SDK="${mingwSdk}"
    export TARGET="${target}"

    # Compilers and assembler
    export CC="${clang'}/bin/clang"
    export CXX="${clang'}/bin/clang++"
    export AS="$CC"
    export ASFLAGS="--target=$TARGET"

    # Linker (use Clang as driver + lld internally)
    export LD="$CC"
    export LD_FOR_TARGET="$LD"

    # LLVM binutils tools
    export AR="${binutils'}/bin/llvm-ar"
    export RANLIB="${binutils'}/bin/llvm-ranlib"
    export NM="${binutils'}/bin/llvm-nm"
    export STRIP="${binutils'}/bin/llvm-strip"

    # Headers and libraries from the MinGW sysroot
    export INCLUDEDIRS="$MINGW_SDK/${mingwSubdir}/include"
    export LIBDIRS="$MINGW_SDK/${mingwSubdir}/lib"

    # Compiler flags: target triple + sysroot override + explicit include path
    export CFLAGS="--target=$TARGET --sysroot=$MINGW_SDK -I$INCLUDEDIRS"
    export CXXFLAGS="--target=$TARGET --sysroot=$MINGW_SDK -I$INCLUDEDIRS"
    # Linker flags: use lld, point to sysroot libs
    export LDFLAGS="--target=$TARGET --sysroot=$MINGW_SDK -L$LIBDIRS -fuse-ld=lld"

    # pkg-config configuration for cross-compilation
    export PKG_CONFIG_SYSROOT_DIR="$MINGW_SDK"
    export PKG_CONFIG_LIBDIR="$MINGW_SDK/${mingwSubdir}/lib/pkgconfig:$MINGW_SDK/lib/pkgconfig"

    # CMake hints
    export CMAKE_LIBRARY_PATH="$LIBDIRS"
    export CMAKE_INCLUDE_PATH="$INCLUDEDIRS"

    # Rust configuration (if Rust is used)
    export CARGO_BUILD_TARGET="$TARGET"
    # Rust's target triplet for x86_64-pc-windows-gnu uses the same name
    export CARGO_TARGET_X86_64_PC_WINDOWS_GNU_LINKER="$CC"
    export CARGO_TARGET_X86_64_PC_WINDOWS_GNU_RUSTFLAGS="-C link-arg=-L$LIBDIRS -C link-arg=--sysroot=$MINGW_SDK -C link-arg=-fuse-ld=lld"

    echo "MinGW-w64 cross shell — target $TARGET, sysroot: $MINGW_SDK"
  '';
}