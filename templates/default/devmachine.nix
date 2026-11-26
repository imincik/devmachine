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
        # NixOS configuration of services running in the VM
        services = {
          # Test service, follow its output with `journalctl -fu hello`
          systemd.services.hello = {
            description = "Hello test service";
            wantedBy = [ "multi-user.target" ];
            script = ''
              while true; do
                echo "Hello from devmachine"
                sleep 10
              done
            '';
          };
        };

        # Ports forwarded from the host to the VM
        forwardPorts = [ ];

        # Packages installed in the VM
        packages = [
          # pkgs.claude-code
          pkgs.git
          pkgs.vim
        ];
      };

      devmachine.shell = {
        # Packages available in the shell environment
        packages = [ ];

        # Environment variables set in the shell environment
        environment = {
        };

        # Shell hook run when entering the shell environment
        shellHook = "";
      };
    };
}
