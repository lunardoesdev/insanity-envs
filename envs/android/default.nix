{ pkgs }:
let
  # Use androidenv to get SDK and NDK
  android = pkgs.androidenv.composeAndroidPackages {
    platformVersions = [ "33" ]; # API 33
    buildToolsVersions = [ "33.0.1" ];
    includeEmulator = false;
    includeNDK = true;
    ndkVersions = [ "26.1.10909125" ]; # NDK r26
  };
  sdk = android.androidsdk;
  ndk = android.ndk;

  # Rust with Android target support
  rust-bin = pkgs.rust-bin.stable.latest.default.override {
    targets = [
      "aarch64-linux-android"
      "armv7-linux-androideabi"
      "i686-linux-android"
      "x86_64-linux-android"
    ];
  };

  # NDK toolchain paths
  ndkRoot = "${ndk}/libexec/android-sdk/ndk-bundle";
  llvmPath = "${ndkRoot}/toolchains/llvm/prebuilt/linux-x86_64/bin";
  clangPrefix = "${ndkRoot}/toolchains/llvm/prebuilt/linux-x86_64/bin";
  target = "aarch64-linux-android"; # default, can be changed
  apiLevel = "33";
in
pkgs.mkShell {
  name = "android-devshell";
  buildInputs = with pkgs; [
    sdk
    ndk
    gradle
    bazel
    cmake
    rust-bin
    # additional build tools
    gnumake
    ninja
    pkg-config
    git
  ];

  shellHook = ''
    # Android SDK & NDK paths
    export ANDROID_HOME="${sdk}/share/android-sdk"
    export ANDROID_SDK_ROOT="$ANDROID_HOME"
    export ANDROID_NDK_HOME="${ndkRoot}"
    export ANDROID_NDK_ROOT="$ANDROID_NDK_HOME"
    export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$PATH"
    export PATH="${llvmPath}:$PATH"

    # Cross‑compilation target
    export TARGET="${target}"
    export API_LEVEL="${apiLevel}"

    # NDK Clang toolchain – use the triplet + API level specific clang
    export CC="${llvmPath}/${target}${apiLevel}-clang"
    export CXX="${llvmPath}/${target}${apiLevel}-clang++"
    export AR="${llvmPath}/llvm-ar"
    export AS="$CC"
    export LD="${llvmPath}/ld.lld"
    export RANLIB="${llvmPath}/llvm-ranlib"
    export NM="${llvmPath}/llvm-nm"
    export STRIP="${llvmPath}/llvm-strip"

    # Basic compiler flags
    export CFLAGS="--target=$TARGET -D__ANDROID_API__=$API_LEVEL"
    export CXXFLAGS="$CFLAGS"
    export LDFLAGS="--target=$TARGET -L$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/$TARGET/$API_LEVEL"

    # Cargo configuration – HARDCODED uppercase target triple
    export CARGO_BUILD_TARGET="$TARGET"
    export CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER="$CC"
    export CARGO_TARGET_AARCH64_LINUX_ANDROID_RUSTFLAGS="-C link-arg=-fuse-ld=lld"

    # Optional: silence pkg-config (avoid host includes)
    export PKG_CONFIG_SYSROOT_DIR="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot"
    export PKG_CONFIG_LIBDIR=""

    echo "✓ Android development shell active"
    echo "  ANDROID_HOME = $ANDROID_HOME"
    echo "  ANDROID_NDK_HOME = $ANDROID_NDK_HOME"
    echo "  Target = $TARGET (API $API_LEVEL)"
    echo "  CC = $CC"
    echo "  Cargo linker = CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER → $CC"
    echo "  Gradle: $(gradle --version | head -n1)"
    echo "  Bazel: $(bazel --version)"
    echo "  CMake: $(cmake --version | head -n1)"
    echo "  Rust: $(rustc --version)"
  '';
}
