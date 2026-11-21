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
        devmachineLib = import ./mkvm.nix { inherit (nixpkgs) lib; };
        devmachineModule = flake-parts-lib.importApply ./flake-module.nix { inherit (devmachineLib) mkVM; };
      in
      {
        imports = [ devmachineModule ];

        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];

        flake = {
          flakeModules = {
            default = devmachineModule;
            devmachine = devmachineModule;
          };

          templates.default = {
            path = ./templates/default;
            description = "Project with services running in devmachine VM";
          };

          lib = devmachineLib;
        };

        perSystem =
          { pkgs, ... }:
          {
            formatter = pkgs.nixfmt-tree;
          };
      }
    );
}
