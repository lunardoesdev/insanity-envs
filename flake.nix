{
  description = "Litoli CMake/Nix cross-compilation example";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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
            ndkver = "26.1.10909125";
            platformver = "34.0.0";
            builttoolsver = "34";
          };
        }
      );

      formatter = forAllSystems (system: (import nixpkgs { inherit system; }).nixfmt-tree);
    };
}
