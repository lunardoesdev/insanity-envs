{pkgs, inputs, system}: import inputs.nixpkgs {
    inherit system;
    crossSystem = {
        config = "x86_64-w64-mingw32";
        libc = "ucrt";
        useLLVM = true;
        rust.rustcTarget = "x86_64-pc-windows-gnullvm";
    };
}