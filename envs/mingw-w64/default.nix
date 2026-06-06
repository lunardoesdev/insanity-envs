{ pkgs, inputs, ... }:
let
    pkgsWin = pkgs.callPackage ./pkgsWin.nix { inherit inputs; };
in
pkgsWin.mkShell {
  buildInputs = with pkgsWin; [
    cmake
    clang
    llvm
    binutils
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
      targets = [ "x86_64-pc-windows-gnullvm" ];
    })
  ];

  shellHook = ''
    export TARGET="x86_64-pc-windows-gnullvm"

    # Compilers and assembler
    export CC="${pkgsWin.clang}/bin/clang"
    export CXX="${pkgsWin.clang}/bin/clang++"
    export AS="$CC"
    export ASFLAGS="--target=$TARGET"

    # Linker (use Clang as driver + lld internally)
    export LD="$CC"
    export LD_FOR_TARGET="$LD"

    # LLVM binutils tools
    export AR="${pkgsWin.binutils}/bin/llvm-ar"
    export RANLIB="${pkgsWin.binutils}/bin/llvm-ranlib"
    export NM="${pkgsWin.binutils}/bin/llvm-nm"
    export STRIP="${pkgsWin.binutils}/bin/llvm-strip"

    # CMake hints
    export CMAKE_LIBRARY_PATH="$LIBDIRS"
    export CMAKE_INCLUDE_PATH="$INCLUDEDIRS"
    
export CMAKE_C_COMPILER_TARGET=x86_64-pc-windows-gnu
export CMAKE_CXX_COMPILER_TARGET=x86_64-pc-windows-gnu
export CMAKE_C_COMPILER_WORKS=ON 
export CMAKE_CXX_COMPILER_WORKS=ON 
export CMAKE_SYSROOT="$MINGW_SDK"

    
  '';
}