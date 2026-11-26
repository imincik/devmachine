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
        devmachineLib = import ./lib.nix { inherit (nixpkgs) lib; };
        devmachineModule = flake-parts-lib.importApply ./flake-module.nix {
          inherit (devmachineLib) mkSystem;
        };
      in
      {
        imports = [
          devmachineModule
          ./devmachine.nix
        ];

        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];

        flake = {
          flakeModules = {
            default = devmachineModule;
            devmachine = devmachineModule;
          };

          templates = {
            default = {
              path = ./templates/default;
              description = "Default devmachine template";
            };
            postgres = {
              path = ./templates/postgres;
              description = "Template with postgresql service";
            };
          };

          lib = devmachineLib;
        };

        perSystem =
          { pkgs, system, ... }:
          {
            formatter = pkgs.nixfmt-tree;

            # Test that the template VM is building
            checks.template-vm =
              (flake-parts.lib.mkFlake { inherit inputs; } {
                imports = [
                  devmachineModule
                  ./templates/default/devmachine.nix
                ];
                systems = [ system ];
              }).packages.${system}.devmachine-vm;

            # Test that the VM with Nix enabled is building
            checks.nix-vm =
              (flake-parts.lib.mkFlake { inherit inputs; } {
                imports = [ devmachineModule ];
                systems = [ system ];
                perSystem.devmachine.vm.nix = true;
              }).packages.${system}.devmachine-vm;
          };
      }
    );
}
