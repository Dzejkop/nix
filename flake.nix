{
  description = "Various nix packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-darwin,
    }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor =
        system:
        if system == "x86_64-darwin" then
          nixpkgs-darwin.legacyPackages.${system}
        else
          nixpkgs.legacyPackages.${system};
    in
    {
      overlays.default = final: _prev: {
        maki = final.callPackage ./packages/maki.nix { };
        iroh-doctor = final.callPackage ./packages/iroh-doctor.nix { };
      };

      packages = forAllSystems (
        system:
        let
          pkgs = (pkgsFor system).extend self.overlays.default;
        in
        {
          inherit (pkgs) maki iroh-doctor;
        }
      );

      formatter = forAllSystems (system: (pkgsFor system).nixfmt);
    };
}
