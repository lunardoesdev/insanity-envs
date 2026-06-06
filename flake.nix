{
  description = "Litoli CMake/Nix cross-compilation example";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs =
    {
      self,
      nixpkgs,
      rust-overlay,
      ...
    }@inputs:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
      rustOverlay = (import rust-overlay);
      pkgsForSystem =
        system:
        import nixpkgs {
          inherit system;
          overlays = [ rustOverlay ];
          config.allowUnfree = true;
          config.android_sdk.accept_license = true;
          config.allowUnsupportedSystem = true;
        };
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsForSystem system;
        in
        {
          debian = pkgs.callPackage ./envs/debiansdk { };
          android = pkgs.callPackage ./envs/android {
            ndkvers = [ "29.0.14206865" ];
            platformvers = [
              "37"
              "36"
              "24"
            ];
            builttoolsvers = [
              "37.0.0"
              "36.0.0"
              "24.0.0"
            ];
          };
          windows = pkgs.callPackage ./envs/mingw-w64 {
            inherit inputs;
          };
        }
      );

      formatter = forAllSystems (system: (import nixpkgs { inherit system; }).nixfmt-tree);
    };
}
