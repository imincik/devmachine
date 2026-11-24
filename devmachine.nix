# Development environment of devmachine itself
{ inputs, ... }:
{
  perSystem =
    {
      lib,
      pkgs,
      system,
      ...
    }:
    {
      # Allow unfree packages used in this configuration
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "claude-code" ];
      };

      devmachine.vm = {
        # Packages installed in the VM
        packages = [
          pkgs.claude-code
          pkgs.git
          pkgs.helix
          pkgs.python3
          pkgs.zellij

          # Tools used to develop and check dev.sh and Nix files
          pkgs.nixfmt-tree
          pkgs.shellcheck
        ];
      };
    };
}
