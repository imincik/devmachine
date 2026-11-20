{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { flake-parts-lib, ... }:
      let
        devosModule = flake-parts-lib.importApply ./flake-module.nix { inherit nixpkgs; };
      in
      {
        imports = [ devosModule ];

        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];

        flake = {
          flakeModules = {
            default = devosModule;
            devos = devosModule;
          };

          templates.default = {
            path = ./templates/default;
            description = "Project with services running in devos VM";
          };

          lib = import ./mkvm.nix { inherit (nixpkgs) lib; };
        };
      }
    );
}
